import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/cases/data/models/case_model.dart';
import '../constants/app_strings.dart';

/// خدمة الطباعة - Printing Service
/// PDF generation + Thermal printer support
class PrintingService {
  static PrintingService? _instance;

  PrintingService._();

  static PrintingService get instance {
    _instance ??= PrintingService._();
    return _instance!;
  }

  /// إنشاء فاتورة PDF - Generate PDF Invoice
  Future<pw.Document> generateInvoice(CaseModel caseModel) async {
    final pdf = pw.Document();

    // تحميل خط عربي - Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // === رأس الفاتورة - Invoice Header ===
                _buildInvoiceHeader(arabicFontBold, arabicFont, caseModel),
                pw.SizedBox(height: 20),

                // === معلومات المريض - Patient Info ===
                _buildPatientInfo(arabicFontBold, arabicFont, caseModel),
                pw.SizedBox(height: 20),

                // === جدول الخدمات - Services Table ===
                if (caseModel.services.isNotEmpty)
                  _buildServicesTable(arabicFontBold, arabicFont, caseModel),
                pw.SizedBox(height: 10),

                // === جدول المستلزمات - Supplies Table ===
                if (caseModel.suppliesUsed.isNotEmpty)
                  _buildSuppliesTable(arabicFontBold, arabicFont, caseModel),
                pw.SizedBox(height: 20),

                // === الإجمالي - Total ===
                _buildTotalSection(arabicFontBold, arabicFont, caseModel),
                pw.SizedBox(height: 30),

                // === التذييل - Footer ===
                pw.Center(
                  child: pw.Text(
                    AppStrings.thankYou,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// رأس الفاتورة - Invoice Header
  pw.Widget _buildInvoiceHeader(
    pw.Font boldFont,
    pw.Font regularFont,
    CaseModel caseModel,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0D3B66'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                AppStrings.appName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                AppStrings.appSubtitle,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${AppStrings.invoiceNumber}: ${caseModel.id.substring(0, 8).toUpperCase()}',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                '${AppStrings.invoiceDate}: ${caseModel.caseDate.day}/${caseModel.caseDate.month}/${caseModel.caseDate.year}',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// معلومات المريض - Patient Info
  pw.Widget _buildPatientInfo(
    pw.Font boldFont,
    pw.Font regularFont,
    CaseModel caseModel,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          _infoItem(
            boldFont,
            regularFont,
            AppStrings.patientName,
            caseModel.patientName,
          ),
          _infoItem(
            boldFont,
            regularFont,
            AppStrings.assignNurse,
            caseModel.nurseName,
          ),
          _infoItem(
            boldFont,
            regularFont,
            AppStrings.caseType,
            caseModel.caseType.label,
          ),
          _infoItem(
            boldFont,
            regularFont,
            AppStrings.caseStatus,
            caseModel.status.label,
          ),
        ],
      ),
    );
  }

  pw.Widget _infoItem(
    pw.Font boldFont,
    pw.Font regularFont,
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: regularFont, fontSize: 12)),
        ],
      ),
    );
  }

  /// جدول الخدمات - Services Table
  pw.Widget _buildServicesTable(
    pw.Font boldFont,
    pw.Font regularFont,
    CaseModel caseModel,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          AppStrings.services,
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#0D3B66'),
          ),
          cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
          cellAlignment: pw.Alignment.center,
          headers: [
            AppStrings.serviceName,
            AppStrings.quantity,
            AppStrings.unitPrice,
            AppStrings.total,
          ],
          data: caseModel.services
              .map(
                (s) => [
                  s.name,
                  '${s.quantity}',
                  '${s.price} ${AppStrings.currency}',
                  '${s.total} ${AppStrings.currency}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  /// جدول المستلزمات - Supplies Table
  pw.Widget _buildSuppliesTable(
    pw.Font boldFont,
    pw.Font regularFont,
    CaseModel caseModel,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          AppStrings.supplies,
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#5AB9C1'),
          ),
          cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
          cellAlignment: pw.Alignment.center,
          headers: [
            AppStrings.itemName,
            AppStrings.quantity,
            AppStrings.unitPrice,
            AppStrings.total,
          ],
          data: caseModel.suppliesUsed
              .map(
                (s) => [
                  s.name,
                  '${s.quantity}',
                  '${s.unitPrice} ${AppStrings.currency}',
                  '${s.total} ${AppStrings.currency}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  /// قسم الإجمالي - Total Section
  pw.Widget _buildTotalSection(
    pw.Font boldFont,
    pw.Font regularFont,
    CaseModel caseModel,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F0F4F8'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _totalRow(
              boldFont,
              regularFont,
              AppStrings.subtotal,
              '${caseModel.totalPrice} ${AppStrings.currency}',
            ),
            if (caseModel.discount > 0)
              _totalRow(
                boldFont,
                regularFont,
                AppStrings.discount,
                '- ${caseModel.discount} ${AppStrings.currency}',
              ),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              boldFont,
              boldFont,
              AppStrings.grandTotal,
              '${caseModel.grandTotal} ${AppStrings.currency}',
              isGrand: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(
    pw.Font labelFont,
    pw.Font valueFont,
    String label,
    String value, {
    bool isGrand = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: labelFont, fontSize: isGrand ? 14 : 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: valueFont, fontSize: isGrand ? 14 : 12),
          ),
        ],
      ),
    );
  }

  /// طباعة الفاتورة - Print Invoice (PDF Printer)
  Future<void> printInvoice(CaseModel caseModel) async {
    final pdf = await generateInvoice(caseModel);
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// طباعة حرارية - Thermal Printer Receipt
  Future<pw.Document> generateThermalReceipt(CaseModel caseModel) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppStrings.appName,
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 16),
                ),
                pw.Text(
                  AppStrings.appSubtitle,
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.Divider(),
                pw.Text(
                  '${AppStrings.patientName}: ${caseModel.patientName}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.Text(
                  '${AppStrings.caseDate}: ${caseModel.caseDate.day}/${caseModel.caseDate.month}/${caseModel.caseDate.year}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.Divider(),
                // الخدمات
                ...caseModel.services.map(
                  (s) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        s.name,
                        style: pw.TextStyle(font: arabicFont, fontSize: 9),
                      ),
                      pw.Text(
                        '${s.total} ${AppStrings.currency}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      AppStrings.grandTotal,
                      style: pw.TextStyle(font: arabicFontBold, fontSize: 12),
                    ),
                    pw.Text(
                      '${caseModel.grandTotal} ${AppStrings.currency}',
                      style: pw.TextStyle(font: arabicFontBold, fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  AppStrings.thankYou,
                  style: pw.TextStyle(font: arabicFont, fontSize: 9),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// طباعة حرارية مباشرة - Direct Thermal Print
  Future<void> printThermalReceipt(CaseModel caseModel) async {
    final pdf = await generateThermalReceipt(caseModel);
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      format: PdfPageFormat.roll80,
    );
  }
}
