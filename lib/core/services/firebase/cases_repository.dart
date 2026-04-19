import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/cases/data/models/case_model.dart';
import '../../constants/app_constants.dart';
import 'firebase_base.dart';

/// مستودع الحالات - Cases Repository
class CasesRepository extends FirebaseBase {
  CollectionReference get _casesRef =>
      firestore.collection(AppConstants.casesCollection);

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

  /// جلب عدد المرضى - Get patients count
  Future<int> getPatientsCount() async {
    final snapshot = await _casesRef.get();
    return snapshot.size;
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
}
