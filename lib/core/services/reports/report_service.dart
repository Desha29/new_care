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

part 'report_service_case_invoice.dart';
part 'report_service_financial.dart';
part 'report_service_cases.dart';
part 'report_service_staff.dart';
part 'report_service_payroll.dart';
part 'report_service_inventory.dart';
part 'report_service_procedures.dart';

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

  static const int _minValidFontBytes = 50000;

  Future<pw.Font?> _tryLoadAssetFont(String path) async {
    try {
      final data = await rootBundle.load(path);
      if (data.lengthInBytes < _minValidFontBytes) return null;
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font> _getFont() async {
    _cachedFont ??=
        await _tryLoadAssetFont('assets/fonts/Cairo-Regular.ttf') ??
        await PdfGoogleFonts.cairoRegular();
    return _cachedFont!;
  }

  Future<pw.Font> _getBoldFont() async {
    _cachedBoldFont ??=
        await _tryLoadAssetFont('assets/fonts/Cairo-Bold.ttf') ??
        await PdfGoogleFonts.cairoBold();
    return _cachedBoldFont!;
  }

  Future<pw.Font> _getFallbackFont() async {
    _cachedFallbackFont ??=
        await _tryLoadAssetFont('assets/fonts/NotoNaskhArabic-Regular.ttf') ??
        await PdfGoogleFonts.notoSansArabicRegular();
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

    final arabicRun = RegExp(r'[\u0600-\u06FF]+');
    return text.splitMapJoin(
      arabicRun,
      onMatch: (m) => ArabicReshaper().reshape(m.group(0)!),
      onNonMatch: (n) => n,
    );
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

  /// طباعة فاتورة حالة - Print case invoice
  Future<void> generateCaseInvoice(CaseModel caseData) async {
    final bytes = await generateCaseInvoiceBytes(caseData);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Invoice-${caseData.patientName}',
    );
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
        textDirection: pw.TextDirection.rtl,
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
}

/// نموذج مساعد داخلي لتجميع بيانات الموظف
class _StaffSummary {
  final String name;
  int totalShifts = 0;
  int totalAttendance = 0;
  int totalMinutes = 0;

  _StaffSummary({required this.name});
}
