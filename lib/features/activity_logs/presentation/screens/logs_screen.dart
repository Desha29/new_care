import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/services/local_log_service.dart';
import '../../data/models/log_model.dart';

/// شاشة سجل الأنشطة - Activity Logs Screen
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<LogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await LocalLogService.instance.getAllLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LogModel> get _filtered {
    if (_searchQuery.isEmpty) return _logs;
    return _logs
        .where((l) =>
            l.userName.contains(_searchQuery) ||
            l.actionLabel.contains(_searchQuery) ||
            l.details.contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getScreenPadding(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.activityLogs,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('متابعة جميع الإجراءات والعمليات في النظام (محلياً)',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: ResponsiveHelper.getSubtitleFontSize(context),
                            color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMobile)
                      SearchBarWidget(
                          hintText: AppStrings.searchLogs,
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v)),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _loadLogs,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: AppStrings.refresh,
                    ),
                  ],
                ),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 12),
              SearchBarWidget(
                  hintText: AppStrings.searchLogs,
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v)),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16))),
                            child: Row(
                              children: [
                                const SizedBox(width: 32),
                                _hc('المستخدم', 2),
                                _hc('الإجراء', 2),
                                _hc('التفاصيل', 3),
                                _hc('التاريخ والوقت', 2),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          Expanded(
                            child: _filtered.isEmpty
                                ? const Center(
                                    child: Text(AppStrings.noLogs,
                                        style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: AppColors.textHint)))
                                : ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(
                                        height: 1,
                                        color: AppColors.borderLight),
                                    itemBuilder: (_, i) {
                                      final l = _filtered[i];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        color: i.isEven
                                            ? Colors.transparent
                                            : AppColors.surfaceVariant
                                                .withValues(alpha: 0.3),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                                width: 32,
                                                child: Text(l.actionEmoji,
                                                    style: const TextStyle(
                                                        fontSize: 18))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(l.userName,
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            Expanded(
                                                flex: 2,
                                                child: Text(l.actionLabel,
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 13))),
                                            Expanded(
                                                flex: 3,
                                                child: Text(l.details,
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary),
                                                    overflow: TextOverflow
                                                        .ellipsis)),
                                            Expanded(
                                                flex: 2,
                                                child: Text(
                                                    _formatDate(l.timestamp),
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .textHint))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _hc(String t, int f) => Expanded(
      flex: f,
      child: Text(t,
          style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)));
}
