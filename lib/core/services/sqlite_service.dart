import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// خدمة قاعدة البيانات المحلية SQLite
/// SQLite Local Database Service for offline backup
class SqliteService {
  static SqliteService? _instance;
  static Database? _database;

  SqliteService._();

  static SqliteService get instance {
    _instance ??= SqliteService._();
    return _instance!;
  }

  /// تهيئة قاعدة البيانات - Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;

    // تهيئة FFI لسطح المكتب - Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await _getDatabasePath();
    _database = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return _database!;
  }

  /// مسار قاعدة البيانات - Database path
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(appDir.path, 'database'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return p.join(dbDir.path, 'new_care_backup.db');
  }

  /// إنشاء الجداول - Create tables
  Future<void> _onCreate(Database db, int version) async {
    // جدول المستخدمين - Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT DEFAULT '',
        role TEXT DEFAULT 'nurse',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // جدول المرضى - Patients table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER DEFAULT 0,
        gender TEXT DEFAULT 'male',
        phone TEXT DEFAULT '',
        address TEXT DEFAULT '',
        medicalHistory TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdBy TEXT DEFAULT ''
      )
    ''');

    // جدول الحالات - Cases table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cases (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        patientName TEXT DEFAULT '',
        nurseId TEXT DEFAULT '',
        nurseName TEXT DEFAULT '',
        caseType TEXT DEFAULT 'in_center',
        status TEXT DEFAULT 'pending',
        totalPrice REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        caseDate TEXT NOT NULL,
        notes TEXT DEFAULT '',
        address TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdBy TEXT DEFAULT '',
        FOREIGN KEY (patientId) REFERENCES patients(id)
      )
    ''');

    // جدول المستلزمات - Inventory table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit TEXT DEFAULT 'قطعة',
        quantity INTEGER DEFAULT 0,
        minStock INTEGER DEFAULT 5,
        price REAL DEFAULT 0,
        category TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdBy TEXT DEFAULT ''
      )
    ''');

    // جدول السجلات - Logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT DEFAULT '',
        action TEXT NOT NULL,
        actionLabel TEXT DEFAULT '',
        targetType TEXT DEFAULT '',
        targetId TEXT DEFAULT '',
        details TEXT DEFAULT '',
        timestamp TEXT NOT NULL
      )
    ''');

    // جدول الإعدادات - Settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// ترقية قاعدة البيانات - Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // سيتم إضافة الترقيات المستقبلية هنا
  }

  // === عمليات CRUD عامة - Generic CRUD Operations ===

  /// إدراج سجل - Insert record
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// إدراج مجموعة سجلات - Insert batch records
  Future<void> insertBatch(String table, List<Map<String, dynamic>> dataList) async {
    final db = await database;
    final batch = db.batch();
    for (final data in dataList) {
      batch.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// تحديث سجل - Update record
  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  /// حذف سجل - Delete record
  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// جلب جميع السجلات - Get all records
  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  /// جلب سجل واحد - Get single record
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return result.isEmpty ? null : result.first;
  }

  /// بحث في السجلات - Search records
  Future<List<Map<String, dynamic>>> search(String table, String column, String query) async {
    final db = await database;
    return db.query(table, where: '$column LIKE ?', whereArgs: ['%$query%']);
  }

  /// حذف جميع البيانات من جدول - Clear table
  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  /// حذف جميع البيانات - Clear all data
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('users');
    await db.delete('patients');
    await db.delete('cases');
    await db.delete('inventory');
    await db.delete('logs');
    await db.delete('settings');
  }

  /// نسخ احتياطي - Create backup file
  Future<String> createBackup() async {
    final dbPath = await _getDatabasePath();
    final appDir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupDir.path, 'backup_$timestamp.db');

    await File(dbPath).copy(backupPath);
    return backupPath;
  }

  /// استعادة من نسخة احتياطية - Restore from backup
  Future<void> restoreBackup(String backupPath) async {
    final dbPath = await _getDatabasePath();

    // إغلاق قاعدة البيانات الحالية
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // نسخ ملف النسخة الاحتياطية
    await File(backupPath).copy(dbPath);

    // إعادة فتح قاعدة البيانات
    await database;
  }

  /// قائمة النسخ الاحتياطية - List backups
  Future<List<FileSystemEntity>> listBackups() async {
    final appDir = await getApplicationSupportDirectory();
    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) return [];

    return backupDir.listSync()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  /// إغلاق قاعدة البيانات - Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
