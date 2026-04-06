import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// شاشة التقارير - Reports Screen
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'daily';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(AppStrings.reports, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Text('إنشاء وتصدير التقارير', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          // Report type cards
          Row(children: [
            _reportCard('daily', AppStrings.dailyReport, Icons.today_rounded, AppColors.info, 'تقرير بالحالات والإيرادات اليومية'),
            const SizedBox(width: 16),
            _reportCard('cases', AppStrings.casesReport, Icons.medical_services_rounded, AppColors.secondary, 'تقرير شامل بجميع الحالات'),
            const SizedBox(width: 16),
            _reportCard('revenue', AppStrings.revenueReport, Icons.account_balance_wallet_rounded, AppColors.success, 'تقرير الإيرادات والمصروفات'),
            const SizedBox(width: 16),
            _reportCard('inventory', AppStrings.inventoryReport, Icons.inventory_2_rounded, AppColors.warning, 'تقرير حالة المخزون'),
          ]),
          const SizedBox(height: 24),
          // Report options
          Expanded(child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getReportTitle(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _dateField(AppStrings.dateFrom)),
                const SizedBox(width: 16),
                Expanded(child: _dateField(AppStrings.dateTo)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assessment_rounded, size: 18),
                  label: const Text(AppStrings.generateReport, style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(AppStrings.exportPdf, style: TextStyle(fontFamily: 'Cairo')),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ]),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 24),
              Expanded(child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.assessment_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('اختر نوع التقرير والفترة الزمنية ثم اضغط "إنشاء التقرير"', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textHint)),
                ]),
              )),
            ]),
          )),
        ]),
      ),
    );
  }

  String _getReportTitle() {
    switch (_selectedReport) {
      case 'daily': return AppStrings.dailyReport;
      case 'cases': return AppStrings.casesReport;
      case 'revenue': return AppStrings.revenueReport;
      case 'inventory': return AppStrings.inventoryReport;
      default: return AppStrings.dailyReport;
    }
  }

  Widget _reportCard(String value, String title, IconData icon, Color color, String desc) {
    final sel = _selectedReport == value;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedReport = value),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: sel ? color.withValues(alpha: 0.1) : AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? color : AppColors.border, width: sel ? 2 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: sel ? color : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint), maxLines: 2),
        ]))));
  }

  Widget _dateField(String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        readOnly: true,
        onTap: () async {
          await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now(), initialDate: DateTime.now());
        },
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textHint), hintText: 'اختر التاريخ', hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
      ),
    ]);
  }
}
