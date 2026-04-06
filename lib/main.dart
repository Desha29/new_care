import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/services/sqlite_service.dart';
import 'core/services/remote_config_service.dart';

/// نقطة الدخول الرئيسية - Main Entry Point
/// تهيئة Firebase وSQLite وRemote Config قبل تشغيل التطبيق
void main() async {
  // ضمان تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة SQLite FFI لسطح المكتب - Initialize SQLite FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // تهيئة Firebase - Initialize Firebase
  await Firebase.initializeApp();

  // تهيئة قاعدة البيانات المحلية - Initialize local database
  await SqliteService.instance.database;

  // تهيئة التحكم عن بُعد - Initialize Remote Config
  await RemoteConfigService.instance.initialize();

  // تشغيل التطبيق - Run the app
  runApp(const NewCareApp());
}
