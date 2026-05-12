import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../cubit/procedures_cubit.dart';

class ProceduresHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const ProceduresHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
        ),
        const SizedBox(height: 20),
        SearchBarWidget(
          hintText: 'البحث عن إجراء...',
          onChanged: (v) => context.read<ProceduresCubit>().searchProcedures(v),
          maxWidth: double.infinity,
        ),
      ],
    );
  }
}
