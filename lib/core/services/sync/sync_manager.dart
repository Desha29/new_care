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
    // Attempt sync every 5 minutes automatically
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncAll(),
    );

    // Attempt sync when connectivity is restored
    _connectivitySub = _connectivityService.connectivityStream.listen((
      isConnected,
    ) {
      if (isConnected) {
        log('[SyncManager] Connection restored, triggering sync');
        syncAll();
      }
    });
  }

  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivitySub?.cancel();
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

      // Trigger sync in background without blocking
      unawaited(syncAll());
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

  /// مزامنة كاملة - Full Sync Orchestration
  Future<void> syncAll() async {
    if (_isSyncing) return;

    final isConnected = await _connectivityService.checkConnection();
    if (!isConnected) return;

    _isSyncing = true;
    log('[SyncManager] Starting sync cycle...');

    try {
      // 1. Process local changes -> Firebase (Upload)
      try {
        await _uploadPendingChanges();
      } catch (e) {
        log('[SyncManager] Upload phase error (continuing): $e');
        // Continue to download phase even if upload fails
      }

      // 2. Process remote changes -> Local (Download)
      try {
        await _downloadDeltaChanges();
      } catch (e) {
        log('[SyncManager] Download phase error: $e');
      }

      log('[SyncManager] Sync cycle completed successfully');
    } catch (e) {
      log('[SyncManager] Sync cycle failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Alias for high-level services
  Future<void> processQueue() async {
    await _uploadPendingChanges();
  }

  /// رفع التغييرات المحلية - Upload pending changes to Firebase
  Future<void> _uploadPendingChanges() async {
    final db = await _sqliteService.database;
    final pending = await db.query(
      'pending_sync',
      orderBy: 'createdAt ASC',
      limit:
          10, // Process max 10 operations per cycle to prevent overwhelming the API
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

        // Break the loop if it's a network/connection error to avoid multiple quick failures
        if (e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('disconnected') ||
            e.toString().contains('socket')) {
          log(
            '[SyncManager] 🔌 Connection error detected. Stopping sync cycle.',
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
            final model = AttendanceModel.fromMap(data, id);
            if (op == 'update') {
              await _firebaseService.checkOut(id);
            } else {
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
        default:
          throw Exception('Unknown table: $table');
      }
    } catch (e, st) {
      log('[SyncManager] Dispatch operation error for $table/$op/$id: $e');
      log('[SyncManager] Dispatch stack: $st');
      rethrow;
    }
  }

  /// تنزيل التغييرات الجديدة - Download only what changed since last sync
  Future<void> _downloadDeltaChanges() async {
    try {
      final lastSync = await _sqliteService.getLastSync();
      log('[SyncManager] Fetching delta since $lastSync');

      // Run downloads with timeout protection and error handling
      final results = await Future.wait([
        _firebaseService
            .getUpdatedCases(lastSync)
            .timeout(const Duration(seconds: 30))
            .catchError((e) {
              log('[SyncManager] Failed to fetch cases: $e');
              return <CaseModel>[];
            }),
        _firebaseService
            .getUpdatedUsers(lastSync)
            .timeout(const Duration(seconds: 30))
            .catchError((e) {
              log('[SyncManager] Failed to fetch users: $e');
              return <UserModel>[];
            }),
        _firebaseService
            .getUpdatedInventory(lastSync)
            .timeout(const Duration(seconds: 30))
            .catchError((e) {
              log('[SyncManager] Failed to fetch inventory: $e');
              return <InventoryModel>[];
            }),
        _firebaseService
            .getUpdatedProcedures(lastSync)
            .timeout(const Duration(seconds: 30))
            .catchError((e) {
              log('[SyncManager] Failed to fetch procedures: $e');
              return <ProcedureModel>[];
            }),
      ]);

      // Small delay between download and write to avoid rapid operations
      await Future.delayed(const Duration(milliseconds: 200));

      await _sqliteService.runTransaction((txn) async {
        try {
          final batch = txn.batch();

          // 1. Cases
          for (var c in results[0] as List<CaseModel>) {
            batch.insert(
              'cases',
              c.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // 2. Users
          for (var u in results[1] as List<UserModel>) {
            batch.insert(
              'users',
              u.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // 3. Inventory
          for (var i in results[2] as List<InventoryModel>) {
            batch.insert(
              'inventory',
              i.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // 4. Procedures
          for (var p in results[3] as List<ProcedureModel>) {
            batch.insert(
              'procedures',
              p.toSqliteMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await batch.commit(noResult: true);
        } catch (e) {
          log('[SyncManager] Transaction error: $e');
          rethrow;
        }
      });

      await _sqliteService.updateLastSync();
      log('[SyncManager] Delta sync applied');
    } catch (e) {
      log('[SyncManager] Download delta changes error: $e');
      // Don't rethrow - download failures shouldn't crash the sync cycle
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

  Future<int> getPendingCount() => _sqliteService.getPendingCount();
}
