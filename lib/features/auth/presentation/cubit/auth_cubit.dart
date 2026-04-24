import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../../../core/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _authRepository;
  UserModel? _currentUser;

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
        final user = await _authRepository.getUser(firebaseUser.uid);
        if (user != null && user.isActive) {
          _currentUser = user;
          emit(AuthAuthenticated(user));
        } else {
          await _authRepository.signOut();
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
    try {
      final credential = await _authRepository.signInWithEmailAndPassword(
        email.trim(),
        password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        final userEmail = credential.user!.email;
        
        var user = await _authRepository.getUser(uid);
        
        // Auto-fix orphaned users (in Auth but missing Firestore doc)
        if (user == null && userEmail != null) {
          user = UserModel(
            id: uid,
            name: userEmail.split('@').first,
            email: userEmail,
            phone: '',
            role: UserRole.nurse, // Fallback default
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          try {
            await _authRepository.createUser(user);
          } catch (e) {
            await _authRepository.signOut();
            emit(AuthError('لم نتمكن من تهيئة ملفك بصورة صحيحة: $e'));
            return;
          }
        }

        if (user != null) {
          if (!user.isActive) {
            await _authRepository.signOut();
            emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
            return;
          }
          _currentUser = user;

          // تسجيل نشاط الدخول محلياً - Log login activity locally
          await LocalLogService.instance.logActivity(
            userId: user.id,
            userName: user.name,
            action: 'login',
            actionLabel: 'تسجيل دخول',
            details: 'قام ${user.name} بتسجيل الدخول',
          );

          emit(AuthAuthenticated(user));
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'البريد الإلكتروني غير مسجل';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          message = 'بريد إلكتروني غير صحيح';
          break;
        case 'user-disabled':
          message = 'تم تعطيل هذا الحساب';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة. حاول لاحقاً';
          break;
        default:
          message = 'خطأ في تسجيل الدخول: ${e.message}';
      }
      emit(AuthError(message));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        emit(
          const AuthError(
            'الصلاحيات غير كافية للوصول (Permission Denied). يرجى مراجعة القواعد (Rules) في كونسول فايربيز كمدير نظام.',
          ),
        );
      } else {
        emit(AuthError('خطأ غير متوقع في تسجيل الدخول: $e'));
      }
    }
  }

  /// تسجيل الخروج - Logout
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        await LocalLogService.instance.logActivity(
          userId: _currentUser!.id,
          userName: _currentUser!.name,
          action: 'logout',
          actionLabel: 'تسجيل خروج',
          details: 'قام ${_currentUser!.name} بتسجيل الخروج',
        );
      }
      await _authRepository.signOut();
      _currentUser = null;
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('خطأ في تسجيل الخروج'));
    }
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

