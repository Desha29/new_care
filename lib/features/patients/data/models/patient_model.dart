import 'package:equatable/equatable.dart';

/// نموذج المريض - Patient Model
class PatientModel extends Equatable {
  final String id;
  final String name;
  final int age;
  final String gender; // 'male' or 'female'
  final String phone;
  final String address;
  final String medicalHistory;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // User ID who created this record

  const PatientModel({
    required this.id,
    required this.name,
    required this.age,
    this.gender = 'male',
    this.phone = '',
    this.address = '',
    this.medicalHistory = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
  });

  /// من Firestore Map
  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
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
      'age': age,
      'gender': gender,
      'phone': phone,
      'address': address,
      'medicalHistory': medicalHistory,
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
  factory PatientModel.fromSqliteMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? address,
    String? medicalHistory,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// عرض الجنس بالعربية
  String get genderLabel => gender == 'male' ? 'ذكر' : 'أنثى';

  @override
  List<Object?> get props => [id, name, age, gender, phone, address, medicalHistory, notes, createdAt, updatedAt, createdBy];
}
