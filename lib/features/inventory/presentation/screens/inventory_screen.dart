import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/widgets/dialogs/confirm_dialog.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:new_care/features/inventory/presentation/cubit/inventory_state.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_alert.dart';
import '../widgets/inventory_table.dart';
import '../widgets/inventory_form_dialog.dart';

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
                InventoryHeader(
                  state: state,
                  onRefresh: () => context.read<InventoryCubit>().loadInventory(),
                  onAddItem: () => _showItemDialog(context),
                ),
                const SizedBox(height: 16),
                if (state is InventoryLoaded) ...[
                  InventoryAlert(state: state),
                  const SizedBox(height: 16),
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
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      );
    } else if (state is InventoryLoaded) {
      return InventoryTable(
        items: state.items,
        onEdit: (item) => _showItemDialog(context, item: item),
        onAddStock: (item) => _showAddStockDialog(context, item),
        onDelete: (item) => _confirmDelete(context, item),
        onEmptyAction: () => _showItemDialog(context),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAddStockDialog(BuildContext context, InventoryModel item) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'إضافة كمية لـ ${item.name}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الكمية المضافة',
            labelStyle: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              final addedVal = int.tryParse(qtyCtrl.text) ?? 0;
              if (addedVal > 0) {
                context.read<InventoryCubit>().addOrUpdateItem(
                      item.copyWith(quantity: item.quantity + addedVal),
                    );
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
    InventoryFormDialog.show(
      context,
      item: item,
      onSave: (newItem) => context.read<InventoryCubit>().addOrUpdateItem(newItem),
    );
  }

  void _confirmDelete(BuildContext context, InventoryModel item) async {
    final result = await ConfirmDialog.show(
      context,
      title: 'حذف المستلزم',
      message: 'هل أنت متأكد من حذف ${item.name}؟ لا يمكن التراجع عن هذا الإجراء.',
    );
    if (result == true) {
      context.read<InventoryCubit>().deleteItem(item.id);
    }
  }
}
