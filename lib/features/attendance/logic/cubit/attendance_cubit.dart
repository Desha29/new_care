import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/device_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/enums/shift_role.dart';
import '../../data/models/attendance_model.dart';
import '../../../auth/data/models/user_model.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final FirebaseService _firebaseService;
  final DeviceService _deviceService;
  final SyncManager _syncManager;

  AttendanceCubit()
      : _firebaseService = FirebaseService.instance,
        _deviceService = DeviceService.instance,
        _syncManager = SyncManager.instance,
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
    emit(AttendanceLoading());
    _todayAttendanceSub?.cancel();
    _todayAttendanceSub = _firebaseService.streamTodayAttendanceRecords().listen(
      (records) {
        if (state is AttendanceLoaded) {
          final s = state as AttendanceLoaded;
          emit(s.copyWith(records: records));
        } else {
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
    _currentStatusSub = _firebaseService.streamTodayAttendance(userId).listen(
      (attendance) async {
        if (state is AttendanceLoaded) {
          final s = state as AttendanceLoaded;
          emit(s.copyWith(
            todayRecord: attendance,
            isCheckedIn: attendance != null && attendance.isCheckedIn,
          ));
        } else {
          final records = await _firebaseService.getTodayAttendanceRecords();
          emit(AttendanceLoaded(
            records: records,
            todayRecord: attendance,
            isCheckedIn: attendance != null && attendance.isCheckedIn,
          ));
        }
      },
    );
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
      final existing = await _firebaseService.getTodayAttendance(targetUserId);
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('الموظف لديه وردية نشطة حالياً مسبقاً'));
        loadTodayAttendance();
        return;
      }

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: targetUserId,
        userName: targetUserName,
        date: today,
        checkInTime: now,
        deviceId: 'qr_scanner', // سجل عبر ماسح الاستقبال
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

  /// مسح الـ QR للتحقق من الحضور أو الانصراف - Handle QR Scan for Check-in / Check-out
  Future<void> handleQrScan({
    required String targetUserId,
    required String targetUserName,
    required String adminUserId,
    required String adminUserName,
  }) async {
    emit(AttendanceLoading());
    try {
      final latest = await _firebaseService.getTodayAttendance(targetUserId);
      if (latest == null || latest.isCheckedOut) {
        // تسجيل حضور جديد - Check in a new session
        await checkInByUserId(
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          adminUserId: adminUserId,
          adminUserName: adminUserName,
        );
      } else {
        // تسجيل انصراف للجلسة النشطة - Check out the active session
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
      // Treat both codes as a toggle if appropriate, or handle them based on unified logic
      final latest = await _firebaseService.getTodayAttendance(userId);
      
      if (qrCode == 'NEWCARE_ATTENDANCE' || qrCode == 'NEWCARE_DEPARTURE' || qrCode == 'NEWCARE_UNIFIED') {
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
      final existing = await _firebaseService.getTodayAttendance(userId);
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('لديك وردية نشطة حالياً مسبقاً'));
        return;
      }

      final deviceId = await _deviceService.getDeviceId();
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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

      try {
        await _firebaseService.updateUserDeviceId(userId, deviceId);
      } catch (_) {}

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
      final attendance = await _firebaseService.getTodayAttendance(userId);
      if (attendance == null || attendance.isCheckedOut) {
        emit(const AttendanceError('لا يوجد تسجيل حضور نشط'));
        return;
      }

      final isConnected = await ConnectivityService.instance.checkConnection();
      if (isConnected) {
        await _firebaseService.checkOut(attendance.id);
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
  /// Comprehensive access verification
  Future<AccessVerificationResult> verifyAccess({
    required UserModel user,
  }) async {
    try {
      // 1. التحقق من الوردية
      final shift = await _firebaseService.getTodayShift(user.id);
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

      // المشرف يتخطى التحقق من الوردية والحضور والجهاز
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
      final attendance = await _firebaseService.getTodayAttendance(user.id);
      final isCheckedIn = attendance != null && attendance.isCheckedIn;

      // 3. التحقق من الجهاز
      final currentDeviceId = await _deviceService.getDeviceId();
      final isCorrectDevice = user.allowedDeviceIds.isEmpty ||
          user.allowedDeviceIds.contains(currentDeviceId);

      // بناء النتيجة
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
