import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/report_service.dart';
import '../../../attendance/data/models/attendance_model.dart';

class NurseReportPreviewScreen extends StatelessWidget {
  final String nurseName;
  final int year;
  final int month;
  final List<AttendanceModel> attendanceRecords;
  final String generatedBy;

  const NurseReportPreviewScreen({
    super.key,
    required this.nurseName,
    required this.year,
    required this.month,
    required this.attendanceRecords,
    required this.generatedBy,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat(
      'MMMM yyyy',
      'ar',
    ).format(DateTime(year, month));

    int totalMinutes = 0;
    for (var r in attendanceRecords) {
      if (r.checkOutTime != null) {
        totalMinutes += r.checkOutTime!.difference(r.checkInTime).inMinutes;
      }
    }
    final totalHours = totalMinutes / 60.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'معاينة تقرير الموظف',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _handlePrint(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (format) =>
            ReportService.instance.generateSingleNurseReportBytes(
              year: year,
              month: month,
              nurseName: nurseName,
              attendanceRecords: attendanceRecords,
              generatedBy: generatedBy,
            ),
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handlePrint(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        label: const Text(
          'طباعة / تحميل PDF',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    final bytes = await ReportService.instance.generateSingleNurseReportBytes(
      year: year,
      month: month,
      nurseName: nurseName,
      attendanceRecords: attendanceRecords,
      generatedBy: generatedBy,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Report_$nurseName',
    );
  }
}
