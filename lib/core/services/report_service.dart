import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/cases/data/models/case_model.dart';
import '../../../features/financials/data/models/expense_model.dart';
import '../constants/app_strings.dart';
import 'package:intl/intl.dart' as intl;

/// خدمة التقارير والفواتير - Reports & Invoices Service
class ReportService {
  static ReportService? _instance;
  ReportService._();
  static ReportService get instance => _instance ??= ReportService._();

  /// إنشاء فاتورة حالة مهنية - Generate Professional Case Invoice
  Future<void> generateCaseInvoice(CaseModel caseData) async {
    final pdf = pw.Document();
    
    // تحميل الخطوط لدعم العربية - Using Google Fonts for reliability
    final ttf = await PdfGoogleFonts.cairoRegular();
    final boldTtf = await PdfGoogleFonts.cairoBold();

    // تحميل الشعار إذا وجد - Load Logo
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // الهيدر - Logo & Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logo != null)
                        pw.Container(
                          width: 40,
                          height: 40,
                          margin: const pw.EdgeInsets.only(left: 10),
                          child: pw.Image(logo),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text('مركز نيو كير للتمريض والخدمات الطبية', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('رقم الفاتورة: #${caseData.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('التاريخ: ${intl.DateFormat('yyyy-MM-dd').format(caseData.caseDate)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
              
              pw.Center(child: pw.Text('فاتورة ضريبية مبسطة', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),

              // بيانات العميل
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _invoiceRow('اسم المريض:', caseData.patientName),
                    _invoiceRow('الخدمة المقدمة:', caseData.caseType.label),
                    _invoiceRow('الممرض المسؤول:', caseData.nurseName),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // التفاصيل المالية
              pw.Table(
                border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey400)),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الوصف', style: const pw.TextStyle(color: PdfColors.white, fontSize: 12))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('المبلغ', style: const pw.TextStyle(color: PdfColors.white, fontSize: 12), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(caseData.caseType.label)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${caseData.totalPrice} ${AppStrings.currency}', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),
              
              // المجموع النهائي
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('الإجمالي المستحق', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 5),
                      pw.Text('${caseData.totalPrice} ${AppStrings.currency}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),
              
              pw.Divider(),
              pw.Center(
                child: pw.Text('شكراً لاختياركم نيو كير لرعايتكم الطبية', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
              pw.Center(
                child: pw.Text('New Care - We Care for Your Health', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ),
            ],
          );
        },
      ),
    );

    // معاينة أو طباعة
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _invoiceRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }

  /// إنشاء تقرير مالي شامل - Generate Financial Report
  Future<void> generateFinancialReport({
    required List<CaseModel> cases,
    required List<ExpenseModel> expenses,
    required DateTime start,
    required DateTime end,
  }) async {
    final pdf = pw.Document();
    
    // تحميل الخطوط لدعم العربية - Using Google Fonts for reliability
    final ttf = await PdfGoogleFonts.cairoRegular();
    final boldTtf = await PdfGoogleFonts.cairoBold();

    double totalIncome = cases.fold(0, (sum, c) => sum + c.totalPrice);
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double netProfit = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Text('تقرير الأداء المالي', style: const pw.TextStyle(fontSize: 16)),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) => [
          pw.Text('الفترة من: ${intl.DateFormat('yyyy-MM-dd').format(start)} إلى: ${intl.DateFormat('yyyy-MM-dd').format(end)}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),

          // ملخص مالي
          pw.Row(
            children: [
              _summaryBox('إجمالي الدخل', '${totalIncome.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.green900),
              pw.SizedBox(width: 10),
              _summaryBox('إجمالي المصروفات', '${totalExpenses.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.red900),
              pw.SizedBox(width: 10),
              _summaryBox('صافي الربح', '${netProfit.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.blue900),
            ],
          ),

          pw.SizedBox(height: 30),
          pw.Text('تفاصيل الدخل (الحالات)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'المريض', 'النوع', 'المبلغ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            data: cases.map((c) => [
              intl.DateFormat('yyyy-MM-dd').format(c.caseDate),
              c.patientName,
              c.caseType.label,
              '${c.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}',
            ]).toList(),
          ),

          pw.SizedBox(height: 30),
          pw.Text('تفاصيل المصروفات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'البند', 'الوصف', 'المبلغ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            data: expenses.map((e) => [
              intl.DateFormat('yyyy-MM-dd').format(e.date),
              e.category,
              e.label,
              '${e.amount.toStringAsFixed(0)} ${AppStrings.currency}',
            ]).toList(),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('تم استخراج هذا التقرير آلياً من نظام نيو كير', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _summaryBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
