import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/attendance_cubit.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';

class AttendanceScannerDialog extends StatefulWidget {
  final UserModel user;

  const AttendanceScannerDialog({super.key, required this.user});

  static void show(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AttendanceCubit>()),
        ],
        child: AttendanceScannerDialog(user: user),
      ),
    );
  }

  @override
  State<AttendanceScannerDialog> createState() => _AttendanceScannerDialogState();
}

class _AttendanceScannerDialogState extends State<AttendanceScannerDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      content: SizedBox(
        width: 400,
        height: 500,
        child: Stack(
          children: [
            if (Platform.isWindows)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.desktop_access_disabled_rounded, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text(
                        'المسح غير مدعوم على نسخة الويندوز',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'يرجى استخدام تطبيق الموبايل لمسح الأكواد',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              MobileScanner(
                controller: MobileScannerController(
                  facing: CameraFacing.back,
                  torchEnabled: false,
                ),
                onDetect: (capture) {
                  if (_isProcessing) return;
                  
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) {
                      setState(() => _isProcessing = true);
                      _handleScan(code);
                    }
                  }
                },
              ),
            // Overlay
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: AppColors.primary,
                  borderRadius: 20,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
            ),
            // Header
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'مسح كود المركز',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'وجه الكاميرا نحو كود الحضور/الانصراف',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Processing Indicator
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            // Close Button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScan(String code) async {
    final cubit = context.read<AttendanceCubit>();
    await cubit.processCenterQr(
      qrCode: code,
      userId: widget.user.id,
      userName: widget.user.name,
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.borderLength = 30,
    this.borderRadius = 0,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left, rrect.top + borderLength)
        ..lineTo(rrect.left, rrect.top)
        ..lineTo(rrect.left + borderLength, rrect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right - borderLength, rrect.top)
        ..lineTo(rrect.right, rrect.top)
        ..lineTo(rrect.right, rrect.top + borderLength),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rrect.right, rrect.bottom - borderLength)
        ..lineTo(rrect.right, rrect.bottom)
        ..lineTo(rrect.right - borderLength, rrect.bottom),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rrect.left + borderLength, rrect.bottom)
        ..lineTo(rrect.left, rrect.bottom)
        ..lineTo(rrect.left, rrect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
