import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/inventory_state.dart';

class InventoryAlert extends StatelessWidget {
  final InventoryLoaded state;

  const InventoryAlert({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final low = state.items.where((i) => i.isLowStock).length;
    final out = state.items.where((i) => i.isOutOfStock).length;

    if (low == 0 && out == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusPending.withOpacity(0.3),
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
              'تنبيه: $low مستلزم بمخزون منخفض، $out نفد مخزونهم',
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
}

