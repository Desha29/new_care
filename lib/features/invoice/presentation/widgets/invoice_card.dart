import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../cases/data/models/case_model.dart';

class InvoiceCard extends StatefulWidget {
  final CaseModel caseData;
  final VoidCallback? onPrint;
  final VoidCallback? onView;

  const InvoiceCard({
    super.key,
    required this.caseData,
    this.onPrint,
    this.onView,
  });

  @override
  State<InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<InvoiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? AppColors.success.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
          border: Border.all(
            color: _isHovered 
                ? AppColors.success.withValues(alpha: 0.3) 
                : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isHovered ? 8 : 6,
                  color: AppColors.success,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8),
                        _buildInfoRow(),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 8),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.caseData.patientName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'رقم الفاتورة: #${widget.caseData.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('yMMMd', 'ar').format(widget.caseData.caseDate),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _infoChip(
          label: widget.caseData.caseType.label,
          icon: Icons.location_on_rounded,
          color: AppColors.primary,
        ),
        _infoChip(
          label: widget.caseData.nurseName,
          icon: Icons.person_rounded,
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _infoChip({required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإجمالي المستحق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${widget.caseData.grandTotal.toStringAsFixed(0)} E.P',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (widget.onView != null)
              _actionButton(
                icon: Icons.visibility_rounded,
                color: AppColors.primary,
                onPressed: widget.onView!,
              ),
            const SizedBox(width: 8),
            if (widget.onPrint != null)
              _actionButton(
                icon: Icons.print_rounded,
                color: AppColors.success,
                onPressed: widget.onPrint!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
