import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../data/models/procedure_model.dart';

class ProceduresTable extends StatelessWidget {
  final List<ProcedureModel> procedures;
  final Function(ProcedureModel) onEdit;
  final Function(ProcedureModel) onDelete;

  const ProceduresTable({
    super.key,
    required this.procedures,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 600 ? 600.0 : constraints.maxWidth;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        _hc('م', 1),
                        _hc('اسم الإجراء', 3),
                        _hc('سعر الداخل', 2),
                        _hc('سعر الخارج', 2),
                        _hc('إجراءات', 2),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: procedures.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد إجراءات مضافة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: minWidth,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: procedures.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            itemBuilder: (context, index) => _buildRow(procedures[index], index),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hc(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.tableHeader.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRow(ProcedureModel item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: index.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.priceInside} ${AppStrings.currency}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.priceOutside} ${AppStrings.currency}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconActionButton.edit(onPressed: () => onEdit(item)),
                const SizedBox(width: 8),
                IconActionButton.delete(onPressed: () => onDelete(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

