import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

class ProceduresHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const ProceduresHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الإجراءات والخدمات',
          style: AppTypography.pageTitle.copyWith(fontSize: 24),
        ),
        PrimaryButton(
          label: 'إضافة إجراء جديد',
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
      ],
    );
  }
}
