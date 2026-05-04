import 'package:equatable/equatable.dart';
import '../../data/models/payroll_model.dart';

/// حالات الرواتب - Payroll States
abstract class PayrollState extends Equatable {
  const PayrollState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية - Initial
class PayrollInitial extends PayrollState {}

/// جاري التحميل - Loading
class PayrollLoading extends PayrollState {}

/// تم التحميل - Loaded
class PayrollLoaded extends PayrollState {
  final List<PayrollModel> payrolls;
  final int selectedYear;
  final int selectedMonth;

  const PayrollLoaded({
    required this.payrolls,
    required this.selectedYear,
    required this.selectedMonth,
  });

  /// إجمالي الرواتب - Total salaries
  double get totalSalaries =>
      payrolls.fold(0, (sum, p) => sum + p.netSalary);

  /// إجمالي الساعات - Total hours
  double get totalHours =>
      payrolls.fold(0, (sum, p) => sum + p.totalHours);

  /// إجمالي الخصومات - Total deductions
  double get totalDeductions =>
      payrolls.fold(0, (sum, p) => sum + p.deductions);

  /// إجمالي الإضافي (ساعات إضافية) - Total overtime bonus
  double get totalBonus =>
      payrolls.fold(0, (sum, p) => sum + p.bonus);

  /// إجمالي العمليات الخارجية - Total outside case fees
  double get totalOutsideFees =>
      payrolls.fold(0, (sum, p) => sum + p.outsideCasesFees);

  /// متوسط سعر الساعة - Average hourly rate
  double get averageHourlyRate {
    if (payrolls.isEmpty) return 0;
    return payrolls.fold(0.0, (sum, p) => sum + p.hourlyRate) / payrolls.length;
  }

  @override
  List<Object?> get props => [payrolls, selectedYear, selectedMonth];
}

/// خطأ - Error
class PayrollError extends PayrollState {
  final String message;
  const PayrollError(this.message);

  @override
  List<Object?> get props => [message];
}

/// نجاح عملية - Action Success (creates, updates)
class PayrollActionSuccess extends PayrollState {
  final String message;
  const PayrollActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
