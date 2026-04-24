import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import 'case_form_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cases_cubit.dart';
import '../cubit/cases_state.dart';

class CasesHeader extends StatelessWidget {
  final CasesLoaded state;

  const CasesHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحالات / المرضى',
                  style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => context.read<CasesCubit>().loadCases(),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
            Text(
              'إدارة و مراجعة الحالات الطبية المسجلة',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMobile)
              SearchBarWidget(
                hintText: 'البحث باسم المريض أو الهاتف...',
                onChanged: (v) => context.read<CasesCubit>().searchCases(v),
              ),
            if (!isMobile) const SizedBox(width: 12),
            PrimaryButton(
              label: isMobile ? 'إضافة' : AppStrings.addCase,
              icon: Icons.add_rounded,
              onPressed: () => _showCaseDialog(context),
            ),
          ],
        ),
        if (isMobile)
          SearchBarWidget(
            hintText: 'البحث باسم المريض أو الهاتف...',
            onChanged: (v) => context.read<CasesCubit>().searchCases(v),
          ),
      ],
    );
  }

  void _showCaseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CasesCubit>()),
        ],
        child: const CaseFormDialog(),
      ),
    );
  }
}
