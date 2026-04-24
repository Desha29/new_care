import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/logic/cubit/auth_cubit.dart';
import '../../../auth/logic/cubit/auth_state.dart';
import '../../logic/cubit/cases_cubit.dart';
import '../../logic/cubit/cases_state.dart';
import '../widgets/cases_header.dart';
import '../widgets/cases_table.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      // If nurse, filter by their own ID. If admin/manager, pass null to see all.
      final nurseId = user.role.isAdmin ? null : user.id;
      context.read<CasesCubit>().loadCases(nurseId: nurseId);
    } else {
      context.read<CasesCubit>().loadCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CasesError) {
            return EmptyStateWidget.error(
              message: state.message,
              onRetry: () => context.read<CasesCubit>().loadCases(),
            );
          }
          if (state is CasesLoaded) {
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CasesHeader(state: state),
                  const SizedBox(height: 24),
                  Expanded(child: CasesTable(cases: state.filteredCases)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
