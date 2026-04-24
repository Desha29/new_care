import 'package:equatable/equatable.dart';

/// فئة الفشل الأساسية - Base Failure Class
/// تمثل الأخطاء المتوقعة في طبقة الدومين
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// خطأ من الخادم - Server failure (Firebase)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

/// خطأ في التخزين المحلي - Local storage failure (SQLite)
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'حدث خطأ في التخزين المحلي']);
}

/// خطأ في الشبكة - Network failure
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

/// خطأ في المصادقة - Authentication failure
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'خطأ في المصادقة']);
}

/// خطأ في الصلاحيات - Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'لا تملك الصلاحيات الكافية']);
}

/// خطأ غير متوقع - Unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'حدث خطأ غير متوقع']);
}
