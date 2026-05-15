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
    final expired = state.items.where((i) => i.isExpired).length;
    final expiring = state.items.where((i) => i.isExpiringSoon).length;

    if (low == 0 && out == 0 && expired == 0 && expiring == 0) return const SizedBox.shrink();

    List<String> messages = [];
    if (out > 0) messages.add('$out نفد مخزونهم');
    if (low > 0) messages.add('$low بمخزون منخفض');
    if (expired > 0) messages.add('$expired منتهية الصلاحية');
    if (expiring > 0) messages.add('$expiring تنتهي قريباً');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (expired > 0 || out > 0) ? AppColors.statusCancelledBg : AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (expired > 0 || out > 0) ? AppColors.statusCancelled.withValues(alpha: 0.3) : AppColors.statusPending.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: (expired > 0 || out > 0) ? AppColors.statusCancelled : AppColors.statusPending,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تنبيه: ${messages.join('، ')}',
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

