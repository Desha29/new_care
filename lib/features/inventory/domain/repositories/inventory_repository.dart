import '../../data/models/inventory_model.dart';

/// واجهة مستودع المخزون - Inventory Repository Interface
abstract class IInventoryRepository {
  /// جلب جميع المستلزمات - Get all inventory
  Future<List<InventoryModel>> getAllInventory();

  /// جلب عدد المستلزمات - Get inventory count
  Future<int> getInventoryCount();

  /// جلب المخزون المحدث بعد وقت معين - Get updated inventory
  Future<List<InventoryModel>> getUpdatedInventory(DateTime lastSync);

  /// جلب المستلزمات منخفضة المخزون - Get low stock items
  Future<List<InventoryModel>> getLowStockItems();

  /// إنشاء مستلزم - Create inventory item
  Future<void> createInventoryItem(InventoryModel item);

  /// تحديث مستلزم - Update inventory item
  Future<void> updateInventoryItem(InventoryModel item);

  /// حذف مستلزم - Delete inventory item
  Future<void> deleteInventoryItem(String itemId);

  /// تحديث كمية المستلزم - Update item quantity
  Future<void> updateInventoryQuantity(String itemId, int newQuantity);
}
