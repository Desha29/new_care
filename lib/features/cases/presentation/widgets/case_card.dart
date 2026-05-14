import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/case_model.dart';

class CaseCard extends StatefulWidget {
  final CaseModel caseData;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CaseCard({
    super.key,
    required this.caseData,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.caseData.caseType.isHome ? AppColors.secondary : AppColors.primary;

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
                  ? color.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
          border: Border.all(
            color: _isHovered 
                ? color.withValues(alpha: 0.3) 
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
                  color: color,
                ),
                Expanded(
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              _buildTypeBadge(color),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailsRow(),
                          const SizedBox(height: 20),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 16),
                          _buildFooter(context),
                        ],
                      ),
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

  Widget _buildTypeBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.caseData.caseType.label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _infoItem(Icons.person_outline_rounded, widget.caseData.nurseName),
        _infoItem(Icons.calendar_today_rounded, DateFormat('yMMMd', 'ar').format(widget.caseData.caseDate)),
        _infoItem(Icons.medical_services_outlined, '${widget.caseData.services.length} خدمات'),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإجمالي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            Text(
              '${widget.caseData.grandTotal.toStringAsFixed(0)} E.P',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (widget.onEdit != null)
              _iconButton(
                Icons.edit_note_rounded,
                AppColors.primary,
                widget.onEdit!,
              ),
            const SizedBox(width: 8),
            if (widget.onDelete != null)
              _iconButton(
                Icons.delete_outline_rounded,
                AppColors.error,
                widget.onDelete!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
