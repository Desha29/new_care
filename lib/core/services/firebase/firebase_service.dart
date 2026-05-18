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
import 'package:new_care/features/payroll/data/models/payroll_model.dart';
import 'package:new_care/features/financials/data/models/expense_model.dart';
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

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

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
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<List<UserModel>> getUpdatedUsers(DateTime lastSync) async {
    _incRead();
    final snapshot = await _usersRef.get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> deleteUser(String uid) async {
    _incWrite();
    await _usersRef.doc(uid).delete();
  }

  Future<List<UserModel>> getActiveNurses() async {
    _incRead();
    final snapshot = await _usersRef.where('role', isEqualTo: 'nurse').get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .where((u) => u.isActive)
        .toList();
  }

  // ============================================
  // === السجلات - Logs ===
  // ============================================

  CollectionReference get _logsRef =>
      _firestore.collection(AppConstants.logsCollection);

  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    _incRead();
    final snapshot = await _logsRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(
          (doc) => LogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
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
      final snapshot = await _casesRef
          .where('nurseId', isEqualTo: nurseId)
          .get();
      final cases = snapshot.docs
          .map(
            (doc) =>
                CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      cases.sort((a, b) => b.caseDate.compareTo(a.caseDate));
      return cases;
    }
    final snapshot = await _casesRef
        .orderBy('caseDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<List<CaseModel>> getUpdatedCases(DateTime lastSync) async {
    _incRead();
    final snapshot = await _casesRef.get();
    return snapshot.docs
        .map(
          (doc) =>
              CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<CaseModel?> getCaseById(String id) async {
    _incRead();
    final doc = await _casesRef.doc(id).get();
    if (!doc.exists) return null;
    return CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// جلب الحالات بصفحات - Get paginated cases
  Future<PaginatedResult<CaseModel>> getCasesPaginated({
    String? nurseId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _incRead();
    Query query = _casesRef.orderBy('caseDate', descending: true);

    if (nurseId != null) {
      query = query.where('nurseId', isEqualTo: nurseId);
    }

    if (startDate != null && endDate != null && startDate.year == endDate.year && startDate.month == endDate.month && startDate.day == endDate.day) {
      // Robust prefix matching for a single day
      final datePrefix = startDate.toIso8601String().split('T')[0];
      query = query.where('caseDate', isGreaterThanOrEqualTo: datePrefix)
                   .where('caseDate', isLessThanOrEqualTo: '$datePrefix\uf8ff');
    } else {
      if (startDate != null) {
        final datePrefix = startDate.toIso8601String().split('T')[0];
        query = query.where('caseDate', isGreaterThanOrEqualTo: datePrefix);
      }
      
      if (endDate != null) {
        final datePrefix = endDate.toIso8601String().split('T')[0];
        query = query.where('caseDate', isLessThanOrEqualTo: '$datePrefix\uf8ff');
      }
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get();
    final items = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: items.length == limit,
    );
  }

  /// جلب سجلات الحضور بصفحات - Get paginated attendance records
  Future<PaginatedResult<AttendanceModel>> getAttendancePaginated({
    String? userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _incRead();
    Query query = _firestore.collection('attendance')
        .orderBy('checkInTime', descending: true);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (startDate != null) {
      query = query.where('checkInTime', isGreaterThanOrEqualTo: startDate);
    }
    
    if (endDate != null) {
      query = query.where('checkInTime', isLessThanOrEqualTo: endDate);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get();
    final items = snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: items.length == limit,
    );
  }

  /// جلب الإحصائيات المجمعة لليوم - Get daily aggregated data (count & sum)
  Future<Map<String, dynamic>> getDailyAggregates({DateTime? date}) async {
    _incRead();
    final targetDate = date ?? DateTime.now();
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day).toIso8601String();
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).toIso8601String();

    final query = _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: start)
        .where('caseDate', isLessThanOrEqualTo: end);

    final snapshot = await query.get();
    double totalRevenue = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
    }

    return {
      'totalCases': snapshot.docs.length,
      'totalRevenue': totalRevenue,
    };
  }

  Stream<List<CaseModel>> streamAllCases({String? nurseId}) {
    Query query = _casesRef.orderBy('caseDate', descending: true);
    if (nurseId != null) {
      query = _casesRef.where('nurseId', isEqualTo: nurseId);
    }
    return safeStream(query).map((snapshot) {
      final cases = snapshot.docs
          .map(
            (doc) =>
                CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
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
    return snapshot.docs
        .map(
          (doc) => InventoryModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<void> deductInventoryItem(String id, int quantity) async {
    try {
      _incWrite();
      final docRef = _inventoryRef.doc(id);

      // First check if item exists to avoid transaction errors
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        log('[FirebaseService] Item $id not found, skipping deduction');
        return; // Item doesn't exist, skip deduction
      }

      final currentQuantity =
          (snapshot.data() as Map<String, dynamic>)['quantity'] ?? 0;
      final newQuantity = (currentQuantity - quantity).clamp(0, 999999);

      // Use simple update instead of transaction to avoid Windows platform issues
      await docRef.update({'quantity': newQuantity});
    } catch (e) {
      log('[FirebaseService] Error deducting inventory $id: $e');
      // Don't throw - inventory deduction failures shouldn't block sync
    }
  }

  Future<List<InventoryModel>> getUpdatedInventory(DateTime lastSync) async {
    _incRead();
    final snapshot = await _inventoryRef.get();
    return snapshot.docs
        .map(
          (doc) => InventoryModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<InventoryModel?> getInventoryItemById(String id) async {
    _incRead();
    final doc = await _inventoryRef.doc(id).get();
    if (!doc.exists) return null;
    return InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ============================================
  // === الإجراءات - Procedures ===
  // ============================================

  CollectionReference get _proceduresRef => _firestore.collection('procedures');

  Future<void> createProcedure(ProcedureModel model) async {
    _incWrite();
    await _proceduresRef
        .doc(model.id)
        .set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updateProcedure(ProcedureModel model) async {
    _incWrite();
    await _proceduresRef
        .doc(model.id)
        .set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProcedure(String id) async {
    _incWrite();
    await _proceduresRef.doc(id).delete();
  }

  Future<List<ProcedureModel>> getAllProcedures() async {
    _incRead();
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map(
          (doc) => ProcedureModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<ProcedureModel>> getUpdatedProcedures(DateTime lastSync) async {
    _incRead();
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map(
          (doc) => ProcedureModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // ============================================
  // === الحضور - Attendance ===
  // ============================================

  CollectionReference get _attendanceRef => _firestore.collection('attendance');

  Future<void> checkIn(AttendanceModel attendance) async {
    _incWrite();
    await _attendanceRef
        .doc(attendance.id)
        .set(attendance.toMap(), SetOptions(merge: true));
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
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .where((a) => a.userId == userId)
        .toList();

    if (records.isEmpty) return null;
    records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return records.first;
  }

  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(
    int year,
    int month,
  ) async {
    _incRead();
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final snapshot = await _attendanceRef
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  /// جلب جميع سجلات الحضور - Get all attendance records
  Future<List<AttendanceModel>> getAllAttendance() async {
    _incRead();
    final snapshot = await _attendanceRef.get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<AttendanceModel?> getAttendanceById(String id) async {
    _incRead();
    final doc = await _attendanceRef.doc(id).get();
    if (!doc.exists) return null;
    return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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
        .map(
          (doc) =>
              ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
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

  /// جلب جميع الورديات - Get all shifts
  Future<List<ShiftModel>> getAllShifts() async {
    _incRead();
    final snapshot = await _shiftsRef.get();
    return snapshot.docs
        .map(
          (doc) =>
              ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // ============================================
  // === الرواتب - Payroll ===
  // ============================================

  CollectionReference get _payrollRef => _firestore.collection('payroll');

  Future<void> createPayroll(PayrollModel model) async {
    _incWrite();
    await _payrollRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updatePayroll(PayrollModel model) async {
    _incWrite();
    await _payrollRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePayroll(String id) async {
    _incWrite();
    await _payrollRef.doc(id).delete();
  }

  Future<List<PayrollModel>> getUpdatedPayroll(DateTime lastSync) async {
    _incRead();
    final snapshot = await _payrollRef.get();
    return snapshot.docs
        .map(
          (doc) => PayrollModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  /// جلب جميع سجلات الرواتب - Get all payroll records
  Future<List<PayrollModel>> getAllPayroll() async {
    _incRead();
    final snapshot = await _payrollRef.get();
    return snapshot.docs
        .map(
          (doc) => PayrollModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // ============================================
  // === المصاريف - Expenses ===
  // ============================================

  CollectionReference get _expensesRef => _firestore.collection('expenses');

  Future<void> createExpense(ExpenseModel model) async {
    _incWrite();
    await _expensesRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> updateExpense(ExpenseModel model) async {
    _incWrite();
    await _expensesRef.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteExpense(String id) async {
    _incWrite();
    await _expensesRef.doc(id).delete();
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    _incRead();
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    return snapshot.docs
        .map(
          (doc) => ExpenseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<List<ExpenseModel>> getUpdatedExpenses(DateTime lastSync) async {
    _incRead();
    final snapshot = await _expensesRef.get();
    return snapshot.docs
        .map(
          (doc) => ExpenseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // ============================================
  // === مسح البيانات - Clear Data ===
  // ============================================

  /// مسح كل documents في collection معين
  /// Delete all documents in a specific collection
  Future<void> clearCollection(CollectionReference collection) async {
    final snapshots = await collection.get();
    final batch = _firestore.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _incWrite();
    log('[FirebaseService] Cleared ${snapshots.docs.length} docs from ${collection.path}');
  }

  /// مسح كل البيانات من جميع الـ collections
  /// Clear all data from all collections
  Future<void> clearAllCollections() async {
    log('[FirebaseService] Clearing all Firestore collections...');
    await clearCollection(_usersRef);
    await clearCollection(_casesRef);
    await clearCollection(_inventoryRef);
    await clearCollection(_proceduresRef);
    await clearCollection(_shiftsRef);
    await clearCollection(_attendanceRef);
    await clearCollection(_payrollRef);
    await clearCollection(_expensesRef);
    log('[FirebaseService] ✓ All collections cleared');
  }

  /// مسح collection معين بالاسم
  /// Clear a specific collection by its table name
  Future<void> clearCollectionByName(String name) async {
    log('[FirebaseService] Clearing collection by name: $name...');
    switch (name) {
      case 'users':
        await clearCollection(_usersRef);
        break;
      case 'cases':
        await clearCollection(_casesRef);
        break;
      case 'inventory':
        await clearCollection(_inventoryRef);
        break;
      case 'procedures':
        await clearCollection(_proceduresRef);
        break;
      case 'shifts':
        await clearCollection(_shiftsRef);
        break;
      case 'attendance':
        await clearCollection(_attendanceRef);
        break;
      case 'payroll':
        await clearCollection(_payrollRef);
        break;
      case 'expenses':
        await clearCollection(_expensesRef);
        break;
      default:
        throw Exception('Unknown collection name: $name');
    }
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
    return Stream.periodic(
      const Duration(seconds: 5),
    ).asyncMap((_) => query.get()).asBroadcastStream();
  }
}

/// نتيجة البحث مع الصفحات - Paginated Result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final dynamic lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}
