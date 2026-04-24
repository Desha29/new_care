import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_base.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_model.dart';

/// تنفيذ مستودع المخزون - Inventory Repository Implementation
class InventoryRepositoryImpl extends FirebaseBase implements IInventoryRepository {
  CollectionReference get _inventoryRef =>
      firestore.collection(AppConstants.inventoryCollection);

  @override
  Future<void> createInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> updateInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).update(item.toMap());
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    await _inventoryRef.doc(itemId).delete();
  }

  @override
  Future<List<InventoryModel>> getAllInventory() async {
    final snapshot = await _inventoryRef.get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<int> getInventoryCount() async {
    final snapshot = await _inventoryRef.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<List<InventoryModel>> getUpdatedInventory(DateTime lastSync) async {
    final snapshot = await _inventoryRef
        .where('updatedAt', isGreaterThan: lastSync.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<InventoryModel>> getLowStockItems() async {
    final allItems = await getAllInventory();
    return allItems.where((item) => item.isLowStock || item.isOutOfStock).toList();
  }

  @override
  Future<void> updateInventoryQuantity(String itemId, int newQuantity) async {
    await _inventoryRef.doc(itemId).update({
      'quantity': newQuantity,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
