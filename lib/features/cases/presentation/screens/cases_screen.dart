import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/services/reports/report_service.dart';
import '../../../../core/services/excel/excel_service.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../reports/presentation/screens/report_preview_screen.dart';
import '../../../procedures/domain/repositories/procedures_repository.dart';
import '../../domain/repositories/cases_repository.dart';
import 'package:get_it/get_it.dart';
import '../cubit/cases_cubit.dart';
import '../cubit/cases_state.dart';
import '../widgets/cases_header.dart';
import '../widgets/cases_table.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthCubit>().state;
    String? nurseId;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      nurseId = user.role.isAdmin ? null : user.id;
    }
    context.read<CasesCubit>().loadCases(nurseId: nurseId, timeFilter: TimeFilter.today);
  }

  Future<void> _generateDailyReport(CasesLoaded state) async {
    final today = DateTime.now();
    final todayCases = state.cases
        .where((c) =>
            c.caseDate.year == today.year &&
            c.caseDate.month == today.month &&
            c.caseDate.day == today.day)
        .toList();

    if (todayCases.isEmpty) {
      UIFeedback.showWarning(context, 'لا توجد حالات مسجلة اليوم');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير عمل اليوم - ${DateFormat('yyyy/MM/dd').format(today)}',
          fileName: 'Daily_Report_${DateFormat('yyyy_MM_dd').format(today)}',
          buildReport: () => ReportService.instance.generateCasesReportBytes(
            cases: todayCases,
            title: 'تقرير العمل اليومي',
            subtitle: 'كشف الحالات المنفذة بتاريخ: ${DateFormat('yyyy/MM/dd').format(today)}',
          ),
          onExportExcel: () async {
            final fileName = 'Daily_Report_${DateFormat('yyyy_MM_dd').format(today)}';
            final success = await ExcelService.instance.exportCasesToExcel(todayCases, fileName);
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            } else if (!success && context.mounted) {
              UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
            }
          },
        ),
      ),
    );
  }

  Future<void> _generateMonthlyReport(CasesLoaded state) async {
    final now = DateTime.now();
    final monthCases = state.cases.where((c) =>
        c.caseDate.month == now.month && c.caseDate.year == now.year).toList();

    if (monthCases.isEmpty) {
      UIFeedback.showWarning(context, 'لا توجد حالات لهذا الشهر');
      return;
    }

    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          title: 'تقرير العمل - $monthName',
          fileName: 'Work_Report_${now.year}_${now.month}',
          buildReport: () => ReportService.instance.generateCasesReportBytes(
            cases: monthCases,
            title: 'تقرير أداء العمل التفصيلي',
            subtitle: 'كشف الحالات والخدمات لشهر: $monthName',
          ),
          onExportExcel: () async {
            final fileName = 'Work_Report_${now.year}_${now.month}';
            final success = await ExcelService.instance.exportCasesToExcel(monthCases, fileName);
            if (success && context.mounted) {
              UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
            } else if (!success && context.mounted) {
              UIFeedback.showError(context, 'فشل تصدير ملف Excel أو تم إلغاؤه');
            }
          },
        ),
      ),
    );
  }

  Future<void> _generateCustomReport() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null || !context.mounted) return;

    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.role.isAdmin ?? false;
    final nurseId = isAdmin ? null : user?.id;

    LoadingDialog.show(context);
    try {
      final repo = GetIt.I<ICasesRepository>();
      final allCases = await repo.getAllCases(nurseId: nurseId);
      final filtered = allCases.where((c) =>
          c.caseDate.isAfter(picked.start.subtract(const Duration(seconds: 1))) &&
          c.caseDate.isBefore(picked.end.add(const Duration(days: 1)))).toList();

      if (!mounted) return;
      LoadingDialog.hide(context);

      if (filtered.isEmpty) {
        UIFeedback.showWarning(context, 'لا توجد حالات في الفترة المختارة');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            title: 'تقرير فترة مخصصة',
            fileName: 'Custom_Report_${DateFormat('yyyy_MM_dd').format(picked.start)}',
            buildReport: () => ReportService.instance.generateCasesReportBytes(
              cases: filtered,
              title: 'تقرير فترة مخصصة',
              subtitle: 'من ${DateFormat('MM/dd').format(picked.start)} إلى ${DateFormat('MM/dd').format(picked.end)}',
            ),
            onExportExcel: () async {
              final success = await ExcelService.instance.exportCasesToExcel(
                filtered, 'Custom_Report_${DateFormat('yyyy_MM_dd').format(picked.start)}');
              if (success && context.mounted) {
                UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        UIFeedback.showError(context, 'خطأ أثناء إصدار التقرير: $e');
      }
    }
  }

  Future<void> _generateProceduresReport() async {
    LoadingDialog.show(context);
    try {
      final userName = context.read<AuthCubit>().state is AuthAuthenticated
          ? (context.read<AuthCubit>().state as AuthAuthenticated).user.name
          : 'Admin';
      final repo = GetIt.I<IProceduresRepository>();
      final procedures = await repo.getAllProcedures();

      if (!mounted) return;
      LoadingDialog.hide(context);

      if (procedures.isEmpty) {
        UIFeedback.showWarning(context, 'لا توجد إجراءات مسجلة');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            title: 'قائمة الإجراءات والأسعار',
            fileName: 'Procedures_Report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
            buildReport: () => ReportService.instance.generateProceduresReportBytes(procedures: procedures, generatedBy: userName),
            onExportExcel: () async {
              final success = await ExcelService.instance.exportProceduresToExcel(procedures);
              if (success && context.mounted) {
                UIFeedback.showSuccess(context, 'تم تصدير ملف Excel بنجاح');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        UIFeedback.showError(context, 'خطأ أثناء إصدار التقرير: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<CasesCubit, CasesState>(
        listener: (context, state) {
          if (state is CasesError) {
            UIFeedback.showError(context, state.message);
          }
        },
        child: BlocBuilder<CasesCubit, CasesState>(
          buildWhen: (previous, current) => 
              current is CasesLoading || 
              current is CasesLoaded || 
              current is CasesError,
          builder: (context, state) {
            if (state is CasesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CasesError) {
              return EmptyStateWidget.error(
                message: state.message,
                onRetry: () => _loadData(),
              );
            }
            if (state is CasesLoaded) {
              final isAdmin = context.read<AuthCubit>().currentUser?.role.isAdmin ?? false;
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CasesHeader(state: state),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _buildReportButtons(state),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: CasesTable(cases: state.filteredCases),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }


  Widget _buildReportButtons(CasesLoaded state) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'التقارير',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _reportButton(
            label: isMobile ? '' : 'تقرير اليوم',
            icon: Icons.today_rounded,
            onTap: () => _generateDailyReport(state),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'monthly') _generateMonthlyReport(state);
              else if (value == 'custom') _generateCustomReport();
              else if (value == 'procedures') _generateProceduresReport();
            },
            child: _reportButton(
              label: isMobile ? '' : 'جميع التقارير',
              icon: Icons.more_horiz_rounded,
            ),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'monthly', child: Row(children: [
                Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.secondary),
                const SizedBox(width: 10), const Text('تقرير شهري'),
              ])),
              PopupMenuItem(value: 'custom', child: Row(children: [
                Icon(Icons.date_range_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 10), const Text('فترة مخصصة'),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'procedures', child: Row(children: [
                Icon(Icons.medical_services_rounded, size: 20, color: Colors.blue),
                const SizedBox(width: 10), const Text('تقرير الإجراءات والأسعار'),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary,
              )),
            ],
          ],
        ),
      ),
    );
  }
}
