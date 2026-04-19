import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/case_status.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../invoice/presentation/screens/invoice_preview_screen.dart';

import '../../data/models/case_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../../procedures/data/models/procedure_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_care/features/cases/logic/cubit/cases_cubit.dart';
import 'package:new_care/features/cases/logic/cubit/cases_state.dart';
import 'package:new_care/features/invoice/logic/cubit/invoice_cubit.dart';

import 'package:new_care/features/procedures/logic/cubit/procedures_cubit.dart';
import 'package:new_care/features/procedures/logic/cubit/procedures_state.dart';
import 'package:new_care/features/inventory/logic/cubit/inventory_cubit.dart';
import 'package:new_care/features/inventory/logic/cubit/inventory_state.dart';

/// شاشة إدارة الحالات - Cases Management Screen
class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

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
                  _buildHeader(context, state),
                  const SizedBox(height: 24),
                  Expanded(child: _buildTable(context, state)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CasesLoaded state) {
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

  Widget _buildTable(BuildContext context, CasesLoaded state) {
    final filtered = state.filteredCases;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _hc('المريض / العميل', 3),
                _hc('الممرض', 2),
                _hc('النوع', 2),
                _hc('السعر', 2),
                _hc('إجراءات', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget.cases(
                    onAction: () => _showCaseDialog(context),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) => _row(context, filtered[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(
      t,
      style: AppTypography.tableHeader.copyWith(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _row(BuildContext context, CaseModel c, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven
          ? Colors.transparent
          : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.patientName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (c.patientPhone.isNotEmpty)
                  Text(
                    c.patientPhone,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              c.nurseName.isNotEmpty ? c.nurseName : '-',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(c.caseType.icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.caseType.label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.totalPrice.toStringAsFixed(0)} ${AppStrings.currency}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconActionButton(
                  icon: Icons.receipt_long_rounded,
                  tooltip: 'فاتورة',
                  color: AppColors.success,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(caseData: c),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconActionButton.edit(
                  onPressed: () => _showCaseDialog(context, caseData: c),
                ),
                const SizedBox(width: 4),
                IconActionButton.delete(
                  onPressed: () => _confirmDelete(context, c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCaseDialog(
    BuildContext context, {
    CaseModel? caseData,
  }) async {
    final isEdit = caseData != null;
    final formKey = GlobalKey<FormState>();

    // controllers for fields that aren't in InvoiceCubit
    final patientPhoneCtrl = TextEditingController(
      text: caseData?.patientPhone ?? '',
    );
    final patientAddressCtrl = TextEditingController(
      text: caseData?.patientAddress ?? '',
    );
    final notesCtrl = TextEditingController(text: caseData?.notes ?? '');

    // Temp selection states for adding to the lists
    String? tmpServiceName;
    final tmpServicePriceCtrl = TextEditingController(text: '0');
    String? tmpSupplyId;
    final tmpSupplyQtyCtrl = TextEditingController(text: '1');

    CaseType selType = caseData?.caseType ?? CaseType.inCenter;
    String? selNurseId;
    String? selNurseName = caseData?.nurseName;

    // Load necessary lists once
    final nurses = await FirebaseService.instance.getActiveNurses();
    final procedures = context.read<ProceduresCubit>().state is ProceduresLoaded
        ? (context.read<ProceduresCubit>().state as ProceduresLoaded).procedures
        : await FirebaseService.instance.getAllProcedures();
    final inventory = context.read<InventoryCubit>().state is InventoryLoaded
        ? (context.read<InventoryCubit>().state as InventoryLoaded).items
        : await FirebaseService.instance.getAllInventory();

    if (caseData != null && caseData.nurseName.isNotEmpty) {
      final idx = nurses.indexWhere((n) => n.name == caseData.nurseName);
      if (idx != -1) selNurseId = nurses[idx].id;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider(
        create: (_) => InvoiceCubit(initialCase: caseData),
        child: BlocBuilder<InvoiceCubit, InvoiceState>(
          builder: (formCtx, formState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: StatefulBuilder(
                builder: (context, dialogSetState) {
                  return Container(
                    width: 650,
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogHeader(ctx, isEdit),
                            const SizedBox(height: 20),

                            if (selType == CaseType.homeVisit) ...[
                              const Text(
                                'بيانات المريض (للزيارة المنزلية)',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _dialogField(
                                      'رقم الهاتف',
                                      patientPhoneCtrl,
                                      Icons.phone_android_rounded,
                                      isNumber: true,
                                      isRequired: true,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _dialogField(
                                      'العنوان',
                                      patientAddressCtrl,
                                      Icons.location_on_rounded,
                                      isRequired: true,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 40),
                            ],

                            const Text(
                              'بيانات الخدمة / الحالة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCaseTypeSelector(selType, (v) {
                              dialogSetState(() => selType = v);
                            }),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNurseDropdown(
                                    nurses,
                                    selNurseId,
                                    (id, name) {
                                      selNurseId = id;
                                      selNurseName = name;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _dialogField(
                                    'السعر النهائي للإجراءات',
                                    TextEditingController(
                                      text: formState.totalPrice
                                          .toStringAsFixed(0),
                                    ),
                                    Icons.payments_rounded,
                                    isReadOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            _buildServicesSection(
                              formCtx,
                              formState,
                              procedures,
                              tmpServiceName,
                              (v) => tmpServiceName = v,
                              tmpServicePriceCtrl,
                              selType,
                            ),
                            const SizedBox(height: 16),
                            _buildSuppliesSection(
                              formCtx,
                              formState,
                              inventory,
                              tmpSupplyId,
                              (v) => tmpSupplyId = v,
                              tmpSupplyQtyCtrl,
                            ),

                            const SizedBox(height: 16),
                            _dialogField(
                              'ملاحظات عن الحالة',
                              notesCtrl,
                              Icons.notes_rounded,
                              maxLines: 2,
                            ),

                            const SizedBox(height: 24),
                            _buildDialogActions(
                              context,
                              formCtx,
                              formState,
                              isEdit,
                              caseData,
                              patientPhoneCtrl,
                              patientAddressCtrl,
                              notesCtrl,
                              selNurseName,
                              selType,
                              formKey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext ctx, bool isEdit) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
            color: AppColors.secondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEdit ? 'تعديل بيانات الحالة' : 'إضافة حالة / مريض جديد',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(ctx),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildCaseTypeSelector(CaseType sel, Function(CaseType) onChanged) {
    return StatefulBuilder(
      builder: (context, ss) => Row(
        children: [
          _chip(
            'داخل المركز',
            CaseType.inCenter,
            Icons.local_hospital_rounded,
            sel,
            (v) {
              ss(() => sel = v);
              onChanged(v);
            },
          ),
          const SizedBox(width: 10),
          _chip('زيارة منزلية', CaseType.homeVisit, Icons.home_rounded, sel, (
            v,
          ) {
            ss(() => sel = v);
            onChanged(v);
          }),
        ],
      ),
    );
  }

  Widget _buildNurseDropdown(
    List<UserModel> nurses,
    String? selId,
    Function(String, String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الممرض المسئول',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selId,
          hint: const Text(
            'اختر الممرض',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: nurses
              .map((n) => DropdownMenuItem(value: n.id, child: Text(n.name)))
              .toList(),
          onChanged: (v) {
            if (v != null)
              onChanged(v, nurses.firstWhere((n) => n.id == v).name);
          },
          validator: (v) => v == null ? 'مطلوب إختيار ممرض' : null,
        ),
      ],
    );
  }

  Widget _buildServicesSection(
    BuildContext formCtx,
    InvoiceState state,
    List<ProcedureModel> procedures,
    String? tmpName,
    Function(String?) setTmpName,
    TextEditingController priceCtrl,
    CaseType selType,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الخدمات المقدمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: tmpName,
                  hint: const Text(
                    'أختر الإجراء',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  items: procedures
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.name,
                          child: Text(
                            e.name,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setTmpName(v);
                    if (v != null) {
                      final proc = procedures.firstWhere((p) => p.name == v);
                      // اختيار السعر بناءً على نوع الحالة (داخل المركز أو زيارة منزلية)
                      final price = selType == CaseType.inCenter
                          ? proc.priceInside
                          : proc.priceOutside;
                      priceCtrl.text = price.toStringAsFixed(0);
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _dialogField(
                  'السعر',
                  priceCtrl,
                  Icons.attach_money_rounded,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (tmpName != null) {
                    formCtx.read<InvoiceCubit>().addProcedure(
                      ServiceItem(
                        name: tmpName,
                        price: double.tryParse(priceCtrl.text) ?? 0,
                        quantity: 1,
                      ),
                    );
                    setTmpName(null);
                    priceCtrl.text = '0';
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إضافة'),
              ),
            ],
          ),
          ...state.services.map(
            (s) => ListTile(
              dense: true,
              title: Text(s.name, style: const TextStyle(fontFamily: 'Cairo')),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    formCtx.read<InvoiceCubit>().removeProcedure(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliesSection(
    BuildContext formCtx,
    InvoiceState state,
    List<InventoryModel> inventory,
    String? tmpId,
    Function(String?) setTmpId,
    TextEditingController qtyCtrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المستلزمات المستخدمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: tmpId,
                  hint: const Text(
                    'أختر المستلزم',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  items: inventory
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(
                            '${e.name} (${e.quantity})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: setTmpId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _dialogField(
                  'الكمية',
                  qtyCtrl,
                  Icons.numbers,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (tmpId != null) {
                    final item = inventory.firstWhere((i) => i.id == tmpId);
                    formCtx.read<InvoiceCubit>().addSupply(
                      SupplyUsed(
                        inventoryId: item.id,
                        name: item.name,
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        unitPrice: item.price,
                      ),
                    );
                    setTmpId(null);
                    qtyCtrl.text = '1';
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إضافة'),
              ),
            ],
          ),
          ...state.supplies.map(
            (s) => ListTile(
              dense: true,
              title: Text(s.name, style: const TextStyle(fontFamily: 'Cairo')),
              subtitle: Text('الكمية: ${s.quantity}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => formCtx.read<InvoiceCubit>().removeSupply(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
    BuildContext screenCtx,
    BuildContext formCtx,
    InvoiceState formState,
    bool isEdit,
    CaseModel? caseData,
    TextEditingController phone,
    TextEditingController address,
    TextEditingController notes,
    String? nurseName,
    CaseType type,
    GlobalKey<FormState> formKey,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(formCtx),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final updatedCase = CaseModel(
                  id: caseData?.id ?? FirebaseService.instance.generateId(),
                  patientName: 'مريض',
                  patientPhone: phone.text,
                  patientAddress: address.text,
                  nurseName: nurseName ?? '',
                  totalPrice: formState.totalPrice,
                  services: formState.services,
                  suppliesUsed: formState.supplies,
                  caseType: type,
                  notes: notes.text,
                  caseDate: caseData?.caseDate ?? DateTime.now(),
                  createdAt: caseData?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: caseData?.createdBy ?? uid,
                );

                // Handle Stock subtraction for new cases, or if modified (simplified logic just subtracts based on the form if it's not a complete rework of edit flow)
                if (!isEdit) {
                  try {
                    final inventoryRepo = await FirebaseService.instance
                        .getAllInventory();
                    for (var supply in formState.supplies) {
                      final item = inventoryRepo.firstWhere(
                        (i) => i.id == supply.inventoryId,
                      );
                      if (item.quantity >= supply.quantity) {
                        final updatedItem = item.copyWith(
                          quantity: item.quantity - supply.quantity,
                          updatedAt: DateTime.now(),
                        );
                        await screenCtx.read<InventoryCubit>().addOrUpdateItem(
                          updatedItem,
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error updating stock: $e');
                  }
                }

                await screenCtx.read<CasesCubit>().addCase(updatedCase);
                if (screenCtx.mounted) {
                  Navigator.pop(formCtx);
                  ConfirmDialog.show(
                    screenCtx,
                    title: 'معاينة الفاتورة',
                    message: 'هل تريد معاينة وطباعة الفاتورة الآن؟',
                    confirmText: 'معاينة',
                  ).then((v) {
                    if (v == true && screenCtx.mounted) {
                      Navigator.push(
                        screenCtx,
                        MaterialPageRoute(
                          builder: (_) =>
                              InvoicePreviewScreen(caseData: updatedCase),
                        ),
                      );
                    }
                  });
                }
              }
            },
            child: Text(
              AppStrings.save,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = false,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          readOnly: isReadOnly,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          validator: isRequired
              ? (v) => v == null || v.isEmpty ? 'مطلوب' : null
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: isReadOnly,
            fillColor: isReadOnly ? AppColors.surfaceVariant : null,
          ),
        ),
      ],
    );
  }

  Widget _chip(
    String l,
    CaseType v,
    IconData ic,
    CaseType sel,
    Function(CaseType) fn,
  ) {
    final s = sel == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => fn(v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: s
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s ? AppColors.secondary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ic,
                size: 18,
                color: s ? AppColors.secondary : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                l,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: s ? FontWeight.w600 : FontWeight.w400,
                  color: s ? AppColors.secondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CaseModel c) async {
    final result = await ConfirmDialog.show(
      context,
      title: 'حذف الحالة',
      message: 'هل أنت متأكد؟',
    );
    if (result == true && context.mounted) {
      context.read<CasesCubit>().deleteCase(c);
    }
  }
}
