import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../domain/repositories/invoice_repository.dart';

/// تنفيذ مستودع الفواتير - Invoice Repository Implementation
class InvoiceRepositoryImpl extends FirebaseBase implements IInvoiceRepository {
  CollectionReference get _casesRef =>
      firestore.collection(AppConstants.casesCollection);

  CollectionReference get _inventoryRef =>
      firestore.collection(AppConstants.inventoryCollection);

  @override
  Future<List<InventoryModel>> getAllInventory() async {
    final snapshot = await _inventoryRef.get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<void> updateInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).update(item.toMap());
  }

  @override
  Future<void> createCase(CaseModel caseModel) async {
    await _casesRef.doc(caseModel.id).set(caseModel.toMap());
  }
}
