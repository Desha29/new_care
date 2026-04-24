import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

/// حالات المصادقة - Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// حالة التحميل الأولية
class AuthInitial extends AuthState {}

/// جاري التحميل
class AuthLoading extends AuthState {}

/// تم المصادقة بنجاح
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// غير مصادق
class AuthUnauthenticated extends AuthState {}

/// خطأ في المصادقة
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
