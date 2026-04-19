import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/services/sqlite_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initDI();
  await initializeDateFormatting('ar');

  sqfliteFfiInit();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SqliteService.instance.database;

  await ConnectivityService.instance.initialize();
  await NotificationService.instance.initialize();

  await FirebaseService.instance.seedDefaultUsers();
  await FirebaseService.instance.seedDefaultInventory();

  Bloc.observer = AppBlocObserver();

  runApp(const NewCareApp());
}
