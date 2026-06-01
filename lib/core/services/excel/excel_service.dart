import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:new_care/features/cases/data/models/case_model.dart';
import 'package:new_care/features/attendance/data/models/attendance_model.dart';
import 'package:new_care/features/shifts/data/models/shift_model.dart';
import 'package:new_care/features/payroll/data/models/payroll_model.dart';
import 'package:new_care/features/financials/data/models/expense_model.dart';
import 'package:new_care/features/inventory/data/models/inventory_model.dart';
import 'package:new_care/features/procedures/data/models/procedure_model.dart';
import 'package:new_care/core/enums/case_status.dart';

/// خدمة التصدير إلى إكسل - Excel Export Service
class ExcelService {
  static ExcelService? _instance;
  ExcelService._();
  static ExcelService get instance => _instance ??= ExcelService._();

  /// تحويل القيمة إلى CellValue مناسب لـ excel 4.x
  CellValue _val(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is String) return TextCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    if (value is DateTime) {
      return DateTimeCellValue(
        year: value.year,
        month: value.month,
        day: value.day,
        hour: value.hour,
        minute: value.minute,
        second: value.second,
      );
    }
    return TextCellValue(value.toString());
  }

  /// تهيئة ورقة العمل الأولى (دائماً موجودة بعد createExcel)
  Sheet _initSheet(Excel excel, String name) {
    // احصل على الورقة الأولى مباشرة من الخريطة لتجنب مشاكل rename
    if (excel.sheets.isEmpty) return excel[name];
    final sheet = excel.sheets.values.first;
    final current = excel.sheets.keys.first;
    if (current != name) {
      try {
        excel.rename(current, name);
      } catch (_) {
        // تجاهل فشل rename – استخدم الورقة كما هي
      }
    }
    return sheet;
  }

  /// فتح نافذة حفظ الملف وتخزين البيانات
  Future<bool> _saveAndOpen(Excel excel, String defaultName) async {
    try {
      final bytes = excel.save();
      if (bytes == null || bytes.isEmpty) return false;

      // اختيار مسار الحفظ عبر FilePicker
      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ ملف الإكسل',
        fileName: '$defaultName.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (selectedPath == null) {
        // ألغى المستخدم العملية
        return false;
      }

      // إضافة الامتداد إذا لم يكن موجوداً
      String filePath = selectedPath;
      if (!filePath.toLowerCase().endsWith('.xlsx')) {
        filePath = '$filePath.xlsx';
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // فتح الملف تلقائياً على نظام ويندوز
      if (Platform.isWindows) {
        await Process.run('cmd', [
          '/c',
          'start',
          '',
          filePath,
        ], runInShell: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================
  // === تقرير المستلزمات - Inventory Report ===
  // ============================================

  Future<bool> exportInventoryToExcel(List<InventoryModel> items) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'المستلزمات والمخزون');

    // العناوين
    sheet.appendRow([
      _val('م'),
      _val('اسم المستلزم'),
      _val('التصنيف'),
      _val('الكمية الحالية'),
      _val('الوحدة'),
      _val('الحد الأدنى'),
      _val('سعر الوحدة (E.P)'),
      _val('القيمة الإجمالية'),
      _val('حالة المخزون'),
      _val('تاريخ الصلاحية'),
      _val('ملاحظات'),
    ]);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final expiryStr = item.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
          : 'غير محدد';

      sheet.appendRow([
        _val(i + 1),
        _val(item.name),
        _val(item.category),
        _val(item.quantity),
        _val(item.unit),
        _val(item.minStock),
        _val(item.price),
        _val(item.quantity * item.price),
        _val(item.stockStatusLabel),
        _val(expiryStr),
        _val(item.notes),
      ]);
    }

    return _saveAndOpen(
      excel,
      'تقرير_المستلزمات_${DateFormat('yyyy_MM_dd').format(DateTime.now())}',
    );
  }

  // ============================================
  // === تقرير الحالات - Cases & Work Report ===
  // ============================================

  Future<bool> exportCasesToExcel(
    List<CaseModel> cases,
    String reportTitle,
  ) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'تقرير الحالات');

    sheet.appendRow([
      _val('م'),
      _val('التاريخ'),
      _val('اسم المريض'),
      _val('العمر'),
      _val('الجنس'),
      _val('الهاتف'),
      _val('العنوان'),
      _val('الممرض القائم'),
      _val('نوع الخدمة'),
      _val('الخدمات المقدمة'),
      _val('المستلزمات المستخدمة'),
      _val('الإجمالي (E.P)'),
      _val('الخصم (E.P)'),
      _val('الصافي المدفوع (E.P)'),
      _val('طريقة الدفع'),
      _val('ملاحظات'),
    ]);

    for (int i = 0; i < cases.length; i++) {
      final c = cases[i];
      final servicesText = c.services
          .map((s) => '${s.name} (${s.quantity}x${s.price})')
          .join(' | ');
      final suppliesText = c.suppliesUsed
          .map((s) => '${s.name} (${s.quantity}x${s.unitPrice})')
          .join(' | ');

      sheet.appendRow([
        _val(i + 1),
        _val(DateFormat('yyyy-MM-dd').format(c.caseDate)),
        _val(c.patientName),
        _val(c.patientAge),
        _val(c.patientGenderLabel),
        _val(c.patientPhone),
        _val(c.patientAddress),
        _val(c.nurseName),
        _val(c.caseType.label),
        _val(servicesText),
        _val(suppliesText),
        _val(c.totalPrice),
        _val(c.discount),
        _val(c.grandTotal),
        _val(c.paymentMethod == 'cash' ? 'نقدي' : 'فيزا/شبكة'),
        _val(c.notes),
      ]);
    }

    return _saveAndOpen(excel, reportTitle.replaceAll(' ', '_'));
  }

  // ============================================
  // === تقرير الإجراءات - Procedures Report ===
  // ============================================

  Future<bool> exportProceduresToExcel(
    List<ProcedureModel> procedures, [
    String? fileName,
  ]) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'قائمة الإجراءات الطبية');

    sheet.appendRow([
      _val('م'),
      _val('اسم الإجراء'),
      _val('السعر الافتراضي (E.P)'),
      _val('السعر داخل المركز (E.P)'),
      _val('السعر خارج المركز (E.P)'),
      _val('ملاحظات'),
    ]);

    for (int i = 0; i < procedures.length; i++) {
      final p = procedures[i];
      sheet.appendRow([
        _val(i + 1),
        _val(p.name),
        _val(p.defaultPrice),
        _val(p.priceInside),
        _val(p.priceOutside),
        _val(p.notes),
      ]);
    }

    return _saveAndOpen(
      excel,
      (fileName ?? 'Medical_Procedures').replaceAll(' ', '_'),
    );
  }

  // ============================================
  // === تقرير الموظفين - Monthly Staff Attendance ===
  // ============================================

  Future<bool> exportAttendanceToExcel({
    required List<AttendanceModel> attendanceRecords,
    required List<ShiftModel> shifts,
    required int year,
    required int month,
    required String generatedBy,
  }) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'حضور الموظفين');

    sheet.appendRow([
      _val('م'),
      _val('اسم الموظف'),
      _val('التاريخ'),
      _val('وقت الحضور'),
      _val('وقت الانصراف'),
      _val('عدد الساعات'),
      _val('ملاحظات'),
    ]);

    for (int i = 0; i < attendanceRecords.length; i++) {
      final record = attendanceRecords[i];
      final checkInStr = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
      final checkOutStr = record.checkOutTime != null
          ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
          : 'قيد العمل';
      final hours = record.checkOutTime != null
          ? record.checkOutTime!.difference(record.checkInTime).inMinutes / 60.0
          : 0.0;

      sheet.appendRow([
        _val(i + 1),
        _val(record.userName),
        _val(record.date),
        _val(checkInStr),
        _val(checkOutStr),
        _val(double.parse(hours.toStringAsFixed(2))),
        _val(record.notes),
      ]);
    }

    return _saveAndOpen(excel, 'تقرير_حضور_شامل_${year}_$month');
  }

  // ===================================================
  // === تقرير موظف منفرد - Single Nurse Attendance ===
  // ===================================================

  Future<bool> exportSingleNurseAttendanceToExcel({
    required List<AttendanceModel> attendanceRecords,
    required String nurseName,
    required int year,
    required int month,
  }) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'حضور الموظف');

    sheet.appendRow([
      _val('تقرير حضور وانصراف الموظف: $nurseName لشهر: $month/$year'),
    ]);
    sheet.appendRow([]); // سطر فارغ

    sheet.appendRow([
      _val('م'),
      _val('التاريخ'),
      _val('وقت الدخول'),
      _val('وقت الخروج'),
      _val('ساعات العمل'),
      _val('ملاحظات'),
    ]);

    double totalHours = 0;
    for (int i = 0; i < attendanceRecords.length; i++) {
      final record = attendanceRecords[i];
      final checkInStr = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
      final checkOutStr = record.checkOutTime != null
          ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
          : 'قيد العمل';
      final hours = record.checkOutTime != null
          ? record.checkOutTime!.difference(record.checkInTime).inMinutes / 60.0
          : 0.0;
      totalHours += hours;

      sheet.appendRow([
        _val(i + 1),
        _val(record.date),
        _val(checkInStr),
        _val(checkOutStr),
        _val(double.parse(hours.toStringAsFixed(2))),
        _val(record.notes),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      _val(''),
      _val('إجمالي ساعات العمل:'),
      _val(''),
      _val(''),
      _val(double.parse(totalHours.toStringAsFixed(2))),
    ]);

    return _saveAndOpen(
      excel,
      'تقرير_حضور_${nurseName.replaceAll(' ', '_')}_${year}_$month',
    );
  }

  // ============================================
  // === تقرير مسير الرواتب - Payroll Report ===
  // ============================================

  Future<bool> exportPayrollToExcel({
    required List<PayrollModel> payrolls,
    required int year,
    required int month,
  }) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'مسير الرواتب');

    sheet.appendRow([
      _val('م'),
      _val('اسم الموظف'),
      _val('عدد الورديات/العمليات'),
      _val('إجمالي الساعات'),
      _val('راتب الورديات الأساسي (E.P)'),
      _val('بدل العمليات الخارجية (E.P)'),
      _val('الحوافز/البونص (E.P)'),
      _val('الاستقطاعات (E.P)'),
      _val('صافي المستحق (E.P)'),
      _val('حالة الصرف'),
      _val('ملاحظات'),
    ]);

    for (int i = 0; i < payrolls.length; i++) {
      final p = payrolls[i];
      String statusStr = 'مسودة';
      if (p.status == 'approved') statusStr = 'معتمد';
      if (p.status == 'paid') statusStr = 'تم الصرف';

      sheet.appendRow([
        _val(i + 1),
        _val(p.userName),
        _val(p.totalDays),
        _val(p.totalHours),
        _val(p.baseSalary),
        _val(p.outsideCasesFees),
        _val(p.bonus),
        _val(p.deductions),
        _val(p.netSalary),
        _val(statusStr),
        _val(p.notes),
      ]);
    }

    return _saveAndOpen(excel, 'مسير_الرواتب_${year}_$month');
  }

  // ===================================================
  // === تفاصيل دخل العمليات - Income Details Report ===
  // ===================================================

  Future<bool> exportIncomeDetailsToExcel({
    required List<CaseModel> cases,
    required int year,
    required int month,
    String? nurseName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = _initSheet(excel, 'دخل العمليات');

    final title = nurseName != null
        ? 'تفاصيل دخل عمليات الممرض: $nurseName لشهر: $month/$year'
        : 'تفاصيل دخل عمليات المركز لشهر: $month/$year';

    sheet.appendRow([_val(title)]);
    sheet.appendRow([]);

    sheet.appendRow([
      _val('م'),
      _val('التاريخ'),
      _val('اسم المريض'),
      _val('الممرض القائم'),
      _val('الخدمة المنفذة'),
      _val('سعر الخدمة (E.P)'),
      _val('سعر المستلزمات (E.P)'),
      _val('الخصم (E.P)'),
      _val('الصافي المدفوع (E.P)'),
      _val('مستحق المركز (E.P)'),
      _val('مستحق الممرض (E.P)'),
    ]);

    double grandTotalPaid = 0;
    double grandTotalNurse = 0;
    double grandTotalCenter = 0;

    for (int i = 0; i < cases.length; i++) {
      final c = cases[i];
      final servicesName = c.services.map((s) => s.name).join(' + ');

      // حساب مستحقات الممرض والمركز
      // بدل العمليات الخارجية (15 E.P لكل عملية خارج المركز)
      double nurseShare = 0;
      if (c.caseType == CaseType.homeVisit) {
        // بدل عملية خارجية ثابتة
        nurseShare = 15.0; // القيمة الافتراضية
      }

      double centerShare = c.grandTotal - nurseShare;

      grandTotalPaid += c.grandTotal;
      grandTotalNurse += nurseShare;
      grandTotalCenter += centerShare;

      sheet.appendRow([
        _val(i + 1),
        _val(DateFormat('yyyy-MM-dd').format(c.caseDate)),
        _val(c.patientName),
        _val(c.nurseName),
        _val(servicesName),
        _val(c.servicesTotal),
        _val(c.suppliesTotal),
        _val(c.discount),
        _val(c.grandTotal),
        _val(centerShare),
        _val(nurseShare),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      _val(''),
      _val('الإجمالي العام:'),
      _val(''),
      _val(''),
      _val(''),
      _val(''),
      _val(''),
      _val(''),
      _val(grandTotalPaid),
      _val(grandTotalCenter),
      _val(grandTotalNurse),
    ]);

    final fileSuffix = nurseName != null
        ? '_${nurseName.replaceAll(' ', '_')}'
        : '_شامل';
    return _saveAndOpen(excel, 'تفاصيل_دخل_العمليات_${year}_$month$fileSuffix');
  }

  // ============================================
  // === التقرير المالي - Financial Report ===
  // ============================================

  Future<bool> exportFinancialsToExcel({
    required List<CaseModel> cases,
    required List<ExpenseModel> expenses,
    required DateTime start,
    required DateTime end,
  }) async {
    final excel = Excel.createExcel();

    // 1. ورقة الإيرادات والمصروفات الإجمالية - Summary Sheet
    final summarySheet = _initSheet(excel, 'الملخص المالي');

    double totalIncome = cases.fold(0, (sum, c) => sum + c.grandTotal);
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double netProfit = totalIncome - totalExpenses;

    summarySheet.appendRow([
      _val(
        'التقرير المالي للفترة من ${DateFormat('yyyy-MM-dd').format(start)} إلى ${DateFormat('yyyy-MM-dd').format(end)}',
      ),
    ]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([_val('البند المالي'), _val('القيمة (E.P)')]);
    summarySheet.appendRow([
      _val('إجمالي الإيرادات (المقبوضات)'),
      _val(totalIncome),
    ]);
    summarySheet.appendRow([
      _val('إجمالي المصروفات التشغيلية'),
      _val(totalExpenses),
    ]);
    summarySheet.appendRow([_val('صافي الأرباح التشغيلية'), _val(netProfit)]);

    // 2. ورقة تفاصيل الإيرادات - Revenues Sheet
    final revSheet = excel['تفاصيل الإيرادات'];
    revSheet.appendRow([
      _val('م'),
      _val('التاريخ'),
      _val('اسم المريض'),
      _val('نوع الخدمة'),
      _val('الممرض القائم'),
      _val('الإجمالي قبل الخصم'),
      _val('الخصم'),
      _val('الصافي المحصل'),
    ]);
    for (int i = 0; i < cases.length; i++) {
      final c = cases[i];
      revSheet.appendRow([
        _val(i + 1),
        _val(DateFormat('yyyy-MM-dd').format(c.caseDate)),
        _val(c.patientName),
        _val(c.caseType.label),
        _val(c.nurseName),
        _val(c.totalPrice),
        _val(c.discount),
        _val(c.grandTotal),
      ]);
    }

    // 3. ورقة تفاصيل المصروفات - Expenses Sheet
    final expSheet = excel['تفاصيل المصروفات'];
    expSheet.appendRow([
      _val('م'),
      _val('التاريخ'),
      _val('البند/المصروف'),
      _val('التصنيف'),
      _val('القيمة (E.P)'),
      _val('الموظف المسؤول'),
      _val('ملاحظات'),
    ]);
    for (int i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      expSheet.appendRow([
        _val(i + 1),
        _val(DateFormat('yyyy-MM-dd').format(e.date)),
        _val(e.label),
        _val(e.category),
        _val(e.amount),
        _val(e.createdBy),
        _val(e.notes),
      ]);
    }

    return _saveAndOpen(
      excel,
      'التقرير_المالي_${DateFormat('yyyy_MM_dd').format(start)}_إلى_${DateFormat('yyyy_MM_dd').format(end)}',
    );
  }
}
