import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/patients/data/models/patient_model.dart';
import '../../features/cases/data/models/case_model.dart';
import '../../features/inventory/data/models/inventory_model.dart';
import '../../features/activity_logs/data/models/log_model.dart';
import '../constants/app_constants.dart';

/// خدمة Firebase Firestore
/// Firebase Firestore Service for cloud data management
class FirebaseService {
  static FirebaseService? _instance;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  FirebaseService._() : _firestore = FirebaseFirestore.instance;

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// توليد معرف فريد - Generate unique ID
  String generateId() => _uuid.v4();

  // ============================================
  // === المستخدمون - Users ===
  // ============================================

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

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
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// جلب جميع المستخدمين - Get all users
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
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

  // ============================================
  // === المرضى - Patients ===
  // ============================================

  CollectionReference get _patientsRef =>
      _firestore.collection(AppConstants.patientsCollection);

  /// إنشاء مريض - Create patient
  Future<void> createPatient(PatientModel patient) async {
    await _patientsRef.doc(patient.id).set(patient.toMap());
  }

  /// تحديث مريض - Update patient
  Future<void> updatePatient(PatientModel patient) async {
    await _patientsRef.doc(patient.id).update(patient.toMap());
  }

  /// حذف مريض - Delete patient
  Future<void> deletePatient(String patientId) async {
    await _patientsRef.doc(patientId).delete();
  }

  /// جلب جميع المرضى - Get all patients
  Future<List<PatientModel>> getAllPatients() async {
    final snapshot = await _patientsRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// بحث المرضى - Search patients
  Future<List<PatientModel>> searchPatients(String query) async {
    final snapshot = await _patientsRef.get();
    return snapshot.docs
        .map((doc) => PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.phone.contains(query))
        .toList();
  }

  // ============================================
  // === الحالات - Cases ===
  // ============================================

  CollectionReference get _casesRef =>
      _firestore.collection(AppConstants.casesCollection);

  /// إنشاء حالة - Create case
  Future<void> createCase(CaseModel caseModel) async {
    await _casesRef.doc(caseModel.id).set(caseModel.toMap());
  }

  /// تحديث حالة - Update case
  Future<void> updateCase(CaseModel caseModel) async {
    await _casesRef.doc(caseModel.id).update(caseModel.toMap());
  }

  /// حذف حالة - Delete case
  Future<void> deleteCase(String caseId) async {
    await _casesRef.doc(caseId).delete();
  }

  /// جلب جميع الحالات - Get all cases
  Future<List<CaseModel>> getAllCases() async {
    final snapshot = await _casesRef.orderBy('caseDate', descending: true).get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب حالات اليوم - Get today's cases
  Future<List<CaseModel>> getTodayCases() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('caseDate', isLessThan: endOfDay.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب حالات بحسب الحالة - Get cases by status
  Future<List<CaseModel>> getCasesByStatus(String status) async {
    final snapshot = await _casesRef
        .where('status', isEqualTo: status)
        .orderBy('caseDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب حالات ممرض - Get nurse's cases
  Future<List<CaseModel>> getNurseCases(String nurseId) async {
    final snapshot = await _casesRef
        .where('nurseId', isEqualTo: nurseId)
        .orderBy('caseDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ============================================
  // === المستلزمات - Inventory ===
  // ============================================

  CollectionReference get _inventoryRef =>
      _firestore.collection(AppConstants.inventoryCollection);

  /// إنشاء مستلزم - Create inventory item
  Future<void> createInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).set(item.toMap());
  }

  /// تحديث مستلزم - Update inventory item
  Future<void> updateInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).update(item.toMap());
  }

  /// حذف مستلزم - Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    await _inventoryRef.doc(itemId).delete();
  }

  /// جلب جميع المستلزمات - Get all inventory
  Future<List<InventoryModel>> getAllInventory() async {
    final snapshot = await _inventoryRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب المستلزمات منخفضة المخزون - Get low stock items
  Future<List<InventoryModel>> getLowStockItems() async {
    final allItems = await getAllInventory();
    return allItems.where((item) => item.isLowStock || item.isOutOfStock).toList();
  }

  /// تحديث كمية المستلزم - Update item quantity
  Future<void> updateInventoryQuantity(String itemId, int newQuantity) async {
    await _inventoryRef.doc(itemId).update({
      'quantity': newQuantity,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ============================================
  // === السجلات - Logs ===
  // ============================================

  CollectionReference get _logsRef =>
      _firestore.collection(AppConstants.logsCollection);

  /// إنشاء سجل - Create log entry
  Future<void> createLog(LogModel log) async {
    await _logsRef.doc(log.id).set(log.toMap());
  }

  /// جلب جميع السجلات - Get all logs
  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    final snapshot = await _logsRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => LogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// تسجيل نشاط - Log activity helper
  Future<void> logActivity({
    required String userId,
    required String userName,
    required String action,
    required String actionLabel,
    String targetType = '',
    String targetId = '',
    String details = '',
  }) async {
    final log = LogModel(
      id: generateId(),
      userId: userId,
      userName: userName,
      action: action,
      actionLabel: actionLabel,
      targetType: targetType,
      targetId: targetId,
      details: details,
      timestamp: DateTime.now(),
    );
    await createLog(log);
  }

  // ============================================
  // === إحصائيات لوحة التحكم - Dashboard Stats ===
  // ============================================

  /// إحصائيات سريعة - Quick stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // جلب البيانات بشكل متوازي
    final results = await Future.wait([
      _patientsRef.count().get(),
      _casesRef
          .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('caseDate', isLessThan: endOfDay.toIso8601String())
          .count()
          .get(),
      _casesRef.where('status', isEqualTo: 'pending').count().get(),
      _casesRef.where('status', isEqualTo: 'in_progress').count().get(),
      _casesRef.where('status', isEqualTo: 'completed').count().get(),
      _usersRef
          .where('role', isEqualTo: 'nurse')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
    ]);

    // حساب الإيرادات اليومية
    final todayCasesSnapshot = await _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('caseDate', isLessThan: endOfDay.toIso8601String())
        .where('status', isEqualTo: 'completed')
        .get();

    double todayRevenue = 0;
    for (final doc in todayCasesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      todayRevenue += (data['totalPrice'] ?? 0).toDouble() - (data['discount'] ?? 0).toDouble();
    }

    return {
      'totalPatients': results[0].count ?? 0,
      'todayCases': results[1].count ?? 0,
      'pendingCases': results[2].count ?? 0,
      'inProgressCases': results[3].count ?? 0,
      'completedCases': results[4].count ?? 0,
      'availableNurses': results[5].count ?? 0,
      'todayRevenue': todayRevenue,
    };
  }
}
