import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../services/firebase_service.dart';
import '../services/sqlite_service.dart';
import '../services/sync_service.dart';
import '../services/sync_manager.dart';
import '../services/device_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/local_log_service.dart';
import '../services/remote_config_service.dart';
import '../../features/auth/logic/cubit/auth_cubit.dart';
import '../logic/connectivity_cubit.dart';
import '../logic/error_cubit.dart';
import '../../features/cases/logic/cubit/cases_cubit.dart';
import '../../features/procedures/logic/cubit/procedures_cubit.dart';
import '../../features/inventory/logic/cubit/inventory_cubit.dart';
import '../../features/financials/logic/cubit/financials_cubit.dart';
import '../../features/shifts/logic/cubit/shift_cubit.dart';
import '../../features/attendance/logic/cubit/attendance_cubit.dart';

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
  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService.instance);
  sl.registerLazySingleton<DeviceService>(() => DeviceService.instance);
  sl.registerLazySingleton<SyncManager>(() => SyncManager.instance);
  
  // SyncService depends on FirebaseService and SqliteService
  sl.registerLazySingleton<SyncService>(() => SyncService.instance);

  // ============================================
  // === Cubits (State Management) ===
  // ============================================
  
  // Singleton Cubits (Global)
  sl.registerLazySingleton<ErrorCubit>(() => ErrorCubit());
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(
    firebaseAuth: FirebaseAuth.instance,
    firebaseService: sl<FirebaseService>(),
  ));
  sl.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  
  // Feature Cubits (Global access for dashboard updates)
  sl.registerLazySingleton<CasesCubit>(() => CasesCubit());
  sl.registerLazySingleton<ProceduresCubit>(() => ProceduresCubit());
  sl.registerLazySingleton<InventoryCubit>(() => InventoryCubit());
  sl.registerLazySingleton<FinancialsCubit>(() => FinancialsCubit());
  sl.registerLazySingleton<ShiftCubit>(() => ShiftCubit());
  sl.registerLazySingleton<AttendanceCubit>(() => AttendanceCubit());
}
