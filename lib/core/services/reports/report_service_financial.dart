part of 'report_service.dart';

extension ReportServiceFinancialExtension on ReportService {
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
        textDirection: pw.TextDirection.rtl,
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
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        _shape('تاريخ الاستخراج:'),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        intl.DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(DateTime.now()),
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
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        _shape('الفترة من:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        '${intl.DateFormat('yyyy/MM/dd').format(start)} - ${intl.DateFormat('yyyy/MM/dd').format(end)}',
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
}
