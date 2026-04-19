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
import '../../features/shifts/data/models/shift_model.dart';
import '../../features/attendance/data/models/attendance_model.dart';
import '../constants/app_constants.dart';

/// خدمة Firebase Firestore
/// Firebase Firestore Service for cloud data management
class FirebaseService {
  static FirebaseService? _instance;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  // Telemetry - إحصائيات الاستخدام
  static int readCount = 0;
  static int writeCount = 0;

  FirebaseService._() : _firestore = FirebaseFirestore.instance;

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  void resetStats() {
    readCount = 0;
    writeCount = 0;
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
    writeCount++;
    await _usersRef.doc(user.id).set(user.toMap());
  }

  /// تحديث مستخدم - Update user
  Future<void> updateUser(UserModel user) async {
    writeCount++;
    await _usersRef.doc(user.id).update(user.toMap());
  }

  /// حذف مستخدم - Delete user
  Future<void> deleteUser(String userId) async {
    writeCount++;
    await _usersRef.doc(userId).delete();
  }

  /// جلب مستخدم - Get user by ID
  Future<UserModel?> getUser(String userId) async {
    readCount++;
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
    readCount++;
    final snapshot = await _usersRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب عدد المستخدمين - Get users count
  Future<int> getUsersCount() async {
    readCount++;
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

  /// جلب الطاقم النشط (ممرضين أو مدراء) - Get active staff for assignments
  Future<List<UserModel>> getActiveNurses() async {
    readCount++;
    final snapshot = await _usersRef
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        // يمكن تعيين الحالات لأي شخص نشط (ممرض أو مدير)
        .where((u) => u.role.value == 'nurse' || u.role.value == 'admin' || u.role.value == 'super_admin')
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
      final snapshot = await _proceduresRef.get();
      final existingNames = snapshot.docs.map((d) => d['name'] as String).toSet();

      final defaults = [
        {'name': 'تركيب كانيولا كبار', 'inside': 50.0, 'outside': 80.0, 'notes': ''},
        {'name': 'متابعه كبار + زيارة', 'inside': 40.0, 'outside': 50.0, 'notes': ''},
        {'name': 'غيار', 'inside': 50.0, 'outside': 80.0, 'notes': ''},
        {'name': 'اختبار حساسية', 'inside': 60.0, 'outside': 80.0, 'notes': ''},
        {'name': 'قسطرة', 'inside': 300.0, 'outside': 400.0, 'notes': ''},
        {'name': 'تعليق حديد', 'inside': 250.0, 'outside': 250.0, 'notes': ''},
        {'name': 'تعليق دم', 'inside': 350.0, 'outside': 500.0, 'notes': ''},
        {'name': 'قياس سكر', 'inside': 30.0, 'outside': 50.0, 'notes': ''},
        {'name': 'جلسة', 'inside': 50.0, 'outside': 100.0, 'notes': ''},
        {'name': 'خياطة', 'inside': 200.0, 'outside': 200.0, 'notes': ''},
        {'name': 'قياس ضغط', 'inside': 30.0, 'outside': 30.0, 'notes': ''},
        {'name': 'قياس ضغط وسكر', 'inside': 60.0, 'outside': 60.0, 'notes': ''},
        {'name': 'غيار فاكيم شامل الجهاز', 'inside': 500.0, 'outside': 500.0, 'notes': ''},
        {'name': 'تركيب رايل', 'inside': 200.0, 'outside': 300.0, 'notes': ''},
        {'name': 'حقنه شرجية', 'inside': 250.0, 'outside': 350.0, 'notes': ''},
        {'name': 'غسول انف', 'inside': 30.0, 'outside': 50.0, 'notes': ''},
        {'name': 'علاج طبيعي ع الصدر', 'inside': 30.0, 'outside': 50.0, 'notes': ''},
        {'name': 'تشفيط', 'inside': 50.0, 'outside': 100.0, 'notes': ''},
        {'name': 'متابعه اطفال', 'inside': 100.0, 'outside': 100.0, 'notes': ''},
        {'name': 'تركيب كانيولا اطفال', 'inside': 70.0, 'outside': 100.0, 'notes': ''},
      ];

      for (var d in defaults) {
        if (!existingNames.contains(d['name'])) {
          final id = _proceduresRef.doc().id;
          await _proceduresRef.doc(id).set({
            'name': d['name'],
            'defaultPrice': d['outside'], 
            'priceInside': d['inside'],
            'priceOutside': d['outside'],
            'notes': d['notes'],
          });
        }
      }
    } catch (_) {}
  }

  /// تهيئة المستلزمات الافتراضية - Seed Default Inventory
  Future<void> seedDefaultInventory() async {
    try {
      final snapshot = await _inventoryRef.get();
      final existingNames = snapshot.docs.map((d) => d['name'] as String).toSet();

      final defaults = [
        {'name': 'سرنجات 1/3/5', 'price': 5.0},
        {'name': 'كانيولا', 'price': 15.0},
        {'name': 'ماسك جلسات', 'price': 30.0},
        {'name': 'ماسك اكسجين', 'price': 25.0},
        {'name': 'جهاز وريد', 'price': 30.0},
        {'name': 'جهاز نقل دم', 'price': 30.0},
        {'name': 'كيس جمع بول', 'price': 30.0},
        {'name': 'نيزل مقاسات', 'price': 25.0},
        {'name': 'رباط شاش مقاسات', 'price': 15.0},
        {'name': 'رباط ضغط', 'price': 20.0},
        {'name': 'سرنجة 20سم', 'price': 15.0},
        {'name': 'محاليل بانواعها', 'price': 30.0},
        {'name': 'محلول بديامنت', 'price': 50.0},
        {'name': 'محلول بانثول', 'price': 50.0},
        {'name': 'سرنجة رايل', 'price': 20.0},
      ];

      for (var d in defaults) {
        if (!existingNames.contains(d['name'])) {
          final id = _inventoryRef.doc().id;
          await _inventoryRef.doc(id).set({
            'name': d['name'],
            'category': 'مستلزمات عامة',
            'quantity': 100, // Default stock
            'price': d['price'],
            'isLowStock': false,
            'isOutOfStock': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (_) {}
  }

  // ============================================
  // === الإجراءات الطبية - Procedures ===
  // ============================================

  CollectionReference get _proceduresRef =>
      _firestore.collection('procedures');

  Future<void> createProcedure(ProcedureModel procedure) async {
    writeCount++;
    await _proceduresRef.doc(procedure.id).set(procedure.toMap());
  }

  Future<void> updateProcedure(ProcedureModel procedure) async {
    writeCount++;
    await _proceduresRef.doc(procedure.id).update(procedure.toMap());
  }

  Future<void> deleteProcedure(String id) async {
    writeCount++;
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
    readCount++;
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<int> getProceduresCount() async {
    readCount++;
    final snapshot = await _proceduresRef.get();
    return snapshot.size;
  }

  // ============================================
  // === الحالات و المرضى - Cases & Patients ===
  // ============================================

  CollectionReference get _casesRef =>
      _firestore.collection(AppConstants.casesCollection);

  /// جلب عدد المرضى (الحالات حالياً) - Get patients count
  Future<int> getPatientsCount() async {
    readCount++;
    final snapshot = await _casesRef.get();
    return snapshot.size;
  }


  /// إنشاء حالة - Create case
  Future<void> createCase(CaseModel caseModel) async {
    writeCount++;
    await _casesRef.doc(caseModel.id).set(caseModel.toMap());
  }

  /// تحديث حالة - Update case
  Future<void> updateCase(CaseModel caseModel) async {
    writeCount++;
    await _casesRef.doc(caseModel.id).update(caseModel.toMap());
  }

  /// حذف حالة - Delete case
  Future<void> deleteCase(String caseId) async {
    writeCount++;
    await _casesRef.doc(caseId).delete();
  }

  /// جلب جميع الحالات - Get all cases
  Future<List<CaseModel>> getAllCases() async {
    readCount++;
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
    readCount++;
    final snapshot = await _firestore.collection('inventory').get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<int> getInventoryCount() async {
    readCount++;
    final snapshot = await _firestore.collection('inventory').get();
    return snapshot.size;
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

  /// إحصائيات الممرض - Nurse dashboard stats
  Future<Map<String, dynamic>> getNurseDashboardStats(String nurseId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // جلب جميع حالات اليوم وفلترتها في الذاكرة لتجنب طلب فهرس مركب (Composite Index)
      final allTodayCases = await getTodayCases();
      final nurseTodayCases = allTodayCases.where((c) => c.nurseId == nurseId).toList();

      final todayAttendance = await getTodayAttendance(nurseId);
      
      // جلب سجلات حضور الشهر لحساب الساعات
      final monthlyAttendance = await getMonthlyAttendanceRecords(now.year, now.month);
      final nurseMonthlyAttendance = monthlyAttendance.where((a) => a.userId == nurseId).toList();

      double totalHours = 0;
      for (var a in nurseMonthlyAttendance) {
        if (a.checkOutTime != null) {
          totalHours += a.checkOutTime!.difference(a.checkInTime).inMinutes / 60.0;
        }
      }

      return {
        'todayCasesCount': nurseTodayCases.length,
        'monthHours': totalHours,
        'attendance': todayAttendance,
        'todayCases': nurseTodayCases,
      };
    } catch (e) {
      log('[NurseStats] Error: $e');
      return {
        'todayCasesCount': 0,
        'monthHours': 0.0,
        'attendance': null,
        'todayCases': <CaseModel>[],
      };
    }
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

  // ============================================
  // === الورديات - Shifts ===
  // ============================================

  CollectionReference get _shiftsRef =>
      _firestore.collection('shifts');

  /// إنشاء وردية - Create shift
  Future<void> createShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).set(shift.toMap());
  }

  /// تحديث وردية - Update shift
  Future<void> updateShift(ShiftModel shift) async {
    await _shiftsRef.doc(shift.id).update(shift.toMap());
  }

  /// حذف وردية - Delete shift
  Future<void> deleteShift(String shiftId) async {
    await _shiftsRef.doc(shiftId).delete();
  }

  /// جلب وردية اليوم للمستخدم - Get today's shift for user
  Future<ShiftModel?> getTodayShift(String userId) async {
    final today = _todayString();
    final snapshot = await _shiftsRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ShiftModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  /// هل المستخدم لديه وردية اليوم؟ - Does user have shift today?
  Future<bool> hasShiftToday(String userId) async {
    final shift = await getTodayShift(userId);
    return shift != null;
  }

  /// جلب جميع ورديات شهر معين
  Future<List<ShiftModel>> getMonthlyShifts(int year, int month) async {
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';
    
    final snapshot = await _shiftsRef
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب جميع ورديات اليوم - Get all today's shifts
  Future<List<ShiftModel>> getTodayShifts() async {
    final today = _todayString();
    final snapshot = await _shiftsRef
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب ورديات مستخدم - Get user shifts
  Future<List<ShiftModel>> getUserShifts(String userId, {int limit = 30}) async {
    final snapshot = await _shiftsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب ورديات حسب التاريخ - Get shifts by date
  Future<List<ShiftModel>> getShiftsByDate(String date) async {
    readCount++;
    final snapshot = await _shiftsRef.where('date', isEqualTo: date).get();
    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<int> getShiftsCount() async {
    readCount++;
    final snapshot = await _shiftsRef.get();
    return snapshot.size;
  }

  /// بث ورديات اليوم - Stream today's shifts
  Stream<List<ShiftModel>> streamTodayShifts() {
    final today = _todayString();
    return _shiftsRef
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ============================================
  // === الحضور والانصراف - Attendance ===
  // ============================================

  CollectionReference get _attendanceRef =>
      _firestore.collection('attendance');

  /// تسجيل حضور - Check in
  Future<void> checkIn(AttendanceModel attendance) async {
    await _attendanceRef.doc(attendance.id).set(attendance.toMap());
  }

  /// تسجيل انصراف - Check out
  Future<void> checkOut(String attendanceId) async {
    await _attendanceRef.doc(attendanceId).update({
      'checkOutTime': DateTime.now().toIso8601String(),
      'status': 'checked_out',
    });
  }

  /// جلب حضور اليوم للمستخدم - Get today's attendance for user
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final today = _todayString();
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  /// هل المستخدم سجل حضوره اليوم؟ - Is user checked in today?
  Future<bool> isCheckedInToday(String userId) async {
    final attendance = await getTodayAttendance(userId);
    return attendance != null && attendance.isCheckedIn;
  }

  /// جلب جميع سجلات حضور شهر معين
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    final startId = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endId = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';
    
    final snapshot = await _attendanceRef
        .where('date', isGreaterThanOrEqualTo: startId)
        .where('date', isLessThan: endId)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب جميع سجلات حضور اليوم - Get all today's attendance
  Future<List<AttendanceModel>> getTodayAttendanceRecords() async {
    final today = _todayString();
    final snapshot = await _attendanceRef
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب سجلات حضور مستخدم - Get user attendance history
  Future<List<AttendanceModel>> getUserAttendance(String userId, {int limit = 30}) async {
    final snapshot = await _attendanceRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// بث حضور اليوم - Stream today's attendance
  Stream<List<AttendanceModel>> streamTodayAttendance() {
    final today = _todayString();
    return _attendanceRef
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
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

  // ============================================
  // === مساعدات - Helpers ===
  // ============================================

  /// تاريخ اليوم بصيغة نصية - Today's date string
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
