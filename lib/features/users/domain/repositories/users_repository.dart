import '../../../auth/data/models/user_model.dart';

/// واجهة مستودع المستخدمين - Users Repository Interface
abstract class IUsersRepository {
  /// إنشاء مستخدم - Create user
  Future<void> createUser(UserModel user);

  /// تحديث مستخدم - Update user
  Future<void> updateUser(UserModel user);

  /// حذف مستخدم - Delete user
  Future<void> deleteUser(String userId);

  /// جلب مستخدم - Get user by ID
  Future<UserModel?> getUser(String userId);

  /// جلب جميع المستخدمين - Get all users
  Future<List<UserModel>> getAllUsers();

  /// جلب عدد المستخدمين - Get users count
  Future<int> getUsersCount();

  /// جلب المستخدمين المحدثين بعد وقت معين - Get updated users
  Future<List<UserModel>> getUpdatedUsers(DateTime lastSync);

  /// بث المستخدمين - Stream all users
  Stream<List<UserModel>> usersStream();

  /// جلب الممرضين النشطين - Get active nurses
  Future<List<UserModel>> getActiveNurses();

  /// تحديث معرف الجهاز للمستخدم - Update user device ID
  Future<void> updateUserDeviceId(String userId, String deviceId);

  /// إضافة جهاز مسموح به - Add allowed device
  Future<void> addAllowedDevice(String userId, String deviceId);

  /// إنشاء حساب في Firebase Authentication - Register user auth
  Future<String> registerUserAuth(String email, String password);
}
