part of 'report_service.dart';

extension ReportServiceProceduresExtension on ReportService {
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
        textDirection: pw.TextDirection.rtl,
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
            headerHeight: 55,
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
