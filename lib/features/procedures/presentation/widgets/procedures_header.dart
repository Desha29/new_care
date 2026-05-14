import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../cubit/procedures_cubit.dart';
import '../cubit/procedures_state.dart';

class ProceduresHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const ProceduresHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProceduresCubit, ProceduresState>(
      builder: (context, state) {
        final isLoading = state is ProceduresLoading;
        final loadedState = state is ProceduresLoaded ? state : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Add Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الإجراءات والخدمات',
                  style: AppTypography.pageTitle.copyWith(fontSize: 24),
                ),
                PrimaryButton(
                  label: 'إضافة إجراء جديد',
                  icon: Icons.add_rounded,
                  onPressed: onAdd,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filter Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppSearchBar(
                          hintText: 'البحث عن إجراء بالاسم...',
                          onChanged: (v) => context
                              .read<ProceduresCubit>()
                              .searchProcedures(v),
                        ),
                      ),
                      if (loadedState != null) ...[
                        const SizedBox(width: 16),
                        _buildDropdownFilter<ProcedureSort>(
                          value: loadedState.sortBy,
                          hint: 'ترتيب حسب',
                          items: const [
                            DropdownMenuItem(
                              value: ProcedureSort.name,
                              child: Text('الاسم (أ-ي)'),
                            ),
                            DropdownMenuItem(
                              value: ProcedureSort.priceAsc,
                              child: Text('السعر: من الأقل'),
                            ),
                            DropdownMenuItem(
                              value: ProcedureSort.priceDesc,
                              child: Text('السعر: من الأعلى'),
                            ),
                          ],
                          onChanged: (v) => v != null
                              ? context.read<ProceduresCubit>().setSortBy(v)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        _buildDropdownFilter<double>(
                          value: loadedState.maxPrice,
                          hint: 'السعر الأقصى',
                          items: const [
                            DropdownMenuItem(value: 50.0, child: Text('حتى 50')),
                            DropdownMenuItem(
                              value: 100.0,
                              child: Text('حتى 100'),
                            ),
                            DropdownMenuItem(
                              value: 200.0,
                              child: Text('حتى 200'),
                            ),
                            DropdownMenuItem(
                              value: 500.0,
                              child: Text('حتى 500'),
                            ),
                          ],
                          onChanged: (v) =>
                              context.read<ProceduresCubit>().setMaxPrice(v),
                          onClear: () =>
                              context.read<ProceduresCubit>().setMaxPrice(null),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownFilter<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (value != null && onClear != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.error,
              ),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
