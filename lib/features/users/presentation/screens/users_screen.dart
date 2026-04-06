import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/search_bar_widget.dart';

/// شاشة إدارة المستخدمين - Users Management Screen
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'محمد أحمد', 'email': 'admin@newcare.com', 'phone': '01012345678', 'role': 'super_admin', 'isActive': true},
    {'id': '2', 'name': 'سارة خالد', 'email': 'sara@newcare.com', 'phone': '01098765432', 'role': 'admin', 'isActive': true},
    {'id': '3', 'name': 'أحمد حسام', 'email': 'ahmed.h@newcare.com', 'phone': '01155566677', 'role': 'nurse', 'isActive': true},
    {'id': '4', 'name': 'نورا عادل', 'email': 'noura@newcare.com', 'phone': '01288899900', 'role': 'nurse', 'isActive': true},
    {'id': '5', 'name': 'محمد عادل', 'email': 'mohamed.a@newcare.com', 'phone': '01033344455', 'role': 'nurse', 'isActive': true},
    {'id': '6', 'name': 'هند سمير', 'email': 'hend@newcare.com', 'phone': '01177788899', 'role': 'nurse', 'isActive': false},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) => u['name'].toString().contains(_searchQuery) || u['email'].toString().contains(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.users, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('إدارة حسابات المستخدمين والصلاحيات', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
            ])),
            SearchBarWidget(hintText: AppStrings.searchUsers, controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v)),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text(AppStrings.addUser, style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
          const SizedBox(height: 20),
          // Stats cards
          Row(children: [
            _statCard('إجمالي المستخدمين', '${_users.length}', Icons.people_rounded, AppColors.primary),
            const SizedBox(width: 16),
            _statCard('الممرضون', '${_users.where((u) => u['role'] == 'nurse').length}', Icons.medical_services_rounded, AppColors.secondary),
            const SizedBox(width: 16),
            _statCard('المشرفون', '${_users.where((u) => u['role'] == 'admin' || u['role'] == 'super_admin').length}', Icons.admin_panel_settings_rounded, const Color(0xFF8B5CF6)),
            const SizedBox(width: 16),
            _statCard('نشط', '${_users.where((u) => u['isActive'] == true).length}', Icons.check_circle_rounded, AppColors.success),
          ]),
          const SizedBox(height: 20),
          Expanded(child: _buildTable()),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ]),
    ));
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [_hc('الاسم', 2), _hc('البريد', 2), _hc('الهاتف', 2), _hc('الصلاحية', 2), _hc('الحالة', 1), _hc('إجراءات', 2)]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(child: ListView.separated(
          itemCount: _filtered.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
          itemBuilder: (_, i) {
            final u = _filtered[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
              child: Row(children: [
                Expanded(flex: 2, child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(u['name'].toString().substring(0, 1), style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u['name'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                ])),
                Expanded(flex: 2, child: Text(u['email'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), textDirection: TextDirection.ltr)),
                Expanded(flex: 2, child: Text(u['phone'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12), textDirection: TextDirection.ltr)),
                Expanded(flex: 2, child: RoleBadge(role: u['role'], fontSize: 11)),
                Expanded(flex: 1, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: u['isActive'] ? AppColors.statusCompletedBg : AppColors.statusCancelledBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(u['isActive'] ? 'نشط' : 'معطل', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: u['isActive'] ? AppColors.statusCompleted : AppColors.statusCancelled)),
                )),
                Expanded(flex: 2, child: Row(children: [
                  _ab(Icons.edit_rounded, AppColors.warning, () => _showUserDialog(user: u)),
                  const SizedBox(width: 4),
                  _ab(u['isActive'] ? Icons.block_rounded : Icons.check_circle_rounded, u['isActive'] ? AppColors.error : AppColors.success, () => setState(() => u['isActive'] = !u['isActive'])),
                ])),
              ]),
            );
          },
        )),
      ]),
    );
  }

  Widget _hc(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)));

  Widget _ab(IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)));

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?['name'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    String role = user?['role'] ?? 'nurse';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 480, padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Text(isEdit ? AppStrings.editUser : AppStrings.addUser, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
        ]),
        const SizedBox(height: 20),
        _field('الاسم', nameCtrl, Icons.person_rounded),
        const SizedBox(height: 12),
        _field('البريد الإلكتروني', emailCtrl, Icons.email_rounded, dir: TextDirection.ltr),
        const SizedBox(height: 12),
        _field('رقم الهاتف', phoneCtrl, Icons.phone_rounded, dir: TextDirection.ltr),
        const SizedBox(height: 12),
        const Text('الصلاحية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          _roleChip('ممرض', 'nurse', role, (v) => ss(() => role = v)),
          const SizedBox(width: 8),
          _roleChip('مشرف', 'admin', role, (v) => ss(() => role = v)),
          const SizedBox(width: 8),
          _roleChip('مدير عام', 'super_admin', role, (v) => ss(() => role = v)),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel, style: TextStyle(fontFamily: 'Cairo')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.save, style: TextStyle(fontFamily: 'Cairo')))),
        ]),
      ])),
    )));
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextDirection? dir}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(controller: ctrl, textDirection: dir, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14), decoration: InputDecoration(prefixIcon: Icon(icon, size: 18, color: AppColors.textHint))),
    ]);
  }

  Widget _roleChip(String label, String value, String sel, Function(String) fn) {
    final s = sel == value;
    return Expanded(child: GestureDetector(onTap: () => fn(value), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: s ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: s ? AppColors.primary : AppColors.border)),
      child: Center(child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: s ? FontWeight.w600 : FontWeight.w400, color: s ? AppColors.primary : AppColors.textSecondary))))));
  }
}
