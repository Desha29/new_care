import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';

/// واجهة مستودع المصادقة - Auth Repository Interface
abstract class IAuthRepository {
  /// الحصول على المستخدم الحالي من Firebase Auth
  User? get currentFirebaseUser;

  /// الحصول على بيانات المستخدم من Firestore
  Future<UserModel?> getUser(String uid, {bool forceRefresh = false});

  /// الحصول على سجل الحضور لليوم - Get today's attendance record
  Future<AttendanceModel?> getTodayAttendance(String userId);

  /// إنشاء مستخدم جديد في Firestore
  Future<void> createUser(UserModel user);

  /// تسجيل الدخول
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);

  /// تسجيل الخروج
  Future<void> signOut();

  /// تغيير كلمة المرور
  Future<void> updatePassword(String newPassword);

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordResetEmail(String email);

  /// تسجيل الدخول بدون إنترنت (محلياً)
  Future<UserModel?> loginOffline(String email, String password);

  /// مراقبة حالة المصادقة
  Stream<User?> get authStateChanges;

  /// مراقبة حالة المستخدم في الوقت الفعلي
  Stream<UserModel?> watchUserStatus(String uid);
}
