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
  final String searchQuery;

  const FinancialsLoaded({
    required this.cases,
    required this.expenses,
    this.isOffline = false,
    this.searchQuery = '',
  });

  FinancialsLoaded copyWith({
    List<CaseModel>? cases,
    List<ExpenseModel>? expenses,
    bool? isOffline,
    String? searchQuery,
  }) {
    return FinancialsLoaded(
      cases: cases ?? this.cases,
      expenses: expenses ?? this.expenses,
      isOffline: isOffline ?? this.isOffline,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  double get totalIncome => cases.fold(0, (sum, c) => sum + c.totalPrice);
  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);
  double get netProfit => totalIncome - totalExpenses;

  List<ExpenseModel> get filteredExpenses {
    if (searchQuery.isEmpty) return expenses;
    final q = searchQuery.toLowerCase();
    return expenses.where((e) => 
      e.label.toLowerCase().contains(q) || 
      e.category.toLowerCase().contains(q)
    ).toList();
  }

  @override
  List<Object?> get props => [cases, expenses, isOffline, searchQuery];
}

class FinancialsError extends FinancialsState {
  final String message;

  const FinancialsError(this.message);

  @override
  List<Object?> get props => [message];
}
