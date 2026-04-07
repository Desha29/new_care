import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/inventory_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  bool _isOffline = false;
  List<InventoryModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (!isConnected) {
        if (mounted) setState(() => _isOffline = true);
      } else {
        if (mounted) setState(() => _isOffline = false);
      }

      final items = await FirebaseService.instance.getAllInventory();
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المخزون: ${e.toString()}')),
        );
      }
    }
  }

  List<InventoryModel> get _filtered {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q),
        )
        .toList();
  }

  int get _lowStockCount => _items
      .where((i) => i.isLowStock)
      .length;
  
  int get _outOfStockCount => _items.where((i) => i.isOutOfStock).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppColors.error),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              AppStrings.offlineMode,
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadInventory,
                            child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),

                _buildHeader(),
                const SizedBox(height: 16),
                if (_lowStockCount > 0 || _outOfStockCount > 0) ...[
                  _buildAlert(),
                  const SizedBox(height: 16),
                ],
                Expanded(child: _buildTable()),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    AppStrings.inventory,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(onPressed: _loadInventory, icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20)),
                ],
              ),
              const Text(
                'إدارة ومتابعة المستلزمات الطبية والمخزون',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SearchBarWidget(
          hintText: AppStrings.searchInventory,
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showItemDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            AppStrings.addItem,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlert() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusPending,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تنبيه: $_lowStockCount مستلزم بمخزون منخفض، $_outOfStockCount نفد مخزونهم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _hc('المستلزم', 3),
                _hc('التصنيف', 2),
                _hc('الوحدة', 1),
                _hc('الكمية', 1),
                _hc('الحد الأدنى', 1),
                _hc('السعر', 1),
                _hc('حالة المخزون', 2),
                _hc('إجراءات', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      AppStrings.noInventory,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) => _row(_filtered[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(
      t,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _row(InventoryModel item, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.category,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.unit,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: item.isOutOfStock
                    ? AppColors.error
                    : item.isLowStock
                    ? AppColors.warning
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.minStock}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.price.toStringAsFixed(0)} ${AppStrings.currency}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: StockBadge(quantity: item.quantity, minStock: item.minStock, fontSize: 11),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _ab(
                  Icons.edit_rounded,
                  AppColors.warning,
                  'تعديل',
                  () => _showItemDialog(item: item),
                ),
                const SizedBox(width: 4),
                _ab(Icons.add_circle_rounded, AppColors.success, 'إضافة كمية', () => _showAddStockDialog(item)),
                const SizedBox(width: 4),
                _ab(
                  Icons.delete_rounded,
                  AppColors.error,
                  'حذف',
                  () => _confirmDelete(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ab(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _showAddStockDialog(InventoryModel item) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة كمية لـ ${item.name}', style: const TextStyle(fontFamily: 'Cairo')),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الكمية المضافة', labelStyle: TextStyle(fontFamily: 'Cairo')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async {
              final addedVal = int.tryParse(qtyCtrl.text) ?? 0;
              if (addedVal > 0) {
                try {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
                  await FirebaseService.instance.updateInventoryQuantity(item.id, item.quantity + addedVal);
                  await LocalLogService.instance.logActivity(
                    userId: uid,
                    userName: uName,
                    action: 'add_inventory_stock',
                    actionLabel: 'إضافة مخزون',
                    targetType: 'inventory',
                    targetId: item.id,
                    details: 'تم إضافة $addedVal ${item.unit} لـ ${item.name}',
                  );
                  
                  final updatedItem = item.copyWith(quantity: item.quantity + addedVal);
                  if (updatedItem.isLowStock || updatedItem.isOutOfStock) {
                    await NotificationService.instance.showNotification(
                      title: 'تنبيه مخزون منخفض',
                      body: 'المستلزم ${item.name} وصل لمستوى منخفض (${updatedItem.quantity})',
                    );
                  }

                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadInventory();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({InventoryModel? item}) {
    final isEdit = item != null;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '');
    final minCtrl = TextEditingController(text: item?.minStock.toString() ?? '5');
    final priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    final categoryCtrl = TextEditingController(text: item?.category ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? 'قطعة');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: isSaving ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())) : Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? AppStrings.editItem : AppStrings.addItem,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _field('اسم المستلزم', nameCtrl, Icons.inventory_2_rounded, isRequired: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('التصنيف', categoryCtrl, Icons.category_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('الوحدة', unitCtrl, Icons.scale_rounded)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('الكمية الحالية', qtyCtrl, Icons.numbers_rounded, isNumber: true, isRequired: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('الحد الأدنى', minCtrl, Icons.warning_rounded, isNumber: true, isRequired: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field('سعر الوحدة', priceCtrl, Icons.attach_money_rounded, isNumber: true, isRequired: true),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              AppStrings.cancel,
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                ss(() => isSaving = true);
                                try {
                                  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                                  final newItem = InventoryModel(
                                    id: item?.id ?? '',
                                    name: nameCtrl.text.trim(),
                                    category: categoryCtrl.text.trim(),
                                    unit: unitCtrl.text.trim(),
                                    quantity: int.tryParse(qtyCtrl.text) ?? 0,
                                    minStock: int.tryParse(minCtrl.text) ?? 5,
                                    price: double.tryParse(priceCtrl.text) ?? 0,
                                    createdAt: item?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    createdBy: item?.createdBy ?? uid,
                                  );

                                  final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
                                  if (isEdit) {
                                    await FirebaseService.instance.updateInventoryItem(newItem);
                                    await LocalLogService.instance.logActivity(
                                      userId: uid,
                                      userName: uName,
                                      action: 'update_inventory',
                                      actionLabel: 'تعديل مستلزم',
                                      targetType: 'inventory',
                                      targetId: newItem.id,
                                      details: 'تم تعديل بيانات المستلزم: ${newItem.name}',
                                    );
                                  } else {
                                    await FirebaseService.instance.createInventoryItem(newItem);
                                    await LocalLogService.instance.logActivity(
                                      userId: uid,
                                      userName: uName,
                                      action: 'add_inventory',
                                      actionLabel: 'إضافة مستلزم',
                                      targetType: 'inventory',
                                      targetId: newItem.name,
                                      details: 'تم إضافة مستلزم جديد: ${newItem.name}',
                                    );
                                  }

                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    _loadInventory();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(isEdit ? 'تم تحديث البيانات بنجاح' : 'تم إضافة المستلزم بنجاح', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
                                    );
                                  }
                                } catch (e) {
                                  ss(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                }
                              }
                            },
                            child: const Text(
                              AppStrings.save,
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            if (isRequired) const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(InventoryModel item) async {
    final result = await ConfirmDialog.show(
      context,
      title: 'حذف المستلزم',
      message: 'هل أنت متأكد من حذف المستلزم "${item.name}"؟',
      confirmText: AppStrings.delete,
      icon: Icons.delete_forever_rounded,
    );
    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
        await FirebaseService.instance.deleteInventoryItem(item.id);
        await LocalLogService.instance.logActivity(
          userId: uid,
          userName: uName,
          action: 'delete_inventory',
          actionLabel: 'حذف مستلزم',
          targetType: 'inventory',
          targetId: item.id,
          details: 'تم حذف المستلزم: ${item.name}',
        );
        _loadInventory();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}
