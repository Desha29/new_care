import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/patient_model.dart';
import '../../logic/cubit/patients_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientsCubit()..loadPatients(),
      child: const _PatientsView(),
    );
  }
}

class _PatientsView extends StatefulWidget {
  const _PatientsView();

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PatientsCubit, PatientsState>(
        listener: (context, state) {
          if (state is PatientsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is PatientsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientsLoaded) {
            final filtered = _filter(state.patients);
            final paged = _page(filtered);
            final totalPages = (filtered.length / _pageSize).ceil();

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isOffline) _buildOfflineBanner(),
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(child: _buildDataTable(context, paged, filtered.isEmpty)),
                  _buildPagination(filtered.length, totalPages),
                ],
              ),
            );
          }

          return const Center(child: Text('حدث خطأ غير متوقع'));
        },
      ),
    );
  }

  List<PatientModel> _filter(List<PatientModel> patients) {
    if (_searchQuery.isEmpty) return patients;
    return patients.where((p) => p.name.contains(_searchQuery) || p.phone.contains(_searchQuery)).toList();
  }

  List<PatientModel> _page(List<PatientModel> patients) {
    final start = _currentPage * _pageSize;
    if (start >= patients.length) return [];
    final end = (start + _pageSize).clamp(0, patients.length);
    return patients.sublist(start, end);
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error)),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          const Expanded(child: Text(AppStrings.offlineMode, style: TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontWeight: FontWeight.bold))),
          TextButton(onPressed: () => context.read<PatientsCubit>().loadPatients(), child: const Text('تحديث')),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.patients, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('إدارة بيانات المرضى المسجلين في النظام', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        SearchBarWidget(
          hintText: AppStrings.searchPatients,
          controller: _searchController,
          onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showPatientDialog(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(AppStrings.addPatient, style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context, List<PatientModel> patients, bool isEmpty) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              children: [
                _hc('الاسم', 3), _hc('العمر', 1), _hc('الجنس', 1), _hc('الهاتف', 2), _hc('العنوان', 2), _hc('التاريخ المرضي', 2), _hc('إجراءات', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: isEmpty
                ? const Center(child: Text(AppStrings.noPatients, style: TextStyle(fontFamily: 'Cairo', color: AppColors.textHint)))
                : ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) => _buildPatientRow(context, patients[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)));

  Widget _buildPatientRow(BuildContext context, PatientModel p, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('${p.age}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          Expanded(flex: 1, child: Text(p.genderLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
          Expanded(flex: 2, child: Text(p.phone, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), textDirection: TextDirection.ltr)),
          Expanded(flex: 2, child: Text(p.address, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(p.medicalHistory, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Row(children: [
            IconButton(onPressed: () => _showPatientDialog(context, patient: p), icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.warning)),
            IconButton(onPressed: () => _confirmDelete(context, p), icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error)),
          ])),
        ],
      ),
    );
  }

  Widget _buildPagination(int count, int total) {
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_right_rounded)),
          Text('صفحة ${_currentPage + 1} من $total', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
          IconButton(onPressed: _currentPage < total - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_left_rounded)),
        ],
      ),
    );
  }

  void _showPatientDialog(BuildContext context, {PatientModel? patient}) {
    final cubit = context.read<PatientsCubit>();
    final isEdit = patient != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: patient?.name ?? '');
    final ageCtrl = TextEditingController(text: patient?.age != null ? patient!.age.toString() : '');
    final phoneCtrl = TextEditingController(text: patient?.phone ?? '');
    final addressCtrl = TextEditingController(text: patient?.address ?? '');
    final historyCtrl = TextEditingController(text: patient?.medicalHistory ?? '');
    String gender = patient?.gender ?? 'male';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? AppStrings.editPatient : AppStrings.addPatient, style: const TextStyle(fontFamily: 'Cairo')),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 12),
                TextFormField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'العمر'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [DropdownMenuItem(value: 'male', child: Text('ذكر')), DropdownMenuItem(value: 'female', child: Text('أنثى'))],
                  onChanged: (v) => gender = v!,
                  decoration: const InputDecoration(labelText: 'الجنس'),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                const SizedBox(height: 12),
                TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
                const SizedBox(height: 12),
                TextFormField(controller: historyCtrl, decoration: const InputDecoration(labelText: 'التاريخ المرضي'), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final p = PatientModel(
                  id: patient?.id ?? '',
                  name: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text) ?? 0,
                  gender: gender,
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  medicalHistory: historyCtrl.text.trim(),
                  notes: patient?.notes ?? '',
                  createdAt: patient?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: patient?.createdBy ?? uid,
                );
                
                if (isEdit) {
                  await cubit.updatePatient(p);
                } else {
                  await cubit.addPatient(p);
                  await NotificationService.instance.showNotification(title: 'مريض جديد', body: 'تم تسجيل ${p.name} بنجاح');
                }
                
                final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
                await LocalLogService.instance.logActivity(userId: uid, userName: uName, action: isEdit ? 'update_patient' : 'add_patient', actionLabel: isEdit ? 'تعديل مريض' : 'إضافة مريض', targetType: 'patient', targetId: p.id, details: 'اسم المريض: ${p.name}');
                
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PatientModel p) async {
    final cubit = context.read<PatientsCubit>();
    final res = await ConfirmDialog.show(context, title: 'حذف مريض', message: 'هل أنت متأكد من حذف ${p.name}؟', confirmText: 'حذف');
    if (res == true) {
      await cubit.deletePatient(p.id);
      final user = FirebaseAuth.instance.currentUser;
      await LocalLogService.instance.logActivity(userId: user?.uid ?? '', userName: user?.displayName ?? 'مستخدم', action: 'delete_patient', actionLabel: 'حذف مريض', targetType: 'patient', targetId: p.id, details: 'تم حذف المريض: ${p.name}');
    }
  }
}
