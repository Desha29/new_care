import 'package:flutter/material.dart';





/// نوع الحالة - Case Type (داخل/خارج المركز)
enum CaseType {
  inCenter('in_center', 'داخل المركز'),
  homeVisit('home_visit', 'زيارة منزلية');

  final String value;
  final String label;
  const CaseType(this.value, this.label);

  static CaseType fromString(String value) {
    return CaseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CaseType.inCenter,
    );
  }

  IconData get icon {
    switch (this) {
      case CaseType.inCenter:
        return Icons.local_hospital_rounded;
      case CaseType.homeVisit:
        return Icons.home_rounded;
    }
  }

  bool get isHome => this == CaseType.homeVisit;
  bool get isInCenter => this == CaseType.inCenter;
}
