import '../../../cases/data/models/case_model.dart';
import '../../../inventory/data/models/inventory_model.dart';

/// واجهة مستودع الفواتير - Invoice Repository Interface
abstract class IInvoiceRepository {
  /// جلب جميع المستلزمات - Get all inventory (for stock validation)
  Future<List<InventoryModel>> getAllInventory();

  /// تحديث مستلزم - Update inventory item (for stock deduction)
  Future<void> updateInventoryItem(InventoryModel item);

  /// إنشاء حالة/فاتورة - Create case/invoice
  Future<void> createCase(CaseModel caseModel);
}
