import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_care/core/enums/user_role.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/patients/data/models/patient_model.dart';
import '../../features/cases/data/models/case_model.dart';
import '../../features/inventory/data/models/inventory_model.dart';
import '../../features/activity_logs/data/models/log_model.dart';
import '../../features/financials/data/models/expense_model.dart';
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

  /// تهيئة المستخدمين الافتراضيين - Seed Default Users
  Future<void> seedDefaultUsers() async {
    final auth = FirebaseAuth.instance;
    
    // تحقق مما إذا كانت هناك مستندات بالفعل في Firestore لتجنب إعادة إنشاء المحذوف
    final snapshot = await _usersRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    // قائمة المستخدمين الافتراضيين
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

        // محاولة إنشاء المستخدم
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: seedData['email'] as String,
            password: seedData['password'] as String,
          );
          uid = cred.user?.uid;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // المستخدم موجود بالفعل - نسجل دخول للحصول على UID
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

        // تحقق من وجود المستند في Firestore، وأنشئه إن لم يكن موجوداً
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
        // تجاهل الخطأ والمتابعة للمستخدم التالي
      }
    }

    // تسجيل الخروج لبدء التطبيق بحالة نظيفة
    try {
      await auth.signOut();
    } catch (_) {}
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
    final snapshot = await _patientsRef.get();
    final patients = snapshot.docs
        .map((doc) => PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    
    // الترتيب في الذاكرة لتجنب استبعاد المستندات التي تفتقد لحقل createdAt
    patients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return patients;
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

    // نستخدم الفرز في الذاكرة لتجنب طلب الفهارس المركبة (Composite Indexes) حالياً
    final cases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    
    cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cases;
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
  // === المصاريف - Expenses ===
  // ============================================

  CollectionReference get _expensesRef =>
      _firestore.collection(AppConstants.expensesCollection);

  /// إنشاء مصروف - Create expense
  Future<void> createExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).set(expense.toMap());
  }

  /// تحديث مصروف - Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesRef.doc(expense.id).update(expense.toMap());
  }

  /// حذف مصروف - Delete expense
  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }

  /// جلب جميع المصاريف - Get all expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    final snapshot = await _expensesRef.orderBy('date', descending: true).get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب مصاريف بحسب التاريخ - Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByRange(DateTime start, DateTime end) async {
    final snapshot = await _expensesRef
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
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

    // جلب حالات اليوم للفلترة في الذاكرة لتجنب مشاكل الفهرسة المركبة
    final todayCases = await getTodayCases();

    final todayCompletedCases = todayCases.where((c) => c.status.name == 'completed').toList();

    double todayRevenue = 0;
    for (final c in todayCompletedCases) {
      todayRevenue += c.totalPrice - c.discount;
    }

    return {
      'totalPatients': results[0].count ?? 0,
      'todayCases': todayCases.length,
      'pendingCases': todayCases.where((c) => c.status.name == 'pending').length,
      'inProgressCases': todayCases.where((c) => c.status.name == 'in_progress').length,
      'completedCases': todayCompletedCases.length,
      'availableNurses': results[5].count ?? 0,
      'todayRevenue': todayRevenue,
    };
  }

  /// بيانات الرسم البياني للأسبوع - Weekly Chart Data (Last 7 Days)
  Future<Map<String, List<double>>> getDashboardChartData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    final snapshot = await _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String())
        .get();

    final allCases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    List<double> counts = List.filled(7, 0.0);
    List<double> revenues = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final targetDate = sevenDaysAgo.add(Duration(days: i));
      final dayCases = allCases.where((c) {
        return c.caseDate.year == targetDate.year &&
               c.caseDate.month == targetDate.month &&
               c.caseDate.day == targetDate.day;
      }).toList();

      counts[i] = dayCases.length.toDouble();
      
      double dayRevenue = 0;
      for (final c in dayCases) {
        if (c.status.name == 'completed') {
          dayRevenue += (c.totalPrice - c.discount);
        }
      }
      revenues[i] = dayRevenue;
    }

    return {
      'counts': counts,
      'revenues': revenues,
    };
  }
}
