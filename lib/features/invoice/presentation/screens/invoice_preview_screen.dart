import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../../core/services/report_service.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final CaseModel caseData;

  const InvoicePreviewScreen({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'معاينة الفاتورة الشخصية',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ReportService.instance.shareCaseInvoice(caseData),
            tooltip: 'مشاركة الفاتورة',
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () =>
                ReportService.instance.generateCaseInvoice(caseData),
            tooltip: 'طباعة الفاتورة',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420, // عرض يشبه الإيصال (Thermal Receipt style)
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildReceiptHeader(),
                _dashedDivider(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientDetails(),
                      const SizedBox(height: 20),
                      _dashedDivider(),
                      const SizedBox(height: 20),
                      _buildReceiptItems(),
                      const SizedBox(height: 20),
                      _dashedDivider(),
                      const SizedBox(height: 20),
                      _buildFinancials(),

                      // _buildQRCode(),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.center,
                        child: _buildFooterText(),
                      ),
                    ],
                  ),
                ),
                _buildBottomCutEffect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.primary,
                size: 60,
              ),
            ),
          ),

          const Text(
            'مركـز نيـو كيـر الطبـي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'فاتورة خدمة طبية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم: #${caseData.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('yyyy/MM/dd HH:mm', 'ar').format(caseData.caseDate),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _receiptRow('المريض:', caseData.patientName, isBold: true),
        const SizedBox(height: 4),
        _receiptRow(
          'الهاتف:',
          caseData.patientPhone.isEmpty ? '-' : caseData.patientPhone,
        ),
        const SizedBox(height: 4),
        _receiptRow('الممرض:', caseData.nurseName),
      ],
    );
  }

  Widget _buildReceiptItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البيان / الخدمات:',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...caseData.services.map(
          (s) => _itemRow(s.name, s.quantity, s.price * s.quantity),
        ),
        ...caseData.suppliesUsed.map(
          (su) => _itemRow('${su.name} (مستلزم)', su.quantity, su.total),
        ),
      ],
    );
  }

  Widget _itemRow(String name, int qty, double total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ),
          Text(
            '${qty}x',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '${total.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancials() {
    return Column(
      children: [
        _receiptRow(
          'المجموع الفرعي:',
          '${caseData.totalPrice.toStringAsFixed(0)} ج.م',
        ),
        if (caseData.discount > 0)
          _receiptRow(
            'الخصم:',
            '- ${caseData.discount.toStringAsFixed(0)} ج.م',
            color: Colors.red,
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _receiptRow(
            'الإجمــالي النهائـي:',
            '${(caseData.totalPrice - caseData.discount).toStringAsFixed(0)} ج.م',
            isBold: true,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0
                ? Colors.transparent
                : Colors.grey.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
    );
  }

  // Widget _buildQRCode() {
  //   return Center(
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: QrImageView(
  //             data: caseData.id,
  //             version: QrVersions.auto,
  //             size: 100.0,
  //             gapless: false,
  //             eyeStyle: const QrEyeStyle(
  //               eyeShape: QrEyeShape.square,
  //               color: Color(0xFF333333),
  //             ),
  //             dataModuleStyle: const QrDataModuleStyle(
  //               dataModuleShape: QrDataModuleShape.square,
  //               color: Color(0xFF333333),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         const Text(
  //           'شكراً لثقتكم بنا',
  //           style: TextStyle(
  //             fontFamily: 'Cairo',
  //             fontSize: 12,
  //             color: AppColors.textHint,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFooterText() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'نتمنى لكم الشفاء العاجل',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'للتواصل: 01012345678',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCutEffect() {
    return Container(
      height: 10,
      child: Row(
        children: List.generate(
          20,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: CustomPaint(painter: _ZigZagPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZigZagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
