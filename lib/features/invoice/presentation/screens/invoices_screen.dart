import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/services/report_service.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../cases/logic/cubit/cases_cubit.dart';
import '../../../cases/logic/cubit/cases_state.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh cases/invoices on load
    context.read<CasesCubit>().loadCases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الفواتير والإيصالات',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              hintText: 'البحث برقم الهاتف أو اسم المريض...',
              onChanged: (v) => context.read<CasesCubit>().searchCases(v),
            ),
          ),
          Expanded(
            child: BlocBuilder<CasesCubit, CasesState>(
              builder: (context, state) {
                if (state is CasesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CasesLoaded) {
                  final cases = state.filteredCases;
                  if (cases.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد فواتير حاليا',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      final caseData = cases[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.receipt_long,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            caseData.patientName.isNotEmpty
                                ? caseData.patientName
                                : 'مريض (${caseData.patientPhone})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'التاريخ: ${caseData.caseDate.toLocal().toString().split(' ')[0]}\nالإجمالي: ${caseData.totalPrice} جنيه',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text(
                              'عرض الإيصال',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            onPressed: () {
                              ReportService.instance.generateCaseInvoice(
                                caseData,
                              );
                            },
                          ),
                        ),
                      );
                    },
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
}
