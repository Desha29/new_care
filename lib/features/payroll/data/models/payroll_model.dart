/// نموذج الرواتب - Payroll Model
/// حساب الراتب بناءً على ساعات العمل
class PayrollModel {
  final String id;
  final String userId;
  final String userName;
  final int year;
  final int month;
  final double totalHours;
  final double hourlyRate;
  final double baseSalary;
  final double bonus;
  final double deductions;
  final double netSalary;
  final int totalDays;
  final int absentDays;
  final String status; // draft, approved, paid
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const PayrollModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.year,
    required this.month,
    this.totalHours = 0,
    this.hourlyRate = 0,
    this.baseSalary = 0,
    this.bonus = 0,
    this.deductions = 0,
    this.netSalary = 0,
    this.totalDays = 0,
    this.absentDays = 0,
    this.status = 'draft',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  /// حساب صافي الراتب - Calculate net salary
  double get calculatedNetSalary => baseSalary + bonus - deductions;

  /// حساب الراتب الأساسي من الساعات - Calculate base from hours
  double get calculatedBaseSalary => totalHours * hourlyRate;

  /// نسبة الحضور - Attendance rate
  double get attendanceRate {
    if (totalDays == 0) return 0;
    return ((totalDays - absentDays) / totalDays) * 100;
  }

  /// اسم الشهر بالعربية - Month name (Arabic)
  String get monthName {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return months[month - 1];
  }

  /// عنوان الفترة - Period title
  String get periodTitle => '$monthName $year';

  /// تحويل إلى خريطة - To map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'year': year,
      'month': month,
      'totalHours': totalHours,
      'hourlyRate': hourlyRate,
      'baseSalary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
      'netSalary': netSalary,
      'totalDays': totalDays,
      'absentDays': absentDays,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// من الخريطة - From map (Firebase)
  factory PayrollModel.fromMap(Map<String, dynamic> map, String id) {
    return PayrollModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      totalHours: (map['totalHours'] ?? 0).toDouble(),
      hourlyRate: (map['hourlyRate'] ?? 0).toDouble(),
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      bonus: (map['bonus'] ?? 0).toDouble(),
      deductions: (map['deductions'] ?? 0).toDouble(),
      netSalary: (map['netSalary'] ?? 0).toDouble(),
      totalDays: map['totalDays'] ?? 0,
      absentDays: map['absentDays'] ?? 0,
      status: map['status'] ?? 'draft',
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// تحويل إلى خريطة SQLite
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// نسخة معدلة - Copy with
  PayrollModel copyWith({
    String? userId,
    String? userName,
    int? year,
    int? month,
    double? totalHours,
    double? hourlyRate,
    double? baseSalary,
    double? bonus,
    double? deductions,
    double? netSalary,
    int? totalDays,
    int? absentDays,
    String? status,
    String? notes,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PayrollModel(
      id: id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      year: year ?? this.year,
      month: month ?? this.month,
      totalHours: totalHours ?? this.totalHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      baseSalary: baseSalary ?? this.baseSalary,
      bonus: bonus ?? this.bonus,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      totalDays: totalDays ?? this.totalDays,
      absentDays: absentDays ?? this.absentDays,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
