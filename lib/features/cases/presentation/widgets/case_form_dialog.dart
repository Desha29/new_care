import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/features/cases/presentation/cubit/cases_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/case_status.dart'; // Desktop stores CaseType here
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../../inventory/presentation/cubit/inventory_cubit.dart';
import '../../../inventory/presentation/cubit/inventory_state.dart';
import '../../../invoice/presentation/cubit/invoice_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../procedures/data/models/procedure_model.dart';
import '../../../procedures/presentation/cubit/procedures_cubit.dart';
import '../../../procedures/presentation/cubit/procedures_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../financials/presentation/cubit/financials_cubit.dart';
import '../../../payroll/presentation/cubit/payroll_cubit.dart';
import '../../data/models/case_model.dart';
import '../cubit/cases_cubit.dart';
import 'package:uuid/uuid.dart' as uuid;

class CaseFormDialog extends StatefulWidget {
  final CaseModel? caseData;

  const CaseFormDialog({super.key, this.caseData});

  @override
  State<CaseFormDialog> createState() => _CaseFormDialogState();
}

class _CaseFormDialogState extends State<CaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEdit;
  bool _hasChanges = false;

  // Controllers
  late TextEditingController _patientNameCtrl;
  late TextEditingController _patientPhoneCtrl;
  late TextEditingController _patientAddressCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _totalPriceCtrl;

  // Selection states
  CaseType _selType = CaseType.inCenter;
  String? _selNurseId;
  String? _selNurseName;
  List<UserModel> _nurses = [];
  List<ProcedureModel> _procedures = [];
  List<InventoryModel> _inventory = [];

  String? _tmpServiceName;
  final _tmpServicePriceCtrl = TextEditingController(text: '0');
  String? _tmpSupplyId;
  final _tmpSupplyQtyCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _isEdit = widget.caseData != null;
    _patientNameCtrl = TextEditingController(
      text: widget.caseData?.patientName ?? '',
    );
    _patientPhoneCtrl = TextEditingController(
      text: widget.caseData?.patientPhone ?? '',
    );
    _patientAddressCtrl = TextEditingController(
      text: widget.caseData?.patientAddress ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.caseData?.notes ?? '');
    _totalPriceCtrl = TextEditingController(
      text: (widget.caseData?.totalPrice ?? 0).toStringAsFixed(0),
    );
    _selType = widget.caseData?.caseType ?? CaseType.inCenter;
    _selNurseName = widget.caseData?.nurseName;

    _loadData();
  }

  Future<void> _loadData() async {
    _nurses = await FirebaseService.instance.getActiveNurses();
    if (_isEdit && _selNurseName != null) {
      final n =
          _nurses.where((e) => e.name == _selNurseName).firstOrNull ??
          (_nurses.isNotEmpty ? _nurses.first : null);
      if (n != null) {
        _selNurseId = n.id;
      }
    }

    if (!mounted) return;
    final procState = context.read<ProceduresCubit>().state;
    _procedures = procState is ProceduresLoaded
        ? procState.procedures
        : await FirebaseService.instance.getAllProcedures();

    if (!mounted) return;
    final invState = context.read<InventoryCubit>().state;
    _inventory = invState is InventoryLoaded
        ? invState.items
        : await FirebaseService.instance.getAllInventory();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _patientAddressCtrl.dispose();
    _notesCtrl.dispose();
    _totalPriceCtrl.dispose();
    _tmpServicePriceCtrl.dispose();
    _tmpSupplyQtyCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تنبيه',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هناك تغييرات لم يتم حفظها، هل تريد الخروج من نموذج الحالة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إكمال العمل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'نعم، تجاهل التغييرات',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvoiceCubit(
        invoiceRepository: sl<IInvoiceRepository>(),
        initialCase: widget.caseData,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 750,
            padding: const EdgeInsets.all(32),
            child: BlocConsumer<InvoiceCubit, InvoiceState>(
              listener: (context, state) {
                _totalPriceCtrl.text = state.totalPrice.toStringAsFixed(0);
                _markChanged();
              },
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPatientInfoSection()),
                            const SizedBox(width: 32),
                            Expanded(child: _buildCaseDetailsSection(context)),
                          ],
                        ),
                        const Divider(height: 48),
                        _buildServicesSection(context, state),
                        const SizedBox(height: 24),
                        _buildSuppliesSection(context, state),
                        const SizedBox(height: 24),
                        _buildNotesAndActions(context, state),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
            color: AppColors.secondary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _isEdit ? 'تعديل بيانات الحالة' : 'إضافة حالة طبية جديدة',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.close_rounded, size: 32),
        ),
      ],
    );
  }

  Widget _buildPatientInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بيانات المريض الأساسية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _field(
          'اسم المريض',
          _patientNameCtrl,
          Icons.person_rounded,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _field(
          'رقم الهاتف',
          _patientPhoneCtrl,
          Icons.phone_android_rounded,
          isNumber: true,
          isRequired: _selType == CaseType.homeVisit,
        ),
        const SizedBox(height: 16),
        if (_selType == CaseType.homeVisit)
          _field(
            'عنوان المريض',
            _patientAddressCtrl,
            Icons.location_on_rounded,
            isRequired: true,
          ),
      ],
    );
  }

  Widget _buildCaseDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الخدمة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildTypeSelector(context),
        const SizedBox(height: 16),
        _buildNurseDropdown(),
        const SizedBox(height: 16),
        _field(
          'إجمالي السعر (تلقائي)',
          _totalPriceCtrl,
          Icons.payments_rounded,
          isReadOnly: true,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        _typeChip(
          'داخل المركز',
          CaseType.inCenter,
          Icons.local_hospital_rounded,
          context,
        ),
        const SizedBox(width: 12),
        _typeChip(
          'زيارة منزلية',
          CaseType.homeVisit,
          Icons.home_rounded,
          context,
        ),
      ],
    );
  }

  Widget _typeChip(
    String label,
    CaseType type,
    IconData icon,
    BuildContext context,
  ) {
    final isSel = _selType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selType = type;
            // Update the temp dropdown price if a service is selected
            if (_tmpServiceName != null) {
              final p = _procedures
                  .where((e) => e.name == _tmpServiceName)
                  .firstOrNull;
              if (p != null) {
                _tmpServicePriceCtrl.text =
                    (type == CaseType.inCenter ? p.priceInside : p.priceOutside)
                        .toStringAsFixed(0);
              }
            }
          });
          _markChanged();
          // Update all already-added service prices for the new case type
          context.read<InvoiceCubit>().updateServicePrices(_procedures, type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSel ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isSel ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNurseDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selNurseId,
      hint: const Text(
        'اختر الممرض المسئول',
        style: TextStyle(fontFamily: 'Cairo'),
      ),
      decoration: _inputDecoration(
        Icons.badge_rounded,
      ).copyWith(labelText: 'الممرض / المشرف'),
      items: _nurses
          .map(
            (n) => DropdownMenuItem(
              value: n.id,
              child: Text(n.name, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          final n = _nurses.firstWhere((n) => n.id == v);
          setState(() {
            _selNurseId = v;
            _selNurseName = n.name;
          });
          _markChanged();
        }
      },
      validator: (v) => v == null ? 'يرجى اختيار ممرض' : null,
    );
  }

  Widget _buildServicesSection(BuildContext context, InvoiceState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخدمات والإجراءات الطبية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('svc_${_selType.name}'),
                  initialValue: _tmpServiceName,
                  hint: const Text(
                    'اختر الإجراء الطبي',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  decoration: _inputDecoration(null),
                  items: {for (var p in _procedures) p.name: p}.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.name,
                          child: Text(
                            p.name,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _tmpServiceName = v);
                    if (v != null) {
                      final p = _procedures
                          .where((e) => e.name == v)
                          .firstOrNull;
                      if (p != null) {
                        _tmpServicePriceCtrl.text =
                            (_selType == CaseType.inCenter
                                    ? p.priceInside
                                    : p.priceOutside)
                                .toStringAsFixed(0);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'السعر',
                  _tmpServicePriceCtrl,
                  null,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (_tmpServiceName != null) {
                    context.read<InvoiceCubit>().addProcedure(
                      ServiceItem(
                        name: _tmpServiceName!,
                        price: double.tryParse(_tmpServicePriceCtrl.text) ?? 0,
                        quantity: 1,
                      ),
                    );
                    setState(() => _tmpServiceName = null);
                    _tmpServicePriceCtrl.text = '0';
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (state.services.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.services
                  .map(
                    (s) => Chip(
                      label: Text(
                        '${s.name} (${s.price.toStringAsFixed(0)} ج.م)',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onDeleted: () =>
                          context.read<InvoiceCubit>().removeProcedure(s),
                      deleteIconColor: Colors.red,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuppliesSection(BuildContext context, InvoiceState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المستلزمات الطبية المستخدمة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _tmpSupplyId,
                  hint: const Text(
                    'اختر المستلزم',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  decoration: _inputDecoration(null),
                  items: _inventory
                      .map(
                        (i) => DropdownMenuItem(
                          value: i.id,
                          child: Text(
                            i.name,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _tmpSupplyId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'الكمية',
                  _tmpSupplyQtyCtrl,
                  null,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (_tmpSupplyId != null) {
                    final item = _inventory
                        .where((e) => e.id == _tmpSupplyId)
                        .firstOrNull;
                    if (item != null) {
                      context.read<InvoiceCubit>().addSupply(
                        SupplyUsed(
                          inventoryId: item.id,
                          name: item.name,
                          quantity: int.tryParse(_tmpSupplyQtyCtrl.text) ?? 1,
                          unitPrice: item.price,
                        ),
                      );
                      setState(() => _tmpSupplyId = null);
                      _tmpSupplyQtyCtrl.text = '1';
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (state.supplies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.supplies
                  .map(
                    (s) => Chip(
                      label: Text(
                        '${s.name} × ${s.quantity}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onDeleted: () =>
                          context.read<InvoiceCubit>().removeSupply(s),
                      deleteIconColor: Colors.red,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesAndActions(BuildContext context, InvoiceState state) {
    return Column(
      children: [
        _field(
          'ملاحظات إضافية',
          _notesCtrl,
          Icons.note_alt_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: _isEdit ? 'تحديث الحالة' : 'حفظ الحالة',
                onPressed: () => _handleSave(context, state),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context, InvoiceState state) async {
    if (_formKey.currentState!.validate()) {
      if (state.services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى إضافة خدمة واحدة على الأقل',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final newCase = CaseModel(
        id: _isEdit ? widget.caseData!.id : const uuid.Uuid().v4(),
        patientName: _patientNameCtrl.text,
        patientPhone: _patientPhoneCtrl.text,
        patientAddress: _patientAddressCtrl.text,
        notes: _notesCtrl.text,
        nurseId: _selNurseId ?? '',
        nurseName: _selNurseName ?? '',
        caseType: _selType,
        totalPrice: state.totalPrice,
        services: state.services,
        suppliesUsed: state.supplies,
        caseDate: DateTime.now(),
        createdAt: _isEdit ? widget.caseData!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: _isEdit ? widget.caseData!.createdBy : 'desktop_admin',
      );
      if (_isEdit) {
        await context.read<CasesCubit>().updateCase(newCase);
      } else {
        await context.read<CasesCubit>().addCase(newCase);
      }

      // Check if the cubit emitted an error (e.g. insufficient stock)
      final casesState = context.read<CasesCubit>().state;
      if (casesState is CasesError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                casesState.message,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.red,
            ),
          );
          // Restore cases state so the screen doesn't break
          context.read<CasesCubit>().loadCases(force: true);
        }
        return;
      }

      // Refresh all connected features based on user role
      final user = context.read<AuthCubit>().state is AuthAuthenticated
          ? (context.read<AuthCubit>().state as AuthAuthenticated).user
          : null;

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
      context.read<InventoryCubit>().loadInventory(force: true);
      context.read<PayrollCubit>().loadPayroll(force: true);

      _hasChanges = false;
      Navigator.pop(context, true);
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData? icon, {
    bool isNumber = false,
    bool isRequired = false,
    bool isReadOnly = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: isReadOnly,
      maxLines: maxLines,
      onChanged: (_) => _markChanged(),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null
          : null,
      decoration: _inputDecoration(icon).copyWith(labelText: label),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(IconData? icon) {
    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppColors.primary)
          : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }
}
