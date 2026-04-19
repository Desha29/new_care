import 'package:flutter/material.dart';

/// أنواع التقارير - Report Types
enum ReportType {
  daily('daily', 'تقرير يومي', Icons.today_rounded),
  weekly('weekly', 'تقرير أسبوعي', Icons.date_range_rounded),
  monthly('monthly', 'تقرير شهري', Icons.calendar_month_rounded),
  custom('custom', 'تقرير مخصص', Icons.tune_rounded);

  final String value;
  final String label;
  final IconData icon;
  const ReportType(this.value, this.label, this.icon);

  /// تحويل من نص إلى ReportType
  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.daily,
    );
  }
}

/// أقسام التقارير - Report Sections
enum ReportSection {
  cases('cases', 'الحالات', Icons.medical_services_rounded),
  financial('financial', 'المالية', Icons.account_balance_wallet_rounded),
  attendance('attendance', 'الحضور والانصراف', Icons.fingerprint_rounded),
  inventory('inventory', 'المستلزمات', Icons.inventory_2_rounded),
  staff('staff', 'الموظفين', Icons.people_rounded);

  final String value;
  final String label;
  final IconData icon;
  const ReportSection(this.value, this.label, this.icon);

  static ReportSection fromString(String value) {
    return ReportSection.values.firstWhere(
      (section) => section.value == value,
      orElse: () => ReportSection.cases,
    );
  }
}
