part of 'report_service.dart';

extension ReportServiceStaffExtension on ReportService {
  /// تقرير ساعات العمل الشهري لكل ممرض بناءً على الحضور والورديات - بايتات
  Future<Uint8List> generateMonthlyStaffReportBytes({
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

    final monthName = intl.DateFormat(
      'MMMM yyyy',
      'ar',
    ).format(DateTime(year, month));

    final Map<String, _StaffSummary> staffMap = {};

    for (final shift in shifts) {
      staffMap.putIfAbsent(
        shift.userId,
        () => _StaffSummary(name: shift.userName),
      );
      staffMap[shift.userId]!.totalShifts++;
    }

    for (final record in attendanceRecords) {
      staffMap.putIfAbsent(
        record.userId,
        () => _StaffSummary(name: record.userName),
      );
      final summary = staffMap[record.userId]!;
      summary.totalAttendance++;

      if (record.checkOutTime != null) {
        final duration = record.checkOutTime!.difference(record.checkInTime);
        summary.totalMinutes += duration.inMinutes;
      }
    }

    final staffList = staffMap.entries.toList();
    int totalAllMinutes = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalMinutes,
    );
    int totalAllShifts = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalShifts,
    );
    int totalAllAttendance = staffList.fold(
      0,
      (sum, e) => sum + e.value.totalAttendance,
    );

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
            _buildHeader(boldTtf, logo, _shape('تقرير الموظفين الشهري')),
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
                        intl.DateFormat(
                          'yyyy/MM/dd HH:mm',
                        ).format(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('تاريخ الاستخراج:'),
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
                  pw.Text(
                    _shape('الفترة: $monthName'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _reportStatCard(
                'إجمالي الساعات',
                '${(totalAllMinutes / 60).toStringAsFixed(1)} ساعة',
                PdfColors.orange900,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي الحضور',
                '$totalAllAttendance سجل',
                PdfColors.green800,
              ),
              pw.SizedBox(width: 15),
              _reportStatCard(
                'إجمالي الورديات',
                '$totalAllShifts وردية',
                PdfColors.blue900,
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            _shape('سجل ساعات العمل الشهري'),
            style: pw.TextStyle(
              font: boldTtf,
              fontSize: 15,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              'متوسط يومي',
              'إجمالي الساعات',
              'أيام الحضور',
              'عدد الورديات',
              'اسم الموظف',
              '#',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 55,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            data: List<List<dynamic>>.generate(staffList.length, (i) {
              final entry = staffList[i];
              final s = entry.value;
              return [
                (s.totalMinutes /
                        60 /
                        (s.totalAttendance > 0 ? s.totalAttendance : 1))
                    .toStringAsFixed(1),
                '${s.totalMinutes ~/ 60}:${(s.totalMinutes % 60).toString().padLeft(2, '0')}',
                '${s.totalAttendance}',
                '${s.totalShifts}',
                _shape(s.name),
                i + 1,
              ];
            }),
          ),
          pw.SizedBox(height: 30),
          ...staffList.map((entry) {
            final userAttendance = attendanceRecords
                .where((a) => a.userId == entry.key)
                .toList();
            if (userAttendance.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 25),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.blue900, width: 4),
                    ),
                  ),
                  child: pw.Text(
                    '${_shape('تفاصيل حضور')}: ${_shape(entry.value.name)}',
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 12,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'الحالة',
                    'المدة',
                    'وقت الانصراف',
                    'وقت الحضور',
                    'التاريخ',
                  ].map((e) => _shape(e)).toList(),
                  headerStyle: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey800,
                  ),
                  headerHeight: 50,
                  cellPadding: const pw.EdgeInsets.all(5),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.center,
                  },
                  data: userAttendance.map((a) {
                    final checkIn = intl.DateFormat(
                      'hh:mm a',
                    ).format(a.checkInTime);
                    final checkOut = a.checkOutTime != null
                        ? intl.DateFormat('hh:mm a').format(a.checkOutTime!)
                        : '---';
                    final duration = a.shiftDuration != null
                        ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m'
                        : '---';
                    return [
                      _shape(a.status.label),
                      duration,
                      checkOut,
                      checkIn,
                      a.date,
                    ];
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
                  pw.Text(
                    _shape('أعد التقرير'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _shape(generatedBy),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع المدير المسؤول'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
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
                pw.Text(
                  _shape('تقرير الموظفين الشهري - نيو كير'),
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

  /// إنشاء بايتات تقرير لممرض واحد - Generate PDF bytes for a single nurse report
  Future<Uint8List> generateSingleNurseReportBytes({
    required int year,
    required int month,
    required String nurseName,
    required List<AttendanceModel> attendanceRecords,
    required String generatedBy,
  }) async {
    final pdf = pw.Document();
    final ttf = await _getFont();
    final boldTtf = await _getBoldFont();
    final logo = await _getLogo();

    final monthName = _shape(
      intl.DateFormat('MMMM yyyy', 'ar').format(DateTime(year, month)),
    );

    int totalMinutes = 0;
    for (var r in attendanceRecords) {
      if (r.checkOutTime != null) {
        totalMinutes += r.checkOutTime!.difference(r.checkInTime).inMinutes;
      }
    }

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
            _buildHeader(boldTtf, logo, _shape('تقرير أداء موظف')),
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
                        _shape(nurseName),
                        style: pw.TextStyle(font: boldTtf, fontSize: 13),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الموظف:'),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 13,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        monthName,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('الفترة:'),
                        style: const pw.TextStyle(fontSize: 11),
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
                        (totalMinutes / 60).toStringAsFixed(1),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        _shape('إجمالي الساعات:'),
                        style: pw.TextStyle(
                          font: boldTtf,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${intl.DateFormat('yyyy/MM/dd').format(DateTime.now())} :${_shape('تاريخ الاستخراج')}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            headers: [
              'الحالة',
              'المدة',
              'وقت الانصراف',
              'وقت الحضور',
              'التاريخ',
            ].map((e) => _shape(e)).toList(),
            headerStyle: pw.TextStyle(
              font: boldTtf,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerHeight: 55,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 10,
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            data: attendanceRecords.map((a) {
              final checkIn = intl.DateFormat('hh:mm a').format(a.checkInTime);
              final checkOut = a.checkOutTime != null
                  ? intl.DateFormat('hh:mm a').format(a.checkOutTime!)
                  : '---';
              final duration = a.shiftDuration != null
                  ? '${a.shiftDuration!.inHours}h ${a.shiftDuration!.inMinutes % 60}m'
                  : '---';
              return [
                _shape(a.status.label),
                duration,
                checkOut,
                checkIn,
                a.date,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 50),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    _shape('أعد التقرير'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _shape(generatedBy),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع الموظف'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
                  pw.Container(width: 120, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    _shape('توقيع المسؤول'),
                    style: pw.TextStyle(font: boldTtf, fontSize: 10),
                  ),
                  pw.SizedBox(height: 38),
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
                pw.Text(
                  _shape('تقرير أداء فردي - نيو كير'),
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
