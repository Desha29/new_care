import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/financials/data/models/expense_model.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/features/shifts/data/models/shift_model.dart';
import 'package:new_care/features/payroll/data/models/payroll_model.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/procedures/data/models/procedure_model.dart';
import 'package:new_care/core/constants/app_strings.dart';
import 'package:intl/intl.dart' as intl;
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;

/// خدمة التقارير والفواتير - Reports & Invoices Service
class ReportService {
  static ReportService? _instance;
  ReportService._();
  static ReportService get instance => _instance ??= ReportService._();

  // ============================================
  // === الخطوط والثوابت - Fonts & Constants ===
  // ============================================

  pw.Font? _cachedFont;
  pw.Font? _cachedBoldFont;
  pw.Font? _cachedFallbackFont;

  Future<pw.Font> _getFont() async {
    _cachedFont ??= await PdfGoogleFonts.cairoRegular();
    return _cachedFont!;
  }

  Future<pw.Font> _getBoldFont() async {
    _cachedBoldFont ??= await PdfGoogleFonts.cairoBold();
    return _cachedBoldFont!;
  }

  Future<pw.Font> _getFallbackFont() async {
    _cachedFallbackFont ??= await PdfGoogleFonts.notoSansArabicRegular();
    return _cachedFallbackFont!;
  }

  Future<pw.MemoryImage?> _getLogo() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  String _shape(String text) {
    if (text.isEmpty) return text;

    // Step 1: Reshape Arabic glyphs so letters connect properly
    final reshaped = ArabicReshaper().reshape(text);

    // Step 2: Apply the Unicode BiDi algorithm
    // We use logicalToVisual to ensure RTL text is displayed correctly in LTR PDF viewers
    // but we wrap numbers to keep them logical
    final visualCodes = bidi.logicalToVisual(reshaped);

    return String.fromCharCodes(visualCodes);
  }

  pw.Widget _buildHeader(
    pw.Font boldTtf,
    pw.MemoryImage? logo,
    String subtitle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5),
        ),
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
                    _shape(AppStrings.appName),
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    _shape('مركز نيو كير للرعاية الطبية والتمريض المنزلي'),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              _shape(subtitle),
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
          border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              blurRadius: 3,
              offset: const PdfPoint(0, 2),
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _shape(title),
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              _shape(value),
              style: pw.TextStyle(
                fontSize: 20,
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
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.ltr,
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
                  _shape(AppStrings.appName),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _shape('مركز نيو كير للرعاية الطبية'),
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 8),

                pw.Text(
                  _shape('فاتورة مبسطة'),
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
                      _shape('رقم الفاتورة:'),
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
                    pw.Text(
                      _shape('التاريخ:'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
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
                    pw.Text(
                      _shape('المريض:'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      _shape(caseData.patientName),
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
                    pw.Text(
                      _shape('الممرض:'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      _shape(caseData.nurseName),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      _shape('طريقة الدفع:'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      _shape(
                        caseData.paymentMethod == 'wallet'
                            ? 'محفظة إلكترونية'
                            : 'كاش',
                      ),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
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
                            _shape('البيان'),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            _shape('الكمية'),
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
                            _shape('المبلغ'),
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
                              _shape(s.name),
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
                              _shape('${su.name} (مستلزم)'),
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
                      _shape('المجموع الفرعي:'),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      '${caseData.totalPrice} ${_shape(AppStrings.currency)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
                if (caseData.discount > 0)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _shape('الخصم:'),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.Text(
                        '-${caseData.discount} ${_shape(AppStrings.currency)}',
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
                        _shape('الإجمالي النهائي:'),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            '${caseData.totalPrice - caseData.discount} ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            _shape(AppStrings.currency),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
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
                  _shape('نتمنى لكم الشفاء العاجل'),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _shape('شكراً لاختياركم نيو كير'),
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
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, _shape('تقرير مالي شامل للمركز')),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        intl.DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('تاريخ الاستخراج:'),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '${intl.DateFormat('yyyy/MM/dd').format(start)} - ${intl.DateFormat('yyyy/MM/dd').format(end)}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الفترة من:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          pw.Row(
            children: [
              _reportStatCard(
                'صافي الأرباح',
                '${netProfit.toStringAsFixed(1)} E.P',
                PdfColors.blue900,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي المصاريف',
                '${totalExpenses.toStringAsFixed(1)} E.P',
                PdfColors.red800,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي الدخل',
                '${totalIncome.toStringAsFixed(1)} E.P',
                PdfColors.green800,
              ),
            ],
          ),

          pw.SizedBox(height: 35),
          pw.Text(
            _shape('تفاصيل الدخل (عمليات الحالات)'),
            style: pw.TextStyle(
              font: boldTtf,
              fontSize: 15,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'المبلغ',
              'الممرض',
              'النوع',
              'اسم المريض',
              'التاريخ',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              5: pw.Alignment.center,
              4: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              2: pw.Alignment.center,
              1: pw.Alignment.centerRight,
              0: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(cases.length, (index) {
              final c = cases[index];
              return [
                (c.totalPrice - c.discount).toStringAsFixed(1),
                _shape(c.nurseName),
                _shape(c.caseType.label),
                _shape(c.patientName),
                intl.DateFormat('MM/dd').format(c.caseDate),
                index + 1,
              ];
            }),
          ),

          pw.SizedBox(height: 35),
          pw.Text(
            _shape('تفصيل المصروفات'),
            style: pw.TextStyle(
              font: boldTtf,
              fontSize: 15,
              color: PdfColors.red900,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'القيمة',
              'البيان',
              'التصنيف',
              'التاريخ',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              3: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              1: pw.Alignment.centerRight,
              0: pw.Alignment.center,
            },
            data: expenses
                .map(
                  (e) => [
                    e.amount.toStringAsFixed(1),
                    _shape(e.label),
                    _shape(e.category),
                    intl.DateFormat('yyyy/MM/dd').format(e.date),
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
                    _shape('توقيع المدير المسؤول'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 12),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
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
                  _shape('تقرير مالي - نيو كير للرعاية الطبية'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, _shape(title)),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '${cases.length}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(_shape('إجمالي الحالات:')),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _shape(subtitle),
                    style: pw.TextStyle(font: boldTtf, fontSize: 13),
                  ),
                  pw.Text(
                    _shape(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                    ),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'المبلغ',
              'الممرض',
              'النوع',
              'اسم المريض',
              'التاريخ',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              5: pw.Alignment.center,
              4: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              2: pw.Alignment.center,
              1: pw.Alignment.centerRight,
              0: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(cases.length, (index) {
              final c = cases[index];
              return [
                (c.totalPrice - c.discount).toStringAsFixed(1),
                _shape(c.nurseName),
                _shape(c.caseType.label),
                _shape(c.patientName),
                intl.DateFormat('MM/dd').format(c.caseDate),
                index + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 35),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${cases.fold(0.0, (sum, c) => sum + (c.totalPrice - c.discount)).toStringAsFixed(2)} E.P',
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 18,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  _shape('إجمالي إيرادات العمل:'),
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 13,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _shape('تقرير أداء العمل - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, _shape('تقرير الموظفين الشهري')),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        intl.DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('تاريخ الاستخراج:'),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _shape('الفترة: $monthName'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // كروت الملخص
          pw.Row(
            children: [
              _reportStatCard(
                'إجمالي الساعات',
                '${(totalAllMinutes / 60).toStringAsFixed(1)} ساعة',
                PdfColors.orange900,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي الحضور',
                '$totalAllAttendance سجل',
                PdfColors.green800,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي الورديات',
                '$totalAllShifts وردية',
                PdfColors.blue900,
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // جدول الموظفين
          pw.Text(
            _shape('سجل ساعات العمل الشهري'),
            style: pw.TextStyle(
              font: boldTtf,
              fontSize: 15,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: [
              'متوسط يومي',
              'إجمالي الساعات',
              'أيام الحضور',
              'عدد الورديات',
              'اسم الموظف',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(staffList.length, (i) {
              final entry = staffList[i];
              final s = entry.value;
              return [
                (s.totalMinutes /
                        60 /
                        (s.totalAttendance > 0 ? s.totalAttendance : 1))
                    .toStringAsFixed(1),
                '${s.totalMinutes ~/ 60}:${(s.totalMinutes % 60).toString().padLeft(2, '0')}',
                '${s.totalAttendance}',
                '${s.totalShifts}',
                _shape(s.name),
                i + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 30),

          // تفاصيل يومية لكل موظف
          ...staffList.map((entry) {
            final userAttendance = attendanceRecords
                .where((a) => a.userId == entry.key)
                .toList();
            if (userAttendance.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 25),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.blue900, width: 4),
                    ),
                  ),
                  child: pw.Text(
                    '${_shape('تفاصيل حضور')}: ${_shape(entry.value.name)}',
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 12,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'الحالة',
                    'المدة',
                    'وقت الانصراف',
                    'وقت الحضور',
                    'التاريخ',
                  ].map((e) => _shape(e)).toList(),
                  headerStyle: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey800,
                  ),
                  headerHeight: 30,
                  cellPadding: const pw.EdgeInsets.all(5),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                  },
                  data: userAttendance.map((a) {
                    final checkIn = intl.DateFormat(
                      'hh:mm a',
                    ).format(a.checkInTime);
                    final checkOut = a.checkOutTime != null
                        ? intl.DateFormat('hh:mm a').format(a.checkOutTime!)
                        : '---';
                    final duration = a.shiftDuration != null
                        ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m'
                        : '---';
                    return [
                      _shape(a.status.label),
                      duration,
                      checkOut,
                      checkIn,
                      a.date,
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
                    _shape('أعد التقرير'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _shape(generatedBy),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع المدير المسؤول'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
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
                  _shape('تقرير الموظفين الشهري - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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

    final monthName = _shape(
      intl.DateFormat('MMMM yyyy', 'ar').format(DateTime(year, month)),
    );

    int totalMinutes = 0;
    for (var r in attendanceRecords) {
      if (r.checkOutTime != null) {
        totalMinutes += r.checkOutTime!.difference(r.checkInTime).inMinutes;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, _shape('تقرير أداء موظف')),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        _shape(nurseName),
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الموظف:'),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 13,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        monthName,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الفترة:'),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        (totalMinutes / 60).toStringAsFixed(1),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('إجمالي الساعات:'),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${intl.DateFormat('yyyy/MM/dd').format(DateTime.now())} :${_shape('تاريخ الاستخراج')}',
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
              'الحالة',
              'المدة',
              'وقت الانصراف',
              'وقت الحضور',
              'التاريخ',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 10,
            ),
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
              return [
                _shape(a.status.label),
                duration,
                checkOut,
                checkIn,
                a.date,
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    _shape('أعد التقرير'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _shape(generatedBy),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع الموظف'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع المسؤول'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
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
                  _shape('تقرير أداء فردي - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
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
            _shape('حالة المستلزمات الطبية'),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _shape(
              'تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            ),
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
            ].map((e) => _shape(e)).toList(),
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
                  ? _shape('نفد')
                  : qty <= minQty
                  ? _shape('منخفض')
                  : _shape('متوفر');
              return [
                i + 1,
                _shape(item['name'] as String),
                _shape((item['category'] ?? '-') as String),
                '$qty',
                '$minQty',
                '${item['price']} ${_shape(AppStrings.currency)}',
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
                  _shape('تقرير المخزون - مركز نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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

  /// تقرير الرواتب الشهري التفصيلي - Detailed Monthly Payroll Report
  Future<Uint8List> generatePayrollReportBytes({
    required List<PayrollModel> payrolls,
    required int year,
    required int month,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final monthName = months[month - 1];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) => _buildHeader(
          boldTtf,
          logo,
          _shape('تقرير مسير الرواتب - $monthName $year'),
        ),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '${payrolls.length}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('عدد الموظفين:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        _shape(generatedBy),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('بواسطة:'),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '$year $monthName',
                        style: pw.TextStyle(font: boldTtf, fontSize: 16),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        _shape('الفترة المالية:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 16),
                      ),
                    ],
                  ),
                  pw.Text(
                    _shape(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                    ),
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'الحالة',
              'الصافي',
              'خصومات',
              'مكافآت',
              'خارجية',
              'الأساسي',
              'الساعات',
              'اسم الموظف',
              '#',
            ].map((h) => _shape(h)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            columnWidths: {
              8: const pw.FixedColumnWidth(30),
              7: const pw.FlexColumnWidth(3.5),
              6: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(1.8),
              0: const pw.FlexColumnWidth(1.5),
            },
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              8: pw.Alignment.center,
              7: pw.Alignment.centerRight,
              6: pw.Alignment.center,
              5: pw.Alignment.center,
              4: pw.Alignment.center,
              3: pw.Alignment.center,
              2: pw.Alignment.center,
              1: pw.Alignment.center,
              0: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(payrolls.length, (index) {
              final p = payrolls[index];
              return [
                _shape(
                  p.status == 'paid'
                      ? 'تم الدفع'
                      : p.status == 'approved'
                      ? 'معتمد'
                      : 'مسودة',
                ),
                p.netSalary.toStringAsFixed(1),
                p.deductions.toStringAsFixed(1),
                p.bonus.toStringAsFixed(1),
                p.outsideCasesFees.toStringAsFixed(1),
                p.baseSalary.toStringAsFixed(0),
                p.totalHours.toStringAsFixed(1),
                _shape(p.userName),
                index + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 35),
          // Total Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  '${payrolls.fold(0.0, (sum, p) => sum + p.netSalary).toStringAsFixed(2)} E.P',
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 20,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  _shape('إجمالي الرواتب الصافية لهذا الشهر:'),
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 15,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _shape('تقرير الرواتب - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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

  /// تقرير تفاصيل الدخل (العمليات) - Income Details (Cases) Report
  Future<Uint8List> generateMonthlyIncomeReportBytes({
    required List<CaseModel> cases,
    required int year,
    required int month,
    required String generatedBy,
    String? nurseName,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    final filteredCases = nurseName != null
        ? cases.where((c) => c.nurseName == nurseName).toList()
        : cases;

    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final monthName = months[month - 1];

    final reportTitle = nurseName != null
        ? 'تفاصيل دخل العمليات: $nurseName - $monthName $year'
        : 'تفاصيل دخل العمليات (جميع الممرضين) - $monthName $year';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, reportTitle),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '${filteredCases.length}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('إجمالي الحالات:'),
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        _shape(generatedBy),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('بواسطة:'),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '$year $monthName',
                        style: pw.TextStyle(font: boldTtf, fontSize: 16),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الفترة:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 16),
                      ),
                    ],
                  ),
                  if (nurseName != null)
                    pw.Row(
                      children: [
                        pw.Text(
                          _shape(nurseName),
                          style: pw.TextStyle(font: boldTtf, fontSize: 14),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          _shape('الممرض:'),
                          style: pw.TextStyle(font: boldTtf, fontSize: 14),
                        ),
                      ],
                    ),
                  pw.Text(
                    _shape(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                    ),
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'المبلغ',
              if (nurseName == null) 'الممرض',
              'النوع',
              'اسم المريض',
              'التاريخ',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              5: pw.Alignment.center,
              4: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              2: pw.Alignment.center,
              1: nurseName == null
                  ? pw.Alignment.centerRight
                  : pw.Alignment.center,
              0: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(filteredCases.length, (index) {
              final c = filteredCases[index];
              return [
                (c.totalPrice - c.discount).toStringAsFixed(1),
                if (nurseName == null) _shape(c.nurseName),
                _shape(c.caseType.label),
                _shape(c.patientName),
                intl.DateFormat('MM/dd').format(c.caseDate),
                index + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 35),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(
                  '${filteredCases.fold(0.0, (sum, c) => sum + (c.totalPrice - c.discount)).toStringAsFixed(2)} E.P',
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 20,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  _shape('إجمالي قيمة العمليات:'),
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 16,
                    color: PdfColors.blue900,
                  ),
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _shape('تقرير تفاصيل الدخل - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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

  /// تقرير جرد المستلزمات والمخزون - Inventory Report Bytes
  Future<Uint8List> generateInventoryReportBytes({
    required List<InventoryModel> items,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    int lowStockCount = items
        .where((i) => i.isLowStock || i.isOutOfStock)
        .length;
    int expiredCount = items.where((i) => i.isExpired).length;
    double totalValue = items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.price),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) => _buildHeader(
          boldTtf,
          logo,
          _shape('تقرير جرد المستلزمات والمخزون'),
        ),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '${items.length}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('إجمالي الأصناف:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        _shape(generatedBy),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('بواسطة:'),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _shape('حالة المستلزمات الطبية'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.Text(
                    _shape(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                    ),
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'تاريخ الصلاحية',
              'الحالة',
              'السعر',
              'الحد الأدنى',
              'الكمية',
              'التصنيف',
              'اسم المستلزم',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              7: pw.Alignment.center,
              6: pw.Alignment.centerRight,
              5: pw.Alignment.center,
              4: pw.Alignment.center,
              3: pw.Alignment.center,
              2: pw.Alignment.center,
              1: pw.Alignment.center,
              0: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(items.length, (i) {
              final item = items[i];
              return [
                item.expiryDate != null
                    ? intl.DateFormat('yyyy/MM/dd').format(item.expiryDate!)
                    : '-',
                _shape(
                  item.isOutOfStock
                      ? 'للنفاد'
                      : item.isLowStock
                      ? 'منخفض'
                      : 'متوفر',
                ),
                item.price.toStringAsFixed(1),
                item.minStock.toString(),
                item.quantity.toString(),
                _shape(item.category),
                _shape(item.name),
                i + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 35),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${totalValue.toStringAsFixed(2)} E.P',
                      style: pw.TextStyle(
                        font: boldTtf,
                        fontSize: 18,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      _shape('إجمالي قيمة المخزون:'),
                      style: pw.TextStyle(font: boldTtf, fontSize: 14),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '$expiredCount',
                          style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 13,
                            color: PdfColors.red800,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          _shape('منتج منتهي:'),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          '$lowStockCount',
                          style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 13,
                            color: PdfColors.orange700,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          _shape('منخفض المخزون:'),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  _shape('تقرير جرد المستلزمات والمخزون - نيو كير'),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  _shape('صفحة ${context.pageNumber} من ${context.pagesCount}'),
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
  // === تقرير الإجراءات - Procedures Report ===
  // ============================================

  Future<Uint8List> generateProceduresReportBytes({
    required List<ProcedureModel> procedures,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) =>
            _buildHeader(boldTtf, logo, 'تقرير الإجراءات الطبية'),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _shape('إجمالي الإجراءات: ${procedures.length}'),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    '${_shape('بواسطة:')} ${_shape(generatedBy)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _shape('قائمة الإجراءات الطبية المعتمدة'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 16),
                  ),
                  pw.Text(
                    _shape(
                      'تاريخ الاستخراج: ${intl.DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                    ),
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'سعر خارج',
              'سعر المركز',
              'السعر الافتراضي',
              'اسم الإجراء',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 11,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 40,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(procedures.length, (i) {
              final p = procedures[i];
              return [
                p.priceOutside.toStringAsFixed(0),
                p.priceInside.toStringAsFixed(0),
                p.defaultPrice.toStringAsFixed(0),
                _shape(p.name),
                i + 1,
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
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
