import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/cases_repository.dart';
import '../models/case_model.dart';

/// تنفيذ مستودع الحالات - Cases Repository Implementation
class CasesRepositoryImpl extends FirebaseBase implements ICasesRepository {
  CollectionReference get _casesRef =>
      firestore.collection(AppConstants.casesCollection);

  @override
  Future<void> createCase(CaseModel caseModel) async {
    await _casesRef.doc(caseModel.id).set(caseModel.toMap());
  }

  @override
  Future<void> updateCase(CaseModel caseModel) async {
    await _casesRef.doc(caseModel.id).update(caseModel.toMap());
  }

  @override
  Future<void> deleteCase(String caseId) async {
    await _casesRef.doc(caseId).delete();
  }

  @override
  Future<List<CaseModel>> getAllCases({String? nurseId}) async {
    Query query = _casesRef.orderBy('caseDate', descending: true);
    if (nurseId != null) {
      query = query.where('nurseId', isEqualTo: nurseId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<int> getPatientsCount() async {
    final snapshot = await _casesRef.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<List<CaseModel>> getTodayCases({String? nurseId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Query query = _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('caseDate', isLessThan: endOfDay.toIso8601String());

    if (nurseId != null) {
      query = query.where('nurseId', isEqualTo: nurseId);
    }

    final snapshot = await query.get();
    final cases = snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cases;
  }

  @override
  Future<List<CaseModel>> getNurseCases(String nurseId) async {
    final snapshot = await _casesRef
        .where('nurseId', isEqualTo: nurseId)
        .orderBy('caseDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<CaseModel>> getUpdatedCases(DateTime lastSync) async {
    final snapshot = await _casesRef
        .where('updatedAt', isGreaterThan: lastSync.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Stream<List<CaseModel>> streamAllCases({String? nurseId}) {
    Query query = _casesRef.orderBy('caseDate', descending: true);
    if (nurseId != null) {
      query = query.where('nurseId', isEqualTo: nurseId);
    }
    return safeStream(query).map(
      (snapshot) => snapshot.docs
          .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  @override
  Stream<List<CaseModel>> streamTodayCases({String? nurseId}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Query query = _casesRef
        .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('caseDate', isLessThan: endOfDay.toIso8601String());

    if (nurseId != null) {
      query = query.where('nurseId', isEqualTo: nurseId);
    }

    return safeStream(query).map(
      (snapshot) => snapshot.docs
          .map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}
