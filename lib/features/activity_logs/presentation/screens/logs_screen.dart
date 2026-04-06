import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/search_bar_widget.dart';

/// شاشة سجل الأنشطة - Activity Logs Screen
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _logs = [
    {'user': 'محمد أحمد', 'action': 'تسجيل دخول', 'emoji': '🔑', 'target': 'النظام', 'date': '06/04/2026 10:30', 'details': 'تسجيل دخول ناجح'},
    {'user': 'سارة خالد', 'action': 'إضافة مريض', 'emoji': '➕', 'target': 'أحمد محمد علي', 'date': '06/04/2026 10:45', 'details': 'إضافة مريض جديد'},
    {'user': 'أحمد حسام', 'action': 'تحديث حالة', 'emoji': '✏️', 'target': 'حالة #1234', 'date': '06/04/2026 11:00', 'details': 'تغيير الحالة من معلقة إلى جاري التنفيذ'},
    {'user': 'محمد أحمد', 'action': 'طباعة فاتورة', 'emoji': '🖨️', 'target': 'فاتورة #5678', 'date': '06/04/2026 11:15', 'details': 'طباعة فاتورة PDF'},
    {'user': 'نورا عادل', 'action': 'تحديث مخزون', 'emoji': '📦', 'target': 'كانيولا وريدية', 'date': '06/04/2026 11:30', 'details': 'خصم 5 قطع من المخزون'},
    {'user': 'سارة خالد', 'action': 'نسخ احتياطي', 'emoji': '💾', 'target': 'قاعدة البيانات', 'date': '06/04/2026 12:00', 'details': 'نسخة احتياطية تلقائية'},
    {'user': 'محمد عادل', 'action': 'إنهاء حالة', 'emoji': '✅', 'target': 'حالة #9012', 'date': '06/04/2026 12:30', 'details': 'تم إنهاء الحالة بنجاح'},
    {'user': 'محمد أحمد', 'action': 'حذف مريض', 'emoji': '🗑️', 'target': 'حسن علي', 'date': '05/04/2026 14:00', 'details': 'حذف سجل مريض'},
    {'user': 'سارة خالد', 'action': 'تعديل مستخدم', 'emoji': '👤', 'target': 'هند سمير', 'date': '05/04/2026 15:00', 'details': 'تعطيل حساب المستخدم'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _logs;
    return _logs.where((l) => l['user'].toString().contains(_searchQuery) || l['action'].toString().contains(_searchQuery) || l['target'].toString().contains(_searchQuery)).toList();
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
              Text(AppStrings.activityLogs, style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('متابعة جميع الإجراءات والعمليات في النظام', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
            ])),
            SearchBarWidget(hintText: AppStrings.searchLogs, controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v)),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: const Text(AppStrings.export, style: TextStyle(fontFamily: 'Cairo')),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
          const SizedBox(height: 20),
          Expanded(child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                child: Row(children: [_hc('', 0), _hc('المستخدم', 2), _hc('الإجراء', 2), _hc('الهدف', 2), _hc('التفاصيل', 3), _hc('التاريخ', 2)]),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _filtered.isEmpty
                ? const Center(child: Text(AppStrings.noLogs, style: TextStyle(fontFamily: 'Cairo', color: AppColors.textHint)))
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) {
                      final l = _filtered[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        color: i.isEven ? Colors.transparent : AppColors.surfaceVariant.withValues(alpha: 0.3),
                        child: Row(children: [
                          SizedBox(width: 32, child: Text(l['emoji'], style: const TextStyle(fontSize: 18))),
                          Expanded(flex: 2, child: Text(l['user'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text(l['action'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                          Expanded(flex: 2, child: Text(l['target'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary))),
                          Expanded(flex: 3, child: Text(l['details'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 2, child: Text(l['date'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint))),
                        ]),
                      );
                    })),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _hc(String t, int f) => f == 0 ? const SizedBox(width: 32) : Expanded(flex: f, child: Text(t, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)));
}
