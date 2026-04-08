import 'dart:convert';
import 'dart:developer';
import '../services/firebase_service.dart';
import '../services/sqlite_service.dart';
import '../services/connectivity_service.dart';
import '../../features/shifts/data/models/shift_model.dart';
import '../../features/attendance/data/models/attendance_model.dart';
import '../../features/cases/data/models/case_model.dart';
import '../../features/inventory/data/models/inventory_model.dart';

/// خدمة المزامنة الشاملة - Comprehensive Sync Service
/// مسؤولة عن المزامنة بين SQLite المحلي و Firebase عند وجود مشاكل في الشبكة
class SyncManager {
  static SyncManager? _instance;
  final FirebaseService _firebaseService;
  final SqliteService _sqliteService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;

  SyncManager._()
      : _firebaseService = FirebaseService.instance,
        _sqliteService = SqliteService.instance,
        _connectivityService = ConnectivityService.instance;

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  // ============================================
  // === العمليات المعلقة - Pending Operations ===
  // ============================================

  /// إضافة عملية معلقة للمزامنة لاحقاً
  /// Add a pending operation to sync later when online
  Future<void> addPendingOperation({
    required String tableName,
    required String operation, // 'create', 'update', 'delete'
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final db = await _sqliteService.database;
    await db.insert('pending_sync', {
      'id': '${tableName}_${operation}_${docId}_${DateTime.now().millisecondsSinceEpoch}',
      'tableName': tableName,
      'operation': operation,
      'docId': docId,
      'data': jsonEncode(data),
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });
    log('[SyncManager] Pending operation added: $operation on $tableName/$docId');
  }

  /// جلب العمليات المعلقة - Get pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await _sqliteService.database;
    return await db.query('pending_sync', orderBy: 'createdAt ASC');
  }

  /// حذف عملية معلقة بعد نجاح المزامنة - Remove pending op after sync
  Future<void> removePendingOperation(String id) async {
    final db = await _sqliteService.database;
    await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================
  // === المزامنة الشاملة - Full Sync ===
  // ============================================

  /// مزامنة كل البيانات عند عودة الاتصال
  /// Sync all data when connectivity is restored
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isConnected = await _connectivityService.checkConnection();
      if (!isConnected) {
        log('[SyncManager] Offline, skipping sync');
        return;
      }

      log('[SyncManager] Starting full sync...');

      // 1. أولاً: رفع العمليات المعلقة المحلية إلى Firebase
      await _processPendingOperations();

      // 2. ثانياً: تنزيل أحدث البيانات من Firebase إلى SQLite
      await _syncDownFromFirebase();

      log('[SyncManager] Full sync completed');
    } catch (e) {
      log('[SyncManager] Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// معالجة العمليات المعلقة - Process pending operations
  Future<void> _processPendingOperations() async {
    final pending = await getPendingOperations();
    log('[SyncManager] Processing ${pending.length} pending operations...');

    for (var op in pending) {
      try {
        final tableName = op['tableName'] as String;
        final operation = op['operation'] as String;
        final docId = op['docId'] as String;
        final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;

        switch (tableName) {
          case 'cases':
            await _syncCaseOperation(operation, docId, data);
            break;
          case 'inventory':
            await _syncInventoryOperation(operation, docId, data);
            break;
          case 'shifts':
            await _syncShiftOperation(operation, docId, data);
            break;
          case 'attendance':
            await _syncAttendanceOperation(operation, docId, data);
            break;
        }

        await removePendingOperation(op['id'] as String);
        log('[SyncManager] Synced: $operation on $tableName/$docId');
      } catch (e) {
        // Increment retry count, keep for next attempt
        final db = await _sqliteService.database;
        final retryCount = (op['retryCount'] as int? ?? 0) + 1;
        if (retryCount > 5) {
          // Give up after 5 retries
          await removePendingOperation(op['id'] as String);
          log('[SyncManager] Gave up on: ${op['id']} after $retryCount retries');
        } else {
          await db.update(
            'pending_sync',
            {'retryCount': retryCount},
            where: 'id = ?',
            whereArgs: [op['id']],
          );
        }
        log('[SyncManager] Error syncing ${op['id']}: $e');
      }
    }
  }

  /// مزامنة عملية حالة - Sync case operation
  Future<void> _syncCaseOperation(String op, String docId, Map<String, dynamic> data) async {
    switch (op) {
      case 'create':
      case 'update':
        final caseModel = CaseModel.fromMap(data, docId);
        if (op == 'create') {
          await _firebaseService.createCase(caseModel);
        } else {
          await _firebaseService.updateCase(caseModel);
        }
        break;
      case 'delete':
        await _firebaseService.deleteCase(docId);
        break;
    }
  }

  /// مزامنة عملية مخزون - Sync inventory operation
  Future<void> _syncInventoryOperation(String op, String docId, Map<String, dynamic> data) async {
    switch (op) {
      case 'create':
      case 'update':
        final item = InventoryModel.fromMap(data, docId);
        if (op == 'create') {
          await _firebaseService.createInventoryItem(item);
        } else {
          await _firebaseService.updateInventoryItem(item);
        }
        break;
      case 'delete':
        await _firebaseService.deleteInventoryItem(docId);
        break;
    }
  }

  /// مزامنة عملية وردية - Sync shift operation
  Future<void> _syncShiftOperation(String op, String docId, Map<String, dynamic> data) async {
    switch (op) {
      case 'create':
      case 'update':
        final shift = ShiftModel.fromMap(data, docId);
        if (op == 'create') {
          await _firebaseService.createShift(shift);
        } else {
          await _firebaseService.updateShift(shift);
        }
        break;
      case 'delete':
        await _firebaseService.deleteShift(docId);
        break;
    }
  }

  /// مزامنة عملية حضور - Sync attendance operation
  Future<void> _syncAttendanceOperation(String op, String docId, Map<String, dynamic> data) async {
    switch (op) {
      case 'create':
        final attendance = AttendanceModel.fromMap(data, docId);
        await _firebaseService.checkIn(attendance);
        break;
      case 'update':
        await _firebaseService.checkOut(docId);
        break;
    }
  }

  // ============================================
  // === تنزيل من Firebase - Download from Firebase ===
  // ============================================

  /// تنزيل أحدث البيانات من Firebase إلى SQLite
  Future<void> _syncDownFromFirebase() async {
    try {
      // مزامنة الحالات
      final cases = await _firebaseService.getAllCases();
      for (var c in cases) {
        await _sqliteService.saveCase(c.toSqliteMap());
      }

      // مزامنة المستخدمين
      final users = await _firebaseService.getAllUsers();
      for (var u in users) {
        await _sqliteService.saveUser(u.toSqliteMap());
      }

      // مزامنة الورديات (آخر 7 أيام)
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final shifts = await _firebaseService.getShiftsByDate(dateStr);
        for (var s in shifts) {
          await _sqliteService.insert('shifts', s.toSqliteMap());
        }
      }

      // مزامنة المخزون
      final inventory = await _firebaseService.getAllInventory();
      for (var item in inventory) {
        await _sqliteService.insert('inventory', item.toSqliteMap());
      }

      log('[SyncManager] Download from Firebase completed');
    } catch (e) {
      log('[SyncManager] Error downloading from Firebase: $e');
    }
  }

  // ============================================
  // === حفظ محلي مع مزامنة - Save locally with sync ===
  // ============================================

  /// حفظ حالة محلياً ومزامنتها - Save case locally and sync
  Future<void> saveCaseWithSync(CaseModel caseModel, {bool isNew = true}) async {
    // حفظ محلياً أولاً
    await _sqliteService.saveCase(caseModel.toSqliteMap());

    final isConnected = await _connectivityService.checkConnection();
    if (isConnected) {
      // متصل: ارسل مباشرة إلى Firebase
      try {
        if (isNew) {
          await _firebaseService.createCase(caseModel);
        } else {
          await _firebaseService.updateCase(caseModel);
        }
      } catch (e) {
        // فشل الإرسال: أضف للعمليات المعلقة
        await addPendingOperation(
          tableName: 'cases',
          operation: isNew ? 'create' : 'update',
          docId: caseModel.id,
          data: caseModel.toMap(),
        );
      }
    } else {
      // غير متصل: أضف للعمليات المعلقة
      await addPendingOperation(
        tableName: 'cases',
        operation: isNew ? 'create' : 'update',
        docId: caseModel.id,
        data: caseModel.toMap(),
      );
    }
  }

  /// حفظ عنصر مخزون مع مزامنة - Save inventory item with sync
  Future<void> saveInventoryWithSync(InventoryModel item, {bool isNew = true}) async {
    await _sqliteService.insert('inventory', item.toSqliteMap());

    final isConnected = await _connectivityService.checkConnection();
    if (isConnected) {
      try {
        if (isNew) {
          await _firebaseService.createInventoryItem(item);
        } else {
          await _firebaseService.updateInventoryItem(item);
        }
      } catch (e) {
        await addPendingOperation(
          tableName: 'inventory',
          operation: isNew ? 'create' : 'update',
          docId: item.id,
          data: item.toMap(),
        );
      }
    } else {
      await addPendingOperation(
        tableName: 'inventory',
        operation: isNew ? 'create' : 'update',
        docId: item.id,
        data: item.toMap(),
      );
    }
  }

  /// حفظ حضور مع مزامنة - Save attendance with sync
  Future<void> saveAttendanceWithSync(AttendanceModel attendance) async {
    await _sqliteService.insert('attendance', attendance.toSqliteMap());

    final isConnected = await _connectivityService.checkConnection();
    if (isConnected) {
      try {
        await _firebaseService.checkIn(attendance);
      } catch (e) {
        await addPendingOperation(
          tableName: 'attendance',
          operation: 'create',
          docId: attendance.id,
          data: attendance.toMap(),
        );
      }
    } else {
      await addPendingOperation(
        tableName: 'attendance',
        operation: 'create',
        docId: attendance.id,
        data: attendance.toMap(),
      );
    }
  }

  /// حفظ وردية مع مزامنة - Save shift with sync
  Future<void> saveShiftWithSync(ShiftModel shift, {bool isNew = true}) async {
    await _sqliteService.insert('shifts', shift.toSqliteMap());

    final isConnected = await _connectivityService.checkConnection();
    if (isConnected) {
      try {
        if (isNew) {
          await _firebaseService.createShift(shift);
        } else {
          await _firebaseService.updateShift(shift);
        }
      } catch (e) {
        await addPendingOperation(
          tableName: 'shifts',
          operation: isNew ? 'create' : 'update',
          docId: shift.id,
          data: shift.toMap(),
        );
      }
    } else {
      await addPendingOperation(
        tableName: 'shifts',
        operation: isNew ? 'create' : 'update',
        docId: shift.id,
        data: shift.toMap(),
      );
    }
  }

  /// عدد العمليات المعلقة - Pending operations count
  Future<int> getPendingCount() async {
    final db = await _sqliteService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_sync');
    return result.first['count'] as int? ?? 0;
  }
}
