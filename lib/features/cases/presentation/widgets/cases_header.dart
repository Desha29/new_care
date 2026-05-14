import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/custom_date_range_dialog.dart';
import '../../../procedures/presentation/cubit/procedures_cubit.dart';
import '../../../procedures/presentation/cubit/procedures_state.dart';
import '../cubit/cases_cubit.dart';
import '../cubit/cases_state.dart';
import '../../../../core/enums/case_status.dart';
import 'case_form_dialog.dart';

class CasesHeader extends StatelessWidget {
  final CasesLoaded state;

  const CasesHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Add Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الحالات / المرضى',
                      style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
                    ),
                    const SizedBox(width: 12),
                    _buildRefreshButton(context),
                  ],
                ),
                Text(
                  'إدارة و مراجعة الحالات الطبية المسجلة',
                  style: AppTypography.pageSubtitle.copyWith(
                    fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                  ),
                ),
              ],
            ),
            if (!isMobile)
              PrimaryButton(
                label: AppStrings.addCase,
                icon: Icons.add_rounded,
                onPressed: () => _showCaseDialog(context),
              ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Search and Main Filters Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                      hintText: 'البحث باسم المريض أو الهاتف...',
                      onChanged: (v) => context.read<CasesCubit>().searchCases(v),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    _buildDropdownFilter<CaseType>(
                      value: state.typeFilter,
                      hint: 'نوع الحالة',
                      items: CaseType.values.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      )).toList(),
                      onChanged: (v) => context.read<CasesCubit>().filterByType(v),
                      onClear: () => context.read<CasesCubit>().filterByType(null),
                    ),
                    const SizedBox(width: 16),
                    _buildProceduresFilter(context),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimeFilters(context)),
                  if (isMobile) ...[
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: '',
                      icon: Icons.add_rounded,
                      onPressed: () => _showCaseDialog(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: () => context.read<CasesCubit>().loadCases(
              force: true,
              timeFilter: state.timeFilter,
            ),
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildTimeFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _timeTab(context, 'اليوم', TimeFilter.today),
          const SizedBox(width: 8),
          _timeTab(context, 'أمس', TimeFilter.yesterday),
          const SizedBox(width: 8),
          _timeTab(context, 'آخر 7 أيام', TimeFilter.last7Days),
          const SizedBox(width: 8),
          _timeTab(context, 'مخصص', TimeFilter.custom),
          const SizedBox(width: 8),
          _timeTab(context, 'الكل', TimeFilter.all),
        ],
      ),
    );
  }

  Widget _timeTab(BuildContext context, String label, TimeFilter filter) {
    final isSelected = state.timeFilter == filter;
    return InkWell(
      onTap: () async {
        if (filter == TimeFilter.custom) {
          final picked = await CustomDateRangeDialog.show(
            context,
            start: state.customStartDate,
            end: state.customEndDate,
          );
          if (picked != null && context.mounted) {
            context.read<CasesCubit>().loadCases(
              timeFilter: TimeFilter.custom,
              customStartDate: picked.start,
              customEndDate: picked.end,
            );
          }
        } else {
          context.read<CasesCubit>().loadCases(timeFilter: filter);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required VoidCallback onClear,
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
              hint: Text(hint, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
              items: items,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProceduresFilter(BuildContext context) {
    return BlocBuilder<ProceduresCubit, ProceduresState>(
      builder: (context, proceduresState) {
        List<DropdownMenuItem<String>> items = [];
        if (proceduresState is ProceduresLoaded) {
          items = proceduresState.procedures.map((p) => DropdownMenuItem(
            value: p.name,
            child: Text(p.name),
          )).toList();
        }

        return _buildDropdownFilter<String>(
          value: state.procedureFilter,
          hint: 'الإجراء الطبي',
          items: items,
          onChanged: (v) => context.read<CasesCubit>().filterByProcedure(v),
          onClear: () => context.read<CasesCubit>().filterByProcedure(null),
        );
      },
    );
  }

  void _showCaseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CaseFormDialog(),
    );
  }
}
