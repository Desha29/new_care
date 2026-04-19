import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'sqlite_service.dart';

/// خدمة النسخ الاحتياطي التلقائي - Auto Backup Service
/// جدولة وإدارة النسخ الاحتياطية لقاعدة البيانات المحلية
class BackupService {
  static BackupService? _instance;
  final SqliteService _sqliteService;

  BackupService._() : _sqliteService = SqliteService.instance;

  static BackupService get instance {
    _instance ??= BackupService._();
    return _instance!;
  }

  /// إنشاء نسخة احتياطية - Create backup
  Future<String> createBackup({String? label}) async {
    final backupPath = await _sqliteService.createBackup();
    // إعادة تسمية بالنسخة الاحتياطية إن وجد تسمية
    if (label != null && label.isNotEmpty) {
      final dir = p.dirname(backupPath);
      final newPath = p.join(dir, 'backup_${label}_${DateTime.now().millisecondsSinceEpoch}.db');
      await File(backupPath).rename(newPath);
      return newPath;
    }
    return backupPath;
  }

  /// جلب قائمة النسخ الاحتياطية - List all backups
  Future<List<BackupInfo>> listBackups() async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(appDir.path);
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((f) => f is File && p.basename(f.path).startsWith('backup_'))
        .cast<File>()
        .toList();

    final backups = <BackupInfo>[];
    for (final file in files) {
      final stat = await file.stat();
      backups.add(BackupInfo(
        path: file.path,
        name: p.basename(file.path),
        size: stat.size,
        createdAt: stat.modified,
      ));
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  /// حذف نسخة احتياطية - Delete backup
  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// حذف النسخ الاحتياطية القديمة (أكثر من 30 يوم) - Cleanup old backups
  Future<int> cleanupOldBackups({int maxAgeDays = 30}) async {
    final backups = await listBackups();
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    int deleted = 0;

    for (final backup in backups) {
      if (backup.createdAt.isBefore(cutoff)) {
        await deleteBackup(backup.path);
        deleted++;
      }
    }

    return deleted;
  }

  /// حجم جميع النسخ الاحتياطية - Total backup size
  Future<int> getTotalBackupSize() async {
    final backups = await listBackups();
    return backups.fold<int>(0, (sum, b) => sum + b.size);
  }
}

/// معلومات النسخة الاحتياطية - Backup Info
class BackupInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  const BackupInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  /// حجم مقروء - Human readable size
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
