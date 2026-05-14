import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// تنفيذ مستودع المصادقة - Auth Repository Implementation
class AuthRepositoryImpl extends FirebaseBase implements IAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  CollectionReference get _usersRef =>
      firestore.collection(AppConstants.usersCollection);

  @override
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      // تحديث نسخة المستخدم محلياً - Update local user copy
      await SqliteService.instance.saveUser(user.toSqliteMap());
      return user;
    }
    // Try getting from local if online fails (implicitly handled by firestore cache usually, but we want explicit)
    final local = await SqliteService.instance.getUser(uid);
    if (local != null) return UserModel.fromMap(local, uid);
    
    return null;
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap());
    await SqliteService.instance.saveUser(user.toSqliteMap());
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // تحديث كلمة المرور المحلية عند النجاح - Update local password hash on success
    if (credential.user != null) {
      final hash = sha256.convert(utf8.encode(password)).toString();
      final userDoc = await _usersRef.doc(credential.user!.uid).get();
      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        final sqliteData = user.toSqliteMap();
        sqliteData['passwordHash'] = hash;
        await SqliteService.instance.saveUser(sqliteData);
      }
    }

    return credential;
  }

  @override
  Future<UserModel?> loginOffline(String email, String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    final localData = await SqliteService.instance.validateLocalLogin(email, hash);
    if (localData != null) {
      return UserModel.fromMap(localData, localData['id'] as String);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _firebaseAuth.currentUser?.updatePassword(newPassword);
    // Note: Local hash update happens next time they login online or if we update here
    if (_firebaseAuth.currentUser != null) {
       final hash = sha256.convert(utf8.encode(newPassword)).toString();
       final localData = await SqliteService.instance.getUser(_firebaseAuth.currentUser!.uid);
       if (localData != null) {
         final user = UserModel.fromSqliteMap(localData);
         final sqliteData = user.toSqliteMap();
         sqliteData['passwordHash'] = hash;
         await SqliteService.instance.saveUser(sqliteData);
       }
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
