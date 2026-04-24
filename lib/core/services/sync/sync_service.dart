import 'package:new_care/core/services/local/sqlite_service.dart';
import 'package:new_care/core/services/sync/sync_manager.dart';
import 'package:new_care/core/logic/error_cubit.dart';
import 'package:new_care/core/di/injection.dart';
import 'package:new_care/core/services/network/connectivity_service.dart';

/// خدمة المزامنة (الجيل الثاني) - Sync Service v2
/// High-level orchestration for manual sync and backups.
class SyncService {
  final _sync = SyncManager.instance;
  final _sqlite = SqliteService.instance;
  final _connectivity = ConnectivityService.instance;

  static SyncService get instance => sl<SyncService>();

  /// التحقق من الاتصال - Check connectivity
  Future<bool> isOnline() async {
    return _connectivity.isOnline;
  }

  /// مزامنة كاملة (تراكمية) - Full incremental sync
  Future<void> syncFromFirebase() async {
    if (!await isOnline()) return;

    try {
      // Use SyncManager's delta sync to avoid heavy downloads
      await _sync.syncAll();
      
      await _sqlite.insert('settings', {
        'id': 'lastSyncTime', // Ensure id is set for getById compatibility
        'key': 'lastSyncTime',
        'value': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, overwrite: true);
      
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
    // 1. Sync pending operations first
    await _sync.processQueue();
    
    // 2. Refresh local data if online
    if (await isOnline()) {
      await syncFromFirebase();
    }
    
    // 3. Create backup file
    return await _sqlite.createBackup();
  }
}
