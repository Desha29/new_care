import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../cubit/procedures_cubit.dart';
import '../cubit/procedures_state.dart';
import '../widgets/procedures_header.dart';
import '../widgets/procedures_table.dart';
import '../widgets/procedure_form_dialog.dart';

class ProceduresScreen extends StatefulWidget {
  const ProceduresScreen({super.key});

  @override
  State<ProceduresScreen> createState() => _ProceduresScreenState();
}

class _ProceduresScreenState extends State<ProceduresScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProceduresCubit>().loadProcedures();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProceduresHeader(
            onAdd: () => ProcedureFormDialog.show(
              context,
              context.read<ProceduresCubit>(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: isDesktop ? 2 : 1,
                child: SearchBarWidget(
                  controller: _searchCtrl,
                  hintText: 'ابحث عن الإجراء أو الخدمة...',
                  onChanged: (v) =>
                      context.read<ProceduresCubit>().searchProcedures(v),
                ),
              ),
              if (isDesktop) const Spacer(flex: 3),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<ProceduresCubit, ProceduresState>(
              builder: (context, state) {
                if (state is ProceduresLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProceduresError) {
                  return Center(child: Text(state.message));
                } else if (state is ProceduresLoaded) {
                  final query = state.searchQuery.toLowerCase().trim();
                  final filtered = state.procedures.where((e) {
                    if (query.isEmpty) return true;
                    return e.name.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.medical_services_rounded,
                      title: 'لا توجد إجراءات',
                      subtitle: 'تأكد من اختيار إجراءات وإضافتها للنظام',
                      actionLabel: 'إضافة إجراء',
                      onAction: () => ProcedureFormDialog.show(
                        context,
                        context.read<ProceduresCubit>(),
                      ),
                    );
                  }

                  return ProceduresTable(
                    procedures: filtered,
                    onEdit: (item) => ProcedureFormDialog.show(
                      context,
                      context.read<ProceduresCubit>(),
                      item: item,
                    ),
                    onDelete: (item) => _confirmDelete(context, item),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    final res = await ConfirmDialog.show(
      context,
      title: 'حذف الإجراء',
      message: 'هل أنت متأكد من حذف الإجراء "${item.name}"؟',
      confirmText: AppStrings.delete,
      icon: Icons.delete_forever_rounded,
    );

    if (res == true && context.mounted) {
      context.read<ProceduresCubit>().deleteProcedure(item.id);
    }
  }
}
