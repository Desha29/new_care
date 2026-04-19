import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../enums/user_role.dart';
import '../../constants/app_constants.dart';
import 'firebase_base.dart';

/// مستودع المستخدمين - Users Repository
class UsersRepository extends FirebaseBase {
  CollectionReference get _usersRef =>
      firestore.collection(AppConstants.usersCollection);

  /// إنشاء مستخدم - Create user
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap());
  }

  /// تحديث مستخدم - Update user
  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toMap());
  }

  /// حذف مستخدم - Delete user
  Future<void> deleteUser(String userId) async {
    await _usersRef.doc(userId).delete();
  }

  /// جلب مستخدم - Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) {
        log('[Firestore] User not found: $userId');
        return null;
      }
      log('[Firestore] User found: $userId');
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      log('[Firestore] Error getting user $userId: $e');
      rethrow;
    }
  }

  /// جلب جميع المستخدمين - Get all users
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب عدد المستخدمين - Get users count
  Future<int> getUsersCount() async {
    final snapshot = await _usersRef.get();
    return snapshot.size;
  }

  /// بث المستخدمين - Stream all users
  Stream<List<UserModel>> usersStream() {
    return _usersRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// جلب الممرضين النشطين - Get active nurses
  Future<List<UserModel>> getActiveNurses() async {
    final snapshot = await _usersRef
        .where('role', isEqualTo: 'nurse')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// تحديث معرف الجهاز للمستخدم - Update user device ID
  Future<void> updateUserDeviceId(String userId, String deviceId) async {
    await _usersRef.doc(userId).update({
      'deviceId': deviceId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// إضافة جهاز مسموح به - Add allowed device
  Future<void> addAllowedDevice(String userId, String deviceId) async {
    final user = await getUser(userId);
    if (user != null) {
      final devices = List<String>.from(user.allowedDeviceIds);
      if (!devices.contains(deviceId)) {
        devices.add(deviceId);
        await _usersRef.doc(userId).update({
          'allowedDeviceIds': devices,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  /// إنشاء حساب مستخدم في Firebase Authentication
  Future<String> registerUserAuth(String email, String password) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) throw 'فشل في الحصول على معرف المستخدم';

      await secondaryApp.delete();
      return uid;
    } catch (e) {
      if (secondaryApp != null) await secondaryApp.delete();
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use': return 'البريد الإلكتروني مستخدم بالفعل';
        case 'weak-password': return 'كلمة المرور ضعيفة جداً';
        case 'invalid-email': return 'البريد الإلكتروني غير صالح';
        default: return e.message ?? 'فشل إنشاء الحساب';
      }
    }
    return e.toString();
  }

  /// تهيئة المستخدمين الافتراضيين - Seed default users
  Future<void> seedDefaultUsers() async {
    final auth = FirebaseAuth.instance;

    try {
      final superAdmins = await _usersRef.where('role', isEqualTo: 'super_admin').limit(1).get();
      if (superAdmins.docs.isNotEmpty) return;
    } catch (_) {
      return;
    }

    final seedUsers = [
      {
        'email': 'kamal@newcare.com',
        'password': '123456',
        'name': 'كمال',
        'phone': '01012345678',
        'role': UserRole.superAdmin,
      },
    ];

    for (final seedData in seedUsers) {
      try {
        String? uid;
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: seedData['email'] as String,
            password: seedData['password'] as String,
          );
          uid = cred.user?.uid;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            try {
              final cred = await auth.signInWithEmailAndPassword(
                email: seedData['email'] as String,
                password: seedData['password'] as String,
              );
              uid = cred.user?.uid;
            } catch (_) {
              continue;
            }
          }
        }

        if (uid == null) continue;

        final existingDoc = await _usersRef.doc(uid).get();
        if (!existingDoc.exists) {
          final user = UserModel(
            id: uid,
            name: seedData['name'] as String,
            email: seedData['email'] as String,
            phone: seedData['phone'] as String,
            role: seedData['role'] as UserRole,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await createUser(user);
        }
      } catch (e) {
        log('[Seed] Error processing user ${seedData['email']}: $e');
      }
    }

    try {
      await auth.signOut();
    } catch (_) {}
  }
}
