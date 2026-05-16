import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  UserModel? _currentUser;
  StreamSubscription<UserModel?>? _userStatusSubscription;

  AuthCubit({
    required IAuthRepository authRepository,
  }) : _authRepository = authRepository,
       super(AuthInitial());

  /// المستخدم الحالي - Current user
  UserModel? get currentUser => _currentUser;

  /// التحقق من حالة المصادقة - Check auth state
  Future<void> checkAuthState() async {
    emit(AuthLoading());
    try {
      final firebaseUser = _authRepository.currentFirebaseUser;
      if (firebaseUser != null) {
        // Force a fresh check from the server during app startup
        final user = await _authRepository.getUser(firebaseUser.uid, forceRefresh: true);
        if (user != null && user.isActive) {
          _currentUser = user;
          _startStatusMonitoring(user.id);
          emit(AuthAuthenticated(user));
        } else {
          await logout();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError('حدث خطأ في التحقق من الحساب: ${e.message}'));
      }
    } catch (e) {
      emit(AuthError('حدث خطأ في التحقق من الحساب: $e'));
    }
  }

  /// تسجيل الدخول - Login
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    
    // 1. التحقق من الاتصال بالإنترنت - Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasNoInternet = connectivityResult.contains(ConnectivityResult.none);

    if (hasNoInternet) {
      // محاولة تسجيل الدخول محلياً - Attempt offline login
      try {
        final user = await _authRepository.loginOffline(email, password);
        if (user != null) {
          if (!user.isActive) {
            emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
            return;
          }
          _currentUser = user;
          await _logActivity(user, 'login_offline', 'تسجيل دخول (بدون إنترنت)');
          _startStatusMonitoring(user.id);
          emit(AuthAuthenticated(user));
          return;
        } else {
          emit(const AuthError('لا يوجد اتصال بالإنترنت، ولم يتم العثور على بيانات دخول محلية مطابقة.'));
          return;
        }
      } catch (e) {
        emit(AuthError('خطأ في تسجيل الدخول المحلي: $e'));
        return;
      }
    }

    // 2. تسجيل دخول عادي (أونلاين) - Standard online login
    try {
      final credential = await _authRepository.signInWithEmailAndPassword(
        email.trim(),
        password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        
        // Force server fetch during login to ensure up-to-date status (especially isActive)
        var user = await _authRepository.getUser(uid, forceRefresh: true);
        
        if (user != null) {
          if (!user.isActive) {
            await _authRepository.signOut();
            emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
            return;
          }

          // === Nurse Attendance Check ===
          // Nurses must check in (attend) before they can login to the dashboard
          if (user.role.isNurse) {
            final attendance = await _authRepository.getTodayAttendance(user.id);
            if (attendance == null || !attendance.isCheckedIn) {
              await _authRepository.signOut();
              emit(const AuthError('عذراً، يجب تسجيل الحضور (البصمة) أولاً قبل الدخول إلى الحساب'));
              return;
            }
          }

          _currentUser = user;
          _startStatusMonitoring(user.id);
          await _logActivity(user, 'login', 'تسجيل دخول');
          emit(AuthAuthenticated(user));
        } else {
          // User exists in Auth but not in our Firestore users collection
          await _authRepository.signOut();
          emit(const AuthError('حسابك غير مسجل في قاعدة البيانات. تواصل مع الدعم'));
        }
      }
    } on FirebaseAuthException catch (e) {
      // معالجة أخطاء الشبكة أثناء المحاولة - Handle network errors during attempt
      if (e.code == 'network-request-failed' || e.code == 'unavailable') {
          // Fallback to offline login if online fails due to network
          final user = await _authRepository.loginOffline(email, password);
          if (user != null) {
             if (!user.isActive) {
               emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
               return;
             }
             _currentUser = user;
             _startStatusMonitoring(user.id);
             emit(AuthAuthenticated(user));
             return;
          }
      }
      
      String message;
      switch (e.code) {
        case 'user-not-found': message = 'البريد الإلكتروني غير مسجل لدينا'; break;
        case 'wrong-password': message = 'كلمة المرور التي أدخلتها غير صحيحة'; break;
        case 'invalid-credential': message = 'بيانات الدخول غير صحيحة. تأكد من البريد وكلمة المرور'; break;
        case 'invalid-email': message = 'تنسيق البريد الإلكتروني غير صحيح'; break;
        case 'user-disabled': message = 'عذراً، هذا الحساب تم تعطيله من قبل الإدارة'; break;
        case 'too-many-requests': message = 'لقد قمت بمحاولات كثيرة خاطئة. يرجى الانتظار قليلاً'; break;
        case 'network-request-failed': message = 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت'; break;
        default: 
          message = 'تعذر تسجيل الدخول حالياً. يرجى المحاولة مرة أخرى';
          LocalLogService.instance.logError('auth_login_error', 'Code: ${e.code}, Message: ${e.message}');
      }
      emit(AuthError(message));
    } catch (e) {
      // Fallback for generic network issues
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
          final user = await _authRepository.loginOffline(email, password);
          if (user != null) {
             if (!user.isActive) {
               emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
               return;
             }
             _currentUser = user;
             _startStatusMonitoring(user.id);
             emit(AuthAuthenticated(user));
             return;
          }
      }
      
      if (e.toString().contains('permission-denied')) {
        emit(const AuthError('عذراً، ليس لديك الصلاحيات الكافية للوصول'));
      } else {
        emit(const AuthError('حدث خطأ غير متوقع. يرجى التأكد من البيانات والمحاولة ثانياً'));
      }
    }
  }

  Future<void> _logActivity(UserModel user, String action, String label) async {
    await LocalLogService.instance.logActivity(
      userId: user.id,
      userName: user.name,
      action: action,
      actionLabel: label,
      details: 'قام ${user.name} بـ $label',
    );
  }

  /// تسجيل الخروج - Logout
  Future<void> logout() async {
    _cancelStatusMonitoring();
    try {
      if (_currentUser != null) {
        await _logActivity(_currentUser!, 'logout', 'تسجيل خروج');
      }
      await _authRepository.signOut();
      _currentUser = null;
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('خطأ في تسجيل الخروج'));
    }
  }

  /// مراقبة حالة الحساب في الوقت الفعلي - Start status monitoring
  void _startStatusMonitoring(String userId) {
    _cancelStatusMonitoring();
    _userStatusSubscription = _authRepository.watchUserStatus(userId).listen((user) {
      if (user != null && !user.isActive) {
        // Account deactivated while logged in
        logout();
        emit(const AuthError('تم تعطيل حسابك من قبل الإدارة. تم تسجيل الخروج'));
      }
    });
  }

  void _cancelStatusMonitoring() {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelStatusMonitoring();
    return super.close();
  }

  /// تغيير كلمة المرور للمستخدم الحالي - Change password for current user
  Future<void> changePassword(String newPassword) async {
    try {
      await _authRepository.updatePassword(newPassword);
      
      // تسجيل النشاط - Log activity
      if (_currentUser != null) {
        await LocalLogService.instance.logActivity(
          userId: _currentUser!.id,
          userName: _currentUser!.name,
          action: 'change_password',
          actionLabel: 'تغيير كلمة المرور',
          details: 'قام ${_currentUser!.name} بتغيير كلمة المرور الخاصة به',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'هذه العملية حساسة وتتطلب تسجيل الدخول مرة أخرى حديثاً';
      }
      throw e.message ?? 'خطأ في تغيير كلمة المرور';
    } catch (e) {
      throw 'خطأ: $e';
    }
  }

  /// طلب إعادة تعيين كلمة المرور لمستخدم آخر (للمسؤولين) - Reset user password email (for admins)
  Future<void> resetUserPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
      
      // تسجيل النشاط - Log activity
      if (_currentUser != null) {
        await LocalLogService.instance.logActivity(
          userId: _currentUser!.id,
          userName: _currentUser!.name,
          action: 'admin_reset_password',
          actionLabel: 'إعادة تعيين كلمة مرور',
          details: 'قام ${_currentUser!.name} بإرسال رابط إعادة تعيين كلمة مرور لـ $email',
        );
      }
    } catch (e) {
      throw 'خطأ في إرسال رابط إعادة التعيين: $e';
    }
  }

  /// إعادة تعيين كلمة المرور - Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email.trim());
    } catch (e) {
      emit(const AuthError('خطأ في إرسال رابط إعادة التعيين'));
    }
  }
}

