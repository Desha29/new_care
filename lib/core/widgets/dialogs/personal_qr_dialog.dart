import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../constants/app_colors.dart';

class PersonalQrDialog extends StatelessWidget {
  final UserModel user;

  const PersonalQrDialog({super.key, required this.user});

  static void show(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => PersonalQrDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'كود الحضور الشخصي',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: '${user.id}:${user.name}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'أظهر هذا الكود للمشرف لتسجيل حضورك',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}
