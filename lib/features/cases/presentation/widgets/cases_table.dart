import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../invoice/presentation/widgets/invoice_preview_dialog.dart';
import '../../data/models/case_model.dart';
import '../cubit/cases_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../financials/presentation/cubit/financials_cubit.dart';
import '../../../payroll/presentation/cubit/payroll_cubit.dart';
import '../cubit/cases_state.dart';
import 'case_form_dialog.dart';
import 'case_card.dart';

class CasesTable extends StatefulWidget {
  final List<CaseModel> cases;

  const CasesTable({super.key, required this.cases});

  @override
  State<CasesTable> createState() => _CasesTableState();
}

class _CasesTableState extends State<CasesTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CasesCubit>().loadMoreCases();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cases.isEmpty) {
      return EmptyStateWidget.cases(onAction: () => _showCaseDialog(context));
    }

    final casesCubit = context.watch<CasesCubit>();
    final isLoadingMore = casesCubit.state is CasesLoaded
        ? (casesCubit.state as CasesLoaded).isLoadingMore
        : false;

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.cases.length + (isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        if (index < widget.cases.length) {
          final c = widget.cases[index];
          return CaseCard(
            caseData: c,
            onTap: () => showDialog(
              context: context,
              builder: (_) => InvoicePreviewDialog(caseData: c),
            ),
            onEdit: () => _showCaseDialog(context, caseData: c),
            onDelete: () => _confirmDelete(context, c),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
      },
    );
  }

  void _showCaseDialog(BuildContext context, {CaseModel? caseData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [BlocProvider.value(value: context.read<CasesCubit>())],
        child: CaseFormDialog(caseData: caseData),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CaseModel c) {
    ConfirmDialog.show(
      context,
      title: 'حذف الحالة',
      message:
          'هل أنت متأكد من حذف حالة المريض "${c.patientName}"؟ لا يمكن التراجع عن هذا الإجراء.',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<CasesCubit>().deleteCase(c);

        final authState = context.read<AuthCubit>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;

        if (user != null) {
          if (user.role.isAdmin) {
            context.read<DashboardCubit>().loadDashboardData(force: true);
          } else {
            context.read<DashboardCubit>().loadNurseDashboardData(
              user.id,
              force: true,
            );
          }
        }

        context.read<FinancialsCubit>().loadFinancials(force: true);
        context.read<PayrollCubit>().loadPayroll(force: true);
      }
    });
  }
}
