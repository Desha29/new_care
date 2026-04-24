import '../../data/models/shift_model.dart';

/// واجهة مستودع الورديات - Shifts Repository Interface
abstract class IShiftsRepository {
  /// إنشاء وردية - Create shift
  Future<void> createShift(ShiftModel shift);

  /// تحديث وردية - Update shift
  Future<void> updateShift(ShiftModel shift);

  /// حذف وردية - Delete shift
  Future<void> deleteShift(String shiftId);

  /// جلب وردية اليوم للمستخدم - Get today's shift for user
  Future<ShiftModel?> getTodayShift(String userId);

  /// هل المستخدم لديه وردية اليوم؟ - Does user have shift today?
  Future<bool> hasShiftToday(String userId);

  /// جلب جميع ورديات شهر معين - Get monthly shifts
  Future<List<ShiftModel>> getMonthlyShifts(int year, int month);

  /// جلب جميع ورديات اليوم - Get all today's shifts
  Future<List<ShiftModel>> getTodayShifts();

  /// جلب ورديات مستخدم - Get user shifts
  Future<List<ShiftModel>> getUserShifts(String userId, {int limit = 30});

  /// جلب ورديات حسب التاريخ - Get shifts by date
  Future<List<ShiftModel>> getShiftsByDate(String date);

  /// جلب عدد الورديات - Get shifts count
  Future<int> getShiftsCount();

  /// بث ورديات اليوم - Stream today's shifts
  Stream<List<ShiftModel>> streamTodayShifts();
}
