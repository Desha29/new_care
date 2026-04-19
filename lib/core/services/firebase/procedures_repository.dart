import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/procedures/data/models/procedure_model.dart';
import 'firebase_base.dart';

/// مستودع الإجراءات الطبية - Procedures Repository
class ProceduresRepository extends FirebaseBase {
  CollectionReference get _proceduresRef =>
      firestore.collection('procedures');

  /// إنشاء إجراء - Create procedure
  Future<void> createProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).set(procedure.toMap());
  }

  /// تحديث إجراء - Update procedure
  Future<void> updateProcedure(ProcedureModel procedure) async {
    await _proceduresRef.doc(procedure.id).update(procedure.toMap());
  }

  /// حذف إجراء - Delete procedure
  Future<void> deleteProcedure(String id) async {
    await _proceduresRef.doc(id).delete();
  }

  /// بث الإجراءات - Stream procedures
  Stream<List<ProcedureModel>> streamProcedures() {
    return _proceduresRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// جلب جميع الإجراءات - Get all procedures
  Future<List<ProcedureModel>> getAllProcedures() async {
    final snapshot = await _proceduresRef.get();
    return snapshot.docs
        .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// تهيئة الإجراءات الافتراضية - Seed default procedures
  Future<void> seedDefaultProcedures() async {
    try {
      final snapshot = await _proceduresRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

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
}
