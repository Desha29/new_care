import 'package:equatable/equatable.dart';

/// نموذج الإجراءات الطبية - Medical Procedure Model
class ProcedureModel extends Equatable {
  final String id;
  final String name;
  final double defaultPrice;
  final double priceInside;
  final double priceOutside;
  final String notes;

  const ProcedureModel({
    required this.id,
    required this.name,
    this.defaultPrice = 0.0,
    this.priceInside = 0.0,
    this.priceOutside = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'defaultPrice': defaultPrice,
      'priceInside': priceInside,
      'priceOutside': priceOutside,
      'notes': notes,
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
    );
  }

  ProcedureModel copyWith({
    String? id,
    String? name,
    double? defaultPrice,
    double? priceInside,
    double? priceOutside,
    String? notes,
  }) {
    return ProcedureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      priceInside: priceInside ?? this.priceInside,
      priceOutside: priceOutside ?? this.priceOutside,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, name, defaultPrice, priceInside, priceOutside, notes];
}
