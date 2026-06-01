part of 'report_service.dart';

extension ReportServiceCaseInvoiceExtension on ReportService {
  /// إنشاء فاتورة حالة - Generate Case Invoice PDF bytes
  Future<Uint8List> generateCaseInvoiceBytes(CaseModel caseData) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: boldTtf,
          fontFallback: [await _getFallbackFont()],
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(width: 70, height: 70, child: pw.Image(logo)),
                pw.SizedBox(height: 2),
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
                pw.Divider(
                  thickness: 0.5,
                  borderStyle: pw.BorderStyle.dashed,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _shape('فاتورة مبسطة'),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
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
                pw.Divider(
                  thickness: 0.5,
                  borderStyle: pw.BorderStyle.dashed,
                ),
                pw.SizedBox(height: 8),
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
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: pw.Text(
                              _shape(s.name),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: pw.Text(
                              '${s.quantity}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
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
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: pw.Text(
                              _shape('${su.name} (مستلزم)'),
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: pw.Text(
                              '${su.quantity}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2,
                            ),
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
                pw.Divider(
                  thickness: 0.5,
                  borderStyle: pw.BorderStyle.dashed,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// مشاركة فاتورة حالة - Share case invoice
  Future<void> shareCaseInvoice(CaseModel caseData) async {
    final bytes = await generateCaseInvoiceBytes(caseData);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Invoice-${caseData.patientName}.pdf',
    );
  }
}
