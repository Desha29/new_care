import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_constants.dart';

/// شاشة الإعدادات - Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoBackup = true;
  bool _systemActive = true;

  // Feature flags simulation
  final Map<String, bool> _flags = {
    'enable_printing': true,
    'enable_backup': true,
    'enable_reports': true,
    'force_update': false,
    'kill_switch': false,
    'maintenance_mode': false,
  };

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppStrings.settings, style: TextStyle(fontFamily: 'Cairo', fontSize: titleSize, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('إعدادات النظام والنسخ الاحتياطي والتحكم عن بُعد', style: TextStyle(fontFamily: 'Cairo', fontSize: ResponsiveHelper.getSubtitleFontSize(context), color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          if (isSmall) ...[
            // Stack vertically on small screens
            _buildBackupSection(),
            const SizedBox(height: 20),
            _buildRemoteConfigSection(),
            const SizedBox(height: 20),
            _buildSystemStatus(),
            const SizedBox(height: 20),
            _buildAppInfo(),
          ] else ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 1, child: _buildBackupSection()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildRemoteConfigSection()),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 1, child: _buildSystemStatus()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildAppInfo()),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _buildBackupSection() {
    return _sectionCard(AppStrings.backup, Icons.backup_rounded, AppColors.info, [
      _settingRow(AppStrings.autoBackup, 'نسخ احتياطي تلقائي كل ساعة', Switch(value: _autoBackup, onChanged: (v) => setState(() => _autoBackup = v), activeThumbColor: AppColors.primary)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppStrings.lastBackup, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
            Text('06/04/2026 12:00', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: () => _showSnackbar(AppStrings.backupSuccess, AppColors.success),
          icon: const Icon(Icons.backup_rounded, size: 18),
          label: const Text(AppStrings.backupNow, style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _showSnackbar(AppStrings.restoreSuccess, AppColors.info),
          icon: const Icon(Icons.restore_rounded, size: 18),
          label: const Text(AppStrings.restoreBackup, style: TextStyle(fontFamily: 'Cairo')),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      ]),
    ]);
  }

  Widget _buildRemoteConfigSection() {
    return _sectionCard(AppStrings.remoteConfig, Icons.cloud_sync_rounded, AppColors.secondary, [
      ..._flags.entries.map((e) {
        String label;
        String desc;
        switch (e.key) {
          case 'enable_printing': label = 'الطباعة'; desc = 'تفعيل/تعطيل ميزة الطباعة'; break;
          case 'enable_backup': label = 'النسخ الاحتياطي'; desc = 'تفعيل/تعطيل النسخ الاحتياطي'; break;
          case 'enable_reports': label = 'التقارير'; desc = 'تفعيل/تعطيل التقارير'; break;
          case 'force_update': label = 'تحديث إجباري'; desc = 'إجبار المستخدمين على التحديث'; break;
          case 'kill_switch': label = 'إيقاف النظام'; desc = 'إيقاف النظام بالكامل'; break;
          case 'maintenance_mode': label = 'وضع الصيانة'; desc = 'تفعيل وضع الصيانة'; break;
          default: label = e.key; desc = '';
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _settingRow(label, desc, Switch(
            value: e.value,
            onChanged: (v) => setState(() => _flags[e.key] = v),
            activeThumbColor: e.key.contains('kill') || e.key.contains('force') ? AppColors.error : AppColors.primary,
          )),
        );
      }),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => _showSnackbar('تم تحديث الإعدادات عن بُعد', AppColors.success),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('تحديث من السيرفر', style: TextStyle(fontFamily: 'Cairo')),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      )),
    ]);
  }

  Widget _buildSystemStatus() {
    return _sectionCard(AppStrings.systemStatus, Icons.monitor_heart_rounded, _systemActive ? AppColors.success : AppColors.error, [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _systemActive ? AppColors.statusCompletedBg : AppColors.statusCancelledBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(_systemActive ? Icons.check_circle_rounded : Icons.error_rounded, color: _systemActive ? AppColors.success : AppColors.error, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_systemActive ? AppStrings.systemActive : AppStrings.systemStopped, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: _systemActive ? AppColors.success : AppColors.error)),
            Text(_systemActive ? 'جميع الأنظمة تعمل بشكل طبيعي' : 'النظام متوقف حالياً', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Switch(value: _systemActive, onChanged: (v) => setState(() => _systemActive = v), activeThumbColor: AppColors.success),
        ]),
      ),
    ]);
  }

  Widget _buildAppInfo() {
    return _sectionCard('معلومات التطبيق', Icons.info_rounded, AppColors.primary, [
      _infoRow(AppStrings.appVersion, AppConstants.appVersion),
      _infoRow('رقم البناء', AppConstants.buildNumber),
      _infoRow('قاعدة البيانات', 'Firebase + SQLite'),
      _infoRow('المنصة', 'Windows Desktop'),
      _infoRow('آخر تحديث', '06/04/2026'),
    ]);
  }

  Widget _settingRow(String title, String desc, Widget trailing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
          Text(desc, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.textHint)),
        ])),
        trailing,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
