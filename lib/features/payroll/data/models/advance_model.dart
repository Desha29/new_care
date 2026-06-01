import 'package:new_care/core/utils/date_utils.dart';

/// نموذج السلف - Advance Model (Salafa)
/// يمثل عملية سلفة واحدة لموظف معين
class AdvanceModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final DateTime date;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const AdvanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.date,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  /// تحويل إلى خريطة لـ Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// إنشاء من خريطة Firebase
  factory AdvanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AdvanceModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: AppDateUtils.parseDynamic(map['date']),
      notes: map['notes'] ?? '',
      createdAt: AppDateUtils.parseDynamic(map['createdAt']),
      updatedAt: AppDateUtils.parseDynamic(map['updatedAt']),
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

  /// نسخة معدلة - copyWith
  AdvanceModel copyWith({
    String? userId,
    String? userName,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AdvanceModel(
      id: id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
