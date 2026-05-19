import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../local/sqlite_service.dart';
import '../notifications/case_change_notifier.dart';
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
  bool _isProcessing = false;

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
      (snapshot) async {
        if (snapshot.docs.isEmpty || _isProcessing) return;

        _isProcessing = true;
        log(
          '[OutsideCasesListener] Found ${snapshot.docs.length} outside case(s), processing...',
        );

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final caseModel = CaseModel.fromMap(data, doc.id);

            // 1. Save to local SQLite
            await _sqlite.saveCase(caseModel.toSqliteMap());
            log(
              '[OutsideCasesListener] Saved case "${caseModel.patientName}" locally',
            );

            // 2. Delete from outside_cases collection
            await _firestore.collection('outside_cases').doc(doc.id).delete();
            log(
              '[OutsideCasesListener] Deleted case "${doc.id}" from outside_cases',
            );

            // 3. Notify UI to refresh (Cases + Reports screens)
            CaseChangeNotifier().notifyCaseAdded(doc.id);
            // 4. Optionally, re-add to main cases collection for backup (commented out to save Firestore writes)
            await _firestore
                .collection('cases')
                .doc(doc.id)
                .set(caseModel.toMap());
          } catch (e) {
            log('[OutsideCasesListener] Error processing case ${doc.id}: $e');
          }
        }

        log('[OutsideCasesListener] UI refresh triggered');

        _isProcessing = false;
      },
      onError: (error) {
        log('[OutsideCasesListener] Stream error: $error');
      },
    );
  }

  /// إيقاف الاستماع - Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
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
