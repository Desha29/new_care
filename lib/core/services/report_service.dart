import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../features/cases/data/models/case_model.dart';
import '../../../features/financials/data/models/expense_model.dart';
import '../../../features/attendance/data/models/attendance_model.dart';
import '../../../features/shifts/data/models/shift_model.dart';
import '../constants/app_strings.dart';
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

  pw.Widget _buildHeader(pw.Font boldTtf, pw.MemoryImage? logo, String subtitle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Container(
                width: 45, height: 45,
                margin: const pw.EdgeInsets.only(left: 10),
                child: pw.Image(logo),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppStrings.appName, style: pw.TextStyle(font: boldTtf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('مركز نيو كير للرعاية الطبية والتمريض المنزلي', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: const pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(5))),
          child: pw.Text(subtitle, style: pw.TextStyle(color: PdfColors.white, fontSize: 12, font: boldTtf)),
        ),
      ],
    );
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

  pw.Widget _reportStatCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border(right: pw.BorderSide(color: color, width: 4)),
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
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logo != null)
                        pw.Container(width: 45, height: 45, margin: const pw.EdgeInsets.only(left: 10), child: pw.Image(logo)),
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
              
              // Patient Info
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

              // Services & Supplies Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('البيان / الخدمة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('الكمية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('سعر الوحدة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('المبلغ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...caseData.services.map((s) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${s.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${s.price}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${s.total} ${AppStrings.currency}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                  ...caseData.suppliesUsed.map((su) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.name} (مستلزم)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.unitPrice}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${su.total} ${AppStrings.currency}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                ],
              ),

              pw.SizedBox(height: 15),
              
              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 180,
                    child: pw.Column(
                      children: [
                        _summaryLine('المجموع:', '${caseData.totalPrice} ${AppStrings.currency}', false),
                        _summaryLine('الخصم:', '${caseData.discount} ${AppStrings.currency}', false),
                        pw.Divider(color: PdfColors.blue900, thickness: 1),
                        _summaryLine('الإجمالي الصافي:', '${caseData.totalPrice - caseData.discount} ${AppStrings.currency}', true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              
              // Footer
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
      filename: 'Invoice_${caseData.id.substring(0, 6)}.pdf',
    );
  }

  // ============================================
  // === التقرير المالي - Financial Report ===
  // ============================================

  /// إنشاء تقرير مالي شامل - Generate Financial Report
  Future<void> generateFinancialReport({
    required List<CaseModel> cases,
    required List<ExpenseModel> expenses,
    required DateTime start,
    required DateTime end,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();

    double totalIncome = cases.fold(0, (sum, c) => sum + (c.totalPrice - c.discount));
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
          pw.Text('تفاصيل الدخل (عمليات الحالات)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['#', 'التاريخ', 'اسم المريض', 'النوع', 'الممرض', 'المبلغ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.center, 5: pw.Alignment.centerLeft},
            data: List<List<dynamic>>.generate(cases.length, (index) {
              final c = cases[index];
              return [index + 1, intl.DateFormat('MM/dd').format(c.caseDate), c.patientName, c.caseType.label, c.nurseName, '${(c.totalPrice - c.discount).toStringAsFixed(0)}'];
            }),
          ),

          pw.SizedBox(height: 35),
          pw.Text('تفصيل المصروفات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
          pw.SizedBox(height: 10),
          
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'التصنيف', 'البيان', 'القيمة'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
            cellPadding: const pw.EdgeInsets.all(6),
            data: expenses.map((e) => [intl.DateFormat('yyyy-MM-dd').format(e.date), e.category, e.label, '${e.amount.toStringAsFixed(0)} ${AppStrings.currency}']).toList(),
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

  // ============================================
  // === تقرير الموظفين الشهري - Monthly Staff Report ===
  // ============================================

  /// تقرير ساعات العمل الشهري لكل ممرض بناءً على الحضور والورديات
  /// Monthly working hours report per nurse based on attendance & shifts
  Future<void> generateMonthlyStaffReport({
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

    final monthName = intl.DateFormat('MMMM yyyy', 'ar').format(DateTime(year, month));

    // تجميع البيانات حسب المستخدم
    final Map<String, _StaffSummary> staffMap = {};

    for (final shift in shifts) {
      staffMap.putIfAbsent(shift.userId, () => _StaffSummary(name: shift.userName));
      staffMap[shift.userId]!.totalShifts++;
    }

    for (final record in attendanceRecords) {
      staffMap.putIfAbsent(record.userId, () => _StaffSummary(name: record.userName));
      final summary = staffMap[record.userId]!;
      summary.totalAttendance++;
      
      if (record.checkOutTime != null) {
        final duration = record.checkOutTime!.difference(record.checkInTime);
        summary.totalMinutes += duration.inMinutes;
      }
    }

    final staffList = staffMap.entries.toList();
    int totalAllMinutes = staffList.fold(0, (sum, e) => sum + e.value.totalMinutes);
    int totalAllShifts = staffList.fold(0, (sum, e) => sum + e.value.totalShifts);
    int totalAllAttendance = staffList.fold(0, (sum, e) => sum + e.value.totalAttendance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (pw.Context context) => pw.Column(
          children: [
            _buildHeader(boldTtf, logo, 'تقرير الموظفين الشهري'),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) => [
          // معلومات التقرير
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الشهر: $monthName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 20),

          // كروت الملخص
          pw.Row(
            children: [
              _reportStatCard('إجمالي الورديات', '$totalAllShifts وردية', PdfColors.blue900),
              pw.SizedBox(width: 15),
              _reportStatCard('إجمالي الحضور', '$totalAllAttendance سجل', PdfColors.green800),
              pw.SizedBox(width: 15),
              _reportStatCard('إجمالي الساعات', '${(totalAllMinutes / 60).toStringAsFixed(1)} ساعة', PdfColors.orange900),
            ],
          ),
          pw.SizedBox(height: 30),

          // جدول الموظفين
          pw.Text('تفاصيل ساعات العمل لكل موظف', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: ['#', 'اسم الموظف', 'عدد الورديات', 'أيام الحضور', 'إجمالي الساعات', 'متوسط يومي'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellPadding: const pw.EdgeInsets.all(8),
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(staffList.length, (i) {
              final entry = staffList[i];
              final s = entry.value;
              final totalHours = (s.totalMinutes / 60).toStringAsFixed(1);
              final avgDaily = s.totalAttendance > 0
                  ? (s.totalMinutes / 60 / s.totalAttendance).toStringAsFixed(1)
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
            final userAttendance = attendanceRecords.where((a) => a.userId == entry.key).toList();
            if (userAttendance.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'تفاصيل حضور: ${entry.value.name}',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray(
                  headers: ['التاريخ', 'وقت الحضور', 'وقت الانصراف', 'المدة', 'الحالة'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
                  cellPadding: const pw.EdgeInsets.all(5),
                  cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center},
                  data: userAttendance.map((a) {
                    final checkIn = intl.DateFormat('hh:mm a').format(a.checkInTime);
                    final checkOut = a.checkOutTime != null ? intl.DateFormat('hh:mm a').format(a.checkOutTime!) : '---';
                    final duration = a.shiftDuration != null ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m' : '---';
                    return [a.date, checkIn, checkOut, duration, a.status.label];
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
                  pw.Text('أَعد التقرير', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(generatedBy, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('توقيع المدير المسؤول', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
                pw.Text('تقرير الموظفين الشهري - مركز نيو كير', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Staff_Report_${year}_$month',
    );
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
          pw.Text('حالة المستلزمات الطبية', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 5),
          pw.Text('تاريخ الاستخراج: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 15),

          pw.Table.fromTextArray(
            headers: ['#', 'اسم المستلزم', 'الفئة', 'الكمية الحالية', 'الحد الأدنى', 'السعر', 'الحالة'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignments: {0: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center, 5: pw.Alignment.center},
            data: List<List<dynamic>>.generate(inventoryData.length, (i) {
              final item = inventoryData[i];
              final qty = item['quantity'] as int;
              final minQty = item['minQuantity'] as int;
              final status = qty <= 0 ? 'نفد' : qty <= minQty ? 'منخفض' : 'متوفر';
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
                pw.Text('تقرير المخزون - مركز نيو كير', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Inventory_Report');
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
