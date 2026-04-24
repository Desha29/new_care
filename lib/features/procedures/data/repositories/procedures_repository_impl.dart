import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../domain/repositories/procedures_repository.dart';
import '../models/procedure_model.dart';

/// تنفيذ مستودع الإجراءات الطبية - Procedures Repository Implementation
class ProceduresRepositoryImpl extends FirebaseBase implements IProceduresRepository {
  CollectionReference get _proceduresRef =>
      firestore.collection('procedures');

  @override
  Future<void> createProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).set(procedure.toMap());
  }

  @override
  Future<void> updateProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).update(procedure.toMap());
  }

  @override
  Future<void> deleteProcedure(String id) async {
    await _proceduresRef.doc(id).delete();
  }

  @override
  Future<List<ProcedureModel>> getAllProcedures() async {
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<int> getProceduresCount() async {
    final snapshot = await _proceduresRef.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<List<ProcedureModel>> getUpdatedProcedures(DateTime lastSync) async {
    final snapshot = await _proceduresRef
        .where('updatedAt', isGreaterThan: lastSync.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Stream<List<ProcedureModel>> streamProcedures() {
    return safeStream(_proceduresRef).map(
      (snapshot) => snapshot.docs
          .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}
