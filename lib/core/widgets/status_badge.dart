import 'package:flutter/material.dart';
import '../../core/enums/case_status.dart';

/// شارة الحالة - Status Badge Widget
/// تعرض حالة الملف بلون مميز
class StatusBadge extends StatelessWidget {
  final CaseStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: fontSize + 2),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة المخزون - Stock Badge Widget
class StockBadge extends StatelessWidget {
  final int quantity;
  final int minStock;
  final double fontSize;

  const StockBadge({
    super.key,
    required this.quantity,
    required this.minStock,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;
    IconData icon;

    if (quantity <= 0) {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
      label = 'نفد المخزون';
      icon = Icons.error_rounded;
    } else if (quantity <= minStock) {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
      label = 'مخزون منخفض';
      icon = Icons.warning_rounded;
    } else {
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFFD1FAE5);
      label = 'متوفر';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: fontSize + 2),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة الدور - Role Badge Widget
class RoleBadge extends StatelessWidget {
  final String role;
  final double fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (role) {
      case 'super_admin':
        color = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFEDE9FE);
        label = 'مدير عام';
        break;
      case 'admin':
        color = const Color(0xFF2563EB);
        bgColor = const Color(0xFFDBEAFE);
        label = 'مشرف';
        break;
      default:
        color = const Color(0xFF059669);
        bgColor = const Color(0xFFD1FAE5);
        label = 'ممرض';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
