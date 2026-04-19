import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/inventory/data/models/inventory_model.dart';
import '../../constants/app_constants.dart';
import 'firebase_base.dart';

/// مستودع المستلزمات - Inventory Repository
class InventoryRepository extends FirebaseBase {
  CollectionReference get _inventoryRef =>
      firestore.collection(AppConstants.inventoryCollection);

  /// إنشاء مستلزم - Create inventory item
  Future<void> createInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).set(item.toMap());
  }

  /// تحديث مستلزم - Update inventory item
  Future<void> updateInventoryItem(InventoryModel item) async {
    await _inventoryRef.doc(item.id).update(item.toMap());
  }

  /// حذف مستلزم - Delete inventory item
  Future<void> deleteInventoryItem(String itemId) async {
    await _inventoryRef.doc(itemId).delete();
  }

  /// جلب جميع المستلزمات - Get all inventory
  Future<List<InventoryModel>> getAllInventory() async {
    final snapshot = await _inventoryRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => InventoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// جلب المستلزمات منخفضة المخزون - Get low stock items
  Future<List<InventoryModel>> getLowStockItems() async {
    final allItems = await getAllInventory();
    return allItems.where((item) => item.isLowStock || item.isOutOfStock).toList();
  }

  /// تحديث كمية المستلزم - Update item quantity
  Future<void> updateInventoryQuantity(String itemId, int newQuantity) async {
    await _inventoryRef.doc(itemId).update({
      'quantity': newQuantity,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
