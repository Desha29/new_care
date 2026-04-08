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
    
    // تحميل الخطوط لدعم العربية
    final ttf = await PdfGoogleFonts.cairoRegular();
    final boldTtf = await PdfGoogleFonts.cairoBold();

    // تحميل الشعار إذا وجد
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
              // الهيدر الاحترافي
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logo != null)
                        pw.Container(
                          width: 45,
                          height: 45,
                          margin: const pw.EdgeInsets.only(left: 10),
                          child: pw.Image(logo),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text('مركز نيو كير للرعاية الطبية والتمريض المنزلي', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: const pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                        child: pw.Text('فاتورة رقم: #${caseData.id.substring(0, 6).toUpperCase()}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('تاريخ الإدراج: ${intl.DateFormat('yyyy/MM/dd').format(caseData.caseDate)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              // بيانات المريض مع ممرات تصميمية
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('إلى السيد / المريض:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(caseData.patientName, style: const pw.TextStyle(fontSize: 14)),
                        if (caseData.patientPhone.isNotEmpty) pw.Text('رقم الهاتف: ${caseData.patientPhone}', style: const pw.TextStyle(fontSize: 9)),
                        if (caseData.patientAddress.isNotEmpty) pw.Text('العنوان: ${caseData.patientAddress}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('نوع الخدمة:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(caseData.caseType.label, style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('القائم بالخدمة:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(caseData.nurseName, style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // جدول الخدمات بالتفصيل
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البيان / الخدمة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('الكمية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('المبلغ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  // إضافة الخدمات
                  ...caseData.services.map((s) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${s.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${s.total} ${AppStrings.currency}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                  // إضافة المستلزمات (إن وجدت)
                  ...caseData.suppliesUsed.map((su) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.name} (مستلزم)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.total} ${AppStrings.currency}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                ],
              ),

              pw.SizedBox(height: 15),
              
              // ملخص الحساب
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      children: [
                        _summaryLine('المجموع:', '${caseData.totalPrice} ${AppStrings.currency}', false),
                        _summaryLine('الخصم:', '0 ${AppStrings.currency}', false),
                        pw.Divider(color: PdfColors.blue900, thickness: 1),
                        _summaryLine('الإجمالي الصافي:', '${caseData.totalPrice} ${AppStrings.currency}', true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              
              // فوتر
              pw.Container(
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('صدرت بواسطة: ${caseData.nurseName}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text('شكراً لاختياركم نيو كير لرعايتكم', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('صفحة 1/1', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // معاينة أو طباعة
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Invoice-${caseData.patientName}');
  }

  pw.Widget _summaryLine(String label, String value, bool isBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isBold ? PdfColors.blue900 : PdfColors.black)),
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
    
    // تحميل الخطوط لدعم العربية
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
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('نظام إدارة مركز التمريض والخدمات الطبية', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(5))),
                  child: pw.Text('تقرير مالي رسمي', style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الفترة من: ${intl.DateFormat('yyyy-MM-dd').format(start)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('إلى: ${intl.DateFormat('yyyy-MM-dd').format(end)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 25),

          // كروت الملخص المالي بتصميم جديد
          pw.Row(
            children: [
                 _reportStatCard('إجمالي الأداء (إيراد)', '${totalIncome.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.green800),
                 pw.SizedBox(width: 15),
                 _reportStatCard('إجمالي المصاريف', '${totalExpenses.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.red800),
                 pw.SizedBox(width: 15),
                 _reportStatCard('صافي الأرباح', '${netProfit.toStringAsFixed(0)} ${AppStrings.currency}', PdfColors.blue900),
            ],
          ),

          pw.SizedBox(height: 35),
          pw.Text('تفاصيل الدخل (عمليات الحالات المرضية)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['#', 'التاريخ', 'اسم المريض', 'النوع', 'الممرض', 'المبلغ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
            },
            data: List<List<dynamic>>.generate(cases.length, (index) {
              final c = cases[index];
              return [
                index + 1,
                intl.DateFormat('MM/dd').format(c.caseDate),
                c.patientName,
                c.caseType.label,
                c.nurseName,
                '${c.totalPrice.toStringAsFixed(0)}'
              ];
            }),
          ),

          pw.SizedBox(height: 35),
          pw.Text('تفصيل المصروفات والبنود المالية', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'التصنيف', 'البيان الوصفي', 'القيمة'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
            cellPadding: const pw.EdgeInsets.all(6),
            data: expenses.map((e) => [
              intl.DateFormat('yyyy-MM-dd').format(e.date),
              e.category,
              e.label,
              '${e.amount.toStringAsFixed(0)} ${AppStrings.currency}',
            ]).toList(),
          ),
          
          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
               pw.Column(
                 children: [
                   pw.Text('توقيع المدير المسؤول', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                   pw.SizedBox(height: 40),
                   pw.Container(width: 150, height: 1, color: PdfColors.black),
                 ]
               )
            ]
          )
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('هذا التقرير مخصص للاستخدام الداخلي بمركز نيو كير', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Financial_Report_${intl.DateFormat('yyyy_MM').format(start)}');
  }

  pw.Widget _reportStatCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border(right: pw.BorderSide(color: color, width: 4)),
          boxShadow: const [pw.BoxShadow(color: PdfColors.grey200, blurRadius: 3)],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

}
