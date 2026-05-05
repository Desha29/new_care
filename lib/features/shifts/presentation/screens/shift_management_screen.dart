import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/enums/shift_role.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../cases/data/models/case_model.dart';
import '../cubit/shift_cubit.dart';
import '../cubit/shift_state.dart';
import '../../data/models/shift_model.dart';

/// شاشة إدارة الورديات - Shift Management Screen
class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    context.read<ShiftCubit>().loadShiftsByDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ShiftCubit, ShiftState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 16),
                _buildDateSelector(context),
                const SizedBox(height: 16),
                Expanded(child: _buildShiftsTable(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShiftState state) {
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
            Text(
              'إدارة الورديات',
              style: AppTypography.pageTitle.copyWith(fontSize: titleSize),
            ),
            Text(
              'تعيين ومتابعة ورديات الموظفين يومياً',
              style: AppTypography.pageSubtitle.copyWith(
                fontSize: ResponsiveHelper.getSubtitleFontSize(context),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.read<ShiftCubit>().loadShiftsByDate(_selectedDate),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            PrimaryButton(
              label: 'تعيين وردية',
              icon: Icons.add_rounded,
              onPressed: () => _showCreateShiftDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i - 1)));

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final date = dates[i];
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final isSelected = dateStr == _selectedDate;
          final dayName = DateFormat('EEEE', 'ar').format(date);
          final dayNum = DateFormat('d', 'ar').format(date);
          final isToday = i == 1;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedDate = dateStr);
                context.read<ShiftCubit>().loadShiftsByDate(dateStr);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isToday && !isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftsTable(BuildContext context, ShiftState state) {
    if (state is ShiftLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ShiftError) {
      return Center(
        child: Text(state.message, style: const TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
      );
    }

    List<ShiftModel> shifts = [];
    Map<String, int> caseCounts = {};
    if (state is ShiftLoaded) {
      shifts = state.filteredShifts;
      caseCounts = state.caseCounts;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 800 ? 800.0 : constraints.maxWidth;
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Container(
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
                        _hc('الموظف', 3),
                        _hc('الدور اليوم', 2),
                        _hc('عدد الحالات', 1),
                        _hc('حالات', 1),
                        _hc('مخزون', 1),
                        _hc('خارجي', 1),
                        _hc('مالية', 1),
                        _hc('ملاحظات', 2),
                        _hc('إجراءات', 1),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: shifts.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.event_busy_rounded,
                        title: 'لا توجد ورديات لهذا اليوم',
                        subtitle: 'قم بتعيين ورديات جديدة للموظفين اليوم',
                        actionLabel: 'تعيين وردية الآن',
                        onAction: () => _showCreateShiftDialog(context),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: minWidth,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: shifts.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, i) => _shiftRow(context, shifts[i], i, caseCounts),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hc(String t, int f) => Expanded(
    flex: f,
    child: Text(t, style: AppTypography.tableHeader.copyWith(fontSize: 12)),
  );

  Widget _shiftRow(BuildContext context, ShiftModel shift, int i, Map<String, int> caseCounts) {
    final caseCount = caseCounts[shift.userId] ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, size: 16, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shift.userName,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                shift.roleToday.label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // عدد الحالات - Case count column (clickable)
          Expanded(
            flex: 1,
            child: Center(
              child: InkWell(
                onTap: caseCount > 0
                    ? () => _showNurseCasesDialog(context, shift)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: caseCount > 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textHint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$caseCount',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: caseCount > 0 ? AppColors.success : AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          _permIcon(shift.permissions.canAccessCases, 1),
          _permIcon(shift.permissions.canAccessInventory, 1),
          _permIcon(shift.permissions.canGoExternal, 1),
          _permIcon(shift.permissions.canManageFinancials, 1),
          Expanded(
            flex: 2,
            child: Text(
              shift.notes.isEmpty ? '-' : shift.notes,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: IconActionButton.delete(
              onPressed: () => context.read<ShiftCubit>().deleteShift(shift.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permIcon(bool isEnabled, int flex) {
    return Expanded(
      flex: flex,
      child: Icon(
        isEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 18,
        color: isEnabled ? AppColors.success : AppColors.textHint.withValues(alpha: 0.4),
      ),
    );
  }

  Future<void> _showCreateShiftDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String? selectedUserId;
    String? selectedUserName;
    ShiftRole selectedRole = ShiftRole.cases;
    final notesCtrl = TextEditingController();

    // Load active nurses
    final nurses = await FirebaseService.instance.getActiveNurses();
    final allUsers = await FirebaseService.instance.getAllUsers();
    final staffList = [...nurses, ...allUsers.where((u) => !nurses.any((n) => n.id == u.id) && u.isActive)];

    if (!context.mounted) return;

    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final permissions = ShiftPermissions.fromRole(selectedRole);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_note_rounded, color: AppColors.info, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'تعيين وردية جديدة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // التاريخ
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'التاريخ: $_selectedDate',
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // اختيار الموظف
                      const Text('الموظف', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUserId,
                        hint: const Text('اختر الموظف', style: TextStyle(fontFamily: 'Cairo')),
                        items: staffList.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.role.label})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedUserId = v;
                            selectedUserName = staffList.firstWhere((u) => u.id == v).name;
                          });
                        },
                        validator: (v) => v == null ? 'مطلوب' : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // اختيار الدور
                      const Text('الدور اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ShiftRole.values.map((role) {
                          final isSelected = selectedRole == role;
                          return GestureDetector(
                            onTap: () => setState(() => selectedRole = role),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Text(
                                role.label,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // معاينة الصلاحيات
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الصلاحيات المُعيّنة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _permPreview('الحالات', permissions.canAccessCases),
                            _permPreview('المخزون', permissions.canAccessInventory),
                            _permPreview('الزيارات الخارجية', permissions.canGoExternal),
                            _permPreview('المالية', permissions.canManageFinancials),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ملاحظات
                      const Text('ملاحظات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'ملاحظات اختيارية...',
                          hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  final shift = ShiftModel(
                                    id: const Uuid().v4(),
                                    userId: selectedUserId!,
                                    userName: selectedUserName ?? '',
                                    date: _selectedDate,
                                    roleToday: selectedRole,
                                    permissions: permissions,
                                    notes: notesCtrl.text,
                                    createdBy: currentUserId,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  context.read<ShiftCubit>().createShift(shift);
                                  Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('تعيين الوردية', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _permPreview(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: enabled ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: enabled ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل حالات الممرض - Show nurse cases details dialog
  Future<void> _showNurseCasesDialog(BuildContext context, ShiftModel shift) async {
    // جلب الحالات من SQLite
    final caseMaps = await SqliteService.instance.getCasesByNurseAndDate(
      shift.userId,
      shift.date.isNotEmpty ? shift.date : _selectedDate,
    );
    final cases = caseMaps.map((m) => CaseModel.fromMap(m, m['id'] as String)).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حالات ${shift.userName}',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_selectedDate} • ${cases.length} حالة',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              // Cases list
              Flexible(
                child: cases.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد حالات',
                          style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: cases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = cases[index];
                          final time = DateFormat('hh:mm a', 'ar').format(c.caseDate);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Patient name & time
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        c.patientName,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        time,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Patient details row
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    _caseInfoChip(Icons.phone_rounded, c.patientPhone.isNotEmpty ? c.patientPhone : '-'),
                                    _caseInfoChip(Icons.person_rounded, '${c.patientAge} سنة - ${c.patientGenderLabel}'),
                                    _caseInfoChip(
                                      c.caseType.value == 'outside' ? Icons.directions_car_rounded : Icons.local_hospital_rounded,
                                      c.caseType.value == 'outside' ? 'زيارة خارجية' : 'داخل المركز',
                                    ),
                                  ],
                                ),

                                // Services
                                if (c.services.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'الخدمات:',
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  ...c.services.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            s.name,
                                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                                          ),
                                        ),
                                        Text(
                                          '${s.total.toStringAsFixed(0)} ج.م',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],

                                // Total
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'الإجمالي',
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${c.grandTotal.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Notes
                                if (c.notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'ملاحظات: ${c.notes}',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Summary footer
              if (cases.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryItem('عدد الحالات', '${cases.length}', Icons.assignment_rounded),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _summaryItem(
                        'إجمالي الإيرادات',
                        '${cases.fold<double>(0, (sum, c) => sum + c.grandTotal).toStringAsFixed(0)} ج.م',
                        Icons.payments_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _caseInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
