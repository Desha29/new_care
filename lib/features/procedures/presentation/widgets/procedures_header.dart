import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../cubit/procedures_cubit.dart';
import '../cubit/procedures_state.dart';
import '../../data/models/procedure_model.dart';
import 'package:intl/intl.dart';
import 'package:new_care/core/services/reports/report_service.dart';
import 'package:new_care/core/services/excel/excel_service.dart';
import 'package:new_care/features/reports/presentation/screens/report_preview_screen.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_state.dart';
import 'package:new_care/core/utils/ui_feedback.dart';

class ProceduresHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const ProceduresHeader({super.key, required this.onAdd});

  Future<void> _generateProceduresReport(
    BuildContext context,
    List<ProcedureModel> procedures,
  ) async {
    if (procedures.isEmpty) {
      UIFeedback.showWarning(context, 'لا توجد إجراءات لتصديرها');
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'مسؤول';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'قائمة الإجراءات الطبية',
          fileName:
              'Procedures_Report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
          buildReport: () =>
              ReportService.instance.generateProceduresReportBytes(
                procedures: procedures,
                generatedBy: userName,
              ),
          onExportExcel: () async {
            final fileName =
                'Procedures_Export_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';
            final success = await ExcelService.instance.exportProceduresToExcel(
              procedures,
              fileName,
            );
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProceduresCubit, ProceduresState>(
      builder: (context, state) {
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
                Row(
                  children: [
                    _reportButton(
                      context,
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'تقرير',
                      onTap: () => _generateProceduresReport(context, loadedState?.procedures ?? []),
                    ),
                    const SizedBox(width: 8),
                    _allReportsButton(context, loadedState?.procedures ?? []),
                    const SizedBox(width: 8),
                    PrimaryButton(
                      label: 'إضافة إجراء جديد',
                      icon: Icons.add_rounded,
                      onPressed: onAdd,
                    ),
                  ],
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
                            DropdownMenuItem(
                              value: 50.0,
                              child: Text('حتى 50'),
                            ),
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

  Widget _reportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _allReportsButton(BuildContext context, List<ProcedureModel> procedures) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'excel') {
          UIFeedback.showSuccess(context, 'جاري تصدير Excel...');
          ExcelService.instance.exportProceduresToExcel(procedures);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text('جميع التقارير', style: TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary,
            )),
          ],
        ),
      ),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'excel', child: Row(children: [
          Icon(Icons.table_view_rounded, size: 20, color: Color(0xFF107C41)),
          SizedBox(width: 10), Text('تصدير Excel'),
        ])),
      ],
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
