import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/case_status.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/case_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// شاشة إدارة الحالات - Cases Management Screen
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  CaseStatus? _statusFilter; // null means 'all'

  bool _isLoading = true;
  bool _isOffline = false;
  List<CaseModel> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (!isConnected) {
        if (mounted) setState(() => _isOffline = true);
      } else {
        if (mounted) setState(() => _isOffline = false);
      }

      final cases = await FirebaseService.instance.getAllCases();
      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _cases = cases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الحالات: ${e.toString()}')),
        );
      }
    }
  }

  List<CaseModel> get _filtered {
    var r = _cases.toList();
    if (_statusFilter != null) {
      r = r.where((c) => c.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      r = r.where((c) => 
        c.patientName.toLowerCase().contains(q) || 
        c.nurseName.toLowerCase().contains(q)
      ).toList();
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppColors.error),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              AppStrings.offlineMode,
                              style: TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadCases,
                            child: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    ),

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Row(
                children: [
                  const Text(AppStrings.cases, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(width: 12),
                  IconButton(onPressed: _loadCases, icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20)),
                ],
              ),
              const Text('إدارة ومتابعة الحالات الطبية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
            ]
          ),
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
      {'value': null, 'label': 'الكل', 'count': _cases.length},
      {'value': CaseStatus.pending, 'label': AppStrings.pending, 'count': _cases.where((c) => c.status == CaseStatus.pending).length},
      {'value': CaseStatus.inProgress, 'label': AppStrings.inProgress, 'count': _cases.where((c) => c.status == CaseStatus.inProgress).length},
      {'value': CaseStatus.completed, 'label': AppStrings.completed, 'count': _cases.where((c) => c.status == CaseStatus.completed).length},
      {'value': CaseStatus.cancelled, 'label': AppStrings.cancelled, 'count': _cases.where((c) => c.status == CaseStatus.cancelled).length},
    ];
    return Row(
      children: filters.map((f) {
        final val = f['value'] as CaseStatus?;
        final sel = _statusFilter == val;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => setState(() => _statusFilter = val),
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
          child: Row(children: [_hc('المريض', 2), _hc('الممرض', 2), _hc('النوع', 1), _hc('الحالة', 2), _hc('الوقت', 1), _hc('السعر', 1), _hc('إجراءات', 2)]),
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

  Widget _row(CaseModel c, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(children: [
        Expanded(flex: 2, child: Text(c.patientName.isNotEmpty ? c.patientName : 'مجهول', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Text(c.nurseName.isNotEmpty ? c.nurseName : '-', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
        Expanded(flex: 1, child: Row(children: [Icon(c.caseType.icon, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text(c.caseType.label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis))])),
        Expanded(flex: 2, child: StatusBadge(status: c.status, fontSize: 11)),
        Expanded(flex: 1, child: Text(DateFormat('yyyy-MM-dd HH:mm').format(c.caseDate), style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
        Expanded(flex: 1, child: Text('${c.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(flex: 2, child: Row(children: [
          _ab(Icons.receipt_long_rounded, AppColors.success, () => ReportService.instance.generateCaseInvoice(c)),
          const SizedBox(width: 4),
          _ab(Icons.edit_rounded, AppColors.warning, () => _showCaseDialog(caseData: c)),
          const SizedBox(width: 4),
          _ab(Icons.delete_rounded, AppColors.error, () => _confirmDelete(c)),
        ])),
      ]),
    );
  }

  Widget _ab(IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(
      message: 'إجراء',
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color))),
    );
  }

  void _showCaseDialog({CaseModel? caseData}) {
    final isEdit = caseData != null;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    CaseType selType = caseData?.caseType ?? CaseType.inCenter;
    CaseStatus selStatus = caseData?.status ?? CaseStatus.pending;
    
    final patientNameCtrl = TextEditingController(text: caseData?.patientName ?? '');
    final nurseNameCtrl = TextEditingController(text: caseData?.nurseName ?? '');
    final priceCtrl = TextEditingController(text: caseData?.totalPrice.toString() ?? '');
    final notesCtrl = TextEditingController(text: caseData?.notes ?? '');

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 550, padding: const EdgeInsets.all(28), child: isSaving
        ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
        : Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(isEdit ? Icons.edit_rounded : Icons.medical_services_rounded, color: AppColors.secondary, size: 22)),
              const SizedBox(width: 12),
              Text(isEdit ? AppStrings.editCase : AppStrings.addCase, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 20),
            _dialogField('الرقم التعريفي للمريض المقترن (يجب أن يكون مسجل في النظام)', patientNameCtrl, Icons.person_rounded, isRequired: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _dialogField('الممرض/الطبيب (اختياري)', nurseNameCtrl, Icons.health_and_safety_rounded)),
              const SizedBox(width: 14),
              Expanded(child: _dialogField('السعر الإجمالي', priceCtrl, Icons.money_rounded, isNumber: true, isRequired: true)),
            ]),
            const SizedBox(height: 16),
            const Text(AppStrings.caseType, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _chip('داخل المركز', CaseType.inCenter, Icons.local_hospital_rounded, selType, (v) => ss(() => selType = v)),
              const SizedBox(width: 10),
              _chip('زيارة منزلية', CaseType.homeVisit, Icons.home_rounded, selType, (v) => ss(() => selType = v)),
            ]),
            const SizedBox(height: 16),
            const Text(AppStrings.caseStatus, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: CaseStatus.values.map((s) {
              final isSel = selStatus == s;
              return GestureDetector(onTap: () => ss(() => selStatus = s),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: isSel ? s.backgroundColor : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? s.color : AppColors.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.icon, size: 14, color: isSel ? s.color : AppColors.textHint), const SizedBox(width: 6), Text(s.label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? s.color : AppColors.textSecondary))])));
            }).toList()),
            const SizedBox(height: 16),
            _dialogField('ملاحظات إضافية', notesCtrl, Icons.notes_rounded, maxLines: 2),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  ss(() => isSaving = true);
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final newCase = CaseModel(
                      id: caseData?.id ?? '',
                      patientId: patientNameCtrl.text, // for simplicty we use name in ID here if they don't pick from dropdown
                      patientName: patientNameCtrl.text,
                      nurseName: nurseNameCtrl.text,
                      totalPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                      caseType: selType,
                      status: selStatus,
                      notes: notesCtrl.text,
                      caseDate: caseData?.caseDate ?? DateTime.now(),
                      createdAt: caseData?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      createdBy: caseData?.createdBy ?? uid,
                    );

                    final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
                    if (isEdit) {
                      await FirebaseService.instance.updateCase(newCase);
                      await LocalLogService.instance.logActivity(
                        userId: uid,
                        userName: uName,
                        action: 'update_case',
                        actionLabel: 'تعديل حالة',
                        targetType: 'case',
                        targetId: newCase.id,
                        details: 'تم تعديل حالة المريض: ${newCase.patientName}',
                      );
                    } else {
                      await FirebaseService.instance.createCase(newCase);
                      await LocalLogService.instance.logActivity(
                        userId: uid,
                        userName: uName,
                        action: 'add_case',
                        actionLabel: 'إضافة حالة',
                        targetType: 'case',
                        targetId: newCase.id,
                        details: 'تم إضافة حالة جديدة للمريض: ${newCase.patientName}',
                      );
                      await NotificationService.instance.showNotification(
                        title: 'حالة طبية جديدة',
                        body: 'تم تسجيل حالة ${newCase.caseType.label} للمريض ${newCase.patientName}',
                      );
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadCases();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'تم تحديث الحالة بنجاح' : 'تم إضافة الحالة بنجاح', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    ss(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }, child: Text(AppStrings.save, style: const TextStyle(fontFamily: 'Cairo')))),
            ]),
          ]),
        ),
      )),
    )));
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
            if (isRequired) const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _chip(String l, CaseType v, IconData ic, CaseType sel, Function(CaseType) fn) {
    final s = sel == v;
    return Expanded(child: GestureDetector(onTap: () => fn(v), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: s ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: s ? AppColors.secondary : AppColors.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, size: 18, color: s ? AppColors.secondary : AppColors.textHint), const SizedBox(width: 8), Text(l, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: s ? FontWeight.w600 : FontWeight.w400, color: s ? AppColors.secondary : AppColors.textSecondary))]))));
  }

  void _confirmDelete(CaseModel c) async {
    final result = await ConfirmDialog.show(
      context,
      title: 'حذف الحالة',
      message: 'هل أنت متأكد من حذف الحالة الخاصة بالمريض "${c.patientName}"؟\nسيتم حذف جميع البيانات المرتبطة بها نهائياً.',
      confirmText: AppStrings.delete,
      icon: Icons.delete_forever_rounded,
    );
    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
        await FirebaseService.instance.deleteCase(c.id);
        await LocalLogService.instance.logActivity(
          userId: uid,
          userName: uName,
          action: 'delete_case',
          actionLabel: 'حذف حالة',
          targetType: 'case',
          targetId: c.id,
          details: 'تم حذف حالة المريض: ${c.patientName}',
        );
        _loadCases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الحالة بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
