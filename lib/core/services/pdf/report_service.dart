import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/financials/data/models/expense_model.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/features/shifts/data/models/shift_model.dart';
import 'package:new_care/core/constants/app_strings.dart';
import 'package:intl/intl.dart' as intl;

/// خدمة التقارير والفواتير - Reports & Invoices Service
class ReportService {
  static ReportService? _instance;
  ReportService._();
  static ReportService get instance => _instance ??= ReportService._();

  // ============================================
  // === الخطوط والثوابت - Fonts & Constants ===
  // ============================================

  Future<pw.Font> _getFont() async => await PdfGoogleFonts.cairoRegular();
  Future<pw.Font> _getBoldFont() async => await PdfGoogleFonts.cairoBold();

  Future<pw.MemoryImage?> _getLogo() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildHeader(
    pw.Font boldTtf,
    pw.MemoryImage? logo,
    String subtitle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: 50,
                  height: 50,
                  margin: const pw.EdgeInsets.only(left: 12),
                  child: pw.Image(logo),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppStrings.appName,
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'مركز نيو كير للرعاية الطبية والتمريض المنزلي',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              subtitle,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
                font: boldTtf,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _reportStatCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          boxShadow: [
            pw.BoxShadow(color: PdfColors.grey200, blurRadius: 2, offset: const PdfPoint(0, 1))
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // === فاتورة حالة - Case Invoice ===
  // ============================================

  /// إنشاء فاتورة حالة - Generate Case Invoice PDF bytes
  Future<Uint8List> generateCaseInvoiceBytes(CaseModel caseData) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo
                if (logo != null)
                  pw.Container(
                    width: 70, // زيادة حجم الشعار كما في الواجهة
                    height: 70,
                    child: pw.Image(logo),
                  ),
                pw.SizedBox(height: 2),

                // Header
                pw.Text(
                  AppStrings.appName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'مركز نيو كير للرعاية الطبية',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 8),

                pw.Text(
                  'فاتورة مبسطة',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),

                // Info Rows
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'رقم الفاتورة:',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      '#${caseData.id.substring(0, 8).toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التاريخ:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(
                      intl.DateFormat(
                        'yyyy/MM/dd HH:mm',
                      ).format(caseData.caseDate),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 8),

                // Patient Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المريض:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      caseData.patientName,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الممرض:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      caseData.nurseName,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Items Table
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            'البيان',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            'الكمية',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            'المبلغ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    ...caseData.services.map(
                      (s) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              s.name,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${s.quantity}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${s.total}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...caseData.suppliesUsed.map(
                      (su) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${su.name} (مستلزم)',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${su.quantity}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${su.total}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 5),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'المجموع الفرعي:',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      '${caseData.totalPrice} ${AppStrings.currency}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (caseData.discount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الخصم:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                        '-${caseData.discount} ${AppStrings.currency}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  color: PdfColors.grey200,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'الإجمالي النهائي:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${caseData.totalPrice - caseData.discount} ${AppStrings.currency}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 15),
                pw.Container(
                  width: 60,
                  height: 60,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: caseData.id,
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Text(
                  'نتمنى لكم الشفاء العاجل',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'شكراً لاختياركم نيو كير',
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// طباعة فاتورة حالة - Print case invoice
  Future<void> generateCaseInvoice(CaseModel caseData) async {
    final bytes = await generateCaseInvoiceBytes(caseData);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Invoice-${caseData.patientName}',
    );
  }

  /// مشاركة فاتورة حالة - Share case invoice
  Future<void> shareCaseInvoice(CaseModel caseData) async {
    final bytes = await generateCaseInvoiceBytes(caseData);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Invoice-${caseData.patientName}.pdf',
    );
  }

  // ============================================
  // === التقرير المالي - Financial Report ===
  // ============================================

  /// إنشاء بايتات التقرير المالي - Generate Financial Report Bytes
  Future<Uint8List> generateFinancialReportBytes({
    required List<CaseModel> cases,
    required List<ExpenseModel> expenses,
    required DateTime start,
    required DateTime end,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    double totalIncome = cases.fold(
      0,
      (sum, c) => sum + (c.totalPrice - c.discount),
    );
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double netProfit = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              _buildHeader(boldTtf, logo, 'تقرير مالي شامل'),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الفترة من: ${intl.DateFormat('yyyy-MM-dd').format(start)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'إلى: ${intl.DateFormat('yyyy-MM-dd').format(end)}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                pw.Row(
                  children: [
                    _reportStatCard(
                      'إجمالي الأداء (إيراد)',
                      '${totalIncome.toStringAsFixed(0)} ${AppStrings.currency}',
                      PdfColors.green800,
                    ),
                    pw.SizedBox(width: 15),
                    _reportStatCard(
                      'إجمالي المصاريف',
                      '${totalExpenses.toStringAsFixed(0)} ${AppStrings.currency}',
                      PdfColors.red800,
                    ),
                    pw.SizedBox(width: 15),
                    _reportStatCard(
                      'صافي الأرباح',
                      '${netProfit.toStringAsFixed(0)} ${AppStrings.currency}',
                      PdfColors.blue900,
                    ),
                  ],
                ),

                pw.SizedBox(height: 35),
                pw.Text(
                  'تفاصيل الدخل (عمليات الحالات)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  headers: [
                    '#',
                    'التاريخ',
                    'اسم المريض',
                    'النوع',
                    'الممرض',
                    'المبلغ',
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  cellPadding: const pw.EdgeInsets.all(6),
                  cellAlignments: {
                    0: pw.Alignment.center,
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
                      (c.totalPrice - c.discount).toStringAsFixed(0),
                    ];
                  }),
                ),

                pw.SizedBox(height: 35),
                pw.Text(
                  'تفصيل المصروفات',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  headers: ['التاريخ', 'التصنيف', 'البيان', 'القيمة'],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.red900,
                  ),
                  cellPadding: const pw.EdgeInsets.all(6),
                  data: expenses
                      .map(
                        (e) => [
                          intl.DateFormat('yyyy-MM-dd').format(e.date),
                          e.category,
                          e.label,
                          '${e.amount.toStringAsFixed(0)} ${AppStrings.currency}',
                        ],
                      )
                      .toList(),
                ),

                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'توقيع المدير المسؤول',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 150,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'هذا التقرير مخصص للاستخدام الداخلي بمركز نيو كير',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ============================================
  // === تقرير الحالات (تقرير العمل) - Cases/Work Report ===
  // ============================================

  /// إنشاء بايتات تقرير الحالات (العمل) - Generate Cases Report Bytes
  Future<Uint8List> generateCasesReportBytes({
    required List<CaseModel> cases,
    required String title,
    required String subtitle,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              _buildHeader(boldTtf, logo, title),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      subtitle,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                pw.TableHelper.fromTextArray(
                  headers: [
                    '#',
                    'التاريخ',
                    'اسم المريض',
                    'النوع',
                    'الممرض',
                    'المبلغ',
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  cellPadding: const pw.EdgeInsets.all(8),
                  data: List<List<dynamic>>.generate(cases.length, (index) {
                    final c = cases[index];
                    return [
                      index + 1,
                      intl.DateFormat('yyyy-MM-dd').format(c.caseDate),
                      c.patientName,
                      c.caseType.label,
                      c.nurseName,
                      (c.totalPrice - c.discount).toStringAsFixed(1),
                    ];
                  }),
                ),

                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'إجمالي عدد الحالات: ${cases.length}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'إجمالي الإيرادات: ${cases.fold(0.0, (sum, c) => sum + (c.totalPrice - c.discount)).toStringAsFixed(1)} ${AppStrings.currency}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'مركز نيو كير - تقرير أداء العمل',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ============================================
  // === تقرير الموظفين الشهري - Monthly Staff Report ===
  // ============================================

  /// تقرير ساعات العمل الشهري لكل ممرض بناءً على الحضور والورديات - بايتات
  Future<Uint8List> generateMonthlyStaffReportBytes({
    required int year,
    required int month,
    required List<AttendanceModel> attendanceRecords,
    required List<ShiftModel> shifts,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    final monthName = intl.DateFormat(
      'MMMM yyyy',
      'ar',
    ).format(DateTime(year, month));

    // تجميع البيانات حسب المستخدم
    final Map<String, _StaffSummary> staffMap = {};

    for (final shift in shifts) {
      staffMap.putIfAbsent(
        shift.userId,
        () => _StaffSummary(name: shift.userName),
      );
      staffMap[shift.userId]!.totalShifts++;
    }

    for (final record in attendanceRecords) {
      staffMap.putIfAbsent(
        record.userId,
        () => _StaffSummary(name: record.userName),
      );
      final summary = staffMap[record.userId]!;
      summary.totalAttendance++;

      if (record.checkOutTime != null) {
        final duration = record.checkOutTime!.difference(record.checkInTime);
        summary.totalMinutes += duration.inMinutes;
      }
    }

    final staffList = staffMap.entries.toList();
    int totalAllMinutes = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalMinutes,
    );
    int totalAllShifts = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalShifts,
    );
    int totalAllAttendance = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalAttendance,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              _buildHeader(boldTtf, logo, 'تقرير الموظفين الشهري'),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // معلومات التقرير
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الشهر: $monthName',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // كروت الملخص
                pw.Row(
                  children: [
                    _reportStatCard(
                      'إجمالي الورديات',
                      '$totalAllShifts وردية',
                      PdfColors.blue900,
                    ),
                    pw.SizedBox(width: 15),
                    _reportStatCard(
                      'إجمالي الحضور',
                      '$totalAllAttendance سجل',
                      PdfColors.green800,
                    ),
                    pw.SizedBox(width: 15),
                    _reportStatCard(
                      'إجمالي الساعات',
                      '${(totalAllMinutes / 60).toStringAsFixed(1)} ساعة',
                      PdfColors.orange900,
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // جدول الموظفين
                pw.Text(
                  'تفاصيل ساعات العمل لكل موظف',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  headers: [
                    '#',
                    'اسم الموظف',
                    'عدد الورديات',
                    'أيام الحضور',
                    'إجمالي الساعات',
                    'متوسط يومي',
                  ],
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  cellPadding: const pw.EdgeInsets.all(8),
                  data: List<List<dynamic>>.generate(staffList.length, (i) {
                    final entry = staffList[i];
                    final s = entry.value;
                    final totalHours = (s.totalMinutes / 60).toStringAsFixed(1);
                    final avgDaily = s.totalAttendance > 0
                        ? (s.totalMinutes / 60 / s.totalAttendance)
                              .toStringAsFixed(1)
                        : '0.0';
                    return [
                      i + 1,
                      s.name,
                      '${s.totalShifts}',
                      '${s.totalAttendance}',
                      '$totalHours ساعة',
                      '$avgDaily ساعة',
                    ];
                  }),
                ),

                pw.SizedBox(height: 40),

                // تفاصيل يومية لكل موظف
                ...staffList.map((entry) {
                  final userAttendance = attendanceRecords
                      .where((a) => a.userId == entry.key)
                      .toList();
                  if (userAttendance.isEmpty) return pw.SizedBox();

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'تفاصيل حضور: ${entry.value.name}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.TableHelper.fromTextArray(
                        headers: [
                          'التاريخ',
                          'وقت الحضور',
                          'وقت الانصراف',
                          'المدة',
                          'الحالة',
                        ],
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.grey700,
                        ),
                        cellPadding: const pw.EdgeInsets.all(5),
                        data: userAttendance.map((a) {
                          final checkIn = intl.DateFormat(
                            'hh:mm a',
                          ).format(a.checkInTime);
                          final checkOut = a.checkOutTime != null
                              ? intl.DateFormat(
                                  'hh:mm a',
                                ).format(a.checkOutTime!)
                              : '---';
                          final duration = a.shiftDuration != null
                              ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m'
                              : '---';
                          return [
                            a.date,
                            checkIn,
                            checkOut,
                            duration,
                            a.status.label,
                          ];
                        }).toList(),
                      ),
                    ],
                  );
                }),

                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'أَعد التقرير',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          generatedBy,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'توقيع المدير المسؤول',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 35),
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'تقرير الموظفين الشهري - مركز نيو كير',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'صفحة ${context.pageNumber} من ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// طباعة تقرير الحضور الشهري - Print Monthly Attendance Report
  Future<void> generateAttendanceReport({
    required int year,
    required int month,
    required List<AttendanceModel> records,
    required List<ShiftModel> shifts,
    String generatedBy = 'مدير النظام',
  }) async {
    final bytes = await generateMonthlyStaffReportBytes(
      year: year,
      month: month,
      attendanceRecords: records,
      shifts: shifts,
      generatedBy: generatedBy,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Staff-Report-$month-$year',
    );
  }

  /// إنشاء بايتات تقرير لممرض واحد - Generate PDF bytes for a single nurse report
  Future<Uint8List> generateSingleNurseReportBytes({
    required int year,
    required int month,
    required String nurseName,
    required List<AttendanceModel> attendanceRecords,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    final monthName = intl.DateFormat(
      'MMMM yyyy',
      'ar',
    ).format(DateTime(year, month));

    int totalMinutes = 0;
    for (var r in attendanceRecords) {
      if (r.checkOutTime != null) {
        totalMinutes += r.checkOutTime!.difference(r.checkInTime).inMinutes;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Column(
          children: [
            _buildHeader(boldTtf, logo, 'تقرير أداء ممرض'),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'اسم الموظف: $nurseName',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'الشهر: $monthName',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'إجمالي الساعات: ${(totalMinutes / 60).toStringAsFixed(1)} ساعة',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          pw.TableHelper.fromTextArray(
            headers: [
              'التاريخ',
              'وقت الحضور',
              'وقت الانصراف',
              'المدة',
              'الحالة',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellPadding: const pw.EdgeInsets.all(8),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            data: attendanceRecords.map((a) {
              final checkIn = intl.DateFormat('hh:mm a').format(a.checkInTime);
              final checkOut = a.checkOutTime != null
                  ? intl.DateFormat('hh:mm a').format(a.checkOutTime!)
                  : '---';
              final duration = a.shiftDuration != null
                  ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m'
                  : '---';
              return [a.date, checkIn, checkOut, duration, a.status.label];
            }).toList(),
          ),

          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    'أَعد التقرير',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(generatedBy, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    'توقيع الموظف',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    'توقيع المدير المسؤول',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 35),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
            ],
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تقرير أداء فردي - مركز نيو كير',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ============================================
  // === تقرير المخزون - Inventory Report ===
  // ============================================

  /// تقرير المخزون mع التنبيهات
  Future<void> generateInventoryReport({
    required List<Map<String, dynamic>> inventoryData,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Column(
          children: [
            _buildHeader(boldTtf, logo, 'تقرير المخزون'),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) => [
          pw.Text(
            'حالة المستلزمات الطبية',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 15),

          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'اسم المستلزم',
              'الفئة',
              'الكمية الحالية',
              'الحد الأدنى',
              'السعر',
              'الحالة',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(inventoryData.length, (i) {
              final item = inventoryData[i];
              final qty = item['quantity'] as int;
              final minQty = item['minQuantity'] as int;
              final status = qty <= 0
                  ? 'نفد'
                  : qty <= minQty
                  ? 'منخفض'
                  : 'متوفر';
              return [
                i + 1,
                item['name'],
                item['category'] ?? '-',
                '$qty',
                '$minQty',
                '${item['price']} ${AppStrings.currency}',
                status,
              ];
            }),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'تقرير المخزون - مركز نيو كير',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventory_Report',
    );
  }
}

/// نموذج مساعد داخلي لتجميع بيانات الموظف
class _StaffSummary {
  final String name;
  int totalShifts = 0;
  int totalAttendance = 0;
  int totalMinutes = 0;

  _StaffSummary({required this.name});
}

