import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_care/core/enums/user_role.dart';
import 'package:uuid/uuid.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/cases/data/models/case_model.dart';
import '../../features/inventory/data/models/inventory_model.dart';
import '../../features/activity_logs/data/models/log_model.dart';
import '../../features/financials/data/models/expense_model.dart';
import '../../features/procedures/data/models/procedure_model.dart';
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

  /// إنشاء حساب مستخدم في Firebase Authentication (للمشرفين)
  /// Create a Firebase Auth account for a new user without logging out the admin
  Future<String> registerUserAuth(String email, String password) async {
    FirebaseApp? secondaryApp;
    try {
      // إعداد تطبيق ثانوي لتجنب تسجيل خروج المشرف الحالي
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

      // تنظيف التطبيق الثانوي فور الانتهاء
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

  /// تهيئة المستخدمين والإجراءات الافتراضية - Seed Default Users & Procedures
  Future<void> seedDefaultUsers() async {
    await seedDefaultProcedures();
    final auth = FirebaseAuth.instance;

    // Check if the database is already seeded (has a super admin)
    // If so, exit immediately to prevent overwriting the active authentication session.
    try {
      final superAdmins = await _usersRef.where('role', isEqualTo: 'super_admin').limit(1).get();
      if (superAdmins.docs.isNotEmpty) {
        return; // Already seeded, safe to exit.
      }
    } catch (_) {
      // Offline or network error, skip seed
      return; 
    }
    
    // سنقوم الآن بالتحقق من كل مستخدم افتراضي على حدة لضمان وجوده في Firestore
    // حتى لو كانت المجموعة غير فارغة، فقد يكون المشرف الافتراضي مفقوداً

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

        if (uid == null) {
          log('[Seed] ERROR: UID is null for ${seedData['email']}');
          continue;
        }

        log('[Seed] Checking Firestore for $uid (${seedData['email']})');
        // تحقق من وجود المستند في Firestore، وأنشئه إن لم يكن موجوداً
        final existingDoc = await _usersRef.doc(uid).get();
        if (!existingDoc.exists) {
          log('[Seed] User doc not found for $uid. Creating now...');
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
          log('[Seed] User doc created successfully for ${seedData['email']}');
        } else {
          log('[Seed] User profile already exists in Firestore for ${seedData['email']}');
        }
      } catch (e) {
        log('[Seed] Error processing user ${seedData['email']}: $e');
      }
    }

    // تسجيل الخروج لبدء التطبيق بحالة نظيفة
    try {
      await auth.signOut();
    } catch (_) {}
  }

  /// تهيئة الإجراءات الافتراضية - Seed Default Procedures
  Future<void> seedDefaultProcedures() async {
    try {
      final snapshot = await _proceduresRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Already seeded

      final defaults = [
        {'name': 'متابعة', 'price': 50.0},
        {'name': 'جهاز وريد', 'price': 80.0},
        {'name': 'كانيولا', 'price': 30.0},
        {'name': 'حقن عضل', 'price': 20.0},
        {'name': 'تغيير جرح', 'price': 60.0},
        {'name': 'غيار طبي', 'price': 40.0},
      ];

      for (var d in defaults) {
        final id = _proceduresRef.doc().id;
        await _proceduresRef.doc(id).set({
          'name': d['name'],
          'defaultPrice': d['price'],
          'notes': 'خدمة افتراضية مُضافة آلياً',
        });
      }
    } catch (_) {}
  }

  // ============================================
  // === الإجراءات الطبية - Procedures ===
  // ============================================

  CollectionReference get _proceduresRef =>
      _firestore.collection('procedures');

  Future<void> createProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).set(procedure.toMap());
  }

  Future<void> updateProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).update(procedure.toMap());
  }

  Future<void> deleteProcedure(String id) async {
    await _proceduresRef.doc(id).delete();
  }

  Stream<List<ProcedureModel>> streamProcedures() {
    return _proceduresRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  Future<List<ProcedureModel>> getAllProcedures() async {
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ============================================
  // === الحالات و المرضى - Cases & Patients ===
  // ============================================

  CollectionReference get _casesRef =>
      _firestore.collection(AppConstants.casesCollection);

  /// جلب عدد المرضى (الحالات حالياً) - Get patients count
  Future<int> getPatientsCount() async {
    final snapshot = await _casesRef.get();
    return snapshot.size;
  }


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
      _casesRef.count().get(),
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
