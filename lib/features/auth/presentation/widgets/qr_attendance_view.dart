import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';

class QrAttendanceView extends StatefulWidget {
  final VoidCallback? onBack;
  const QrAttendanceView({super.key, this.onBack});

  @override
  State<QrAttendanceView> createState() => _QrAttendanceViewState();
}

class _QrAttendanceViewState extends State<QrAttendanceView> {
  String? _sessionId;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startNewSession() async {
    setState(() => _isLoading = true);
    try {
      // Create session locally (no cloud save needed)
      final newId = 'session_${const Uuid().v4()}';
      
      // Simulate slight delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _sessionId = newId;
        _isLoading = false;
      });

      // Auto-expire after 5 minutes
      _timer?.cancel();
      _timer = Timer(const Duration(minutes: 5), () {
        if (mounted) {
          setState(() => _sessionId = null);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في بدء الجلسة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'نظام تسجيل الحضور بالـ QR',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sessionId == null 
                ? 'لا توجد جلسة حضور نشطة حالياً' 
                : 'امسح الكود عبر تطبيق الموبايل لتسجيل الحضور',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          // QR Area
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.1),
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessionId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 64,
                              color: AppColors.textHint.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'قم ببدء الجلسة لإظهار الكود',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: QrImageView(
                          data: _sessionId!,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.transparent,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _startNewSession,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text(
                'بدء جلسة حضور جديدة',
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
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          
          if (widget.onBack != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onBack,
              child: const Text(
                'العودة لتسجيل الدخول',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
