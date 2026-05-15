import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/financials_cubit.dart';

class FinancialCharts extends StatelessWidget {
  final FinancialsLoaded state;

  const FinancialCharts({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (!isDesktop) {
      return Column(
        children: [
          _buildTrendChart(context),
          const SizedBox(height: 24),
          _buildCategoryPieChart(context),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTrendChart(context),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildCategoryPieChart(context),
        ),
      ],
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final Map<String, double> incomeByDate = {};
    final Map<String, double> expensesByDate = {};
    
    final now = DateTime.now();
    final List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      last7Days.add(dateStr);
      incomeByDate[dateStr] = 0;
      expensesByDate[dateStr] = 0;
    }

    for (var c in state.cases) {
      final dateStr = DateFormat('yyyy-MM-dd').format(c.createdAt);
      if (incomeByDate.containsKey(dateStr)) {
        incomeByDate[dateStr] = incomeByDate[dateStr]! + c.totalPrice;
      }
    }

    for (var e in state.expenses) {
      final dateStr = DateFormat('yyyy-MM-dd').format(e.date);
      if (expensesByDate.containsKey(dateStr)) {
        expensesByDate[dateStr] = expensesByDate[dateStr]! + e.amount;
      }
    }

    final incomeSpots = List.generate(7, (i) => FlSpot(i.toDouble(), incomeByDate[last7Days[i]]!));
    final expenseSpots = List.generate(7, (i) => FlSpot(i.toDouble(), expensesByDate[last7Days[i]]!));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل التدفقات المالية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _indicator(AppColors.primary, 'الإيرادات'),
              const SizedBox(width: 16),
              _indicator(Colors.red, 'المصاريف'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= 7) return const SizedBox.shrink();
                        final dateStr = last7Days[value.toInt()];
                        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E', 'ar').format(date),
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context) {
    final Map<String, double> categorySums = {};
    for (var e in state.expenses) {
      categorySums[e.category] = (categorySums[e.category] ?? 0) + e.amount;
    }

    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع المصاريف',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: List.generate(topCategories.length, (i) {
                  final cat = topCategories[i];
                  return PieChartSectionData(
                    color: _getColor(i),
                    value: cat.value,
                    title: '${((cat.value / state.totalExpenses) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(topCategories.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _indicator(_getColor(i), topCategories[i].key),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _getColor(int index) {
    final colors = [AppColors.primary, Colors.red, Colors.orange, Colors.blue, Colors.teal];
    return colors[index % colors.length];
  }
}
