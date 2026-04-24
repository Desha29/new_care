import 'package:equatable/equatable.dart';

/// نموذج الإجراءات الطبية - Medical Procedure Model
class ProcedureModel extends Equatable {
  final String id;
  final String name;
  final double defaultPrice;
  final double priceInside;
  final double priceOutside;
  final String notes;

  final DateTime? updatedAt;

  const ProcedureModel({
    required this.id,
    required this.name,
    this.defaultPrice = 0.0,
    this.priceInside = 0.0,
    this.priceOutside = 0.0,
    this.notes = '',
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'defaultPrice': defaultPrice,
      'priceInside': priceInside,
      'priceOutside': priceOutside,
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'priceInside': priceInside,
      'priceOutside': priceOutside,
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory ProcedureModel.fromMap(Map<String, dynamic> map, String id) {
    final dPrice = (map['defaultPrice'] ?? 0.0).toDouble();
    return ProcedureModel(
      id: id,
      name: map['name'] ?? '',
      defaultPrice: dPrice,
      priceInside: (map['priceInside'] ?? dPrice).toDouble(),
      priceOutside: (map['priceOutside'] ?? dPrice).toDouble(),
      notes: map['notes'] ?? '',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  ProcedureModel copyWith({
    String? id,
    String? name,
    double? defaultPrice,
    double? priceInside,
    double? priceOutside,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ProcedureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      priceInside: priceInside ?? this.priceInside,
      priceOutside: priceOutside ?? this.priceOutside,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, defaultPrice, priceInside, priceOutside, notes, updatedAt];
}
