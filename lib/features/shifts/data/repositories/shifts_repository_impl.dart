import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../models/shift_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// تنفيذ مستودع الورديات (الجيل الثاني) - Shifts Repository Implementation v2
/// Professional, offline-first shift scheduling.
class ShiftsRepositoryImpl implements IShiftsRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createShift(ShiftModel shift) async {
    await _local.insert('shifts', shift.toSqliteMap());
    await _sync.enqueue(
      tableName: 'shifts',
      operation: 'create',
      docId: shift.id,
      data: shift.toMap(),
    );
  }

  @override
  Future<void> updateShift(ShiftModel shift) async {
    await _local.insert('shifts', shift.toSqliteMap());
    await _sync.enqueue(
      tableName: 'shifts',
      operation: 'update',
      docId: shift.id,
      data: shift.toMap(),
    );
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    await _local.delete('shifts', where: 'id = ?', whereArgs: [shiftId]);
    await _sync.enqueue(
      tableName: 'shifts',
      operation: 'delete',
      docId: shiftId,
      data: {},
    );
  }

  @override
  Future<ShiftModel?> getTodayShift(String userId) async {
    final db = await _local.database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final results = await db.query('shifts', 
      where: 'userId = ? AND date = ?', 
      whereArgs: [userId, todayStr],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return ShiftModel.fromMap(results.first, results.first['id'] as String);
    }
    
    final remote = await _remote.getTodayShift(userId);
    if (remote != null) {
      await _local.insert('shifts', remote.toSqliteMap());
    }
    return remote;
  }

  @override
  Future<bool> hasShiftToday(String userId) async {
    final shift = await getTodayShift(userId);
    return shift != null;
  }

  @override
  Future<List<ShiftModel>> getMonthlyShifts(int year, int month) async {
    return await _remote.getMonthlyShifts(year, month);
  }

  @override
  Future<List<ShiftModel>> getTodayShifts() async {
    final db = await _local.database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final results = await db.query('shifts', where: 'date = ?', whereArgs: [todayStr]);
    return results.map((m) => ShiftModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<List<ShiftModel>> getUserShifts(String userId, {int limit = 30}) async {
    final db = await _local.database;
    final results = await db.query('shifts', 
      where: 'userId = ?', 
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return results.map((m) => ShiftModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<List<ShiftModel>> getShiftsByDate(String date) async {
    final db = await _local.database;
    final results = await db.query('shifts', where: 'date = ?', whereArgs: [date]);
    return results.map((m) => ShiftModel.fromMap(m, m['id'] as String)).toList();
  }

  @override
  Future<int> getShiftsCount() async {
    return await _local.getShiftsCount();
  }

  @override
  Stream<List<ShiftModel>> streamTodayShifts() {
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final query = FirebaseFirestore.instance.collection('shifts').where('date', isEqualTo: todayStr);
    return _remote.safeStream(query).map((snapshot) {
      return snapshot.docs.map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
