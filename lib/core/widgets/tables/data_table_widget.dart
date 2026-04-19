import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

/// جدول البيانات المحسن - Enhanced Data Table Widget
/// جدول قابل للترتيب مع ترقيم الصفحات ودعم البحث
class NewCareDataTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int>? onSort;
  final bool showCheckboxColumn;
  final double? minWidth;

  const NewCareDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.showCheckboxColumn = false,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth ?? MediaQuery.of(context).size.width - 320,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
              headingRowHeight: AppSpacing.tableHeaderHeight,
              dataRowMinHeight: AppSpacing.tableRowHeight,
              dataRowMaxHeight: AppSpacing.tableRowHeight,
              horizontalMargin: AppSpacing.tableCellPaddingH,
              columnSpacing: AppSpacing.tableCellPaddingH,
              showCheckboxColumn: showCheckboxColumn,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              columns: columns.asMap().entries.map((entry) {
                return DataColumn(
                  label: Text(
                    entry.value,
                    style: AppTypography.tableHeader,
                  ),
                  onSort: onSort != null
                      ? (columnIndex, ascending) => onSort!(columnIndex)
                      : null,
                );
              }).toList(),
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}

/// جدول مع ترقيم صفحات - Paginated Data Table Wrapper
class NewCarePaginatedTable extends StatefulWidget {
  final List<String> columns;
  final List<DataRow> allRows;
  final int rowsPerPage;
  final ValueChanged<int>? onPageChanged;

  const NewCarePaginatedTable({
    super.key,
    required this.columns,
    required this.allRows,
    this.rowsPerPage = 15,
    this.onPageChanged,
  });

  @override
  State<NewCarePaginatedTable> createState() => _NewCarePaginatedTableState();
}

class _NewCarePaginatedTableState extends State<NewCarePaginatedTable> {
  int _currentPage = 0;

  int get _totalPages => (widget.allRows.length / widget.rowsPerPage).ceil();
  int get _startIndex => _currentPage * widget.rowsPerPage;
  int get _endIndex =>
      (_startIndex + widget.rowsPerPage).clamp(0, widget.allRows.length);

  List<DataRow> get _currentRows =>
      widget.allRows.sublist(_startIndex, _endIndex);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NewCareDataTable(
          columns: widget.columns,
          rows: _currentRows,
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() {
                    _currentPage--;
                    widget.onPageChanged?.call(_currentPage);
                  })
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
          iconSize: AppSpacing.iconLg,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${_currentPage + 1} / $_totalPages',
          style: AppTypography.cardBody,
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() {
                    _currentPage++;
                    widget.onPageChanged?.call(_currentPage);
                  })
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: AppSpacing.iconLg,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          '${widget.allRows.length} سجل',
          style: AppTypography.cardCaption,
        ),
      ],
    );
  }
}
