import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../local/sqlite_service.dart';
import '../notifications/case_change_notifier.dart';
import '../notifications/data_change_notifier.dart';
import '../../../features/cases/data/models/case_model.dart';

/// مستمع الحالات الخارجية - Outside Cases Listener
/// يستمع لمجموعة outside_cases في Firestore
/// عند إضافة حالة جديدة:
///   1. يحفظها محلياً في SQLite
///   2. يحذفها من Firestore (لتوفير الاستهلاك)
///   3. يُحدّث واجهة المستخدم عبر CaseChangeNotifier
class OutsideCasesListener {
  OutsideCasesListener._();
  static final OutsideCasesListener instance = OutsideCasesListener._();

  final _firestore = FirebaseFirestore.instance;
  final _sqlite = SqliteService.instance;
  StreamSubscription? _subscription;
  
  /// قائمة الحالات الخارجية المعلقة - List of pending outside cases
  final ValueNotifier<List<QueryDocumentSnapshot>> pendingCasesNotifier =
      ValueNotifier<List<QueryDocumentSnapshot>>([]);

  /// بدء الاستماع - Start listening to outside_cases collection
  void startListening() {
    log('[OutsideCasesListener] Starting listener on outside_cases...');

    final query = _firestore.collection('outside_cases');

    // Use polling on Windows to avoid threading crashes
    Stream<QuerySnapshot<Object?>> stream;
    if (kIsWeb || !Platform.isWindows) {
      stream = query.snapshots();
    } else {
      // Poll every 10 seconds on Windows
      stream = Stream.periodic(
        const Duration(seconds: 10),
      ).asyncMap((_) => query.get()).asBroadcastStream();
    }

    _subscription = stream.listen(
      (snapshot) {
        log('[OutsideCasesListener] Found ${snapshot.docs.length} outside case(s) pending approval.');
        pendingCasesNotifier.value = snapshot.docs;
      },
      onError: (error) {
        log('[OutsideCasesListener] Stream error: $error');
      },
    );
  }

  /// اعتماد وحفظ الحالة يدوياً - Manually approve and save the case
  Future<Map<String, dynamic>> processCase(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final caseModel = CaseModel.fromMap(data, doc.id);

      // Check inventory availability - تحقق من توفر المستلزمات
      final inventoryCheck = await _checkInventoryAvailability(caseModel);
      if (!inventoryCheck['available']) {
        log(
          '[OutsideCasesListener] Insufficient inventory for case "${caseModel.patientName}": ${inventoryCheck['message']}',
        );
        return {
          'success': false,
          'message': inventoryCheck['message'] ?? 'المستلزمات غير كافية في المخزن',
        };
      }

      // 1. Save to local SQLite
      await _sqlite.saveCase(caseModel.toSqliteMap());
      log(
        '[OutsideCasesListener] Saved case "${caseModel.patientName}" locally',
      );

      // 2. Deduct inventory - خصم المستلزمات من المخزون
      for (final supply in caseModel.suppliesUsed) {
        final inventoryId = supply.inventoryId.isNotEmpty
            ? supply.inventoryId
            : await _findInventoryIdByName(supply.name);
        if (inventoryId != null) {
          await _sqlite.deductInventory(inventoryId, supply.quantity);
          log(
            '[OutsideCasesListener] Deducted ${supply.quantity} of "${supply.name}" from inventory',
          );
        }
      }

      // 3. Delete from outside_cases collection
      await _firestore.collection('outside_cases').doc(doc.id).delete();
      log(
        '[OutsideCasesListener] Deleted case "${doc.id}" from outside_cases',
      );

      // 4. Notify UI to refresh (Cases + Reports + Inventory screens)
      CaseChangeNotifier().notifyCaseAdded(doc.id);
      DataChangeNotifier().notifyLocalDataChanged();

      // 5. Re-add to main cases collection for backup
      await _firestore
          .collection('cases')
          .doc(doc.id)
          .set(caseModel.toMap());

      return {
        'success': true,
        'message': 'تم حفظ الحالة "${caseModel.patientName}" بنجاح وتحديث المخزون',
      };
    } catch (e) {
      log('[OutsideCasesListener] Error processing case ${doc.id}: $e');
      return {
        'success': false,
        'message': 'خطأ أثناء معالجة الحالة: $e',
      };
    }
  }

  /// تحقق من توفر المستلزمات - Check if all supplies for a case are available in inventory
  Future<Map<String, dynamic>> _checkInventoryAvailability(
    CaseModel caseModel,
  ) async {
    if (caseModel.suppliesUsed.isEmpty) {
      return {'available': true, 'message': 'No supplies required'};
    }

    try {
      // Get all current inventory items
      final allInventory = await _sqlite.getAllInventory();

      // Check each supply used in the case
      for (final supply in caseModel.suppliesUsed) {
        // Find the inventory item by name (since inventoryId might not match)
        final inventoryItem = allInventory.firstWhere(
          (inv) =>
              inv['name'] == supply.name || inv['id'] == supply.inventoryId,
          orElse: () => {},
        );

        if (inventoryItem.isEmpty) {
          return {
            'available': false,
            'message': 'Supply "${supply.name}" not found in inventory',
          };
        }

        final availableQuantity = (inventoryItem['quantity'] ?? 0) as int;
        if (availableQuantity < supply.quantity) {
          return {
            'available': false,
            'message':
                'Insufficient quantity for "${supply.name}": need ${supply.quantity}, have $availableQuantity',
          };
        }
      }

      log(
        '[OutsideCasesListener] Inventory check passed for case "${caseModel.patientName}"',
      );
      return {'available': true, 'message': 'All supplies available'};
    } catch (e) {
      log('[OutsideCasesListener] Error checking inventory: $e');
      // If there's an error checking inventory, reject the case to be safe
      return {'available': false, 'message': 'Error checking inventory: $e'};
    }
  }

  /// البحث عن معرف المستلزم بالاسم - Find inventory item ID by name
  Future<String?> _findInventoryIdByName(String name) async {
    try {
      final allInventory = await _sqlite.getAllInventory();
      final item = allInventory.firstWhere(
        (inv) => inv['name'] == name,
        orElse: () => {},
      );
      return item.isNotEmpty ? item['id'] as String? : null;
    } catch (e) {
      log('[OutsideCasesListener] Error finding inventory by name "$name": $e');
      return null;
    }
  }

  /// إيقاف الاستماع - Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    pendingCasesNotifier.value = [];
    log('[OutsideCasesListener] Listener stopped');
  }

  /// إضافة حالة تجريبية - Add a fake test case to outside_cases
  Future<void> addFakeTestCase() async {
    final now = DateTime.now();
    final fakeCase = {
      'patientName': 'مريض تجريبي - زيارة منزلية',
      'patientAge': 45,
      'patientGender': 'male',
      'patientPhone': '01098765432',
      'patientAddress': 'شارع النيل، المنصورة',
      'medicalHistory': '',
      'nurseId': '',
      'nurseName': 'ممرض خارجي',
      'caseType': 'home_visit',
      'services': [
        {'name': 'غيار', 'price': 80.0, 'quantity': 1, 'notes': ''},
        {'name': 'حقن', 'price': 50.0, 'quantity': 2, 'notes': 'حقن عضل'},
      ],
      'suppliesUsed': [
        {'inventoryId': '', 'name': 'قفازات', 'quantity': 2, 'unitPrice': 5.0},
      ],
      'totalPrice': 190.0,
      'discount': 0,
      'caseDate': now.toIso8601String(),
      'notes': 'حالة تجريبية من تطبيق الممرض الخارجي',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'createdBy': 'mobile_nurse_test',
    };

    await _firestore.collection('outside_cases').add(fakeCase);
    log('[OutsideCasesListener] Fake test case added to outside_cases');
  }
}
