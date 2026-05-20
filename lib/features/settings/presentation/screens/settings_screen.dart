import 'package:flutter/material.dart';
import '../../../../core/utils/windows_file_picker.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/utils/ui_feedback.dart';

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
  bool _isBackingUp = false;
  bool _isRestoring = false;

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
              _buildClinicInfoSection(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildBackupSection()),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.1),
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
            activeThumbColor: AppColors.primary,
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
                onPressed: _isBackingUp ? null : _performBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_rounded, size: 18),
                label: Text(
                  _isBackingUp ? 'جاري النسخ...' : AppStrings.backupNow,
                  style: const TextStyle(fontFamily: 'Cairo'),
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
                onPressed: _isRestoring ? null : _performRestore,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_rounded, size: 18),
                label: Text(
                  _isRestoring ? 'جاري الاستعادة...' : AppStrings.restoreBackup,
                  style: const TextStyle(fontFamily: 'Cairo'),
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
    if (color == AppColors.success) {
      UIFeedback.showSuccess(context, message);
    } else if (color == AppColors.error) {
      UIFeedback.showError(context, message);
    } else {
      UIFeedback.showInfo(context, message);
    }
  }

  /// نسخ احتياطي - Backup database to user-chosen folder
  Future<void> _performBackup() async {
    // Let user pick a directory
    final selectedDir = await WindowsFilePicker.pickDirectory();
    if (selectedDir == null) return; // User cancelled

    setState(() => _isBackingUp = true);
    try {
      final savedPath = await SqliteService.instance.backupToPath(selectedDir);
      if (mounted) {
        UIFeedback.showSuccess(
          context,
          'تم حفظ النسخة الاحتياطية بنجاح في:\n$savedPath',
        );
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, 'فشل في النسخ الاحتياطي: $e');
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  /// استعادة نسخة احتياطية - Restore from user-chosen .db file
  Future<void> _performRestore() async {
    // Let user pick a .db file
    final filePath = await WindowsFilePicker.pickFile();
    if (filePath == null) return;

    // Confirm restore
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
              SizedBox(width: 8),
              Text('تأكيد الاستعادة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في النسخة الاحتياطية المحددة.\n\nهل أنت متأكد من المتابعة؟',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);
    try {
      await SqliteService.instance.restoreFromPath(filePath);
      if (mounted) {
        UIFeedback.showSuccess(context, 'تم استعادة النسخة الاحتياطية بنجاح! يرجى إعادة تشغيل التطبيق.');
      }
    } catch (e) {
      if (mounted) {
        UIFeedback.showError(context, 'فشل في الاستعادة: $e');
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }
}


