import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/report_service.dart';
import '../../../cases/data/models/case_model.dart';
import 'package:intl/intl.dart';

/// شاشة معاينة الفاتورة - Invoice Preview Screen
/// تعرض الفاتورة مع خيارات الطباعة والمشاركة والحفظ
class InvoicePreviewScreen extends StatelessWidget {
  final CaseModel caseData;

  const InvoicePreviewScreen({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معاينة الفاتورة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '#${caseData.id.substring(0, 6).toUpperCase()} • ${DateFormat('yyyy/MM/dd').format(caseData.caseDate)}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // زر الطباعة
          _ActionButton(
            icon: Icons.print_rounded,
            label: 'طباعة',
            color: AppColors.primary,
            onTap: () => ReportService.instance.generateCaseInvoice(caseData),
          ),
          const SizedBox(width: 8),
          // زر المشاركة
          _ActionButton(
            icon: Icons.share_rounded,
            label: 'مشاركة',
            color: AppColors.info,
            onTap: () => ReportService.instance.shareCaseInvoice(caseData),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // شريط المعلومات السريعة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _InfoChip(label: 'المريض', value: caseData.patientName, icon: Icons.person_rounded),
                const SizedBox(width: 16),
                _InfoChip(label: 'النوع', value: caseData.caseType.label, icon: Icons.category_rounded),
                const SizedBox(width: 16),
                _InfoChip(label: 'الممرض', value: caseData.nurseName, icon: Icons.local_hospital_rounded),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(caseData.totalPrice - caseData.discount).toStringAsFixed(0)} E.P',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // عرض الفاتورة PDF مباشرة
          Expanded(
            child: FutureBuilder<Uint8List>(
              future: ReportService.instance.generateCaseInvoiceBytes(caseData),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('جاري تحضير الفاتورة...', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في تحضير الفاتورة: ${snapshot.error}', style: const TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
                  );
                }
                if (snapshot.hasData) {
                  final pdfBytes = snapshot.data!;
                  return PdfPreview(
                    build: (format) async => pdfBytes,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: 'Invoice_${caseData.id.substring(0, 6)}.pdf',
                    actions: const [], // الأزرار في AppBar
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppColors.textHint)),
            Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
