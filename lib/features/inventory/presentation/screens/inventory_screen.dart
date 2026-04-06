import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';

/// شاشة إدارة المستلزمات الطبية - Inventory Management Screen
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _items = [
    {'id': '1', 'name': 'كانيولا وريدية', 'unit': 'قطعة', 'quantity': 45, 'minStock': 10, 'price': 15.0, 'category': 'مستلزمات وريدية'},
    {'id': '2', 'name': 'محلول ملحي 500مل', 'unit': 'عبوة', 'quantity': 30, 'minStock': 15, 'price': 25.0, 'category': 'محاليل'},
    {'id': '3', 'name': 'شاش معقم', 'unit': 'لفة', 'quantity': 8, 'minStock': 10, 'price': 12.0, 'category': 'ضمادات'},
    {'id': '4', 'name': 'قفازات طبية', 'unit': 'علبة', 'quantity': 3, 'minStock': 5, 'price': 35.0, 'category': 'حماية'},
    {'id': '5', 'name': 'سرنجة 5مل', 'unit': 'قطعة', 'quantity': 120, 'minStock': 20, 'price': 3.0, 'category': 'مستلزمات وريدية'},
    {'id': '6', 'name': 'بلاستر طبي', 'unit': 'لفة', 'quantity': 0, 'minStock': 5, 'price': 8.0, 'category': 'ضمادات'},
    {'id': '7', 'name': 'كحول طبي 70%', 'unit': 'زجاجة', 'quantity': 15, 'minStock': 5, 'price': 20.0, 'category': 'تعقيم'},
    {'id': '8', 'name': 'قسطرة بولية', 'unit': 'قطعة', 'quantity': 2, 'minStock': 5, 'price': 45.0, 'category': 'مستلزمات طبية'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((i) => i['name'].toString().contains(_searchQuery) || i['category'].toString().contains(_searchQuery)).toList();
  }

  int get _lowStockCount => _items.where((i) => (i['quantity'] as int) <= (i['minStock'] as int) && (i['quantity'] as int) > 0).length;
  int get _outOfStockCount => _items.where((i) => (i['quantity'] as int) <= 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_lowStockCount > 0 || _outOfStockCount > 0) ...[_buildAlert(), const SizedBox(height: 16)],
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.inventory, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text('إدارة ومتابعة المستلزمات الطبية والمخزون', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
      ])),
      SearchBarWidget(hintText: AppStrings.searchInventory, controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v)),
      const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(AppStrings.addItem, style: TextStyle(fontFamily: 'Cairo')),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]);
  }

  Widget _buildAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.statusPendingBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text('تنبيه: $_lowStockCount مستلزم بمخزون منخفض، $_outOfStockCount نفد مخزونهم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textPrimary))),
        TextButton(onPressed: () {}, child: const Text('عرض التفاصيل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
      ]),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [_hc('المستلزم', 3), _hc('التصنيف', 2), _hc('الوحدة', 1), _hc('الكمية', 1), _hc('الحد الأدنى', 1), _hc('السعر', 1), _hc('حالة المخزون', 2), _hc('إجراءات', 2)]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text(AppStrings.noInventory, style: TextStyle(fontFamily: 'Cairo', color: AppColors.textHint)))
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (_, i) => _row(_filtered[i], i),
                ),
        ),
      ]),
    );
  }

  Widget _hc(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)));

  Widget _row(Map<String, dynamic> item, int i) {
    final qty = item['quantity'] as int;
    final min = item['minStock'] as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.secondary)),
          const SizedBox(width: 10),
          Expanded(child: Text(item['name'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 2, child: Text(item['category'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))),
        Expanded(flex: 1, child: Text(item['unit'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 1, child: Text('$qty', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: qty <= 0 ? AppColors.error : qty <= min ? AppColors.warning : AppColors.textPrimary))),
        Expanded(flex: 1, child: Text('$min', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))),
        Expanded(flex: 1, child: Text('${(item['price'] as double).toStringAsFixed(0)} ${AppStrings.currency}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 2, child: StockBadge(quantity: qty, minStock: min, fontSize: 11)),
        Expanded(flex: 2, child: Row(children: [
          _ab(Icons.edit_rounded, AppColors.warning, () => _showItemDialog(item: item)),
          const SizedBox(width: 4),
          _ab(Icons.add_circle_rounded, AppColors.success, () {}),
          const SizedBox(width: 4),
          _ab(Icons.delete_rounded, AppColors.error, () => setState(() => _items.removeWhere((x) => x['id'] == item['id']))),
        ])),
      ]),
    );
  }

  Widget _ab(IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(message: '', child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color))));
  }

  void _showItemDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString() ?? '');
    final minCtrl = TextEditingController(text: item?['minStock']?.toString() ?? '5');
    final priceCtrl = TextEditingController(text: item?['price']?.toString() ?? '');

    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 480, padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded, color: AppColors.secondary, size: 22)),
          const SizedBox(width: 12),
          Text(isEdit ? AppStrings.editItem : AppStrings.addItem, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 20),
        _field('اسم المستلزم', nameCtrl, Icons.inventory_2_rounded),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('الكمية', qtyCtrl, Icons.numbers_rounded)), const SizedBox(width: 12), Expanded(child: _field('الحد الأدنى', minCtrl, Icons.warning_rounded))]),
        const SizedBox(height: 12),
        _field('السعر', priceCtrl, Icons.attach_money_rounded),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')))),
        ]),
      ])),
    ));
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(controller: ctrl, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14), decoration: InputDecoration(prefixIcon: Icon(icon, size: 18, color: AppColors.textHint))),
    ]);
  }
}
