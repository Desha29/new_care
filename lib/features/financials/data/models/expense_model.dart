import 'package:equatable/equatable.dart';

/// نموذج المصاريف - Expense Model
class ExpenseModel extends Equatable {
  final String id;
  final String category; // النوع (إيجار، كهرباء، مرتبات، مستلزمات، إلخ)
  final String label; // وصف المصروف
  final double amount;
  final DateTime date;
  final String createdBy; // المستخدم الذي سجل المصروف
  final String notes;

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.label,
    required this.amount,
    required this.date,
    required this.createdBy,
    this.notes = '',
  });

  /// من Firestore Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      category: map['category'] ?? '',
      label: map['label'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'label': label,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, category, label, amount, date, createdBy, notes];
}
