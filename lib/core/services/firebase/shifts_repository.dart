import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/shifts/data/models/shift_model.dart';
import 'firebase_base.dart';

/// مستودع الورديات - Shifts Repository
class ShiftsRepository extends FirebaseBase {
  CollectionReference get _shiftsRef =>
      firestore.collection('shifts');

  /// إنشاء وردية - Create shift
  Future<void> createShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).set(shift.toMap());
  }

  /// تحديث وردية - Update shift
  Future<void> updateShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).update(shift.toMap());
  }

  /// حذف وردية - Delete shift
  Future<void> deleteShift(String shiftId) async {
    await _shiftsRef.doc(shiftId).delete();
  }

  /// جلب وردية اليوم للمستخدم - Get today's shift for user
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

  /// هل المستخدم لديه وردية اليوم؟
  Future<bool> hasShiftToday(String userId) async {
    final shift = await getTodayShift(userId);
    return shift != null;
  }

  /// جلب جميع ورديات شهر معين
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

  /// جلب جميع ورديات اليوم - Get all today's shifts
  Future<List<ShiftModel>> getTodayShifts() async {
    final today = todayString();
    final snapshot = await _shiftsRef
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب ورديات مستخدم - Get user shifts
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

  /// جلب ورديات حسب التاريخ - Get shifts by date
  Future<List<ShiftModel>> getShiftsByDate(String date) async {
    final snapshot = await _shiftsRef
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// بث ورديات اليوم - Stream today's shifts
  Stream<List<ShiftModel>> streamTodayShifts() {
    final today = todayString();
    return _shiftsRef
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
