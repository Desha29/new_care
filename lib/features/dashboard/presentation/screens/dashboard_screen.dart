import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/utils/responsive_helper.dart';
import 'package:new_care/core/utils/ui_feedback.dart';
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:new_care/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:new_care/features/dashboard/presentation/screens/nurse_dashboard_screen.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:new_care/features/dashboard/presentation/widgets/stats_cards_grid.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_weekly_chart.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_kpi_metrics.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_revenue_chart.dart';
import 'package:new_care/features/dashboard/presentation/widgets/dashboard_recent_cases.dart';
import 'package:new_care/features/reports/presentation/screens/report_preview_screen.dart';
import 'package:new_care/core/services/reports/report_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllCases;
  const DashboardScreen({super.key, this.onViewAllCases});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboardData();
  }

  Widget _buildReportButtons(Map<String, dynamic> stats) {
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
          Text('التقارير', style: TextStyle(
            fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
          )),
          const Spacer(),
          _dashReportButton(
            icon: Icons.summarize_rounded,
            label: 'تقرير سريع',
            onTap: () => _generateDashboardQuickReport(stats),
          ),
          const SizedBox(width: 8),
          _dashReportButton(
            icon: Icons.more_horiz_rounded,
            label: 'جميع التقارير',
            onTap: () => _showDashboardReportsMenu(stats),
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _dashReportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final color = isSecondary ? AppColors.secondary : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: color,
            )),
          ],
        ),
      ),
    );
  }

  void _generateDashboardQuickReport(Map<String, dynamic> stats) async {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.cairoRegular();
    final boldTtf = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ملخص لوحة التحكم', style: pw.TextStyle(font: boldTtf, fontSize: 22)),
              pw.SizedBox(height: 20),
              pw.Text('تاريخ التقرير: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['المؤشر', 'القيمة'],
                data: [
                ['إجمالي الحالات اليوم', '${stats['todayCases'] ?? 0}'],
                ['حالات المركز', '${stats['centerCases'] ?? 0}'],
                ['زيارات منزلية', '${stats['homeCases'] ?? 0}'],
                ['إيرادات اليوم', '${(stats['todayRevenue'] ?? 0.0) as double} E.P'],
                ['مصروفات اليوم', '${(stats['todayExpenses'] ?? 0.0) as double} E.P'],
                ['الممرضون المتاحون', '${stats['availableNurses'] ?? 0}'],
                ],
                headerStyle: pw.TextStyle(font: boldTtf, fontSize: 11, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.centerLeft},
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            title: 'ملخص لوحة التحكم',
            fileName: 'Dashboard_Summary_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
            buildReport: () async => bytes!,
          ),
        ),
      );
    }
  }

  void _showDashboardReportsMenu(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assessment_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('جميع التقارير', style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.summarize_rounded, color: AppColors.primary),
              title: const Text('ملخص Dashboard', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () { Navigator.pop(ctx); _generateDashboardQuickReport(stats); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final isAdmin = user?.role.isAdmin ?? false;

    if (!isAdmin) {
      return NurseDashboardScreen(onViewAll: widget.onViewAllCases);
    }

    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardError) {
          return Scaffold(
            body: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is DashboardLoaded) {
          final stats = state.stats;
          final recentCases = state.recentCases;
          final weeklyCounts = state.chartData['counts'] ?? List.filled(7, 0.0);
          final weeklyRevenues = state.chartData['revenues'] ?? List.filled(7, 0.0);

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DashboardHeader(),
                          const SizedBox(height: 12),
                          _buildReportButtons(state.stats),
                          const SizedBox(height: 24),
                          StatsCardsGrid(stats: stats),
                          const SizedBox(height: 24),

                          if (isSmall) ...[
                            DashboardWeeklyChart(weeklyCounts: weeklyCounts),
                            const SizedBox(height: 20),
                            DashboardKpiMetrics(stats: stats),
                            const SizedBox(height: 20),
                            DashboardRevenueChart(weeklyRevenues: weeklyRevenues),
                            const SizedBox(height: 20),
                            DashboardRecentCases(recentCases: recentCases),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      DashboardWeeklyChart(weeklyCounts: weeklyCounts),
                                      const SizedBox(height: 20),
                                      DashboardRevenueChart(weeklyRevenues: weeklyRevenues),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      DashboardKpiMetrics(stats: stats),
                                      const SizedBox(height: 20),
                                      DashboardRecentCases(recentCases: recentCases),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
