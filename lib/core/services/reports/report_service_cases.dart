part of 'report_service.dart';

extension ReportServiceCasesExtension on ReportService {
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
        textDirection: pw.TextDirection.rtl,
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
                      pw.Text(_shape('إجمالي الحالات:')),

                      pw.SizedBox(width: 4),
                      pw.Text(
                        '${cases.length}',
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
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
              "طريقة الدفع",
              'المبلغ',
              'الممرض',
              'النوع',
              'اسم المريض',
              "الوقت والتاريخ",
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
            headerHeight: 55,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            cellAlignments: {
              7: pw.Alignment.center,
              6: pw.Alignment.center,
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
                _shape(c.paymentMethod == "cash" ? "كاش" : "محفظة"),
                (c.totalPrice - c.discount).toStringAsFixed(1),
                _shape(c.nurseName),
                _shape(c.caseType.label),
                _shape(c.patientName),

                _shape(c.createdAt.toString().split(".")[0]),
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
}
