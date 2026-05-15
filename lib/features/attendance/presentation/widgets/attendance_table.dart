import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/shift_role.dart';
import '../../data/models/attendance_model.dart';
import '../cubit/attendance_state.dart';

class AttendanceTable extends StatelessWidget {
  final AttendanceLoaded state;
  final bool isPersonal;

  const AttendanceTable({
    super.key,
    required this.state,
    this.isPersonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final records = state.filteredRecords;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
          columns: [
            if (!isPersonal)
              const DataColumn(label: Text('الموظف', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('وقت الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('وقت الانصراف', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('التأخير', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('المدة', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: records.map((record) => _buildRow(record)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(AttendanceModel record) {
    final checkIn = DateFormat('hh:mm a', 'ar').format(record.checkInTime);
    final checkOut = record.checkOutTime != null
        ? DateFormat('hh:mm a', 'ar').format(record.checkOutTime!)
        : '---';

    final date = DateFormat('yyyy/MM/dd', 'ar').format(record.checkInTime);

    return DataRow(cells: [
      if (!isPersonal)
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(record.userName),
            ],
          ),
        ),
      DataCell(Text(date)),
      DataCell(_buildStatusBadge(record.status)),
      DataCell(Text(checkIn)),
      DataCell(Text(checkOut)),
      DataCell(
        Text(
          record.delayMinutes > 0 ? '${record.delayMinutes} د' : '---',
          style: TextStyle(color: record.delayMinutes > 0 ? Colors.red : Colors.grey),
        ),
      ),
      DataCell(Text(record.shiftDurationText)),
    ]);
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color color;
    switch (status) {
      case AttendanceStatus.checkedIn:
        color = Colors.green;
        break;
      case AttendanceStatus.late:
        color = Colors.orange;
        break;
      case AttendanceStatus.checkedOut:
      case AttendanceStatus.earlyLeave:
        color = Colors.blue;
        break;
      case AttendanceStatus.absent:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
