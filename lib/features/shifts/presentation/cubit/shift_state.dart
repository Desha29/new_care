import 'package:equatable/equatable.dart';
import '../../data/models/shift_model.dart';

abstract class ShiftState extends Equatable {
  const ShiftState();
  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftLoaded extends ShiftState {
  final List<ShiftModel> shifts;
  final ShiftModel? todayShift; // وردية المستخدم الحالي اليوم
  final String searchQuery;
  final String selectedDate;
  final Map<String, int> caseCounts; // عدد الحالات لكل ممرض - case count per nurse

  const ShiftLoaded({
    required this.shifts,
    this.todayShift,
    this.searchQuery = '',
    this.selectedDate = '',
    this.caseCounts = const {},
  });

  List<ShiftModel> get filteredShifts {
    if (searchQuery.isEmpty) return shifts;
    final q = searchQuery.toLowerCase();
    return shifts.where((s) =>
      s.userName.toLowerCase().contains(q) ||
      s.roleToday.label.contains(q)
    ).toList();
  }

  @override
  List<Object?> get props => [shifts, todayShift, searchQuery, selectedDate, caseCounts];
}

class ShiftError extends ShiftState {
  final String message;
  const ShiftError(this.message);
  @override
  List<Object?> get props => [message];
}
