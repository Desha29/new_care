import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../models/shift_model.dart';

/// تنفيذ مستودع الورديات - Shifts Repository Implementation
class ShiftsRepositoryImpl extends FirebaseBase implements IShiftsRepository {
  CollectionReference get _shiftsRef => firestore.collection('shifts');

  @override
  Future<void> createShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).set(shift.toMap());
  }

  @override
  Future<void> updateShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).update(shift.toMap());
  }

  @override
  Future<void> deleteShift(String shiftId) async {
    await _shiftsRef.doc(shiftId).delete();
  }

  @override
  Future<ShiftModel?> getTodayShift(String userId) async {
    final today = todayString();
    final snapshot = await _shiftsRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ShiftModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  @override
  Future<bool> hasShiftToday(String userId) async {
    final shift = await getTodayShift(userId);
    return shift != null;
  }

  @override
  Future<List<ShiftModel>> getMonthlyShifts(int year, int month) async {
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _shiftsRef
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<ShiftModel>> getTodayShifts() async {
    final today = todayString();
    final snapshot = await _shiftsRef.where('date', isEqualTo: today).get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<ShiftModel>> getUserShifts(String userId, {int limit = 30}) async {
    final snapshot = await _shiftsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<ShiftModel>> getShiftsByDate(String date) async {
    final snapshot = await _shiftsRef.where('date', isEqualTo: date).get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<int> getShiftsCount() async {
    final snapshot = await _shiftsRef.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Stream<List<ShiftModel>> streamTodayShifts() {
    final todayStr = todayString();
    return safeStream(_shiftsRef.where('date', isEqualTo: todayStr)).map(
      (snapshot) => snapshot.docs
          .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}
