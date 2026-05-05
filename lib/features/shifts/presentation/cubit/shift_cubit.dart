import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../../data/models/shift_model.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final IShiftsRepository _shiftsRepository;
  final SyncManager _syncManager;
  StreamSubscription? _caseChangeSub;

  ShiftCubit({
    required IShiftsRepository shiftsRepository,
    SyncManager? syncManager,
  })  : _shiftsRepository = shiftsRepository,
        _syncManager = syncManager ?? SyncManager.instance,
        super(ShiftInitial()) {
    // الاستماع لتغييرات الحالات لتحديث عدد الحالات تلقائياً
    // Listen for case changes to auto-refresh case counts
    _caseChangeSub = CaseChangeNotifier().onCaseChanged.listen((_) {
      _refreshCaseCounts();
    });
  }

  @override
  Future<void> close() {
    _caseChangeSub?.cancel();
    return super.close();
  }

  /// تحديث عدد الحالات فقط بدون إعادة تحميل الورديات
  /// Refresh only case counts without reloading shifts
  Future<void> _refreshCaseCounts() async {
    if (state is ShiftLoaded) {
      try {
        final currentState = state as ShiftLoaded;
        final date = currentState.selectedDate.isNotEmpty
            ? currentState.selectedDate
            : _todayStr();
        final caseCounts = await SqliteService.instance.getCaseCountsByDate(date);
        emit(ShiftLoaded(
          shifts: currentState.shifts,
          todayShift: currentState.todayShift,
          searchQuery: currentState.searchQuery,
          selectedDate: currentState.selectedDate,
          caseCounts: caseCounts,
        ));
      } catch (_) {}
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// تحميل ورديات اليوم - Load today's shifts
  Future<void> loadTodayShifts() async {
    emit(ShiftLoading());
    try {
      final shifts = await _shiftsRepository.getTodayShifts();
      final caseCounts = await SqliteService.instance.getCaseCountsByDate(_todayStr());
      emit(ShiftLoaded(shifts: shifts, caseCounts: caseCounts));
    } catch (e) {
      emit(ShiftError('خطأ في تحميل الورديات: ${e.toString()}'));
    }
  }

  /// تحميل ورديات تاريخ محدد - Load shifts by date
  Future<void> loadShiftsByDate(String date) async {
    emit(ShiftLoading());
    try {
      final shifts = await _shiftsRepository.getShiftsByDate(date);
      final caseCounts = await SqliteService.instance.getCaseCountsByDate(date);
      emit(ShiftLoaded(shifts: shifts, selectedDate: date, caseCounts: caseCounts));
    } catch (e) {
      emit(ShiftError('خطأ في تحميل الورديات: ${e.toString()}'));
    }
  }

  /// جلب وردية المستخدم اليوم - Get current user's today shift
  Future<ShiftModel?> getUserTodayShift(String userId) async {
    try {
      return await _shiftsRepository.getTodayShift(userId);
    } catch (e) {
      return null;
    }
  }

  /// هل لدى المستخدم وردية اليوم؟
  Future<bool> hasShiftToday(String userId) async {
    try {
      return await _shiftsRepository.hasShiftToday(userId);
    } catch (e) {
      return false;
    }
  }

  /// إنشاء وردية جديدة - Create new shift
  Future<void> createShift(ShiftModel shift) async {
    try {
      await _syncManager.saveShiftWithSync(shift, isNew: true);

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
        await _shiftsRepository.deleteShift(shiftId);
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
        caseCounts: currentState.caseCounts,
      ));
    }
  }
}

