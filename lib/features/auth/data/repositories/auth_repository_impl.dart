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
  Future<UserModel?> getUser(String uid, {bool forceRefresh = false}) async {
    // 1. جلب النسخة المحلية أولاً للتحقق من وجود تغييرات معلقة
    final localData = await SqliteService.instance.getUser(uid);
    UserModel? localUser;
    if (localData != null) {
      localUser = UserModel.fromSqliteMap(localData);
    }

    try {
      final doc = await _usersRef.doc(uid).get(
        GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache),
      );
      
      if (doc.exists) {
        var user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // إذا كان المستخدم معطلاً محلياً ولكن السيرفر يقول أنه نشط، نتحقق من طابور المزامنة
        if (localUser != null && !localUser.isActive && user.isActive) {
          final hasPending = await SqliteService.instance.hasPendingSync('users', uid);
          if (hasPending) {
            // نثق في الحالة المحلية لأنها أحدث (بانتظار الرفع)
            user = user.copyWith(isActive: false);
          }
        }

        // تحديث نسخة المستخدم محلياً
        await SqliteService.instance.saveUser(user.toSqliteMap());
        return user;
      }
    } catch (e) {
      // فشل الاتصال أو خطأ آخر - العودة للنسخة المحلية
    }
    
    return localUser;
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
      final uid = credential.user!.uid;
      final hash = sha256.convert(utf8.encode(password)).toString();
      
      // جلب البيانات المحلية الحالية للتحقق من الحالة
      final localData = await SqliteService.instance.getUser(uid);
      
      final userDoc = await _usersRef.doc(uid).get();
      if (userDoc.exists) {
        var user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
        
        // التحقق من طابور المزامنة لمنع الكتابة فوق حالة الحظر المحلية
        if (localData != null) {
          final localUser = UserModel.fromSqliteMap(localData);
          if (!localUser.isActive && user.isActive) {
            final hasPending = await SqliteService.instance.hasPendingSync('users', uid);
            if (hasPending) {
              user = user.copyWith(isActive: false);
            }
          }
        }

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

  @override
  Stream<UserModel?> watchUserStatus(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        // Also update local storage when status changes
        SqliteService.instance.saveUser(user.toSqliteMap());
        return user;
      }
      return null;
    });
  }
}
