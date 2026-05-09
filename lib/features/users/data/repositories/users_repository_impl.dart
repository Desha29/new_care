import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/users_repository.dart';

/// تنفيذ مستودع المستخدمين (الجيل الثاني) - Users Repository Implementation v2
/// Robust, offline-first user management.
class UsersRepositoryImpl implements IUsersRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createUser(UserModel user) async {
    await _local.saveUser(user.toSqliteMap());
    await _sync.enqueue(
      tableName: 'users',
      operation: 'create',
      docId: user.id,
      data: user.toMap(),
    );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _local.saveUser(user.toSqliteMap());
    await _sync.enqueue(
      tableName: 'users',
      operation: 'update',
      docId: user.id,
      data: user.toMap(),
    );
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _local.delete('users', where: 'id = ?', whereArgs: [userId]);
    await _sync.enqueue(
      tableName: 'users',
      operation: 'delete',
      docId: userId,
      data: {},
    );
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    final localData = await _local.getById('users', userId);
    if (localData != null) {
      return UserModel.fromMap(localData, userId);
    }
    
    final remote = await _remote.getUser(userId);
    if (remote != null) {
      await _local.saveUser(remote.toSqliteMap());
    }
    return remote;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final results = await _local.database.then((db) => db.query('users', orderBy: 'name'));
    return results.map((m) => UserModel.fromMap(m, m['id'] as String)).toList();
  }


  @override
  Future<int> getUsersCount() async {
    return await _local.getUsersCount();
  }

  @override
  Future<List<UserModel>> getUpdatedUsers(DateTime lastSync) async {
    return await _remote.getUpdatedUsers(lastSync);
  }

  @override
  Stream<List<UserModel>> usersStream() {
    return _remote.safeStream(FirebaseFirestore.instance.collection(AppConstants.usersCollection).orderBy('name')).map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  @override
  Future<List<UserModel>> getActiveNurses() async {
    final all = await getAllUsers();
    return all.where((u) => u.role == UserRole.nurse && u.isActive).toList();
  }

  @override
  Future<void> updateUserDeviceId(String userId, String deviceId) async {
    final user = await getUser(userId);
    if (user != null) {
      final updated = user.copyWith(deviceId: deviceId, updatedAt: DateTime.now());
      await updateUser(updated);
    }
  }

  @override
  Future<void> addAllowedDevice(String userId, String deviceId) async {
    final user = await getUser(userId);
    if (user != null) {
      if (!user.allowedDeviceIds.contains(deviceId)) {
        final devices = List<String>.from(user.allowedDeviceIds)..add(deviceId);
        final updated = user.copyWith(allowedDeviceIds: devices, updatedAt: DateTime.now());
        await updateUser(updated);
      }
    }
  }

  @override
  Future<String> registerUserAuth(String email, String password) async {
    return await _remote.registerUserAuth(email, password);
  }
}
