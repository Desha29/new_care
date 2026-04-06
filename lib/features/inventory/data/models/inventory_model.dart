import 'package:equatable/equatable.dart';

/// نموذج المستلزمات الطبية - Inventory Item Model
class InventoryModel extends Equatable {
  final String id;
  final String name;
  final String unit; // وحدة القياس (قطعة، عبوة، etc.)
  final int quantity;
  final int minStock; // الحد الأدنى للتنبيه
  final double price;
  final String category;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const InventoryModel({
    required this.id,
    required this.name,
    this.unit = 'قطعة',
    this.quantity = 0,
    this.minStock = 5,
    this.price = 0,
    this.category = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  /// هل المخزون منخفض؟
  bool get isLowStock => quantity <= minStock && quantity > 0;

  /// هل نفد المخزون؟
  bool get isOutOfStock => quantity <= 0;

  /// حالة المخزون بالعربية
  String get stockStatusLabel {
    if (isOutOfStock) return 'نفد المخزون';
    if (isLowStock) return 'مخزون منخفض';
    return 'متوفر';
  }

  /// من Firestore Map
  factory InventoryModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryModel(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'قطعة',
      quantity: map['quantity'] ?? 0,
      minStock: map['minStock'] ?? 5,
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minStock': minStock,
      'price': price,
      'category': category,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// إلى SQLite Map
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// من SQLite Map
  factory InventoryModel.fromSqliteMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'قطعة',
      quantity: map['quantity'] ?? 0,
      minStock: map['minStock'] ?? 5,
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  InventoryModel copyWith({
    String? id,
    String? name,
    String? unit,
    int? quantity,
    int? minStock,
    double? price,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      price: price ?? this.price,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [id, name, unit, quantity, minStock, price, category, notes, createdAt, updatedAt, createdBy];
}
