import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/inventory_model.dart';

/// تنفيذ مستودع المخزون (الجيل الثاني) - Inventory Repository Implementation v2
/// Professional, offline-first inventory management.
class InventoryRepositoryImpl implements IInventoryRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createInventoryItem(InventoryModel item) async {
    await _local.insert('inventory', item.toSqliteMap());
    await _sync.enqueue(
      tableName: 'inventory',
      operation: 'create',
      docId: item.id,
      data: item.toMap(),
    );
  }

  @override
  Future<void> updateInventoryItem(InventoryModel item) async {
    await _local.insert('inventory', item.toSqliteMap());
    await _sync.enqueue(
      tableName: 'inventory',
      operation: 'update',
      docId: item.id,
      data: item.toMap(),
    );
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    await _local.delete('inventory', where: 'id = ?', whereArgs: [itemId]);
    await _sync.enqueue(
      tableName: 'inventory',
      operation: 'delete',
      docId: itemId,
      data: {},
    );
  }

  @override
  Future<List<InventoryModel>> getAllInventory() async {
    final results = await _local.database.then((db) => db.query('inventory'));
    return results.map((m) => InventoryModel.fromMap(m, m['id'] as String)).toList();
  }


  @override
  Future<int> getInventoryCount() async {
    return await _local.getInventoryCount();
  }

  @override
  Future<List<InventoryModel>> getUpdatedInventory(DateTime lastSync) async {
    return await _remote.getUpdatedInventory(lastSync);
  }

  @override
  Future<List<InventoryModel>> getLowStockItems() async {
    final allItems = await getAllInventory();
    return allItems.where((item) => item.isLowStock || item.isOutOfStock).toList();
  }

  @override
  Future<void> updateInventoryQuantity(String itemId, int newQuantity) async {
    final itemMap = await _local.getById('inventory', itemId);
    if (itemMap != null) {
      final updated = Map<String, dynamic>.from(itemMap);
      updated['quantity'] = newQuantity;
      updated['updatedAt'] = DateTime.now().toIso8601String();
      
      final model = InventoryModel.fromMap(updated, itemId);
      await updateInventoryItem(model);
    }
  }
}
