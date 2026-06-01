import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/shift_role.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/attendance_session_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../shifts/data/models/shift_model.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final IAttendanceRepository _attendanceRepository;

  AttendanceCubit({required IAttendanceRepository attendanceRepository})
    : _attendanceRepository = attendanceRepository,
      super(AttendanceInitial());

  StreamSubscription? _todayAttendanceSub;
  StreamSubscription? _currentStatusSub;
  StreamSubscription? _activeSessionSub;
  Timer? _qrRotationTimer;
  Timer? _statusRefreshTimer;
  Timer? _autoCheckoutTimer;
  String? _currentUserIdForRefresh;

  @override
  Future<void> close() {
    _todayAttendanceSub?.cancel();
    _currentStatusSub?.cancel();
    _activeSessionSub?.cancel();
    _qrRotationTimer?.cancel();
    _statusRefreshTimer?.cancel();
    _autoCheckoutTimer?.cancel();
    return super.close();
  }

  /// تحميل البيانات الأولية - Initialize attendance module
  void init({String? userId}) {
    loadTodayAttendance(userId: userId);
    if (userId != null) {
      // For individual users, also listen to their specific today's status
      _currentUserIdForRefresh = userId;
      checkTodayStatus(userId);
      // checkTodayStatus already sets up the refresh timer
    }
    loadAnalytics(userId: userId);
    _startAutoCheckoutChecker();
    // Only listen to session if specifically needed (e.g. nurse app or explicit admin action)
    // For now, disabling to prevent unnecessary polling/generation on desktop
    // listenToActiveSession();
  }

  /// فاحص دوري للتحقق من الانصراف التلقائي الفوري دون الحاجة لإعادة تشغيل النظام
  void _startAutoCheckoutChecker() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (state is AttendanceLoaded) {
        final currentState = state as AttendanceLoaded;
        final hasActiveCheckIns =
            currentState.records.any((r) => r.isCheckedIn) ||
            (currentState.todayRecord != null &&
                currentState.todayRecord!.isCheckedIn);

        if (hasActiveCheckIns) {
          try {
            // هذا الفحص سيقوم بتحديث السجلات في Firestore فوراً بمجرد انتهاء ساعات العمل
            await _attendanceRepository.getTodayAttendanceRecords();
            if (_currentUserIdForRefresh != null) {
              await _attendanceRepository.getTodayAttendance(
                _currentUserIdForRefresh!,
              );
            }
          } catch (e) {
            // معالجة الأخطاء الصامتة لتجنب تعطيل واجهة المستخدم
          }
        }
      }
    });
  }

  /// Start periodic refresh timer for immediate updates
  void _startStatusRefreshTimer(String userId) {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_currentUserIdForRefresh == userId && state is AttendanceLoaded) {
        try {
          final latest = await _attendanceRepository.getTodayAttendance(userId);
          final currentState = state as AttendanceLoaded;

          // Only emit if the status changed
          if (latest?.id != currentState.todayRecord?.id ||
              latest?.isCheckedIn != currentState.isCheckedIn) {
            emit(
              currentState.copyWith(
                todayRecord: latest,
                isCheckedIn: latest != null && latest.isCheckedIn,
              ),
            );
          }
        } catch (e) {
          // Silent error handling - don't block UI
        }
      }
    });
  }

  /// تحميل جميع سجلات الحضور بصفحات - Load all attendance records paginated
  Future<void> loadAttendancePaginated({
    String? userId,
    bool force = false,
  }) async {
    if (!force &&
        state is AttendanceLoaded &&
        (state as AttendanceLoaded).records.isNotEmpty) {
      return;
    }

    emit(AttendanceLoading());
    try {
      final result = await _attendanceRepository.getAttendancePaginated(
        userId: userId,
        limit: 20,
      );

      emit(
        AttendanceLoaded(
          records: result.items,
          hasMore: result.hasMore,
          lastDocument: result.lastDocument,
        ),
      );

      loadAnalytics();
      listenToActiveSession();
    } catch (e) {
      emit(AttendanceError('خطأ في تحميل سجلات الحضور: ${e.toString()}'));
    }
  }

  // === Analytics ===

  Future<void> loadAnalytics({String? userId}) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    emit(currentState.copyWith(isLoadingStats: true));
    try {
      final stats = await _attendanceRepository.getAttendanceStats(
        days: 7,
        userId: userId,
      );
      emit(
        (state as AttendanceLoaded).copyWith(
          stats: stats,
          isLoadingStats: false,
        ),
      );
    } catch (e) {
      if (state is AttendanceLoaded) {
        emit((state as AttendanceLoaded).copyWith(isLoadingStats: false));
      }
    }
  }

  // === Session Management ===

  void listenToActiveSession() {
    _activeSessionSub?.cancel();
    _activeSessionSub = _attendanceRepository.streamActiveSession().listen((
      session,
    ) {
      if (state is AttendanceLoaded) {
        final currentState = state as AttendanceLoaded;
        emit(
          currentState.copyWith(
            activeSession: session,
            clearActiveSession: session == null,
          ),
        );

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
    _qrRotationTimer = Timer.periodic(const Duration(seconds: 45), (
      timer,
    ) async {
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

    if (currentState.isLoadingMore ||
        !currentState.hasMore ||
        currentState.lastDocument == null) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final result = await _attendanceRepository.getAttendancePaginated(
        userId: userId,
        limit: 20,
        startAfter: currentState.lastDocument,
      );

      emit(
        currentState.copyWith(
          records: [...currentState.records, ...result.items],
          isLoadingMore: false,
          hasMore: result.hasMore,
          lastDocument: result.lastDocument,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// تحميل سجلات حضور اليوم بشكل تفاعلي - Reactive Load today's attendance records
  void loadTodayAttendance({String? userId}) {
    _todayAttendanceSub?.cancel();
    _todayAttendanceSub = _attendanceRepository
        .streamTodayAttendanceRecords()
        .listen(
          (records) {
            // تصفية السجلات حسب المستخدم إذا وجد - Filter records by userId if provided
            final filteredRecords = userId != null
                ? records.where((r) => r.userId == userId).toList()
                : records;

            if (state is AttendanceLoaded) {
              final s = state as AttendanceLoaded;
              emit(s.copyWith(records: filteredRecords));
            } else {
              emit(AttendanceLoaded(records: filteredRecords));
            }
          },
          onError: (e) {
            emit(AttendanceError('خطأ في تحميل سجلات الحضور: ${e.toString()}'));
          },
        );
  }

  void checkTodayStatus(String userId) {
    _currentUserIdForRefresh = userId;
    _statusRefreshTimer?.cancel();
    // Start immediate periodic refresh
    _startStatusRefreshTimer(userId);

    _currentStatusSub?.cancel();
    _currentStatusSub = _attendanceRepository
        .streamTodayAttendance(userId)
        .listen(
          (attendanceList) {
            // Stream now returns only today's records filtered by userId
            final attendance = attendanceList.isNotEmpty
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
              emit(
                AttendanceLoaded(
                  records: [?attendance],
                  todayRecord: attendance,
                  isCheckedIn: attendance != null && attendance.isCheckedIn,
                ),
              );
            }
          },
          onError: (e) {
            // If stream errors, log it but don't emit error to avoid blocking UI
            print('Error in checkTodayStatus stream: $e');
          },
        );
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
        emit(
          const AttendanceError('رمز QR منتهي الصلاحية، يرجى المسح مرة أخرى'),
        );
        loadTodayAttendance();
        return;
      }

      final existing = await _attendanceRepository.getTodayAttendance(
        targetUserId,
      );
      if (existing != null && !existing.isCheckedOut) {
        emit(const AttendanceError('الموظف لديه وردية نشطة حالياً'));
        loadTodayAttendance();
        return;
      }

      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

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

      // Save directly to Firestore (Firestore-first)
      await _attendanceRepository.checkIn(attendance);

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
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final attendance = AttendanceModel(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        date: today,
        checkInTime: now,
        status: AttendanceStatus.checkedIn,
      );

      // Save directly to Firestore (Firestore-first)
      await _attendanceRepository.checkIn(attendance);

      emit(AttendanceCheckedIn(attendance));
      loadTodayAttendance();
    } catch (e) {
      emit(AttendanceError('خطأ في تسجيل الحضور: ${e.toString()}'));
    }
  }

  /// تسجيل الانصراف - Check out (Firestore-first)
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

      // Checkout directly on Firestore
      await _attendanceRepository.checkOut(attendance.id);

      final now = DateTime.now();
      final updatedRecord = attendance.copyWith(
        checkOutTime: now,
        status: AttendanceStatus.checkedOut,
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
          hasShift: true,
          isCheckedIn: true,
          isCorrectDevice: true,
          isGranted: true,
          message: 'وصول كامل للمشرفين',
        );
      }

      final attendance = await _attendanceRepository.getTodayAttendance(
        user.id,
      );
      final isCheckedIn = attendance != null && attendance.isCheckedIn;

      if (!isCheckedIn) {
        return AccessVerificationResult(
          hasShift: true,
          isCheckedIn: false,
          isCorrectDevice: true,
          isGranted: false,
          message: 'يجب تسجيل الحضور أولاً',
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

  /// الحصول على بيانات التقرير الشهري - Get monthly report data
  Future<Map<String, dynamic>?> getMonthlyReportData(
    int year,
    int month,
  ) async {
    try {
      final records = await _attendanceRepository.getMonthlyAttendanceRecords(
        year,
        month,
      );
      if (records.isEmpty) return null;

      // We might also need shifts for context in the report
      // But for now, returning records is the priority
      return {'records': records, 'shifts': <ShiftModel>[]};
    } catch (e) {
      return null;
    }
  }

  /// حذف سجل الحضور والإنصراف
  Future<void> deleteAttendance(String id) async {
    try {
      await _attendanceRepository.deleteAttendance(id);
    } catch (e) {
      emit(AttendanceError('خطأ في حذف السجل: ${e.toString()}'));
    }
  }
}
