import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../data/models/case_model.dart';
import '../cubit/cases_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../financials/presentation/cubit/financials_cubit.dart';
import '../../../payroll/presentation/cubit/payroll_cubit.dart';
import '../../../invoice/presentation/screens/invoice_preview_screen.dart';
import 'case_form_dialog.dart';

class CasesTable extends StatelessWidget {
  final List<CaseModel> cases;

  const CasesTable({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return EmptyStateWidget.cases(
        onAction: () => _showCaseDialog(context),
      );
    }

    return ListView.builder(
      itemCount: cases.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) => _buildCaseCard(context, cases[index]),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Indicator color based on case type
              Container(
                width: 6,
                color: c.caseType.label.contains('طوارئ') ? AppColors.error : AppColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Patient Info
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    c.patientName,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (c.patientPhone.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_rounded, size: 10, color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          c.patientPhone,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                      // Nurse Info
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'الممرض المسئول',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.medical_services_outlined, size: 13, color: AppColors.secondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    c.nurseName.isNotEmpty ? c.nurseName : 'غير محدد',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                      // Case Type & Price
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(c.caseType.icon, size: 12, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.caseType.label,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo', 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.bold, 
                                      color: AppColors.secondary
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${c.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _actionIconBtn(
                            context: context,
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.success,
                            tooltip: 'عرض الفاتورة',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoicePreviewScreen(caseData: c)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _actionIconBtn(
                            context: context,
                            icon: Icons.edit_rounded,
                            color: AppColors.warning,
                            tooltip: 'تعديل',
                            onPressed: () => _showCaseDialog(context, caseData: c),
                          ),
                          const SizedBox(width: 8),
                          _actionIconBtn(
                            context: context,
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            tooltip: 'حذف',
                            onPressed: () => _confirmDelete(context, c),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIconBtn({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showCaseDialog(BuildContext context, {CaseModel? caseData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [BlocProvider.value(value: context.read<CasesCubit>())],
        child: CaseFormDialog(caseData: caseData),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CaseModel c) {
    ConfirmDialog.show(
      context,
      title: 'حذف الحالة',
      message:
          'هل أنت متأكد من حذف حالة المريض "${c.patientName}"؟ لا يمكن التراجع عن هذا الإجراء.',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<CasesCubit>().deleteCase(c);
        
        // Refresh all connected features based on user role
        final user = context.read<AuthCubit>().state is AuthAuthenticated 
            ? (context.read<AuthCubit>().state as AuthAuthenticated).user 
            : null;
            
        if (user != null) {
          if (user.role.isAdmin) {
            context.read<DashboardCubit>().loadDashboardData(force: true);
          } else {
            context.read<DashboardCubit>().loadNurseDashboardData(user.id, force: true);
          }
        }
        
        context.read<FinancialsCubit>().loadFinancials(force: true);
        context.read<PayrollCubit>().loadPayroll(force: true);
      }
    });
  }
}

