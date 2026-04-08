import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_service.dart';
import 'sqlite_service.dart';
import '../logic/error_cubit.dart';
import '../di/injection.dart';

/// خدمة المزامنة - Sync Service
/// مزامنة البيانات بين Firebase وSQLite
class SyncService {
  final FirebaseService _firebase;
  final SqliteService _sqlite;

  SyncService({
    FirebaseService? firebase,
    SqliteService? sqlite,
  }) : _firebase = firebase ?? FirebaseService.instance,
       _sqlite = sqlite ?? SqliteService.instance;

  static SyncService get instance => sl<SyncService>();

  /// التحقق من الاتصال - Check connectivity
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// مزامنة كاملة من Firebase إلى SQLite - Full sync from Firebase to SQLite
  Future<void> syncFromFirebase() async {
    if (!await isOnline()) return;

    try {
      // مزامنة المستخدمين
      final users = await _firebase.getAllUsers();
      await _sqlite.clearTable('users');
      await _sqlite.insertBatch('users', users.map((u) => u.toSqliteMap()).toList());

      // مزامنة الحالات و بيانات المرضى المدمجة
      final cases = await _firebase.getAllCases();
      await _sqlite.clearTable('cases');
      await _sqlite.insertBatch('cases', cases.map((c) => c.toSqliteMap()).toList());

      // مزامنة المستلزمات
      final inventory = await _firebase.getAllInventory();
      await _sqlite.clearTable('inventory');
      await _sqlite.insertBatch('inventory', inventory.map((i) => i.toSqliteMap()).toList());

      // مزامنة السجلات
      final logs = await _firebase.getAllLogs();
      await _sqlite.clearTable('logs');
      await _sqlite.insertBatch('logs', logs.map((l) => l.toSqliteMap()).toList());

      await _sqlite.insert('settings', {
        'key': 'lastSyncTime',
        'value': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      sl<ErrorCubit>().showError('فشلت عملية المزامنة: $e');
      rethrow;
    }
  }

  /// جلب وقت آخر مزامنة - Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final result = await _sqlite.getById('settings', 'lastSyncTime');
    if (result == null) return null;
    return DateTime.tryParse(result['value'] ?? '');
  }

  /// نسخ احتياطي مع مزامنة - Backup with sync
  Future<String> backupWithSync() async {
    // مزامنة أولاً إن كان متصلاً
    if (await isOnline()) {
      await syncFromFirebase();
    }
    // إنشاء نسخة احتياطية
    return await _sqlite.createBackup();
  }
}
