import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/case_status.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';

/// شاشة إدارة الحالات - Cases Management Screen
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  final List<Map<String, dynamic>> _cases = [
    {'id': '1', 'patient': 'أحمد محمد علي', 'nurse': 'سارة أحمد', 'type': 'in_center', 'status': 'completed', 'date': '06/04', 'time': '10:30', 'price': 450.0},
    {'id': '2', 'patient': 'فاطمة حسن', 'nurse': 'محمد عادل', 'type': 'home_visit', 'status': 'in_progress', 'date': '06/04', 'time': '11:00', 'price': 600.0},
    {'id': '3', 'patient': 'محمود عبد الرحمن', 'nurse': 'نورا خالد', 'type': 'in_center', 'status': 'pending', 'date': '06/04', 'time': '11:30', 'price': 350.0},
    {'id': '4', 'patient': 'نورا سعيد', 'nurse': 'أحمد حسام', 'type': 'home_visit', 'status': 'completed', 'date': '06/04', 'time': '09:00', 'price': 800.0},
    {'id': '5', 'patient': 'عمر خالد', 'nurse': 'سارة أحمد', 'type': 'in_center', 'status': 'pending', 'date': '06/04', 'time': '12:30', 'price': 300.0},
    {'id': '6', 'patient': 'سارة عادل', 'nurse': 'محمد عادل', 'type': 'home_visit', 'status': 'cancelled', 'date': '05/04', 'time': '14:00', 'price': 500.0},
    {'id': '7', 'patient': 'يوسف إبراهيم', 'nurse': 'نورا خالد', 'type': 'home_visit', 'status': 'completed', 'date': '05/04', 'time': '10:00', 'price': 700.0},
    {'id': '8', 'patient': 'هند محمد', 'nurse': 'أحمد حسام', 'type': 'in_center', 'status': 'in_progress', 'date': '06/04', 'time': '13:00', 'price': 400.0},
  ];

  List<Map<String, dynamic>> get _filtered {
    var r = _cases.toList();
    if (_statusFilter != 'all') r = r.where((c) => c['status'] == _statusFilter).toList();
    if (_searchQuery.isNotEmpty) {
      r = r.where((c) => c['patient'].toString().contains(_searchQuery) || c['nurse'].toString().contains(_searchQuery)).toList();
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppStrings.cases, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('إدارة ومتابعة الحالات الطبية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),
        SearchBarWidget(hintText: AppStrings.searchCases, controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v)),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showCaseDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(AppStrings.addCase, style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'value': 'all', 'label': 'الكل', 'count': _cases.length},
      {'value': 'pending', 'label': AppStrings.pending, 'count': _cases.where((c) => c['status'] == 'pending').length},
      {'value': 'in_progress', 'label': AppStrings.inProgress, 'count': _cases.where((c) => c['status'] == 'in_progress').length},
      {'value': 'completed', 'label': AppStrings.completed, 'count': _cases.where((c) => c['status'] == 'completed').length},
      {'value': 'cancelled', 'label': AppStrings.cancelled, 'count': _cases.where((c) => c['status'] == 'cancelled').length},
    ];
    return Row(
      children: filters.map((f) {
        final sel = _statusFilter == f['value'];
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => setState(() => _statusFilter = f['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppColors.primary : AppColors.border)),
              child: Row(children: [
                Text(f['label'] as String, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sel ? Colors.white.withValues(alpha: 0.2) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                  child: Text('${f['count']}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textHint))),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [_hc('المريض', 2), _hc('الممرض', 2), _hc('النوع', 1), _hc('الحالة', 2), _hc('التاريخ', 1), _hc('السعر', 1), _hc('إجراءات', 2)]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text(AppStrings.noCases, style: TextStyle(fontFamily: 'Cairo', color: AppColors.textHint)))
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (_, i) => _row(_filtered[i], i),
                ),
        ),
      ]),
    );
  }

  Widget _hc(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)));

  Widget _row(Map<String, dynamic> c, int i) {
    final status = CaseStatus.fromString(c['status']);
    final type = CaseType.fromString(c['type']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(children: [
        Expanded(flex: 2, child: Text(c['patient'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(c['nurse'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
        Expanded(flex: 1, child: Row(children: [Icon(type.icon, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text(type.label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))])),
        Expanded(flex: 2, child: StatusBadge(status: status, fontSize: 11)),
        Expanded(flex: 1, child: Text(c['date'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 1, child: Text('${(c['price'] as double).toStringAsFixed(0)} ${AppStrings.currency}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Row(children: [
          _ab(Icons.receipt_long_rounded, AppColors.success, () {}),
          const SizedBox(width: 4),
          _ab(Icons.edit_rounded, AppColors.warning, () => _showCaseDialog(caseData: c)),
          const SizedBox(width: 4),
          _ab(Icons.delete_rounded, AppColors.error, () => setState(() => _cases.removeWhere((x) => x['id'] == c['id']))),
        ])),
      ]),
    );
  }

  Widget _ab(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)));
  }

  void _showCaseDialog({Map<String, dynamic>? caseData}) {
    final isEdit = caseData != null;
    String selType = caseData?['type'] ?? 'in_center';
    String selStatus = caseData?['status'] ?? 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 550, padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.medical_services_rounded, color: AppColors.secondary, size: 22)),
          const SizedBox(width: 12),
          Text(isEdit ? AppStrings.editCase : AppStrings.addCase, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 20),
        const Text(AppStrings.caseType, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          _chip('داخل المركز', 'in_center', Icons.local_hospital_rounded, selType, (v) => ss(() => selType = v)),
          const SizedBox(width: 10),
          _chip('زيارة منزلية', 'home_visit', Icons.home_rounded, selType, (v) => ss(() => selType = v)),
        ]),
        const SizedBox(height: 16),
        const Text(AppStrings.caseStatus, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: CaseStatus.values.map((s) {
          final isSel = selStatus == s.value;
          return GestureDetector(onTap: () => ss(() => selStatus = s.value),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: isSel ? s.backgroundColor : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? s.color : AppColors.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.icon, size: 14, color: isSel ? s.color : AppColors.textHint), const SizedBox(width: 6), Text(s.label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? s.color : AppColors.textSecondary))])));
        }).toList()),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')))),
        ]),
      ])),
    )));
  }

  Widget _chip(String l, String v, IconData ic, String sel, Function(String) fn) {
    final s = sel == v;
    return Expanded(child: GestureDetector(onTap: () => fn(v), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: s ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: s ? AppColors.secondary : AppColors.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, size: 18, color: s ? AppColors.secondary : AppColors.textHint), const SizedBox(width: 8), Text(l, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: s ? FontWeight.w600 : FontWeight.w400, color: s ? AppColors.secondary : AppColors.textSecondary))]))));
  }
}
