import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;

  const UserFormDialog({super.key, this.user, required this.onSaved});

  static void show(BuildContext context, {UserModel? user, required VoidCallback onSaved}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserFormDialog(user: user, onSaved: onSaved),
    );
  }

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _salaryCtrl;
  late UserRole _role;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email.replaceFirst('@newcare.com', '') ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _passCtrl = TextEditingController();
    _salaryCtrl = TextEditingController(
      text: widget.user != null ? widget.user!.salary.toStringAsFixed(0) : '3000',
    );
    _role = widget.user?.role ?? UserRole.nurse;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      try {
        final email = _emailCtrl.text.trim().contains('@')
            ? _emailCtrl.text.trim()
            : '${_emailCtrl.text.trim()}@newcare.com';

        final repo = sl<IUsersRepository>();

        if (_isEdit) {
          final salary = _role == UserRole.nurse
              ? (double.tryParse(_salaryCtrl.text.trim()) ?? 3000.0)
              : widget.user!.salary;
          final updatedUser = widget.user!.copyWith(
            name: _nameCtrl.text.trim(),
            email: email,
            phone: _phoneCtrl.text.trim(),
            role: _role,
            salary: salary,
            updatedAt: DateTime.now(),
          );
          await repo.updateUser(updatedUser);
        } else {
          final uid = await repo.registerUserAuth(
            email,
            _passCtrl.text.trim(),
          );

          final salary = _role == UserRole.nurse
              ? (double.tryParse(_salaryCtrl.text.trim()) ?? 3000.0)
              : 0.0;
          final newUser = UserModel(
            id: uid,
            name: _nameCtrl.text.trim(),
            email: email,
            phone: _phoneCtrl.text.trim(),
            role: _role,
            salary: salary,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await repo.createUser(newUser);
        }

        if (mounted) {
          Navigator.pop(context);
          widget.onSaved();
          DataChangeNotifier().notifyLocalDataChanged();
          UIFeedback.showSuccess(
            context,
            _isEdit ? 'تم تحديث بيانات المستخدم بنجاح' : 'تم إضافة المستخدم بنجاح',
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          UIFeedback.showError(context, 'خطأ: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: _isSaving
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isEdit ? AppStrings.editUser : AppStrings.addUser,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field('الاسم', _nameCtrl, Icons.person_rounded, isRequired: true),
                      const SizedBox(height: 12),
                      _field(
                        'اسم المستخدم (للبريد)',
                        _emailCtrl,
                        Icons.alternate_email_rounded,
                        dir: TextDirection.ltr,
                        isRequired: true,
                        suffixText: '@newcare.com',
                        hint: 'مثال: ahmed',
                      ),
                      const SizedBox(height: 12),
                      if (!_isEdit)
                        _field(
                          'كلمة المرور',
                          _passCtrl,
                          Icons.lock_rounded,
                          dir: TextDirection.ltr,
                          isRequired: true,
                        ),
                      if (!_isEdit) const SizedBox(height: 12),
                      _field('رقم الهاتف', _phoneCtrl, Icons.phone_rounded, dir: TextDirection.ltr),
                      const SizedBox(height: 12),
                      const Text(
                        'الصلاحية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _roleChip('ممرض', UserRole.nurse),
                          const SizedBox(width: 8),
                          _roleChip('مشرف', UserRole.admin),
                        ],
                      ),
                      // حقل المرتب - يظهر فقط عندما يكون الدور ممرض
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _role == UserRole.nurse
                            ? Column(
                                children: [
                                  const SizedBox(height: 12),
                                  _field(
                                    'المرتب الأساسي (جنيه)',
                                    _salaryCtrl,
                                    Icons.payments_rounded,
                                    dir: TextDirection.ltr,
                                    isRequired: true,
                                    hint: 'مثال: 3000',
                                    isNumber: true,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                AppStrings.cancel,
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _save,
                              child: Text(
                                AppStrings.save,
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
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
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextDirection? dir,
    bool isRequired = false,
    String? suffixText,
    String? hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          textDirection: dir,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          validator: isRequired ? Validators.required : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: AppColors.textHint,
              fontFamily: 'Cairo',
              fontSize: 12,
            ),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _roleChip(String label, UserRole value) {
    final s = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: s ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s ? AppColors.primary : AppColors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: s ? FontWeight.w600 : FontWeight.w400,
                color: s ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

