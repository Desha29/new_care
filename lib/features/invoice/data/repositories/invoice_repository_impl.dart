import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../domain/repositories/invoice_repository.dart';

/// تنفيذ مستودع الفواتير (الجيل الثاني) - Invoice Repository Implementation v2
/// Robust, offline-first invoice and case management.
class InvoiceRepositoryImpl implements IInvoiceRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<List<InventoryModel>> getAllInventory() async {
    final results = await _local.database.then((db) => db.query('inventory'));
    if (results.isNotEmpty) {
      return results.map((m) => InventoryModel.fromMap(m, m['id'] as String)).toList();
    }
    
    final remote = await _remote.getAllInventory();
    for (var item in remote) {
      await _local.insert('inventory', item.toSqliteMap());
    }
    return remote;
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
  Future<void> createCase(CaseModel caseModel) async {
    await _local.saveCase(caseModel.toSqliteMap());
    await _sync.enqueue(
      tableName: 'cases',
      operation: 'create',
      docId: caseModel.id,
      data: caseModel.toMap(),
    );
  }
}
