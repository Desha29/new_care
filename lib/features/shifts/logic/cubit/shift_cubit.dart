import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/shift_model.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final FirebaseService _firebaseService;
  final SyncManager _syncManager;

  ShiftCubit()
      : _firebaseService = FirebaseService.instance,
        _syncManager = SyncManager.instance,
        super(ShiftInitial());

  /// تحميل ورديات اليوم - Load today's shifts
  Future<void> loadTodayShifts() async {
    emit(ShiftLoading());
    try {
      final shifts = await _firebaseService.getTodayShifts();
      emit(ShiftLoaded(shifts: shifts));
    } catch (e) {
      emit(ShiftError('خطأ في تحميل الورديات: ${e.toString()}'));
    }
  }

  /// تحميل ورديات تاريخ محدد - Load shifts by date
  Future<void> loadShiftsByDate(String date) async {
    emit(ShiftLoading());
    try {
      final shifts = await _firebaseService.getShiftsByDate(date);
      emit(ShiftLoaded(shifts: shifts, selectedDate: date));
    } catch (e) {
      emit(ShiftError('خطأ في تحميل الورديات: ${e.toString()}'));
    }
  }

  /// جلب وردية المستخدم اليوم - Get current user's today shift
  Future<ShiftModel?> getUserTodayShift(String userId) async {
    try {
      return await _firebaseService.getTodayShift(userId);
    } catch (e) {
      return null;
    }
  }

  /// هل لدى المستخدم وردية اليوم؟ - Check if user has shift today
  Future<bool> hasShiftToday(String userId) async {
    try {
      return await _firebaseService.hasShiftToday(userId);
    } catch (e) {
      return false;
    }
  }

  /// إنشاء وردية جديدة - Create new shift
  Future<void> createShift(ShiftModel shift) async {
    try {
      await _syncManager.saveShiftWithSync(shift, isNew: true);

      // Refresh list
      if (state is ShiftLoaded) {
        final currentState = state as ShiftLoaded;
        final date = currentState.selectedDate.isNotEmpty
            ? currentState.selectedDate
            : null;
        if (date != null) {
          await loadShiftsByDate(date);
        } else {
          await loadTodayShifts();
        }
      } else {
        await loadTodayShifts();
      }
    } catch (e) {
      emit(ShiftError('خطأ في إنشاء الوردية: ${e.toString()}'));
    }
  }

  /// تحديث وردية - Update shift
  Future<void> updateShift(ShiftModel shift) async {
    try {
      await _syncManager.saveShiftWithSync(shift, isNew: false);
      await loadTodayShifts();
    } catch (e) {
      emit(ShiftError('خطأ في تحديث الوردية: ${e.toString()}'));
    }
  }

  /// حذف وردية - Delete shift
  Future<void> deleteShift(String shiftId) async {
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (isConnected) {
        await _firebaseService.deleteShift(shiftId);
      } else {
        await _syncManager.addPendingOperation(
          tableName: 'shifts',
          operation: 'delete',
          docId: shiftId,
          data: {},
        );
      }
      await loadTodayShifts();
    } catch (e) {
      emit(ShiftError('خطأ في حذف الوردية: ${e.toString()}'));
    }
  }

  /// بحث في الورديات - Search shifts
  void searchShifts(String query) {
    if (state is ShiftLoaded) {
      final currentState = state as ShiftLoaded;
      emit(ShiftLoaded(
        shifts: currentState.shifts,
        todayShift: currentState.todayShift,
        searchQuery: query,
        selectedDate: currentState.selectedDate,
      ));
    }
  }
}
