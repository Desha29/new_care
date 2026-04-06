import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/dialogs/confirm_dialog.dart';

/// شاشة إدارة المرضى - Patients Management Screen
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  final int _pageSize = 10;

  // بيانات تجريبية - Sample data
  final List<Map<String, dynamic>> _patients = [
    {'id': '1', 'name': 'أحمد محمد علي', 'age': 45, 'gender': 'male', 'phone': '01012345678', 'address': 'المعادي، القاهرة', 'history': 'ضغط دم مرتفع'},
    {'id': '2', 'name': 'فاطمة حسن إبراهيم', 'age': 62, 'gender': 'female', 'phone': '01098765432', 'address': 'مصر الجديدة، القاهرة', 'history': 'سكري نوع 2'},
    {'id': '3', 'name': 'محمود عبد الرحمن', 'age': 38, 'gender': 'male', 'phone': '01155566677', 'address': 'الدقي، الجيزة', 'history': 'كسر في الساق'},
    {'id': '4', 'name': 'نورا سعيد أحمد', 'age': 55, 'gender': 'female', 'phone': '01288899900', 'address': 'المهندسين، الجيزة', 'history': 'عملية قلب مفتوح'},
    {'id': '5', 'name': 'عمر خالد محمد', 'age': 72, 'gender': 'male', 'phone': '01033344455', 'address': 'التجمع الخامس، القاهرة', 'history': 'التهاب رئوي'},
    {'id': '6', 'name': 'سارة عادل حسين', 'age': 29, 'gender': 'female', 'phone': '01177788899', 'address': 'الشروق، القاهرة', 'history': 'حمل (الشهر السابع)'},
    {'id': '7', 'name': 'يوسف إبراهيم عبد الله', 'age': 85, 'gender': 'male', 'phone': '01066677788', 'address': 'مدينة نصر، القاهرة', 'history': 'زهايمر - رعاية مستمرة'},
    {'id': '8', 'name': 'هند محمد كمال', 'age': 50, 'gender': 'female', 'phone': '01244455566', 'address': '6 أكتوبر، الجيزة', 'history': 'روماتيزم مزمن'},
  ];

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((p) =>
      p['name'].toString().contains(_searchQuery) ||
      p['phone'].toString().contains(_searchQuery) ||
      p['address'].toString().contains(_searchQuery)
    ).toList();
  }

  List<Map<String, dynamic>> get _pagedPatients {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredPatients.length);
    if (start >= _filteredPatients.length) return [];
    return _filteredPatients.sublist(start, end);
  }

  int get _totalPages => (_filteredPatients.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === الرأس - Header ===
            _buildHeader(),
            const SizedBox(height: 20),

            // === الجدول - Table ===
            Expanded(child: _buildDataTable()),

            // === ترقيم الصفحات - Pagination ===
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.patients,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                'إدارة بيانات المرضى المسجلين في النظام',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SearchBarWidget(
          hintText: AppStrings.searchPatients,
          controller: _searchController,
          onChanged: (v) => setState(() {
            _searchQuery = v;
            _currentPage = 0;
          }),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showPatientDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(AppStrings.addPatient, style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // رأس الجدول - Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _headerCell('الاسم', flex: 3),
                _headerCell('العمر', flex: 1),
                _headerCell('الجنس', flex: 1),
                _headerCell('الهاتف', flex: 2),
                _headerCell('العنوان', flex: 2),
                _headerCell('التاريخ المرضي', flex: 2),
                _headerCell('إجراءات', flex: 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // صفوف البيانات - Data Rows
          Expanded(
            child: _pagedPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text(AppStrings.noPatients, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: AppColors.textHint)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _pagedPatients.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final patient = _pagedPatients[index];
                      return _buildPatientRow(patient, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildPatientRow(Map<String, dynamic> patient, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: index.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
        child: Row(
          children: [
            // الاسم مع أيقونة
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: patient['gender'] == 'male'
                        ? AppColors.info.withValues(alpha: 0.1)
                        : const Color(0xFFF472B6).withValues(alpha: 0.1),
                    child: Icon(
                      patient['gender'] == 'male' ? Icons.man_rounded : Icons.woman_rounded,
                      size: 16,
                      color: patient['gender'] == 'male' ? AppColors.info : const Color(0xFFF472B6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patient['name'],
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Text('${patient['age']}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
            Expanded(
              flex: 1,
              child: Text(
                patient['gender'] == 'male' ? 'ذكر' : 'أنثى',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(patient['phone'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13), textDirection: TextDirection.ltr),
            ),
            Expanded(
              flex: 2,
              child: Text(patient['address'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(patient['history'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            ),
            // أزرار الإجراءات - Action buttons
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _actionButton(Icons.visibility_rounded, AppColors.info, 'عرض', () {}),
                  const SizedBox(width: 4),
                  _actionButton(Icons.edit_rounded, AppColors.warning, 'تعديل', () => _showPatientDialog(patient: patient)),
                  const SizedBox(width: 4),
                  _actionButton(Icons.delete_rounded, AppColors.error, 'حذف', () => _confirmDelete(patient)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'عرض ${_currentPage * _pageSize + 1} - ${((_currentPage + 1) * _pageSize).clamp(0, _filteredPatients.length)} من ${_filteredPatients.length}',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
          ),
          ...List.generate(_totalPages, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _currentPage = i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _currentPage == i ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showPatientDialog({Map<String, dynamic>? patient}) {
    final isEdit = patient != null;
    final nameCtrl = TextEditingController(text: patient?['name'] ?? '');
    final ageCtrl = TextEditingController(text: patient?['age']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: patient?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: patient?['address'] ?? '');
    final historyCtrl = TextEditingController(text: patient?['history'] ?? '');
    final notesCtrl = TextEditingController(text: patient?['notes'] ?? '');
    String gender = patient?['gender'] ?? 'male';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? AppStrings.editPatient : AppStrings.addPatient,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // حقول الإدخال
                  _dialogField(AppStrings.patientName, nameCtrl, Icons.person_rounded),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _dialogField(AppStrings.patientAge, ageCtrl, Icons.cake_rounded, isNumber: true)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(AppStrings.patientGender, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _genderChip('ذكر', 'male', gender, (v) => setDialogState(() => gender = v)),
                                const SizedBox(width: 8),
                                _genderChip('أنثى', 'female', gender, (v) => setDialogState(() => gender = v)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _dialogField(AppStrings.patientPhone, phoneCtrl, Icons.phone_rounded, textDir: TextDirection.ltr),
                  const SizedBox(height: 14),
                  _dialogField(AppStrings.patientAddress, addressCtrl, Icons.location_on_rounded),
                  const SizedBox(height: 14),
                  _dialogField(AppStrings.patientHistory, historyCtrl, Icons.medical_information_rounded, maxLines: 2),
                  const SizedBox(height: 14),
                  _dialogField(AppStrings.patientNotes, notesCtrl, Icons.notes_rounded, maxLines: 2),
                  const SizedBox(height: 24),
                  // أزرار
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // حفظ البيانات
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.saveSuccess, style: const TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(AppStrings.save, style: const TextStyle(fontFamily: 'Cairo')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, TextDirection? textDir}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textDirection: textDir,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _genderChip(String label, String value, String selected, Function(String) onSelect) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> patient) async {
    final result = await ConfirmDialog.show(
      context,
      title: AppStrings.deletePatient,
      message: 'هل أنت متأكد من حذف المريض "${patient['name']}"؟\n${AppStrings.deleteConfirmMessage}',
      confirmText: AppStrings.delete,
      icon: Icons.delete_forever_rounded,
    );
    if (result == true) {
      setState(() => _patients.removeWhere((p) => p['id'] == patient['id']));
    }
  }
}
