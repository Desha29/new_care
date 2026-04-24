import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';

class ReportPreviewScreen extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function() buildReport;

  const ReportPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.buildReport,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (format) => buildReport(),
        allowSharing: false,
        allowPrinting: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        pdfFileName: fileName,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: 'print',
            onPressed: () async {
              final bytes = await buildReport();
              await Printing.layoutPdf(
                onLayout: (format) async => bytes,
                name: fileName,
              );
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            label: const Text(
              'طباعة التقرير',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'share',
            onPressed: () async {
              final bytes = await buildReport();
              await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
            },
            backgroundColor: AppColors.secondary,
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            label: const Text(
              'مشاركة التقرير',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
