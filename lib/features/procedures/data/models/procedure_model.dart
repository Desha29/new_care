import 'package:equatable/equatable.dart';

/// نموذج الإجراءات الطبية - Medical Procedure Model
class ProcedureModel extends Equatable {
  final String id;
  final String name;
  final double defaultPrice;
  final String notes;

  const ProcedureModel({
    required this.id,
    required this.name,
    this.defaultPrice = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'defaultPrice': defaultPrice,
      'notes': notes,
    };
  }

  factory ProcedureModel.fromMap(Map<String, dynamic> map, String id) {
    return ProcedureModel(
      id: id,
      name: map['name'] ?? '',
      defaultPrice: (map['defaultPrice'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  ProcedureModel copyWith({
    String? id,
    String? name,
    double? defaultPrice,
    String? notes,
  }) {
    return ProcedureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, name, defaultPrice, notes];
}
