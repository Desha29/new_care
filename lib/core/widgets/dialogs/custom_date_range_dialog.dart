import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../buttons/primary_button.dart';

class CustomDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CustomDateRangeDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  static Future<DateTimeRange?> show(BuildContext context, {DateTime? start, DateTime? end}) {
    return showDialog<DateTimeRange>(
      context: context,
      builder: (_) => CustomDateRangeDialog(
        initialStartDate: start,
        initialEndDate: end,
      ),
    );
  }

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = widget.initialEndDate ?? DateTime.now();
    
    // If start and end are same day, maybe default to single day mode
    if (_startDate != null && _endDate != null) {
       final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
       final e = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
       if (s.isAtSameMomentAs(e)) {
         _isRange = false;
       }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate! : _endDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Cairo'),
              titleMedium: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (!_isRange || (_endDate != null && _endDate!.isBefore(_startDate!))) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'تحديد التاريخ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTab('يوم واحد', !_isRange),
                        _buildTab('فترة زمنية', _isRange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (!_isRange)
                    _buildDateBox(
                      label: 'التاريخ المختار',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateBox(
                            label: 'من تاريخ',
                            date: _startDate,
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateBox(
                            label: 'إلى تاريخ',
                            date: _endDate,
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 40),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'تطبيق الفلتر',
                          onPressed: () {
                            if (_startDate != null && _endDate != null) {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
                                  end: _isRange 
                                      ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
                                      : DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRange = label == 'فترة زمنية'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? '${date.day} / ${date.month} / ${date.year}'
                      : 'اختر التاريخ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: date != null ? AppColors.textPrimary : AppColors.textHint,
                    fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
