import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase/firebase_base.dart';
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
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap());
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _firebaseAuth.currentUser?.updatePassword(newPassword);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
