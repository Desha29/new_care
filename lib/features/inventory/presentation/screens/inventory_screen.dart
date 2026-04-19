import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/constants/app_strings.dart';
import 'package:new_care/core/constants/app_typography.dart';
import 'package:new_care/core/widgets/status_badge.dart';
import 'package:new_care/core/widgets/search_bar_widget.dart';
import 'package:new_care/core/widgets/dialogs/confirm_dialog.dart';
import 'package:new_care/core/widgets/empty_state_widget.dart';
import 'package:new_care/core/widgets/buttons/primary_button.dart';
import 'package:new_care/core/widgets/buttons/icon_action_button.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/inventory/logic/cubit/inventory_cubit.dart';
import 'package:new_care/features/inventory/logic/cubit/inventory_state.dart';
import 'package:new_care/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryInitial) {
          context.read<InventoryCubit>().loadInventory();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.getScreenPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 16),
                if (state is InventoryLoaded) ...[
                  if (state.items.any((i) => i.isLowStock || i.isOutOfStock)) ...[
                    _buildAlert(state),
                    const SizedBox(height: 16),
                  ],
                ],
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, InventoryState state) {
    if (state is InventoryLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is InventoryError) {
      return Center(child: Text(state.message, style: AppTypography.tableCell));
    } else if (state is InventoryLoaded) {
      return _buildTable(context, state.items);
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context, InventoryState state) {
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Wrap(
      spacing: 12, runSpacing: 12, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(AppStrings.inventory, style: AppTypography.pageTitle.copyWith(fontSize: titleSize)),
            const SizedBox(width: 12),
            IconButton(onPressed: () => context.read<InventoryCubit>().loadInventory(), icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20)),
          ]),
          Text('إدارة ومتابعة المستلزمات الطبية والمخزون', style: AppTypography.pageSubtitle.copyWith(fontSize: ResponsiveHelper.getSubtitleFontSize(context))),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (!isMobile) SearchBarWidget(hintText: AppStrings.searchInventory, controller: TextEditingController(), onChanged: (v) => context.read<InventoryCubit>().searchInventory(v)),
          if (!isMobile) const SizedBox(width: 12),
          PrimaryButton(
            label: isMobile ? 'إضافة' : AppStrings.addItem,
            icon: Icons.add_rounded,
            onPressed: () => _showItemDialog(context),
          ),
        ]),
        if (isMobile) SearchBarWidget(hintText: AppStrings.searchInventory, controller: TextEditingController(), onChanged: (v) => context.read<InventoryCubit>().searchInventory(v)),
      ],
    );
  }

  Widget _buildAlert(InventoryLoaded state) {
    final low = state.items.where((i) => i.isLowStock).length;
    final out = state.items.where((i) => i.isOutOfStock).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.statusPendingBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.statusPending, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text('تنبيه: $low مستلزم بمخزون منخفض، $out نفد مخزونهم', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textPrimary))),
      ]),
    );
  }

  Widget _buildTable(BuildContext context, List<InventoryModel> items) {
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
          child: items.isEmpty
              ? EmptyStateWidget.inventory(
                  onAction: () => _showItemDialog(context),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (_, i) => _row(context, items[i], i),
                ),
        ),
      ]),
    );
  }

  Widget _hc(String t, int f) => Expanded(flex: f, child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 13, color: AppColors.textSecondary)));

  Widget _row(BuildContext context, InventoryModel item, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.secondary)),
          const SizedBox(width: 10),
          Expanded(child: Text(item.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 2, child: Text(item.category, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))),
        Expanded(flex: 1, child: Text(item.unit, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 1, child: Text('${item.quantity}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: item.isOutOfStock ? AppColors.error : item.isLowStock ? AppColors.warning : AppColors.textPrimary))),
        Expanded(flex: 1, child: Text('${item.minStock}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))),
        Expanded(flex: 1, child: Text('${item.price.toStringAsFixed(0)} ${AppStrings.currency}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 2, child: StockBadge(quantity: item.quantity, minStock: item.minStock, fontSize: 11)),
        Expanded(flex: 2, child: Row(children: [
          IconActionButton.edit(onPressed: () => _showItemDialog(context, item: item)),
          const SizedBox(width: 4),
          IconActionButton(
            icon: Icons.add_circle_rounded,
            tooltip: 'إضافة كمية',
            color: AppColors.success,
            onPressed: () => _showAddStockDialog(context, item),
          ),
          const SizedBox(width: 4),
          IconActionButton.delete(onPressed: () => _confirmDelete(context, item)),
        ])),
      ]),
    );
  }

  Widget _ab(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(message: tooltip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color))));
  }

  void _showAddStockDialog(BuildContext context, InventoryModel item) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة كمية لـ ${item.name}', style: const TextStyle(fontFamily: 'Cairo')),
        content: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية المضافة', labelStyle: TextStyle(fontFamily: 'Cairo'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () {
              final addedVal = int.tryParse(qtyCtrl.text) ?? 0;
              if (addedVal > 0) {
                context.read<InventoryCubit>().addOrUpdateItem(item.copyWith(quantity: item.quantity + addedVal));
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, {InventoryModel? item}) {
    final isEdit = item != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '');
    final minCtrl = TextEditingController(text: item?.minStock.toString() ?? '5');
    final priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    final categoryCtrl = TextEditingController(text: item?.category ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? 'قطعة');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480, padding: const EdgeInsets.all(28),
          child: Form(key: formKey, child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded, color: AppColors.secondary, size: 22)),
                const SizedBox(width: 12),
                Text(isEdit ? AppStrings.editItem : AppStrings.addItem, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 20),
              _field('اسم المستلزم', nameCtrl, Icons.inventory_2_rounded, isRequired: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('التصنيف', categoryCtrl, Icons.category_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _field('الوحدة', unitCtrl, Icons.scale_rounded)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('الكمية الحالية', qtyCtrl, Icons.numbers_rounded, isNumber: true, isRequired: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('الحد الأدنى', minCtrl, Icons.warning_rounded, isNumber: true, isRequired: true)),
              ]),
              const SizedBox(height: 12),
              _field('سعر الوحدة', priceCtrl, Icons.attach_money_rounded, isNumber: true, isRequired: true),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final newItem = InventoryModel(
                        id: item?.id ?? FirebaseService.instance.generateId(),
                        name: nameCtrl.text.trim(),
                        category: categoryCtrl.text.trim(),
                        unit: unitCtrl.text.trim(),
                        quantity: int.tryParse(qtyCtrl.text) ?? 0,
                        minStock: int.tryParse(minCtrl.text) ?? 5,
                        price: double.tryParse(priceCtrl.text) ?? 0,
                        createdAt: item?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                        createdBy: item?.createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? '',
                      );
                      context.read<InventoryCubit>().addOrUpdateItem(newItem);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')),
                )),
              ]),
            ]),
          )),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, bool isRequired = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null : null,
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 18, color: AppColors.textHint)),
      ),
    ]);
  }

  void _confirmDelete(BuildContext context, InventoryModel item) async {
    final result = await ConfirmDialog.show(context, title: 'حذف المستلزم', message: 'هل أنت متأكد؟');
    if (result == true) {
      context.read<InventoryCubit>().deleteItem(item.id);
    }
  }
}
