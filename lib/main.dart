import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/services/local/sqlite_service.dart';
import 'core/services/network/connectivity_service.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/services/notifications/case_change_notifier.dart';
import 'core/services/notifications/data_change_notifier.dart';
import 'core/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/services/sync/sync_manager.dart';
import 'core/services/sync/outside_cases_listener.dart';
import 'core/services/sync/realtime_update_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDI();
  await initializeDateFormatting('ar');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(1000, 700),
      center: true,
      title: 'نيو كير - إدارة التمريض',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setFullScreen(false);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  sqfliteFfiInit();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SqliteService.instance.database;

  await ConnectivityService.instance.initialize();
  await NotificationService.instance.initialize();
  Bloc.observer = AppBlocObserver();

  // تجاهل أخطاء Flutter المعروفة على Windows (مشاكل لوحة المفاتيح)
  // Suppress known Flutter Windows keyboard event bugs
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exceptionAsString();
    if (error.contains('physicalKey is already pressed') ||
        error.contains('is not currently pressed')) {
      // Known Flutter Windows bug - safe to ignore
      return;
    }
    // For all other errors, use the default handler
    FlutterError.presentError(details);
  };
  if (kReleaseMode) {
    runZonedGuarded(
      () async {
        await SentryFlutter.init((options) {
          options.dsn =
              'https://4342bb1bdcc3f64fcfa6514ad0fe7bb7@o4511422159323136.ingest.us.sentry.io/4511422170988544';
        });

        runApp(NewCareApp());
      },
      (exception, stackTrace) async {
        await Sentry.captureException(exception, stackTrace: stackTrace);
      },
    );
  } else {
    runApp(NewCareApp());
  }
  // تحميل البيانات من السحابة وبدء المستمعين بعد استقرار الواجهة
  // Load data and start listeners after UI is stable to prevent threading issues
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // SyncManager.instance.downloadFromCloud(); // Disabled: no full cloud download on startup
    OutsideCasesListener.instance.startListening();

    // === Real-time Update Listener (10s poll, cost-optimized) ===
    // Routes mobile events through surgical sync → cubits auto-react
    final rtListener = RealtimeUpdateListener.instance;

    // الحالات - Targeted Case Sync
    rtListener.onCaseAdded = (id) async {
      final model = await SyncManager.instance.downloadCase(id);
      CaseChangeNotifier().notifyCaseAdded(id, model: model);
      DataChangeNotifier()
          .notifyLocalDataChanged(); // Trigger dashboard stats refresh

      // Redundant Sync: Ensure inventory used in this case is also updated immediately
      if (model != null) {
        for (var supply in model.suppliesUsed) {
          await SyncManager.instance.downloadInventoryItem(supply.inventoryId);
        }
      }

      NotificationService.instance.showNotification(
        title: 'حالة جديدة 🏥',
        body: 'تم إضافة حالة جديدة من التطبيق. جاري تحديث البيانات...',
      );
    };
    rtListener.onCaseUpdated = (id) async {
      final model = await SyncManager.instance.downloadCase(id);
      CaseChangeNotifier().notifyCaseUpdated(id, model: model);
      DataChangeNotifier().notifyLocalDataChanged();
    };
    rtListener.onCaseDeleted = (id) async {
      await SyncManager.instance.deleteCaseLocally(id);
      CaseChangeNotifier().notifyCaseDeleted(id);
      DataChangeNotifier().notifyLocalDataChanged();
    };

    // الحضور - Targeted Attendance Sync
    rtListener.onAttendanceChanged = (id) async {
      await SyncManager.instance.downloadAttendance(id);
      DataChangeNotifier().notifyLocalDataChanged();
    };

    // المخزون - Targeted Inventory Sync
    rtListener.onInventoryChanged = (id) async {
      await SyncManager.instance.downloadInventoryItem(id);
      DataChangeNotifier().notifyLocalDataChanged();
    };

    // Fallbacks for other modules (using full sync for now)
    rtListener.onPayrollChanged = (_) async {
      await SyncManager.instance.downloadFromCloud();
      DataChangeNotifier().notifyLocalDataChanged();
    };
    rtListener.onShiftsChanged = (_) async {
      await SyncManager.instance.downloadFromCloud();
      DataChangeNotifier().notifyLocalDataChanged();
    };
    rtListener.onUsersChanged = (_) async {
      await SyncManager.instance.downloadFromCloud();
      DataChangeNotifier().notifyLocalDataChanged();
    };
    rtListener.onExpensesChanged = (_) async {
      await SyncManager.instance.downloadFromCloud();
      DataChangeNotifier().notifyLocalDataChanged();
    };
    rtListener.onProceduresChanged = (_) async {
      await SyncManager.instance.downloadFromCloud();
      DataChangeNotifier().notifyLocalDataChanged();
    };

    rtListener.startListening();
  });
}
