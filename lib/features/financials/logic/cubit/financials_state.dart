part of 'financials_cubit.dart';

abstract class FinancialsState extends Equatable {
  const FinancialsState();

  @override
  List<Object?> get props => [];
}

class FinancialsInitial extends FinancialsState {}

class FinancialsLoading extends FinancialsState {}

class FinancialsLoaded extends FinancialsState {
  final List<CaseModel> cases;
  final List<ExpenseModel> expenses;
  final bool isOffline;

  const FinancialsLoaded({
    required this.cases,
    required this.expenses,
    this.isOffline = false,
  });

  double get totalIncome => cases.fold(0, (sum, c) => sum + c.totalPrice);
  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get netProfit => totalIncome - totalExpenses;

  @override
  List<Object?> get props => [cases, expenses, isOffline];
}

class FinancialsError extends FinancialsState {
  final String message;

  const FinancialsError(this.message);

  @override
  List<Object?> get props => [message];
}
