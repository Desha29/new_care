part of 'report_service.dart';

extension ReportServicePayrollExtension on ReportService {
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
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) => _buildHeader(
          boldTtf,
          logo,
          _shape('تقرير الرواتب - $monthName $year'),
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
                        _shape('عدد الموظفين:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        '${payrolls.length}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        _shape('بواسطة:'),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape(generatedBy),
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
                        _shape('الفترة المالية:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 16),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '$year $monthName',
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
                  _shape('إجمالي الرواتب الصافية لهذا الشهر:'),
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 15,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  '${payrolls.fold(0.0, (sum, p) => sum + p.netSalary).toStringAsFixed(2)} E.P',
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 20,
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
        textDirection: pw.TextDirection.rtl,
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
}
