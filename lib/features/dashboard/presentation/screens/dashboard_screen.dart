import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../cases/data/models/case_model.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import 'nurse_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isOffline = false;
  final List<StreamSubscription> _subscriptions = [];

  Map<String, dynamic> _stats = {
    'todayCases': 0,
    'totalPatients': 0,
    'todayRevenue': 0.0,
    'availableNurses': 0,
    'pendingCases': 0,
    'inProgressCases': 0,
    'completedCases': 0,
  };

  List<CaseModel> _recentCases = [];
  List<double> _weeklyCounts = List.filled(7, 0.0);
  List<double> _weeklyRevenues = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData(showLoading: true);
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Listen to changes in today's cases
    _subscriptions.add(
      FirebaseService.instance.streamTodayCases().listen((_) {
        _loadDashboardData(showLoading: false);
      }),
    );
    // Listen to attendance changes
    _subscriptions.add(
      FirebaseService.instance.streamTodayAttendanceRecords().listen((_) {
        _loadDashboardData(showLoading: false);
      }),
    );
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _loadDashboardData({bool showLoading = false}) async {
    if (showLoading) setState(() => _isLoading = true);

    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isOffline = true;
            _isLoading = false;
          });
        }
        return;
      }

      final stats = await FirebaseService.instance.getDashboardStats();
      final chartData = await FirebaseService.instance.getDashboardChartData();
      final cases = await FirebaseService.instance.getTodayCases();

      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // الأحدث أولاً
      final recent = cases.take(5).toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentCases = recent;
          _weeklyCounts = chartData['counts']!;
          _weeklyRevenues = chartData['revenues']!;
          _isOffline = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    final isAdmin = user?.role.isAdmin ?? false;

    if (!isAdmin) {
      return const NurseDashboardScreen();
    }

    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                AppStrings.offlineMode,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDashboardData,
                              child: const Text(
                                'إعادة المحاولة',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // === الرأس - Header ===
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // === بطاقات الإحصائيات - Stats Cards ===
                    _buildStatsCards(),
                    const SizedBox(height: 24),

                    // === الرسوم البيانية - Charts ===
                    if (isSmall) ...[
                      _buildCasesChart(),
                      const SizedBox(height: 20),
                      _buildKPIMetricsWidget(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildCasesChart()),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _buildKPIMetricsWidget()),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // === الإيرادات والحالات الأخيرة ===
                    if (isSmall) ...[
                      _buildRevenueChart(),
                      const SizedBox(height: 20),
                      _buildRecentCases(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildRevenueChart()),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _buildRecentCases()),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'صباح الخير'
        : now.hour < 18
        ? 'مساء الخير'
        : 'مساء الخير';
    final user = context.read<AuthCubit>().currentUser;
    final titleSize = ResponsiveHelper.getTitleFontSize(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting ${user?.name ?? ""} 👋',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: isMobile ? 12 : 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              AppStrings.dashboard,
              style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
            ),
          ],
        ),
        // تاريخ اليوم
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showCenterQr(isDeparture: false),
                icon: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
                tooltip: 'عرض كود حضور المركز',
              ),
              IconButton(
                onPressed: () => _showCenterQr(isDeparture: true),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                tooltip: 'عرض كود انصراف المركز',
              ),
              IconButton(
                onPressed: _loadDashboardData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCenterQr({required bool isDeparture}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isDeparture ? 'كود انصراف المركز' : 'كود حضور المركز',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: isDeparture ? 'NEWCARE_DEPARTURE' : 'NEWCARE_ATTENDANCE',
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isDeparture
                    ? 'اطلب من الممرض مسح هذا الكود في نهاية نوبة العمل لتسجيل الانصراف'
                    : 'اطلب من الممرض مسح هذا الكود في بداية نوبة العمل لتسجيل الحضور',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  /// بطاقات الإحصائيات - Stats Cards Grid
  Widget _buildStatsCards() {
    final columns = ResponsiveHelper.getStatCardColumns(context);
    final aspectRatio = ResponsiveHelper.getAspectRatio(context);

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: [
        StatCard(
          title: AppStrings.todayCases,
          value: '${_stats['todayCases']}',
          icon: Icons.medical_services_rounded,
          color: AppColors.info,
          subtitle: 'حالة اليوم',
        ),
        StatCard(
          title: AppStrings.totalRevenue,
          value: NumberFormatter.currency((_stats['todayRevenue'] as double)),
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.success,
          subtitle: 'إيرادات اليوم',
        ),
        StatCard(
          title: 'توزيع الحالات',
          value: '${_stats['todayCases'] > 0 ? ((_stats['completedCases'] / _stats['todayCases']) * 100).toStringAsFixed(0) : 0}%',
          icon: Icons.pie_chart_rounded,
          color: AppColors.secondary,
          subtitle: 'نسبة الإنجاز اليومي',
        ),
        StatCard(
          title: AppStrings.availableNurses,
          value: '${_stats['availableNurses']}',
          icon: Icons.person_rounded,
          color: const Color(0xFF8B5CF6),
          subtitle: 'ممرض نشط',
        ),
      ],
    );
  }

  /// رسم بياني للحالات الأسبوعية - Weekly Cases Bar Chart
  Widget _buildCasesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.casesOverview,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'حالات آخر 7 أيام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (_weeklyCounts.reduce((a, b) => a > b ? a : b) + 5),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final now = DateTime.now();
                      final date = now.subtract(Duration(days: 6 - group.x));
                      final dayName = DateFormat('EEEE', 'ar').format(date);
                      return BarTooltipItem(
                        '$dayName\n${rod.toY.toInt()} حالة',
                        const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final dayInit = DateFormat(
                          'E',
                          'ar',
                        ).format(date).substring(0, 1);
                        return Text(
                          dayInit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.borderLight, strokeWidth: 1);
                  },
                ),
                barGroups: List.generate(
                  7,
                  (i) => _makeBarGroup(i, _weeklyCounts[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          width: 20,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  /// مقاييس الأداء المهنية - Professional KPI Metrics
  Widget _buildKPIMetricsWidget() {
    final totalCases = _stats['todayCases'] as int;
    final completedCases = _stats['completedCases'] as int;
    final availableNurses = _stats['availableNurses'] as int;
    final todayRevenue = _stats['todayRevenue'] as double;

    // حساب المقاييس
    final completionRate = totalCases > 0
        ? (completedCases / totalCases * 100).toStringAsFixed(1)
        : '0.0';
    final casesPerNurse = availableNurses > 0
        ? (totalCases / availableNurses).toStringAsFixed(1)
        : '0.0';
    final avgRevenue = totalCases > 0
        ? (todayRevenue / totalCases).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مؤشرات الأداء',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildKPIRow(
            label: 'معدل الإنجاز',
            value: '$completionRate%',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildKPIRow(
            label: 'حالات لكل ممرض',
            value: casesPerNurse,
            icon: Icons.person_outline_rounded,
            color: AppColors.info,
          ),
          const SizedBox(height: 16),
          _buildKPIRow(
            label: 'متوسط الإيراد',
            value: '$avgRevenue ج.م',
            icon: Icons.attach_money_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// صف مقياس أداء واحد - Single KPI Row
  Widget _buildKPIRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// رسم بياني للإيرادات - Revenue Line Chart
  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.revenueOverview,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'الإيرادات خلال آخر 7 أيام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.borderLight, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        final dayInit = DateFormat(
                          'E',
                          'ar',
                        ).format(date).substring(0, 1);
                        return Text(
                          dayInit,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: (_weeklyRevenues.reduce((a, b) => a > b ? a : b) + 1000),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), _weeklyRevenues[i]),
                    ),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.success,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.success.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// أحدث الحالات - Recent Cases List
  Widget _buildRecentCases() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.recentCases,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentCases.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "لا يوجد حالات اليوم",
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            )
          else
            ..._recentCases.map((c) => _buildRecentCaseItem(c)),
        ],
      ),
    );
  }

  Widget _buildRecentCaseItem(CaseModel caseData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseData.patientName.isNotEmpty
                      ? caseData.patientName
                      : 'مريض غير معروف',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${caseData.caseType.label} • ${DateFormat('hh:mm a').format(caseData.createdAt)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
