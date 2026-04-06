import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../../../core/services/firebase_service.dart';
import 'auth_state.dart';

/// كيوبت المصادقة - Auth Cubit
/// يدير حالة تسجيل الدخول والمستخدم الحالي
class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseService _firebaseService;
  UserModel? _currentUser;

  AuthCubit()
      : _firebaseAuth = FirebaseAuth.instance,
        _firebaseService = FirebaseService.instance,
        super(AuthInitial());

  /// المستخدم الحالي - Current user
  UserModel? get currentUser => _currentUser;

  /// التحقق من حالة المصادقة - Check auth state
  Future<void> checkAuthState() async {
    emit(AuthLoading());
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final user = await _firebaseService.getUser(firebaseUser.uid);
        if (user != null && user.isActive) {
          _currentUser = user;
          emit(AuthAuthenticated(user));
        } else {
          await _firebaseAuth.signOut();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('حدث خطأ في التحقق من الحساب'));
    }
  }

  /// تسجيل الدخول - Login
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final user = await _firebaseService.getUser(credential.user!.uid);
        if (user != null) {
          if (!user.isActive) {
            await _firebaseAuth.signOut();
            emit(const AuthError('تم تعطيل حسابك. تواصل مع المدير'));
            return;
          }
          _currentUser = user;

          // تسجيل نشاط الدخول - Log login activity
          await _firebaseService.logActivity(
            userId: user.id,
            userName: user.name,
            action: 'login',
            actionLabel: 'تسجيل دخول',
            details: 'قام ${user.name} بتسجيل الدخول',
          );

          emit(AuthAuthenticated(user));
        } else {
          await _firebaseAuth.signOut();
          emit(const AuthError('لم يتم العثور على بيانات المستخدم'));
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
      emit(const AuthError('خطأ غير متوقع في تسجيل الدخول'));
    }
  }

  /// تسجيل الخروج - Logout
  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        await _firebaseService.logActivity(
          userId: _currentUser!.id,
          userName: _currentUser!.name,
          action: 'logout',
          actionLabel: 'تسجيل خروج',
          details: 'قام ${_currentUser!.name} بتسجيل الخروج',
        );
      }
      await _firebaseAuth.signOut();
      _currentUser = null;
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('خطأ في تسجيل الخروج'));
    }
  }

  /// إعادة تعيين كلمة المرور - Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      emit(const AuthError('خطأ في إرسال رابط إعادة التعيين'));
    }
  }
}
