/// نموذج مسير الراتب - Salary Slip Model
/// بيان الراتب التفصيلي للطباعة
class SalarySlipModel {
  final String id;
  final String payrollId;
  final String userId;
  final String userName;
  final String userRole;
  final String period; // e.g., "أبريل 2026"
  final int year;
  final int month;

  // === تفاصيل الحضور - Attendance Details ===
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final double totalHoursWorked;
  final double hourlyRate;

  // === التفاصيل المالية - Financial Details ===
  final double baseSalary;
  final double overtimeHours;
  final double overtimeAmount;
  final double bonus;
  final double allowances;
  final double deductions;
  final double penalties;
  final double grossSalary;
  final double netSalary;

  // === معلومات إضافية - Additional Info ===
  final String notes;
  final DateTime generatedAt;
  final String generatedBy;

  const SalarySlipModel({
    required this.id,
    required this.payrollId,
    required this.userId,
    required this.userName,
    this.userRole = '',
    required this.period,
    required this.year,
    required this.month,
    this.workingDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.totalHoursWorked = 0,
    this.hourlyRate = 0,
    this.baseSalary = 0,
    this.overtimeHours = 0,
    this.overtimeAmount = 0,
    this.bonus = 0,
    this.allowances = 0,
    this.deductions = 0,
    this.penalties = 0,
    this.grossSalary = 0,
    this.netSalary = 0,
    this.notes = '',
    required this.generatedAt,
    this.generatedBy = '',
  });

  /// إجمالي الإضافات - Total additions
  double get totalAdditions => baseSalary + overtimeAmount + bonus + allowances;

  /// إجمالي الخصومات - Total deductions
  double get totalDeductions => deductions + penalties;

  /// تحويل إلى خريطة - To map
  Map<String, dynamic> toMap() {
    return {
      'payrollId': payrollId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'period': period,
      'year': year,
      'month': month,
      'workingDays': workingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'totalHoursWorked': totalHoursWorked,
      'hourlyRate': hourlyRate,
      'baseSalary': baseSalary,
      'overtimeHours': overtimeHours,
      'overtimeAmount': overtimeAmount,
      'bonus': bonus,
      'allowances': allowances,
      'deductions': deductions,
      'penalties': penalties,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'notes': notes,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
    };
  }

  /// من الخريطة - From map
  factory SalarySlipModel.fromMap(Map<String, dynamic> map, String id) {
    return SalarySlipModel(
      id: id,
      payrollId: map['payrollId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      period: map['period'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      workingDays: map['workingDays'] ?? 0,
      presentDays: map['presentDays'] ?? 0,
      absentDays: map['absentDays'] ?? 0,
      totalHoursWorked: (map['totalHoursWorked'] ?? 0).toDouble(),
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      overtimeHours: (map['overtimeHours'] ?? 0).toDouble(),
      overtimeAmount: (map['overtimeAmount'] ?? 0).toDouble(),
      bonus: (map['bonus'] ?? 0).toDouble(),
      allowances: (map['allowances'] ?? 0).toDouble(),
      deductions: (map['deductions'] ?? 0).toDouble(),
      penalties: (map['penalties'] ?? 0).toDouble(),
      grossSalary: (map['grossSalary'] ?? 0).toDouble(),
      netSalary: (map['netSalary'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
      generatedAt: DateTime.tryParse(map['generatedAt'] ?? '') ?? DateTime.now(),
      generatedBy: map['generatedBy'] ?? '',
    );
  }
}
