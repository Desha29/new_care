import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/services/local/sqlite_service.dart';
import 'core/services/network/connectivity_service.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/services/sync/sync_manager.dart';
import 'core/services/sync/outside_cases_listener.dart';

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

  // تحميل البيانات من السحابة مرة واحدة عند فتح التطبيق
  // Download data from cloud once on app startup
  SyncManager.instance.downloadFromCloud(); // fire-and-forget

  // بدء الاستماع لحالات الممرضين الخارجيين
  // Start listening for outside nurse cases
  OutsideCasesListener.instance.startListening();

  runApp(const NewCareApp());
}
