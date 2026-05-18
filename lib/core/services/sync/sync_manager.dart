import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'package:new_care/core/services/firebase/firebase_service.dart';
import 'package:new_care/core/services/local/sqlite_service.dart';
import 'package:new_care/core/services/network/connectivity_service.dart';
import 'package:new_care/features/shifts/data/models/shift_model.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/procedures/data/models/procedure_model.dart';
import 'package:new_care/features/auth/data/models/user_model.dart';
import 'package:new_care/features/payroll/data/models/payroll_model.dart';
import 'package:new_care/features/financials/data/models/expense_model.dart';
import 'package:new_care/core/services/sync/sync_progress.dart';





/// خدمة المزامنة الشاملة (الجيل الثاني) - SyncManager v2
/// Robust, queue-based, offline-first sync orchestrator.
class SyncManager {
  static SyncManager? _instance;
  final FirebaseService _firebaseService;
  final SqliteService _sqliteService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  StreamSubscription? _connectivitySub;

  // بث تقدم المزامنة - Sync progress stream
  final _progressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get progressStream => _progressController.stream;

  SyncManager._()
    : _firebaseService = FirebaseService.instance,
      _sqliteService = SqliteService.instance,
      _connectivityService = ConnectivityService.instance {
    _initAutoSync();
  }

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  void _initAutoSync() {
    // المزامنة التلقائية معطلة - كل العمليات محلية فقط
    // Auto-sync disabled: all operations are local-only.
    // Firebase sync only happens via manual "مزامنة إجبارية شاملة" button.
    // _autoSyncTimer = Timer.periodic(
    //   const Duration(minutes: 5),
    //   (_) => syncAll(),
    // );
    // _connectivitySub = _connectivityService.connectivityStream.listen((
    //   isConnected,
    // ) {
    //   if (isConnected) {
    //     log('[SyncManager] Connection restored, triggering sync');
    //     syncAll();
    //   }
    // });
  }

  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivitySub?.cancel();
    _progressController.close();
  }

  /// بث تقدم المزامنة للواجهة - Emit progress to UI
  void _emitProgress(String message, {String icon = '🔄', int step = 0, int total = 1, bool isDone = false, bool isError = false}) {
    _progressController.add(SyncProgress(
      message: message,
      icon: icon,
      currentStep: step,
      totalSteps: total,
      isDone: isDone,
      isError: isError,
    ));
  }

  // ============================================
  // === إدارة الطابور - Queue Management ===
  // ============================================

  /// إضافة عملية إلى طابور المزامنة
  /// Enqueue an operation for background sync
  Future<void> enqueue({
    required String tableName,
    required String operation, // 'create', 'update', 'delete'
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final db = await _sqliteService.database;
      final syncId =
          '${tableName}_$docId'; // Use a predictable ID to prevent duplicate pending ops for same record

      await db.insert('pending_sync', {
        'id': syncId,
        'tableName': tableName,
        'operation': operation,
        'docId': docId,
        'data': jsonEncode(data),
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Apply locally if it's a deduction to keep UI in sync
      if (tableName == 'inventory' && operation == 'deduct') {
        final qty = (data['quantity'] ?? 0) as int;
        await _sqliteService.deductInventory(docId, qty);
      }

      log('[SyncManager] Enqueued: $operation on $tableName/$docId');

      // المزامنة التلقائية معطلة - العمليات تتراكم محلياً حتى المزامنة اليدوية
      // Auto-sync disabled: operations accumulate locally until manual sync
    } catch (e) {
      log('[SyncManager] Failed to enqueue operation: $e');
    }
  }

  /// Alias for compatibility
  Future<void> addPendingOperation({
    required String tableName,
    required String operation,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    return enqueue(
      tableName: tableName,
      operation: operation,
      docId: docId,
      data: data,
    );
  }

  // ============================================
  // === المزامنة - Synchronization ===
  // ============================================

  /// مزامنة شاملة - رفع كل البيانات المحلية إلى Firestore
  /// Full Sync: Upload ALL local database records to Firestore (not just pending)
  Future<void> syncAll() async {
    if (_isSyncing) return;

    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) return;

    _isSyncing = true;
    log('[SyncManager] Starting FULL sync (uploading all local data)...');

    try {
      // رفع كل البيانات من قاعدة البيانات المحلية إلى Firestore
      await _uploadAllLocalData();

      log('[SyncManager] Full sync completed successfully');
    } catch (e) {
      log('[SyncManager] Full sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// مزامنة فئة معينة - رفع فئة محددة من البيانات المحلية إلى Firestore
  /// Partial Sync: Upload ONLY a specific table's local records to Firestore
  Future<void> syncCategory(String tableName) async {
    if (_isSyncing) return;

    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) return;

    _isSyncing = true;
    log('[SyncManager] Starting partial sync for table "$tableName"...');

    try {
      final db = await _sqliteService.database;

      switch (tableName) {
        case 'users':
          _emitProgress('مسح الموظفين القدامى...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('users');
          final users = await db.query('users');
          _emitProgress('الموظفين — ${users.length} سجل', icon: '👥', step: 1, total: 3);
          for (var u in users) {
            try {
              final model = UserModel.fromMap(u, u['id'] as String);
              await _firebaseService.updateUser(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload user ${u['id']}: $e');
            }
          }
          break;
        case 'cases':
          _emitProgress('مسح الحالات القديمة...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('cases');
          final cases = await db.query('cases');
          _emitProgress('الحالات — ${cases.length} سجل', icon: '🏥', step: 1, total: 3);
          for (var c in cases) {
            try {
              final model = CaseModel.fromMap(c, c['id'] as String);
              await _firebaseService.updateCase(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload case ${c['id']}: $e');
            }
          }
          break;
        case 'inventory':
          _emitProgress('مسح المخزون القديم...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('inventory');
          final inventory = await db.query('inventory');
          _emitProgress('المخزون — ${inventory.length} صنف', icon: '📦', step: 1, total: 3);
          for (var i in inventory) {
            try {
              final model = InventoryModel.fromMap(i, i['id'] as String);
              await _firebaseService.updateInventoryItem(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload inventory ${i['id']}: $e');
            }
          }
          break;
        case 'procedures':
          _emitProgress('مسح الإجراءات القديمة...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('procedures');
          final procedures = await db.query('procedures');
          _emitProgress('الإجراءات — ${procedures.length} إجراء', icon: '💊', step: 1, total: 3);
          for (var p in procedures) {
            try {
              final model = ProcedureModel.fromMap(p, p['id'] as String);
              await _firebaseService.updateProcedure(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload procedure ${p['id']}: $e');
            }
          }
          break;
        case 'shifts':
          _emitProgress('مسح الورديات القديمة...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('shifts');
          final shifts = await db.query('shifts');
          _emitProgress('الورديات — ${shifts.length} وردية', icon: '📅', step: 1, total: 3);
          for (var s in shifts) {
            try {
              final model = ShiftModel.fromMap(s, s['id'] as String);
              await _firebaseService.updateShift(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload shift ${s['id']}: $e');
            }
          }
          break;
        case 'attendance':
          _emitProgress('مسح الحضور القديم...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('attendance');
          final attendance = await db.query('attendance');
          _emitProgress('الحضور — ${attendance.length} سجل', icon: '✅', step: 1, total: 3);
          for (var a in attendance) {
            try {
              final model = AttendanceModel.fromMap(a, a['id'] as String);
              await _firebaseService.checkIn(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload attendance ${a['id']}: $e');
            }
          }
          break;
        case 'payroll':
          _emitProgress('مسح الرواتب القديمة...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('payroll');
          final payroll = await db.query('payroll');
          _emitProgress('الرواتب — ${payroll.length} سجل', icon: '💰', step: 1, total: 3);
          for (var p in payroll) {
            try {
              final model = PayrollModel.fromMap(p, p['id'] as String);
              await _firebaseService.updatePayroll(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload payroll ${p['id']}: $e');
            }
          }
          break;
        case 'expenses':
          _emitProgress('مسح المصاريف القديمة...', icon: '🗑️', step: 0, total: 3);
          await _firebaseService.clearCollectionByName('expenses');
          final expenses = await db.query('expenses');
          _emitProgress('المصاريف — ${expenses.length} سجل', icon: '💳', step: 1, total: 3);
          for (var ex in expenses) {
            try {
              final model = ExpenseModel.fromMap(ex, ex['id'] as String);
              await _firebaseService.updateExpense(model).timeout(const Duration(seconds: 30));
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              log('[SyncManager] ❌ Failed to upload expense ${ex['id']}: $e');
            }
          }
          break;
        default:
          throw Exception('Unknown table: $tableName');
      }

      // تنظيف طابور المزامنة الخاص بهذا الجدول
      _emitProgress('تنظيف الطابور...', icon: '🧹', step: 2, total: 3);
      await db.delete('pending_sync', where: 'tableName = ?', whereArgs: [tableName]);
      _emitProgress('تمت مزامنة القسم بنجاح ✓', icon: '🎉', step: 3, total: 3, isDone: true);
      log('[SyncManager] ✓ Category "$tableName" uploaded & pending queue cleared');
    } catch (e) {
      _emitProgress('فشلت المزامنة: $e', icon: '❌', isError: true);
      log('[SyncManager] Sync category "$tableName" error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Alias for high-level services
  Future<void> processQueue() async {
    await _uploadPendingChanges();
  }

  /// تحميل كل البيانات من السحابة - Download all data from Firestore to local SQLite
  /// يضيف الجديد فقط بدون حذف البيانات الموجودة
  /// Downloads ALL Firestore data and merges into local DB (no deletes, only add/update)
  Future<void> downloadFromCloud() async {
    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) {
      log('[SyncManager] No connection, skipping cloud download');
      return;
    }

    log('[SyncManager] Downloading ALL data from cloud (merge mode)...');
    try {
      await _downloadAllFromCloud();
      log('[SyncManager] Cloud download completed');
    } catch (e) {
      log('[SyncManager] Cloud download error: $e');
    }
  }

  /// تنزيل حالة محددة من السحابة - Download a specific case from cloud
  Future<CaseModel?> downloadCase(String id) async {
    try {
      final c = await _firebaseService.getCaseById(id);
      if (c != null) {
        await _sqliteService.saveCase(c.toSqliteMap());
        log('[SyncManager] ✓ Successfully synced case $id from cloud');
        return c;
      }
      return null;
    } catch (e) {
      log('[SyncManager] Error syncing case $id: $e');
      return null;
    }
  }

  /// تنزيل سجل حضور محدد - Download a specific attendance record
  Future<void> downloadAttendance(String id) async {
    try {
      final a = await _firebaseService.getAttendanceById(id);
      if (a != null) {
        await _sqliteService.insert('attendance', a.toSqliteMap());
        await _sqliteService.cleanupDuplicateAttendance();
        log('[SyncManager] ✓ Successfully synced attendance $id from cloud');
      }
    } catch (e) {
      log('[SyncManager] Error syncing attendance $id: $e');
    }
  }

  /// تنزيل صنف مخزون محدد - Download a specific inventory item
  Future<void> downloadInventoryItem(String id) async {
    try {
      final i = await _firebaseService.getInventoryItemById(id);
      if (i != null) {
        await _sqliteService.insert('inventory', i.toSqliteMap());
        log('[SyncManager] ✓ Successfully synced inventory item $id from cloud');
      }
    } catch (e) {
      log('[SyncManager] Error syncing inventory item $id: $e');
    }
  }

  /// حذف حالة محلياً - Delete a case locally
  Future<void> deleteCaseLocally(String id) async {
    try {
      await _sqliteService.delete('cases', where: 'id = ?', whereArgs: [id]);
      log('[SyncManager] ✓ Successfully deleted case $id locally');
    } catch (e) {
      log('[SyncManager] Error deleting case $id locally: $e');
    }
  }

  /// رفع التغييرات المحلية - Upload pending changes to Firebase
  Future<void> _uploadPendingChanges() async {
    final db = await _sqliteService.database;
    final pending = await db.query(
      'pending_sync',
      orderBy: 'createdAt ASC',
      limit:
          50, // Process max 10 operations per cycle to prevent overwhelming the API
    );

    if (pending.isEmpty) return;
    log('[SyncManager] Processing ${pending.length} pending uploads...');

    for (var op in pending) {
      final id = op['id'] as String;
      final tableName = op['tableName'] as String;
      final operation = op['operation'] as String;
      final docId = op['docId'] as String;
      final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;
      final retryCount = op['retryCount'] as int;

      try {
        // Add timeout to prevent hanging
        log('[SyncManager] Syncing $tableName/$docId (Operation: $operation)');

        await _dispatchOperation(
          tableName,
          operation,
          docId,
          data,
        ).timeout(const Duration(seconds: 30));

        // Success: Remove from queue
        await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
        log('[SyncManager] ✓ Successfully synced $tableName/$docId');

        // Increased delay to avoid rapid-fire Firebase operations on Windows
        await Future.delayed(const Duration(milliseconds: 250));
      } on TimeoutException {
        log(
          '[SyncManager] ⏱️ Timeout syncing $tableName/$docId (Attempt ${retryCount + 1})',
        );

        // Timeout: Update retry count and continue
        await db.update(
          'pending_sync',
          {
            'retryCount': retryCount + 1,
            'lastError': 'Timeout after 30 seconds',
            'lastAttempt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        if (retryCount >= 5) {
          log(
            '[SyncManager] ❌ Max retries reached for $tableName/$docId. Discarding timeout.',
          );
          await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
        }
        // Break to avoid more timeouts
        break;
      } catch (e, st) {
        log(
          '[SyncManager] ❌ Failed to sync $tableName/$docId (Attempt ${retryCount + 1}): $e',
        );
        log('[SyncManager] Stack trace: $st');

        // Error: Update retry count and last error
        await db.update(
          'pending_sync',
          {
            'retryCount': retryCount + 1,
            'lastError': e.toString(),
            'lastAttempt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        if (retryCount >= 10) {
          log(
            '[SyncManager] ❌ Max retries reached for $tableName/$docId. Discarding.',
          );
          await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
        }

        // Break the loop if it's a network/connection error or permission issue to avoid multiple quick failures
        if (e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('disconnected') ||
            e.toString().contains('permission-denied') ||
            e.toString().contains('socket')) {
          log(
            '[SyncManager] 🔌 Connection or permission error detected. Stopping sync cycle.',
          );
          break;
        }
      }
    }
  }

  /// توزيع العملية على الخدمة المناسبة - Dispatch operation to Firebase
  Future<void> _dispatchOperation(
    String table,
    String op,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      log('[SyncManager] Dispatching $op on $table/$id');

      switch (table) {
        case 'cases':
          try {
            final model = CaseModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deleteCase(id);
            } else {
              // Idempotent: set/update will work regardless of 'create' vs 'update'
              await _firebaseService.updateCase(model);
            }
            log('[SyncManager] Case operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Case model/operation error: $e');
            log('[SyncManager] Case stack: $st');
            log('[SyncManager] Case data keys: ${data.keys.toString()}');
            rethrow;
          }
          break;
        case 'inventory':
          try {
            if (op == 'delete') {
              await _firebaseService.deleteInventoryItem(id);
            } else if (op == 'deduct') {
              final qty = (data['quantity'] ?? 0) as int;
              log('[SyncManager] Attempting to deduct $qty from inventory $id');
              // Deduct operations can safely fail without crashing sync
              try {
                await _firebaseService
                    .deductInventoryItem(id, qty)
                    .timeout(
                      const Duration(seconds: 15),
                    ); // Shorter timeout for deduct
              } catch (deductError) {
                log(
                  '[SyncManager] Deduct operation failed (non-fatal): $deductError',
                );
                // Don't rethrow - deduct failures are recoverable
              }
            } else {
              final model = InventoryModel.fromMap(data, id);
              await _firebaseService.updateInventoryItem(model);
            }
            log('[SyncManager] Inventory operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Inventory operation error: $e');
            log('[SyncManager] Inventory stack: $st');
            rethrow;
          }
          break;
        case 'attendance':
          try {
            if (op == 'update') {
              // checkOut logic handles timestamp directly on Firebase
              await _firebaseService.checkOut(id);
            } else {
              final model = AttendanceModel.fromMap(data, id);
              await _firebaseService.checkIn(model);
            }
            log('[SyncManager] Attendance operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Attendance operation error: $e');
            log('[SyncManager] Attendance stack: $st');
            rethrow;
          }
          break;
        case 'shifts':
          try {
            final model = ShiftModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deleteShift(id);
            } else {
              await _firebaseService.updateShift(model);
            }
            log('[SyncManager] Shift operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Shift operation error: $e');
            log('[SyncManager] Shift stack: $st');
            rethrow;
          }
          break;
        case 'procedures':
          try {
            final model = ProcedureModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deleteProcedure(id);
            } else {
              await _firebaseService.updateProcedure(model);
            }
            log('[SyncManager] Procedure operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Procedure operation error: $e');
            log('[SyncManager] Procedure stack: $st');
            rethrow;
          }
          break;
        case 'users':
          try {
            final model = UserModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deleteUser(id);
            } else {
              await _firebaseService.updateUser(model);
            }
            log('[SyncManager] User operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] User operation error: $e');
            log('[SyncManager] User stack: $st');
            rethrow;
          }
          break;
        case 'payroll':
          try {
            final model = PayrollModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deletePayroll(id);
            } else {
              await _firebaseService.updatePayroll(model);
            }
            log('[SyncManager] Payroll operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Payroll operation error: $e');
            log('[SyncManager] Payroll stack: $st');
            rethrow;
          }
          break;
        case 'expenses':
          try {
            final model = ExpenseModel.fromMap(data, id);
            if (op == 'delete') {
              await _firebaseService.deleteExpense(id);
            } else {
              await _firebaseService.updateExpense(model);
            }
            log('[SyncManager] Expense operation completed: $op on $id');
          } catch (e, st) {
            log('[SyncManager] Expense operation error: $e');
            log('[SyncManager] Expense stack: $st');
            rethrow;
          }
          break;
        default:
          throw Exception('Unknown table: $table');
      }
    } catch (e, st) {
      log('[SyncManager] Dispatch operation error for $table/$op/$id: $e');
      log('[SyncManager] Dispatch stack: $st');
      rethrow;
    }
  }

  /// استبدال كل البيانات في Firestore بالبيانات المحلية
  /// Replace ALL Firestore data with local SQLite data
  Future<void> _uploadAllLocalData() async {
    final db = await _sqliteService.database;
    const totalSteps = 10; // clear + 8 tables + done

    try {
      // 0. مسح كل البيانات من Firestore
      _emitProgress('مسح البيانات القديمة...', icon: '🗑️', step: 0, total: totalSteps);
      log('[SyncManager] Clearing all Firestore data...');
      await _firebaseService.clearAllCollections();

      // 1. رفع المستخدمين
      final users = await db.query('users');
      _emitProgress('الموظفين — ${users.length} سجل', icon: '👥', step: 1, total: totalSteps);
      log('[SyncManager] Uploading ${users.length} users...');
      for (var u in users) {
        try {
          final model = UserModel.fromMap(u, u['id'] as String);
          await _firebaseService.updateUser(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload user ${u['id']}: $e');
        }
      }

      // 2. رفع الحالات
      final cases = await db.query('cases');
      _emitProgress('الحالات — ${cases.length} سجل', icon: '🏥', step: 2, total: totalSteps);
      log('[SyncManager] Uploading ${cases.length} cases...');
      for (var c in cases) {
        try {
          final model = CaseModel.fromMap(c, c['id'] as String);
          await _firebaseService.updateCase(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload case ${c['id']}: $e');
        }
      }

      // 3. رفع المخزون
      final inventory = await db.query('inventory');
      _emitProgress('المخزون — ${inventory.length} صنف', icon: '📦', step: 3, total: totalSteps);
      log('[SyncManager] Uploading ${inventory.length} inventory items...');
      for (var i in inventory) {
        try {
          final model = InventoryModel.fromMap(i, i['id'] as String);
          await _firebaseService.updateInventoryItem(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload inventory ${i['id']}: $e');
        }
      }

      // 4. رفع الإجراءات
      final procedures = await db.query('procedures');
      _emitProgress('الإجراءات — ${procedures.length} إجراء', icon: '💊', step: 4, total: totalSteps);
      log('[SyncManager] Uploading ${procedures.length} procedures...');
      for (var p in procedures) {
        try {
          final model = ProcedureModel.fromMap(p, p['id'] as String);
          await _firebaseService.updateProcedure(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload procedure ${p['id']}: $e');
        }
      }

      // 5. رفع الورديات
      final shifts = await db.query('shifts');
      _emitProgress('الورديات — ${shifts.length} وردية', icon: '📅', step: 5, total: totalSteps);
      log('[SyncManager] Uploading ${shifts.length} shifts...');
      for (var s in shifts) {
        try {
          final model = ShiftModel.fromMap(s, s['id'] as String);
          await _firebaseService.updateShift(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload shift ${s['id']}: $e');
        }
      }

      // 6. رفع الحضور
      final attendance = await db.query('attendance');
      _emitProgress('الحضور — ${attendance.length} سجل', icon: '✅', step: 6, total: totalSteps);
      log('[SyncManager] Uploading ${attendance.length} attendance records...');
      for (var a in attendance) {
        try {
          final model = AttendanceModel.fromMap(a, a['id'] as String);
          await _firebaseService.checkIn(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload attendance ${a['id']}: $e');
        }
      }

      // 7. رفع الرواتب
      final payroll = await db.query('payroll');
      _emitProgress('الرواتب — ${payroll.length} سجل', icon: '💰', step: 7, total: totalSteps);
      log('[SyncManager] Uploading ${payroll.length} payroll records...');
      for (var p in payroll) {
        try {
          final model = PayrollModel.fromMap(p, p['id'] as String);
          await _firebaseService.updatePayroll(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload payroll ${p['id']}: $e');
        }
      }

      // 8. رفع المصاريف
      final expenses = await db.query('expenses');
      _emitProgress('المصاريف — ${expenses.length} سجل', icon: '💳', step: 8, total: totalSteps);
      log('[SyncManager] Uploading ${expenses.length} expenses...');
      for (var ex in expenses) {
        try {
          final model = ExpenseModel.fromMap(ex, ex['id'] as String);
          await _firebaseService.updateExpense(model).timeout(const Duration(seconds: 30));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          log('[SyncManager] ❌ Failed to upload expense ${ex['id']}: $e');
        }
      }

      // 9. مسح طابور المزامنة
      _emitProgress('تنظيف الطابور...', icon: '🧹', step: 9, total: totalSteps);
      await db.delete('pending_sync');
      _emitProgress('تمت المزامنة بنجاح ✓', icon: '🎉', step: totalSteps, total: totalSteps, isDone: true);
      log('[SyncManager] ✓ All local data uploaded & pending queue cleared');

    } catch (e) {
      _emitProgress('فشلت المزامنة: $e', icon: '❌', isError: true);
      log('[SyncManager] Upload all local data error: $e');
      rethrow;
    }
  }

  /// تنزيل كل البيانات من Firestore إلى SQLite (بدون حذف - إضافة/تحديث فقط)
  /// Download ALL data from Firestore and merge into SQLite (no deletes, only insert/update)
  Future<void> _downloadAllFromCloud() async {
    const totalSteps = 10;
    try {
      _emitProgress('بدء تحميل البيانات من السحابة...', icon: '☁️', step: 0, total: totalSteps);
      log('[SyncManager] Fetching ALL data from Firestore...');

      final db = await _sqliteService.database;

      // 1. Cases
      _emitProgress('الحالات...', icon: '🏥', step: 1, total: totalSteps);
      final cases = await _firebaseService.getAllCases().timeout(const Duration(seconds: 45));
      _emitProgress('الحالات — ${cases.length} سجل', icon: '🏥', step: 1, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var c in cases) {
          batch.insert('cases', c.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 2. Users - Preserve passwordHash during cloud download
      _emitProgress('الموظفين...', icon: '👥', step: 2, total: totalSteps);
      final users = await _firebaseService.getAllUsers().timeout(const Duration(seconds: 45));
      _emitProgress('الموظفين — ${users.length} سجل', icon: '👥', step: 2, total: totalSteps);
      
      // Fetch existing password hashes to preserve them
      final existingUsers = await db.query('users', columns: ['id', 'passwordHash']);
      final Map<String, String> hashes = {
        for (var row in existingUsers) 
          if (row['passwordHash'] != null && (row['passwordHash'] as String).isNotEmpty)
            row['id'] as String: row['passwordHash'] as String
      };

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var u in users) {
          final userMap = u.toSqliteMap();
          // Restore hash if it exists locally
          if (hashes.containsKey(u.id)) {
            userMap['passwordHash'] = hashes[u.id];
          }
          batch.insert('users', userMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 3. Inventory
      _emitProgress('المخزون...', icon: '📦', step: 3, total: totalSteps);
      final inventory = await _firebaseService.getAllInventory().timeout(const Duration(seconds: 45));
      _emitProgress('المخزون — ${inventory.length} صنف', icon: '📦', step: 3, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var i in inventory) {
          batch.insert('inventory', i.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 4. Procedures
      _emitProgress('الإجراءات...', icon: '💊', step: 4, total: totalSteps);
      final procedures = await _firebaseService.getAllProcedures().timeout(const Duration(seconds: 45));
      _emitProgress('الإجراءات — ${procedures.length} إجراء', icon: '💊', step: 4, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var p in procedures) {
          batch.insert('procedures', p.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 5. Shifts
      _emitProgress('الورديات...', icon: '📅', step: 5, total: totalSteps);
      final shifts = await _firebaseService.getAllShifts().timeout(const Duration(seconds: 45));
      _emitProgress('الورديات — ${shifts.length} وردية', icon: '📅', step: 5, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var s in shifts) {
          batch.insert('shifts', s.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 6. Attendance
      _emitProgress('الحضور...', icon: '✅', step: 6, total: totalSteps);
      final attendance = await _firebaseService.getAllAttendance().timeout(const Duration(seconds: 45));
      _emitProgress('الحضور — ${attendance.length} سجل', icon: '✅', step: 6, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var a in attendance) {
          batch.insert('attendance', a.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
      // مسح التكرارات المحتملة بعد المزامنة
      await _sqliteService.cleanupDuplicateAttendance();

      // 7. Payroll
      _emitProgress('الرواتب...', icon: '💰', step: 7, total: totalSteps);
      final payroll = await _firebaseService.getAllPayroll().timeout(const Duration(seconds: 45));
      _emitProgress('الرواتب — ${payroll.length} سجل', icon: '💰', step: 7, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var p in payroll) {
          batch.insert('payroll', p.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 8. Expenses
      _emitProgress('المصاريف...', icon: '💳', step: 8, total: totalSteps);
      final expenses = await _firebaseService.getAllExpenses().timeout(const Duration(seconds: 45));
      _emitProgress('المصاريف — ${expenses.length} سجل', icon: '💳', step: 8, total: totalSteps);
      await db.transaction((txn) async {

        final batch = txn.batch();
        for (var e in expenses) {
          batch.insert('expenses', e.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      // 9. Finalizing
      _emitProgress('تحديث الحالة النهائية...', icon: '⚙️', step: 9, total: totalSteps);
      final totalRecords = cases.length + users.length + inventory.length + procedures.length + shifts.length + attendance.length + payroll.length + expenses.length;
      
      _emitProgress('تم تحميل $totalRecords سجل بنجاح ✓', icon: '🎉', step: totalSteps, total: totalSteps, isDone: true);
      log('[SyncManager] ✓ Downloaded & merged $totalRecords records from cloud');
    } catch (e) {
      _emitProgress('فشل التحميل: $e', icon: '❌', isError: true);
      log('[SyncManager] Download all from cloud error: $e');
    }
  }


  // ============================================
  // === Legacy Wrappers (For Compatibility) ===
  // ============================================

  /// Simplified wrapper for existing code
  Future<void> saveCaseWithSync(CaseModel model, {bool isNew = true}) async {
    await _sqliteService.saveCase(model.toSqliteMap());
    await enqueue(
      tableName: 'cases',
      operation: isNew ? 'create' : 'update',
      docId: model.id,
      data: model.toMap(),
    );
  }

  Future<void> saveInventoryWithSync(
    InventoryModel item, {
    bool isNew = true,
  }) async {
    await _sqliteService.insert('inventory', item.toSqliteMap());
    await enqueue(
      tableName: 'inventory',
      operation: isNew ? 'create' : 'update',
      docId: item.id,
      data: item.toMap(),
    );
  }

  Future<void> saveAttendanceWithSync(AttendanceModel attendance) async {
    await _sqliteService.insert('attendance', attendance.toSqliteMap());
    await enqueue(
      tableName: 'attendance',
      operation: 'create',
      docId: attendance.id,
      data: attendance.toMap(),
    );
  }

  Future<void> saveShiftWithSync(ShiftModel shift, {bool isNew = true}) async {
    await _sqliteService.insert('shifts', shift.toSqliteMap());
    await enqueue(
      tableName: 'shifts',
      operation: isNew ? 'create' : 'update',
      docId: shift.id,
      data: shift.toMap(),
    );
  }

  Future<void> savePayrollWithSync(
    PayrollModel payroll, {
    bool isNew = true,
  }) async {
    await _sqliteService.insert('payroll', payroll.toSqliteMap());
    await enqueue(
      tableName: 'payroll',
      operation: isNew ? 'create' : 'update',
      docId: payroll.id,
      data: payroll.toMap(),
    );
  }

  Future<void> saveExpenseWithSync(
    ExpenseModel expense, {
    bool isNew = true,
  }) async {
    await _sqliteService.insert('expenses', expense.toSqliteMap());
    await enqueue(
      tableName: 'expenses',
      operation: isNew ? 'create' : 'update',
      docId: expense.id,
      data: expense.toMap(),
    );
  }

  Future<int> getPendingCount() => _sqliteService.getPendingCount();
}
