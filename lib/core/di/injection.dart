import 'package:get_it/get_it.dart';
import 'package:new_care/core/services/firebase/firebase_service.dart';
import 'package:new_care/core/services/local/sqlite_service.dart';
import 'package:new_care/core/services/sync/sync_service.dart';
import 'package:new_care/core/services/sync/sync_manager.dart';
import 'package:new_care/core/services/device/device_service.dart';
import 'package:new_care/core/services/network/connectivity_service.dart';
import 'package:new_care/core/services/notifications/notification_service.dart';
import 'package:new_care/core/services/pdf/report_service.dart';
import 'package:new_care/core/services/local/local_log_service.dart';
import 'package:new_care/core/services/sync/backup_service.dart';
import 'package:new_care/core/services/pdf/export_service.dart';

// === Legacy Firebase Repositories (core/services/firebase/) ===
import 'package:new_care/core/services/firebase/users_repository.dart';
import 'package:new_care/core/services/firebase/logs_repository.dart';

// === Domain Layer - Abstract Interfaces ===
import 'package:new_care/features/cases/domain/repositories/cases_repository.dart';
import 'package:new_care/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:new_care/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:new_care/features/procedures/domain/repositories/procedures_repository.dart';
import 'package:new_care/features/financials/domain/repositories/financials_repository.dart';
import 'package:new_care/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:new_care/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:new_care/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:new_care/features/auth/domain/repositories/auth_repository.dart';
import 'package:new_care/features/dashboard/domain/repositories/dashboard_repository.dart';

// === Data Layer - Concrete Implementations ===
import 'package:new_care/features/cases/data/repositories/cases_repository_impl.dart';
import 'package:new_care/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:new_care/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:new_care/features/procedures/data/repositories/procedures_repository_impl.dart';
import 'package:new_care/features/financials/data/repositories/financials_repository_impl.dart';
import 'package:new_care/features/shifts/data/repositories/shifts_repository_impl.dart';
import 'package:new_care/features/payroll/data/repositories/payroll_repository_impl.dart';
import 'package:new_care/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:new_care/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:new_care/features/dashboard/data/repositories/dashboard_repository_impl.dart';

// === Cubits ===
import 'package:new_care/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:new_care/core/logic/connectivity_cubit.dart';
import 'package:new_care/core/logic/error_cubit.dart';
import 'package:new_care/features/cases/presentation/cubit/cases_cubit.dart';
import 'package:new_care/features/procedures/presentation/cubit/procedures_cubit.dart';
import 'package:new_care/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:new_care/features/financials/presentation/cubit/financials_cubit.dart';
import 'package:new_care/features/shifts/presentation/cubit/shift_cubit.dart';
import 'package:new_care/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:new_care/features/payroll/presentation/cubit/payroll_cubit.dart';
import 'package:new_care/features/dashboard/presentation/cubit/dashboard_cubit.dart';

final sl = GetIt.instance; // sl: short for Service Locator

Future<void> initDI() async {
  // ============================================
  // === الخدمات - Services ===
  // ============================================
  
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService.instance);
  sl.registerLazySingleton<SqliteService>(() => SqliteService.instance);
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);
  sl.registerLazySingleton<NotificationService>(() => NotificationService.instance);
  sl.registerLazySingleton<ReportService>(() => ReportService.instance);
  sl.registerLazySingleton<LocalLogService>(() => LocalLogService.instance);
  sl.registerLazySingleton<DeviceService>(() => DeviceService.instance);
  sl.registerLazySingleton<SyncManager>(() => SyncManager.instance);
  
  // SyncService depends on FirebaseService and SqliteService
  sl.registerLazySingleton<SyncService>(() => SyncService.instance);

  // === خدمات جديدة - New Services ===
  sl.registerLazySingleton<BackupService>(() => BackupService.instance);
  sl.registerLazySingleton<ExportService>(() => ExportService.instance);

  // ============================================
  // === المستودعات القديمة - Legacy Firebase Repositories ===
  // === (تستخدمها بعض الشاشات مؤقتاً حتى الترحيل الكامل) ===
  // ============================================
  
  sl.registerLazySingleton<UsersRepository>(() => UsersRepository());
  sl.registerLazySingleton<LogsRepository>(() => LogsRepository());

  // ============================================
  // === مستودعات الدومين - Domain Repositories ===
  // === (الواجهات المجردة ← التنفيذ الفعلي) ===
  // ============================================

  sl.registerLazySingleton<ICasesRepository>(() => CasesRepositoryImpl());
  sl.registerLazySingleton<IAttendanceRepository>(() => AttendanceRepositoryImpl());
  sl.registerLazySingleton<IInventoryRepository>(() => InventoryRepositoryImpl());
  sl.registerLazySingleton<IProceduresRepository>(() => ProceduresRepositoryImpl());
  sl.registerLazySingleton<IFinancialsRepository>(() => FinancialsRepositoryImpl());
  sl.registerLazySingleton<IShiftsRepository>(() => ShiftsRepositoryImpl());
  sl.registerLazySingleton<IPayrollRepository>(() => PayrollRepositoryImpl());
  sl.registerLazySingleton<IInvoiceRepository>(() => InvoiceRepositoryImpl());
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<IDashboardRepository>(
      () => DashboardRepositoryImpl(casesRepository: sl()));

  // ============================================
  // === البلوك / كيوبيت - Bloc / Cubit ===
  // ============================================

  sl.registerFactory(() => AuthCubit(authRepository: sl()));
  sl.registerFactory(() => ConnectivityCubit());
  sl.registerFactory(() => ErrorCubit());
  sl.registerFactory(() => CasesCubit(casesRepository: sl()));
  sl.registerFactory(() => ProceduresCubit(proceduresRepository: sl()));
  sl.registerFactory(() => InventoryCubit(inventoryRepository: sl()));
  sl.registerFactory(() => FinancialsCubit(financialsRepository: sl()));
  sl.registerFactory(() => ShiftCubit(shiftsRepository: sl()));
  sl.registerFactory(() => AttendanceCubit(
        attendanceRepository: sl(),
        shiftsRepository: sl(),
      ));
  sl.registerFactory(() => PayrollCubit(payrollRepository: sl()));
  sl.registerFactory(() => DashboardCubit(dashboardRepository: sl()));
}
