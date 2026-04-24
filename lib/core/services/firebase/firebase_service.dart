import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:new_care/features/auth/data/models/user_model.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/activity_logs/data/models/log_model.dart';
import 'package:new_care/features/procedures/data/models/procedure_model.dart';
import 'package:new_care/features/shifts/data/models/shift_model.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/core/constants/app_constants.dart';

/// خدمة Firebase Firestore المحدثة - Optimized FirebaseService
/// Focus: ONLY Firestore operations, high reliability, idempotency.
class FirebaseService {
  static FirebaseService? _instance;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  // Telemetry
  static int readCount = 0;
  static int writeCount = 0;

  FirebaseService._() : _firestore = FirebaseFirestore.instance;

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  void _incRead() => readCount++;
  void _incWrite() => writeCount++;

  String generateId() => _uuid.v4();

  // ============================================
  // === المصادقة - Auth ===
  // ============================================

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
      if (uid == null) throw 'Failed to get UID';

      await secondaryApp.delete();
      return uid;
    } catch (e) {
      if (secondaryApp != null) await secondaryApp.delete();
      throw _handleError('Auth', e);
    }
  }

  // ============================================
  // === المستخدمون - Users ===
  // ============================================

  CollectionReference get _usersRef => _firestore.collection(AppConstants.usersCollection);

  Future<void> createUser(UserModel user) async {
    _incWrite();
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUser(UserModel user) async {
    _incWrite();
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUser(String uid) async {
    _incRead();
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<List<UserModel>> getAllUsers() async {
    _incRead();
    final snapshot = await _usersRef.orderBy('name').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<UserModel>> getUpdatedUsers(DateTime lastSync) async {
    _incRead();
    final snapshot = await _usersRef.where('updatedAt', isGreaterThan: lastSync.toIso8601String()).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> deleteUser(String uid) async {
    _incWrite();
    await _usersRef.doc(uid).delete();
  }

  Future<List<UserModel>> getActiveNurses() async {
    _incRead();
    final snapshot = await _usersRef.where('role', isEqualTo: 'nurse').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((u) => u.isActive)
        .toList();
  }

  // ============================================
  // === السجلات - Logs ===
  // ============================================

  CollectionReference get _logsRef => _firestore.collection(AppConstants.logsCollection);

  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    _incRead();
    final snapshot = await _logsRef.orderBy('timestamp', descending: true).limit(limit).get();
    return snapshot.docs.map((doc) => LogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // ============================================
  // === الحالات - Cases ===
  // ============================================

  CollectionReference get _casesRef => _firestore.collection('cases');

  Future<void> createCase(CaseModel model) async {
    _incWrite();
    await _casesRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updateCase(CaseModel model) async {
    _incWrite();
    await _casesRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCase(String id) async {
    _incWrite();
    await _casesRef.doc(id).delete();
  }

  Future<List<CaseModel>> getAllCases({String? nurseId}) async {
    _incRead();
    if (nurseId != null) {
      final snapshot = await _casesRef.where('nurseId', isEqualTo: nurseId).get();
      final cases = snapshot.docs.map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      cases.sort((a, b) => b.caseDate.compareTo(a.caseDate));
      return cases;
    }
    final snapshot = await _casesRef.orderBy('caseDate', descending: true).get();
    return snapshot.docs.map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<CaseModel>> getUpdatedCases(DateTime lastSync) async {
    _incRead();
    final snapshot = await _casesRef.where('updatedAt', isGreaterThan: lastSync.toIso8601String()).get();
    return snapshot.docs.map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Stream<List<CaseModel>> streamAllCases({String? nurseId}) {
    Query query = _casesRef.orderBy('caseDate', descending: true);
    if (nurseId != null) {
      query = _casesRef.where('nurseId', isEqualTo: nurseId);
    }
    return safeStream(query).map((snapshot) {
      final cases = snapshot.docs.map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      if (nurseId != null) {
        // Double check filtering in Dart as well for consistency across platforms if needed
        return cases.where((c) => c.nurseId == nurseId).toList();
      }
      return cases;
    });
  }

  // ============================================
  // === الإحصائيات - Statistics ===
  // ============================================

  Future<int> getUsersCount() async {
    _incRead();
    final snapshot = await _usersRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getPatientsCount() async {
    _incRead();
    final snapshot = await _casesRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getShiftsCount() async {
    _incRead();
    final snapshot = await _shiftsRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getInventoryCount() async {
    _incRead();
    final snapshot = await _inventoryRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getProceduresCount() async {
    _incRead();
    final snapshot = await _proceduresRef.count().get();
    return snapshot.count ?? 0;
  }

  void resetStats() {
    readCount = 0;
    writeCount = 0;
  }

  // ============================================
  // === الجرد - Inventory ===
  // ============================================

  CollectionReference get _inventoryRef => _firestore.collection('inventory');

  Future<void> createInventoryItem(InventoryModel item) async {
    _incWrite();
    await _inventoryRef.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> updateInventoryItem(InventoryModel item) async {
    _incWrite();
    await _inventoryRef.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteInventoryItem(String id) async {
    _incWrite();
    await _inventoryRef.doc(id).delete();
  }

  Future<List<InventoryModel>> getAllInventory() async {
    _incRead();
    final snapshot = await _inventoryRef.get();
    return snapshot.docs.map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<InventoryModel>> getUpdatedInventory(DateTime lastSync) async {
    _incRead();
    final snapshot = await _inventoryRef.where('updatedAt', isGreaterThan: lastSync.toIso8601String()).get();
    return snapshot.docs.map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // ============================================
  // === الإجراءات - Procedures ===
  // ============================================

  CollectionReference get _proceduresRef => _firestore.collection('procedures');

  Future<void> createProcedure(ProcedureModel model) async {
    _incWrite();
    await _proceduresRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updateProcedure(ProcedureModel model) async {
    _incWrite();
    await _proceduresRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProcedure(String id) async {
    _incWrite();
    await _proceduresRef.doc(id).delete();
  }

  Future<List<ProcedureModel>> getAllProcedures() async {
    _incRead();
    final snapshot = await _proceduresRef.get();
    return snapshot.docs.map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<ProcedureModel>> getUpdatedProcedures(DateTime lastSync) async {
    _incRead();
    final snapshot = await _proceduresRef.where('updatedAt', isGreaterThan: lastSync.toIso8601String()).get();
    return snapshot.docs.map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // ============================================
  // === الحضور - Attendance ===
  // ============================================

  CollectionReference get _attendanceRef => _firestore.collection('attendance');

  Future<void> checkIn(AttendanceModel attendance) async {
    _incWrite();
    await _attendanceRef.doc(attendance.id).set(attendance.toMap(), SetOptions(merge: true));
  }

  Future<void> checkOut(String attendanceId) async {
    _incWrite();
    await _attendanceRef.doc(attendanceId).update({
      'checkOutTime': DateTime.now().toIso8601String(),
      'status': 'checked_out',
    });
  }

  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    _incRead();
    final today = _todayString();
    final snapshot = await _attendanceRef.where('date', isEqualTo: today).get();
    
    final records = snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((a) => a.userId == userId)
        .toList();

    if (records.isEmpty) return null;
    records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return records.first;
  }

  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    _incRead();
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _attendanceRef.where('date', isGreaterThanOrEqualTo: startId).where('date', isLessThan: endId).get();
    return snapshot.docs.map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  // ============================================
  // === الورديات - Shifts ===
  // ============================================

  CollectionReference get _shiftsRef => _firestore.collection('shifts');

  Future<void> updateShift(ShiftModel shift) async {
    _incWrite();
    await _shiftsRef.doc(shift.id).set(shift.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteShift(String shiftId) async {
    _incWrite();
    await _shiftsRef.doc(shiftId).delete();
  }

  Future<ShiftModel?> getTodayShift(String userId) async {
    _incRead();
    final today = _todayString();
    final snapshot = await _shiftsRef.where('date', isEqualTo: today).get();
    
    final records = snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((s) => s.userId == userId)
        .toList();
    
    return records.isNotEmpty ? records.first : null;
  }

  Future<List<ShiftModel>> getMonthlyShifts(int year, int month) async {
    _incRead();
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _firestore
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();

    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ============================================
  // === المساعدات - Helpers ===
  // ============================================

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  dynamic _handleError(String module, dynamic e) {
    log('[$module Error] ${e.toString()}');
    return e;
  }

  Stream<QuerySnapshot<Object?>> safeStream(Query query) {
    if (kIsWeb || !Platform.isWindows) return query.snapshots();
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) => query.get()).asBroadcastStream();
  }
}
