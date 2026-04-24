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
