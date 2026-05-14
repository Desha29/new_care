import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/cases_cubit.dart';
import '../cubit/cases_state.dart';
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
    String? nurseId;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      nurseId = user.role.isAdmin ? null : user.id;
    }
    context.read<CasesCubit>().loadCases(nurseId: nurseId, timeFilter: TimeFilter.today);
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<CasesCubit, CasesState>(
        listener: (context, state) {
          if (state is CasesError) {
            UIFeedback.showError(context, state.message);
          }
        },
        child: BlocBuilder<CasesCubit, CasesState>(
          buildWhen: (previous, current) => 
              current is CasesLoading || 
              current is CasesLoaded || 
              current is CasesError,
          builder: (context, state) {
            if (state is CasesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CasesError) {
              return EmptyStateWidget.error(
                message: state.message,
                onRetry: () => _loadData(),
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
                    Expanded(
                      child: CasesTable(cases: state.filteredCases),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
