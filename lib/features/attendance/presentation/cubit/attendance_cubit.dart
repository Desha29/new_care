import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/pdf/report_service.dart';
import '../../../../core/enums/shift_role.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../auth/data/models/user_model.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final IAttendanceRepository _attendanceRepository;
  final IShiftsRepository _shiftsRepository;
  final DeviceService _deviceService;
  final SyncManager _syncManager;

  AttendanceCubit({
    required IAttendanceRepository attendanceRepository,
    required IShiftsRepository shiftsRepository,
    DeviceService? deviceService,
    SyncManager? syncManager,
  }) : _attendanceRepository = attendanceRepository,
       _shiftsRepository = shiftsRepository,
       _deviceService = deviceService ?? DeviceService.instance,
       _syncManager = syncManager ?? SyncManager.instance,
       super(AttendanceInitial());

  StreamSubscription? _todayAttendanceSub;
  StreamSubscription? _currentStatusSub;

  @override
  Future<void> close() {
    _todayAttendanceSub?.cancel();
    _currentStatusSub?.cancel();
    return super.close();
  }

  /// تحميل سجلات حضور اليوم بشكل تفاعلي - Reactive Load today's attendance records
  void loadTodayAttendance() {
    print("Loading attendance records...");
    emit(AttendanceLoading());
    _todayAttendanceSub?.cancel();
    _todayAttendanceSub = _attendanceRepository
        .streamTodayAttendanceRecords()
        .listen(
          (records) {
            print("Attendance records loaded: ${records.length}");
            if (state is AttendanceLoaded) {
              final s = state as AttendanceLoaded;
              print("Attendance records loaded: ${records.length}");
              emit(s.copyWith(records: records));
            } else {
              print("Attendance records loaded: ${records.length}");
              emit(AttendanceLoaded(records: records));
            }
          },
          onError: (e) {
            emit(AttendanceError('خطأ في تحميل سجلات الحضور: ${e.toString()}'));
          },
        );
  }

  void checkTodayStatus(String userId) {
    _currentStatusSub?.cancel();
    _currentStatusSub = _attendanceRepository
        .streamTodayAttendance(userId)
        .listen((attendanceList) async {
          final now = DateTime.now();
          final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          
          // Find the record for today specifically
          final attendance = attendanceList.isNotEmpty && attendanceList.first.date == todayStr 
              ? attendanceList.first 
              : null;

          if (state is AttendanceLoaded) {
            final s = state as AttendanceLoaded;
            emit(
              s.copyWith(
                todayRecord: attendance,
                isCheckedIn: attendance != null && attendance.isCheckedIn,
              ),
            );
          } else {
            final records = await _attendanceRepository
                .getTodayAttendanceRecords();
            emit(
              AttendanceLoaded(
                records: records,
                todayRecord: attendance,
                isCheckedIn: attendance != null && attendance.isCheckedIn,
              ),
            );
          }
        });
  }

  void searchAttendance(String query) {
    if (state is AttendanceLoaded) {
      final s = state as AttendanceLoaded;
      emit(s.copyWith(searchQuery: query));
    }
  }

  void filterByDate(DateTime? date) {
    if (state is AttendanceLoaded) {
      final s = state as AttendanceLoaded;
      emit(s.copyWith(dateFilter: date, clearDateFilter: date == null));
    }
  }

  /// توليد تقرير الحضور الشهري - Generate Monthly Attendance Report
  /// Returns the report data (records + shifts) for preview usage
  Future<Map<String, dynamic>?> getMonthlyReportData(int year, int month) async {
    try {
      final records = await _attendanceRepository.getMonthlyAttendanceRecords(
        year,
        month,
      );
      final shifts = await _shiftsRepository.getMonthlyShifts(year, month);
      return {
        'records': records,
        'shifts': shifts,
      };
    } catch (e) {
      emit(AttendanceError('خطأ في تحميل بيانات التقرير: ${e.toString()}'));
      return null;
    }
  }

  /// Legacy: Generate and print directly (kept for backward compat)
  Future<void> generateMonthlyReport(int year, int month) async {
    try {
      final records = await _attendanceRepository.getMonthlyAttendanceRecords(
        year,
        month,
      );
      final shifts = await _shiftsRepository.getMonthlyShifts(year, month);

      await ReportService.instance.generateAttendanceReport(
        records: records,
        shifts: shifts,
        year: year,
        month: month,
      );
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في توليد التقرير: ${e.toString()}'));
    }
  }

  /// تسجيل الحضور للموظف (من قبل المدير عبر QR) - Check in nurse (by ID)
  Future<void> checkInByUserId({
    required String targetUserId,
    required String targetUserName,
    required String adminUserId,
    required String adminUserName,
  }) async {
    emit(AttendanceLoading());
    try {
      final existing = await _attendanceRepository.getTodayAttendance(
        targetUserId,
      );
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('الموظف لديه وردية نشطة حالياً مسبقاً'));
        loadTodayAttendance();
        return;
      }

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: targetUserId,
        userName: targetUserName,
        date: today,
        checkInTime: now,
        deviceId: 'qr_scanner',
        location: 'center',
        status: AttendanceStatus.checkedIn,
      );

      await _syncManager.saveAttendanceWithSync(attendance);

      await LocalLogService.instance.logActivity(
        userId: adminUserId,
        userName: adminUserName,
        action: 'qr_check_in',
        actionLabel: 'تسجيل حضور QR',
        details: 'قام $adminUserName بتسجيل حضور الممرض $targetUserName عبر QR',
      );

      emit(AttendanceCheckedIn(attendance));
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل حضور QR: ${e.toString()}'));
    }
  }

  /// مسح الـ QR للتحقق من الحضور أو الانصراف
  Future<void> handleQrScan({
    required String targetUserId,
    required String targetUserName,
    required String adminUserId,
    required String adminUserName,
  }) async {
    emit(AttendanceLoading());
    try {
      final latest = await _attendanceRepository.getTodayAttendance(
        targetUserId,
      );
      if (latest == null || latest.isCheckedOut) {
        await checkInByUserId(
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          adminUserId: adminUserId,
          adminUserName: adminUserName,
        );
      } else {
        await checkOut(userId: targetUserId, userName: targetUserName);
      }
    } catch (e) {
      emit(AttendanceError('خطأ في مسح QR: ${e.toString()}'));
      loadTodayAttendance();
    }
  }

  Future<void> processCenterQr({
    required String qrCode,
    required String userId,
    required String userName,
  }) async {
    emit(AttendanceLoading());
    try {
      final latest = await _attendanceRepository.getTodayAttendance(userId);

      if (qrCode == 'NEWCARE_ATTENDANCE' ||
          qrCode == 'NEWCARE_DEPARTURE' ||
          qrCode == 'NEWCARE_UNIFIED') {
        if (latest == null || latest.isCheckedOut) {
          await checkIn(userId: userId, userName: userName);
        } else {
          await checkOut(userId: userId, userName: userName);
        }
      } else {
        emit(const AttendanceError('كود QR غير صالح أو غير معترف به'));
      }
    } catch (e) {
      emit(AttendanceError('خطأ في معالجة الكود: ${e.toString()}'));
    }
  }

  /// تسجيل الحضور الذاتي - Self Check in
  Future<void> checkIn({
    required String userId,
    required String userName,
  }) async {
    emit(AttendanceLoading());
    try {
      final existing = await _attendanceRepository.getTodayAttendance(userId);
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('لديك وردية نشطة حالياً مسبقاً'));
        return;
      }

      final deviceId = await _deviceService.getDeviceId();
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        date: today,
        checkInTime: now,
        deviceId: deviceId,
        location: '',
        status: AttendanceStatus.checkedIn,
      );

      await _syncManager.saveAttendanceWithSync(attendance);

      await LocalLogService.instance.logActivity(
        userId: userId,
        userName: userName,
        action: 'check_in',
        actionLabel: 'تسجيل حضور',
        details: 'قام $userName بتسجيل الحضور',
      );

      emit(AttendanceCheckedIn(attendance));
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل الحضور: ${e.toString()}'));
    }
  }

  /// تسجيل الانصراف - Check out
  Future<void> checkOut({
    required String userId,
    required String userName,
  }) async {
    emit(AttendanceLoading());
    try {
      final attendance = await _attendanceRepository.getTodayAttendance(userId);
      if (attendance == null || attendance.isCheckedOut) {
        emit(const AttendanceError('لا يوجد تسجيل حضور نشط'));
        return;
      }

      final isConnected = await ConnectivityService.instance.checkConnection();
      if (isConnected) {
        await _attendanceRepository.checkOut(attendance.id);
      } else {
        await _syncManager.addPendingOperation(
          tableName: 'attendance',
          operation: 'update',
          docId: attendance.id,
          data: attendance.toMap(),
        );
      }

      final updatedRecord = attendance.copyWith(
        checkOutTime: DateTime.now(),
        status: AttendanceStatus.checkedOut,
      );

      await LocalLogService.instance.logActivity(
        userId: userId,
        userName: userName,
        action: 'check_out',
        actionLabel: 'تسجيل انصراف',
        details: 'قام $userName بتسجيل الانصراف',
      );

      emit(AttendanceCheckedOut(updatedRecord));
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل الانصراف: ${e.toString()}'));
    }
  }

  // ============================================
  // === نظام التحقق من الوصول - Access Guard ===
  // ============================================

  /// التحقق الشامل من صلاحية الوصول
  Future<AccessVerificationResult> verifyAccess({
    required UserModel user,
  }) async {
    try {
      // 1. التحقق من الوردية
      final shift = await _shiftsRepository.getTodayShift(user.id);
      final hasShift = shift != null;

      // المدير العام يتخطى التحقق
      if (user.role.isSuperAdmin) {
        return const AccessVerificationResult(
          hasShift: true,
          isCheckedIn: true,
          isCorrectDevice: true,
          isGranted: true,
          message: 'مدير عام - وصول كامل',
        );
      }

      // المشرف يتخطى التحقق
      if (user.role.isAdmin) {
        return const AccessVerificationResult(
          hasShift: true,
          isCheckedIn: true,
          isCorrectDevice: true,
          isGranted: true,
          message: 'مشرف - وصول كامل معفى من الحضور',
        );
      }

      // 2. التحقق من الحضور
      final attendance = await _attendanceRepository.getTodayAttendance(
        user.id,
      );
      final isCheckedIn = attendance != null && attendance.isCheckedIn;

      // 3. التحقق من الجهاز
      final currentDeviceId = await _deviceService.getDeviceId();
      final isCorrectDevice =
          user.allowedDeviceIds.isEmpty ||
          user.allowedDeviceIds.contains(currentDeviceId);

      if (!hasShift) {
        return AccessVerificationResult(
          hasShift: false,
          isCheckedIn: isCheckedIn,
          isCorrectDevice: isCorrectDevice,
          isGranted: false,
          message: 'لا توجد وردية مُعيّنة لك اليوم. تواصل مع المشرف.',
        );
      }

      if (!isCheckedIn) {
        return AccessVerificationResult(
          hasShift: true,
          isCheckedIn: false,
          isCorrectDevice: isCorrectDevice,
          isGranted: false,
          message: 'يجب تسجيل الحضور أولاً قبل الوصول للنظام.',
        );
      }

      if (!isCorrectDevice) {
        return AccessVerificationResult(
          hasShift: true,
          isCheckedIn: true,
          isCorrectDevice: false,
          isGranted: false,
          message: 'هذا الجهاز غير مصرح به. تواصل مع المشرف.',
        );
      }

      return const AccessVerificationResult(
        hasShift: true,
        isCheckedIn: true,
        isCorrectDevice: true,
        isGranted: true,
        message: 'تم التحقق بنجاح',
      );
    } catch (e) {
      return AccessVerificationResult(
        hasShift: false,
        isCheckedIn: false,
        isCorrectDevice: false,
        isGranted: false,
        message: 'خطأ في التحقق: ${e.toString()}',
      );
    }
  }
}
