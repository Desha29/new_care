import '../../../../core/services/firebase/firebase_base.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/data/repositories/attendance_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// تنفيذ مستودع الرواتب - Payroll Repository Implementation
class PayrollRepositoryImpl extends FirebaseBase implements IPayrollRepository {
  CollectionReference get _usersRef =>
      firestore.collection(AppConstants.usersCollection);

  final AttendanceRepositoryImpl _attendanceRepo = AttendanceRepositoryImpl();

  @override
  Future<List<UserModel>> getActiveStaff() async {
    final snapshot = await _usersRef.where('isActive', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((u) =>
            u.role.value == 'nurse' ||
            u.role.value == 'admin' ||
            u.role.value == 'super_admin')
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getMonthlyAttendanceRecords(int year, int month) async {
    return _attendanceRepo.getMonthlyAttendanceRecords(year, month);
  }
}
