import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../data/models/case_model.dart';

/// واجهة مستودع الحالات - Cases Repository Interface
/// تحدد العقد بين طبقة الدومين وطبقة البيانات
abstract class ICasesRepository {
  /// جلب جميع الحالات - Get all cases
  Future<List<CaseModel>> getAllCases({String? nurseId});

  /// جلب الحالات بصفحات - Get paginated cases
  Future<PaginatedResult<CaseModel>> getCasesPaginated({
    String? nurseId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// جلب حالات اليوم - Get today's cases
  Future<List<CaseModel>> getTodayCases({String? nurseId});

  /// جلب حالات ممرض - Get nurse's cases
  Future<List<CaseModel>> getNurseCases(String nurseId);

  /// جلب عدد المرضى - Get patients count
  Future<int> getPatientsCount();

  /// جلب الحالات المحدثة بعد وقت معين - Get updated cases
  Future<List<CaseModel>> getUpdatedCases(DateTime lastSync);

  /// إنشاء حالة - Create case
  Future<void> createCase(CaseModel caseModel);

  /// تحديث حالة - Update case
  Future<void> updateCase(CaseModel caseModel);

  /// حذف حالة - Delete case
  Future<void> deleteCase(String caseId);

  /// بث جميع الحالات - Stream all cases
  Stream<List<CaseModel>> streamAllCases({String? nurseId});

  /// بث حالات اليوم - Stream today's cases
  Stream<List<CaseModel>> streamTodayCases({String? nurseId});
}
