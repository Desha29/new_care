import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/shift_role.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_session_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../auth/data/models/user_model.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final IAttendanceRepository _attendanceRepository;
  final SyncManager _syncManager;

  AttendanceCubit({
    required IAttendanceRepository attendanceRepository,
    SyncManager? syncManager,
  }) : _attendanceRepository = attendanceRepository,
       _syncManager = syncManager ?? SyncManager.instance,
       super(AttendanceInitial());

  StreamSubscription? _todayAttendanceSub;
  StreamSubscription? _currentStatusSub;
  StreamSubscription? _activeSessionSub;
  Timer? _qrRotationTimer;

  @override
  Future<void> close() {
    _todayAttendanceSub?.cancel();
    _currentStatusSub?.cancel();
    _activeSessionSub?.cancel();
    _qrRotationTimer?.cancel();
    return super.close();
  }

  /// تحميل البيانات الأولية - Initialize attendance module
  void init() {
    loadTodayAttendance();
    loadAnalytics();
    listenToActiveSession();
  }

  /// تحميل جميع سجلات الحضور بصفحات - Load all attendance records paginated
  Future<void> loadAttendancePaginated({String? userId, bool force = false}) async {
    if (!force && state is AttendanceLoaded && (state as AttendanceLoaded).records.isNotEmpty) return;

    emit(AttendanceLoading());
    try {
      final result = await _attendanceRepository.getAttendancePaginated(
        userId: userId,
        limit: 20,
      );

      emit(AttendanceLoaded(
        records: result.items,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      ));
      
      loadAnalytics();
      listenToActiveSession();
    } catch (e) {
      emit(AttendanceError('خطأ في تحميل سجلات الحضور: ${e.toString()}'));
    }
  }

  // === Analytics ===

  Future<void> loadAnalytics() async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;
    
    emit(currentState.copyWith(isLoadingStats: true));
    try {
      final stats = await _attendanceRepository.getAttendanceStats(days: 7);
      emit((state as AttendanceLoaded).copyWith(
        stats: stats,
        isLoadingStats: false,
      ));
    } catch (e) {
      if (state is AttendanceLoaded) {
        emit((state as AttendanceLoaded).copyWith(isLoadingStats: false));
      }
    }
  }

  // === Session Management ===

  void listenToActiveSession() {
    _activeSessionSub?.cancel();
    _activeSessionSub = _attendanceRepository.streamActiveSession().listen((session) {
      if (state is AttendanceLoaded) {
        final currentState = state as AttendanceLoaded;
        emit(currentState.copyWith(
          activeSession: session,
          clearActiveSession: session == null,
        ));

        if (session != null && session.isActive) {
          _startQrRotation(session.id);
        } else {
          _qrRotationTimer?.cancel();
        }
      }
    });
  }

  void _startQrRotation(String sessionId) {
    _qrRotationTimer?.cancel();
    _qrRotationTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      final newSecret = const Uuid().v4();
      await _attendanceRepository.updateSessionQr(sessionId, newSecret);
    });
  }

  Future<void> startNewSession(String adminId) async {
    try {
      final session = AttendanceSessionModel(
        id: const Uuid().v4(),
        adminId: adminId,
        startTime: DateTime.now(),
        qrSecret: const Uuid().v4(),
        isActive: true,
      );
      await _attendanceRepository.startSession(session);
    } catch (e) {
      emit(AttendanceError('خطأ في بدء الجلسة: ${e.toString()}'));
    }
  }

  Future<void> endCurrentSession() async {
    if (state is! AttendanceLoaded) return;
    final session = (state as AttendanceLoaded).activeSession;
    if (session == null) return;

    try {
      await _attendanceRepository.endSession(session.id);
      _qrRotationTimer?.cancel();
    } catch (e) {
      emit(AttendanceError('خطأ في إنهاء الجلسة: ${e.toString()}'));
    }
  }

  /// تحميل المزيد من سجلات الحضور - Load more attendance records
  Future<void> loadMoreAttendance({String? userId}) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;
    
    if (currentState.isLoadingMore || !currentState.hasMore || currentState.lastDocument == null) return;

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final result = await _attendanceRepository.getAttendancePaginated(
        userId: userId,
        limit: 20,
        startAfter: currentState.lastDocument,
      );

      emit(currentState.copyWith(
        records: [...currentState.records, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// تحميل سجلات حضور اليوم بشكل تفاعلي - Reactive Load today's attendance records
  void loadTodayAttendance() {
    _todayAttendanceSub?.cancel();
    _todayAttendanceSub = _attendanceRepository
        .streamTodayAttendanceRecords()
        .listen(
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
    _currentStatusSub = _attendanceRepository
        .streamTodayAttendance(userId)
        .listen((attendanceList) async {
          final now = DateTime.now();
          final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          
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

  /// تسجيل الحضور للموظف (عبر QR) - Check in nurse via session
  Future<void> checkInWithSession({
    required String targetUserId,
    required String targetUserName,
    required String sessionId,
    required String secret,
  }) async {
    emit(AttendanceLoading());
    try {
      final session = await _attendanceRepository.getActiveSession();
      if (session == null || !session.isActive || session.id != sessionId) {
        emit(const AttendanceError('الجلسة غير نشطة أو منتهية الصلاحية'));
        loadTodayAttendance();
        return;
      }

      if (session.qrSecret != secret) {
        emit(const AttendanceError('رمز QR منتهي الصلاحية، يرجى المسح مرة أخرى'));
        loadTodayAttendance();
        return;
      }

      final existing = await _attendanceRepository.getTodayAttendance(targetUserId);
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('الموظف لديه وردية نشطة حالياً'));
        loadTodayAttendance();
        return;
      }

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Calculate lateness (example: if after 9:00 AM)
      int delay = 0;
      AttendanceStatus status = AttendanceStatus.checkedIn;
      if (now.hour >= 9 && now.minute > 15) {
        delay = (now.hour - 9) * 60 + now.minute;
        status = AttendanceStatus.late;
      }

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: targetUserId,
        userName: targetUserName,
        date: today,
        checkInTime: now,
        sessionId: sessionId,
        status: status,
        delayMinutes: delay,
      );

      await _syncManager.saveAttendanceWithSync(attendance);
      emit(AttendanceCheckedIn(attendance));
      loadTodayAttendance();
      loadAnalytics();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل الحضور: ${e.toString()}'));
    }
  }

  /// معالجة الكود الموحد (للتوافق مع الأنظمة القديمة) - Process Center QR (Legacy Compat)
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
          // Fallback to checkIn without session for legacy QR
          await checkInLegacy(userId: userId, userName: userName);
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

  /// تسجيل الحضور بدون جلسة (للتوافق القديم)
  Future<void> checkInLegacy({
    required String userId,
    required String userName,
  }) async {
    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        date: today,
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
      );

      await _syncManager.saveAttendanceWithSync(attendance);
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

      final now = DateTime.now();
      int earlyLeave = 0;
      AttendanceStatus status = AttendanceStatus.checkedOut;
      
      // Example early leave: if before 4:00 PM
      if (now.hour < 16) {
        earlyLeave = (16 - now.hour) * 60 - now.minute;
        status = AttendanceStatus.earlyLeave;
      }

      await _attendanceRepository.checkOut(attendance.id);
      
      final updatedRecord = attendance.copyWith(
        checkOutTime: now,
        status: status,
        earlyLeaveMinutes: earlyLeave,
      );

      await _syncManager.enqueue(
        tableName: 'attendance',
        operation: 'update',
        docId: attendance.id,
        data: updatedRecord.toMap(),
      );

      emit(AttendanceCheckedOut(updatedRecord));
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل الانصراف: ${e.toString()}'));
    }
  }

  /// التحقق الشامل من صلاحية الوصول
  Future<AccessVerificationResult> verifyAccess({
    required UserModel user,
  }) async {
    try {
      if (user.role.isSuperAdmin || user.role.isAdmin) {
        return const AccessVerificationResult(
          hasShift: true, isCheckedIn: true, isCorrectDevice: true, isGranted: true, message: 'وصول كامل للمشرفين',
        );
      }

      final attendance = await _attendanceRepository.getTodayAttendance(user.id);
      final isCheckedIn = attendance != null && attendance.isCheckedIn;

      if (!isCheckedIn) {
        return AccessVerificationResult(
          hasShift: true, isCheckedIn: false, isCorrectDevice: true, isGranted: false, message: 'يجب تسجيل الحضور أولاً',
        );
      }

      return const AccessVerificationResult(
        hasShift: true, isCheckedIn: true, isCorrectDevice: true, isGranted: true, message: 'تم التحقق بنجاح',
      );
    } catch (e) {
      return AccessVerificationResult(
        hasShift: false, isCheckedIn: false, isCorrectDevice: false, isGranted: false, message: 'خطأ في التحقق: ${e.toString()}',
      );
    }
  }

  /// الحصول على بيانات التقرير الشهري - Get monthly report data
  Future<Map<String, dynamic>?> getMonthlyReportData(int year, int month) async {
    try {
      final records = await _attendanceRepository.getMonthlyAttendanceRecords(year, month);
      if (records.isEmpty) return null;

      // We might also need shifts for context in the report
      // But for now, returning records is the priority
      return {
        'records': records,
        'shifts': [], // Placeholder if shifts are needed
      };
    } catch (e) {
      return null;
    }
  }
}
