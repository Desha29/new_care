import '../../data/models/procedure_model.dart';

/// واجهة مستودع الإجراءات الطبية - Procedures Repository Interface
abstract class IProceduresRepository {
  /// جلب جميع الإجراءات - Get all procedures
  Future<List<ProcedureModel>> getAllProcedures();

  /// جلب عدد الإجراءات - Get procedures count
  Future<int> getProceduresCount();

  /// جلب الإجراءات المحدثة بعد وقت معين - Get updated procedures
  Future<List<ProcedureModel>> getUpdatedProcedures(DateTime lastSync);

  /// إنشاء إجراء - Create procedure
  Future<void> createProcedure(ProcedureModel procedure);

  /// تحديث إجراء - Update procedure
  Future<void> updateProcedure(ProcedureModel procedure);

  /// حذف إجراء - Delete procedure
  Future<void> deleteProcedure(String id);

  /// بث الإجراءات - Stream procedures
  Stream<List<ProcedureModel>> streamProcedures();
}
