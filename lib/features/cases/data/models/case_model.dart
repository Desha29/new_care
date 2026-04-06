import 'package:equatable/equatable.dart';
import 'package:new_care/core/enums/case_status.dart';

/// نموذج الخدمة المقدمة - Service Item in a Case
class ServiceItem extends Equatable {
  final String name;
  final double price;
  final int quantity;
  final String notes;

  const ServiceItem({
    required this.name,
    this.price = 0,
    this.quantity = 1,
    this.notes = '',
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'quantity': quantity, 'notes': notes};
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, price, quantity, notes];
}

/// نموذج المستلزم المستخدم - Supply Used in a Case
class SupplyUsed extends Equatable {
  final String inventoryId;
  final String name;
  final int quantity;
  final double unitPrice;

  const SupplyUsed({
    required this.inventoryId,
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'inventoryId': inventoryId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory SupplyUsed.fromMap(Map<String, dynamic> map) {
    return SupplyUsed(
      inventoryId: map['inventoryId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [inventoryId, name, quantity, unitPrice];
}

/// نموذج الحالة الطبية - Medical Case Model
class CaseModel extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String nurseId;
  final String nurseName;
  final CaseType caseType;
  final CaseStatus status;
  final List<ServiceItem> services;
  final List<SupplyUsed> suppliesUsed;
  final double totalPrice;
  final double discount;
  final DateTime caseDate;
  final String notes;
  final String address; // For home visits
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CaseModel({
    required this.id,
    required this.patientId,
    this.patientName = '',
    this.nurseId = '',
    this.nurseName = '',
    this.caseType = CaseType.inCenter,
    this.status = CaseStatus.pending,
    this.services = const [],
    this.suppliesUsed = const [],
    this.totalPrice = 0,
    this.discount = 0,
    required this.caseDate,
    this.notes = '',
    this.address = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  /// الإجمالي بعد الخصم
  double get grandTotal => totalPrice - discount;

  /// مجموع الخدمات
  double get servicesTotal => services.fold(0, (sum, s) => sum + s.total);

  /// مجموع المستلزمات
  double get suppliesTotal => suppliesUsed.fold(0, (sum, s) => sum + s.total);

  /// من Firestore Map
  factory CaseModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      nurseId: map['nurseId'] ?? '',
      nurseName: map['nurseName'] ?? '',
      caseType: CaseType.fromString(map['caseType'] ?? 'in_center'),
      status: CaseStatus.fromString(map['status'] ?? 'pending'),
      services:
          (map['services'] as List<dynamic>?)
              ?.map((e) => ServiceItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      suppliesUsed:
          (map['suppliesUsed'] as List<dynamic>?)
              ?.map((e) => SupplyUsed.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      caseDate: DateTime.tryParse(map['caseDate'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
      address: map['address'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'nurseId': nurseId,
      'nurseName': nurseName,
      'caseType': caseType.value,
      'status': status.value,
      'services': services.map((e) => e.toMap()).toList(),
      'suppliesUsed': suppliesUsed.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'discount': discount,
      'caseDate': caseDate.toIso8601String(),
      'notes': notes,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// إلى SQLite Map (بدون القوائم المتداخلة)
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'nurseId': nurseId,
      'nurseName': nurseName,
      'caseType': caseType.value,
      'status': status.value,
      'totalPrice': totalPrice,
      'discount': discount,
      'caseDate': caseDate.toIso8601String(),
      'notes': notes,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  CaseModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? nurseId,
    String? nurseName,
    CaseType? caseType,
    CaseStatus? status,
    List<ServiceItem>? services,
    List<SupplyUsed>? suppliesUsed,
    double? totalPrice,
    double? discount,
    DateTime? caseDate,
    String? notes,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CaseModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      nurseId: nurseId ?? this.nurseId,
      nurseName: nurseName ?? this.nurseName,
      caseType: caseType ?? this.caseType,
      status: status ?? this.status,
      services: services ?? this.services,
      suppliesUsed: suppliesUsed ?? this.suppliesUsed,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      caseDate: caseDate ?? this.caseDate,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    nurseId,
    nurseName,
    caseType,
    status,
    services,
    suppliesUsed,
    totalPrice,
    discount,
    caseDate,
    notes,
    address,
    createdAt,
    updatedAt,
    createdBy,
  ];
}
