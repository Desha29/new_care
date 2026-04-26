import 'dart:convert';
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
/// يدمج بيانات المريض مباشرة في الحالة - Integrates patient data directly
class CaseModel extends Equatable {
  final String id;
  // Patient Details (Merged)
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientPhone;
  final String patientAddress;
  final String medicalHistory;

  final String nurseId;
  final String nurseName;
  final CaseType caseType;
  final List<ServiceItem> services;
  final List<SupplyUsed> suppliesUsed;
  final double totalPrice;
  final double discount;
  final DateTime caseDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const CaseModel({
    required this.id,
    required this.patientName,
    this.patientAge = 0,
    this.patientGender = 'male',
    this.patientPhone = '',
    this.patientAddress = '',
    this.medicalHistory = '',
    this.nurseId = '',
    this.nurseName = '',
    this.caseType = CaseType.inCenter,
    this.services = const [],
    this.suppliesUsed = const [],
    this.totalPrice = 0,
    this.discount = 0,
    required this.caseDate,
    this.notes = '',
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

  /// الجنس بالعربية
  String get patientGenderLabel => patientGender == 'male' ? 'ذكر' : 'أنثى';

  /// من Firestore Map أو SQLite Map
  factory CaseModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle services: could be List (Firestore) or JSON String (SQLite)
    List<ServiceItem> parsedServices = [];
    final rawServices = map['services'];
    if (rawServices is List) {
      parsedServices = rawServices
          .map((e) => ServiceItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (rawServices is String && rawServices.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawServices) as List;
        parsedServices = decoded
            .map((e) => ServiceItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    // Handle suppliesUsed: could be List (Firestore) or JSON String (SQLite)
    List<SupplyUsed> parsedSupplies = [];
    final rawSupplies = map['suppliesUsed'];
    if (rawSupplies is List) {
      parsedSupplies = rawSupplies
          .map((e) => SupplyUsed.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (rawSupplies is String && rawSupplies.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSupplies) as List;
        parsedSupplies = decoded
            .map((e) => SupplyUsed.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    return CaseModel(
      id: id,
      patientName: map['patientName'] ?? '',
      patientAge: map['patientAge'] ?? 0,
      patientGender: map['patientGender'] ?? 'male',
      patientPhone: map['patientPhone'] ?? '',
      patientAddress: map['patientAddress'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      nurseId: map['nurseId'] ?? '',
      nurseName: map['nurseName'] ?? '',
      caseType: CaseType.fromString(map['caseType'] ?? 'in_center'),
      services: parsedServices,
      suppliesUsed: parsedSupplies,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      caseDate: DateTime.tryParse(map['caseDate'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientPhone': patientPhone,
      'patientAddress': patientAddress,
      'medicalHistory': medicalHistory,
      'nurseId': nurseId,
      'nurseName': nurseName,
      'caseType': caseType.value,
      'services': services.map((e) => e.toMap()).toList(),
      'suppliesUsed': suppliesUsed.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'discount': discount,
      'caseDate': caseDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// إلى SQLite Map (مع الخدمات والمستلزمات كـ JSON)
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientPhone': patientPhone,
      'patientAddress': patientAddress,
      'medicalHistory': medicalHistory,
      'nurseId': nurseId,
      'nurseName': nurseName,
      'caseType': caseType.value,
      'totalPrice': totalPrice,
      'discount': discount,
      'caseDate': caseDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'services': jsonEncode(services.map((e) => e.toMap()).toList()),
      'suppliesUsed': jsonEncode(suppliesUsed.map((e) => e.toMap()).toList()),
    };
  }

  CaseModel copyWith({
    String? id,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? patientPhone,
    String? patientAddress,
    String? medicalHistory,
    String? nurseId,
    String? nurseName,
    CaseType? caseType,
    List<ServiceItem>? services,
    List<SupplyUsed>? suppliesUsed,
    double? totalPrice,
    double? discount,
    DateTime? caseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CaseModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientPhone: patientPhone ?? this.patientPhone,
      patientAddress: patientAddress ?? this.patientAddress,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      nurseId: nurseId ?? this.nurseId,
      nurseName: nurseName ?? this.nurseName,
      caseType: caseType ?? this.caseType,
      services: services ?? this.services,
      suppliesUsed: suppliesUsed ?? this.suppliesUsed,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      caseDate: caseDate ?? this.caseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientName,
    patientAge,
    patientGender,
    patientPhone,
    patientAddress,
    medicalHistory,
    nurseId,
    nurseName,
    caseType,
    services,
    suppliesUsed,
    totalPrice,
    discount,
    caseDate,
    notes,
    createdAt,
    updatedAt,
    createdBy,
  ];
}
