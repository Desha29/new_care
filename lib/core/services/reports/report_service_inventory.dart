part of 'report_service.dart';

extension ReportServiceInventoryExtension on ReportService {
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
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        header: (pw.Context context) => _buildHeader(
          boldTtf,
          logo,
          _shape('تقرير  جرد  المستلزمات والمخزون'),
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
                        _shape('إجمالي الأصناف:'),
                        style: pw.TextStyle(font: boldTtf, fontSize: 14),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        '${items.length}',
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
            headerHeight: 55,
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
                      _shape('إجمالي قيمة المخزون:'),
                      style: pw.TextStyle(font: boldTtf, fontSize: 14),
                    ),
                    pw.Text(
                      '${totalValue.toStringAsFixed(2)} E.P',
                      style: pw.TextStyle(
                        font: boldTtf,
                        fontSize: 18,
                        color: PdfColors.blue900,
                      ),
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
                          _shape('منتج منتهي:'),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '$expiredCount',
                          style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 13,
                            color: PdfColors.red800,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          _shape('منخفض المخزون:'),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '$lowStockCount',
                          style: pw.TextStyle(
                            font: boldTtf,
                            fontSize: 13,
                            color: PdfColors.orange700,
                          ),
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
}
