import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/sqlite_service.dart';

/// شاشة الإعدادات - Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSavingInfo = false;
  bool _autoBackup = true;
  bool _systemActive = true;

  final Map<String, bool> _flags = {
    'enable_printing': true,
    'enable_backup': true,
    'enable_reports': true,
    'force_update': false,
    'kill_switch': false,
    'maintenance_mode': false,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadClinicInfo();
  }

  Future<void> _loadClinicInfo() async {
    final info = await SqliteService.instance.getClinicInfo();
    setState(() {
      _nameController.text = info['name'] ?? '';
      _phoneController.text = info['phone'] ?? '';
      _addressController.text = info['address'] ?? '';
    });
  }

  Future<void> _saveClinicInfo() async {
    setState(() => _isSavingInfo = true);
    try {
      await SqliteService.instance.saveClinicInfo(
        _nameController.text,
        _phoneController.text,
        _addressController.text,
      );
      _showSnackbar('تم حفظ المعلومات بنجاح', AppColors.success);
    } catch (e) {
      _showSnackbar('خطأ في حفظ البيانات: $e', AppColors.error);
    } finally {
      setState(() => _isSavingInfo = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final isSmall = !ResponsiveHelper.isDesktop(context);
    final titleSize = ResponsiveHelper.getTitleFontSize(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.settings,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'إعدادات النظام والنسخ الاحتياطي والتحكم عن بُعد بمزايا التطبيق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            if (isSmall) ...[
              _buildBackupSection(),
              const SizedBox(height: 20),
              _buildRemoteConfigSection(),
              const SizedBox(height: 20),
              _buildSystemStatus(),
              const SizedBox(height: 20),
              _buildClinicInfoSection(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildBackupSection()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildRemoteConfigSection()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildSystemStatus()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildClinicInfoSection()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return _sectionCard(
      AppStrings.backup,
      Icons.backup_rounded,
      AppColors.info,
      [
        _settingRow(
          AppStrings.autoBackup,
          'نسخ احتياطي تلقائي كل ساعة لمزامنة البيانات',
          Switch(
            value: _autoBackup,
            onChanged: (v) => setState(() => _autoBackup = v),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.lastBackup,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '21/04/2026 14:00',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showSnackbar(AppStrings.backupSuccess, AppColors.success),
                icon: const Icon(Icons.backup_rounded, size: 18),
                label: const Text(
                  AppStrings.backupNow,
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showSnackbar(AppStrings.restoreSuccess, AppColors.info),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text(
                  AppStrings.restoreBackup,
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemoteConfigSection() {
    return _sectionCard(
      AppStrings.remoteConfig,
      Icons.cloud_sync_rounded,
      AppColors.secondary,
      [
        ..._flags.entries.map((e) {
          String label;
          String desc;
          switch (e.key) {
            case 'enable_printing':
              label = 'الطباعة';
              desc = 'تفعيل/تعطيل ميزة الطباعة والتقارير الورقية';
              break;
            case 'enable_backup':
              label = 'النسخ السحابي';
              desc = 'تفعيل المزامنة التلقائية مع Firebase';
              break;
            case 'enable_reports':
              label = 'التقارير';
              desc = 'الوصول لتقارير الأداء الشهرية';
              break;
            case 'force_update':
              label = 'تحديث إجباري';
              desc = 'إلزام المستخدمين بالانتقال لأحدث نسخة';
              break;
            case 'kill_switch':
              label = 'إيقاف النظام';
              desc = 'تعطيل الدخول للتطبيق في وضع الطوارئ';
              break;
            case 'maintenance_mode':
              label = 'وضع الصيانة';
              desc = 'إظهار شاشة الصيانة للمستخدمين';
              break;
            default:
              label = e.key;
              desc = '';
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _settingRow(
              label,
              desc,
              Switch(
                value: e.value,
                onChanged: (v) => setState(() => _flags[e.key] = v),
                activeColor: e.key.contains('kill') || e.key.contains('force')
                    ? AppColors.error
                    : AppColors.primary,
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showSnackbar(
              'تم تحديث الإعدادات من السيرفر بنجاح',
              AppColors.success,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'تحديث من Cloud Config',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStatus() {
    return _sectionCard(
      AppStrings.systemStatus,
      Icons.monitor_heart_rounded,
      _systemActive ? AppColors.success : AppColors.error,
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _systemActive
                ? AppColors.statusCompletedBg
                : AppColors.statusCancelledBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _systemActive
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: _systemActive ? AppColors.success : AppColors.error,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _systemActive
                          ? AppStrings.systemActive
                          : AppStrings.systemStopped,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _systemActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      _systemActive
                          ? 'جميع أنظمة تطبيق نيو كير تعمل بشكل مستقر'
                          : 'توجد بعض المشاكل في الاتصال بالسيرفر',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicInfoSection() {
    return _sectionCard(
      'إعدادات معلومات التطبيق',
      Icons.info_outline_rounded,
      AppColors.primary,
      [
        _editableInfoRow('معلومات نيو كير', _nameController),
        const SizedBox(height: 12),
        _editableInfoRow('رقم التواصل', _phoneController, isPhone: true),
        const SizedBox(height: 12),
        _editableInfoRow('بيانات تغيير CNA', _addressController),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSavingInfo ? null : _saveClinicInfo,
            icon: _isSavingInfo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text(
              'حفظ المعلومات الجديد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editableInfoRow(
    String label,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingRow(String title, String desc, Widget trailing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
