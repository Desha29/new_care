import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
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

    sqfliteFfiInit();

    final dbPath = await _getDatabasePath();
    _database = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 6, // ترقية لإضافة حقول الجرد المفقودة وتصحيح الأسماء
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
        deviceId TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // جدول الحالات - Cases table (دمج بيانات المريض)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cases (
        id TEXT PRIMARY KEY,
        patientName TEXT NOT NULL,
        patientAge INTEGER DEFAULT 0,
        patientGender TEXT DEFAULT 'male',
        patientPhone TEXT DEFAULT '',
        patientAddress TEXT DEFAULT '',
        medicalHistory TEXT DEFAULT '',
        nurseId TEXT DEFAULT '',
        nurseName TEXT DEFAULT '',
        caseType TEXT DEFAULT 'in_center',
        status TEXT DEFAULT 'pending',
        totalPrice REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        caseDate TEXT NOT NULL,
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        createdBy TEXT DEFAULT ''
      )
    ''');

    // جدول الجرد - Inventory table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT DEFAULT '',
        quantity INTEGER DEFAULT 0,
        minStock INTEGER DEFAULT 5,
        unit TEXT DEFAULT 'قطعة',
        price REAL DEFAULT 0,
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
        id TEXT PRIMARY KEY,
        key TEXT,
        value TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');

    // جدول الورديات - Shifts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT DEFAULT '',
        date TEXT NOT NULL,
        roleToday TEXT DEFAULT 'cases',
        canAccessCases INTEGER DEFAULT 0,
        canAccessInventory INTEGER DEFAULT 0,
        canGoExternal INTEGER DEFAULT 0,
        canManageFinancials INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        createdBy TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // جدول الحضور - Attendance table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT DEFAULT '',
        date TEXT NOT NULL,
        checkInTime TEXT NOT NULL,
        checkOutTime TEXT,
        deviceId TEXT DEFAULT '',
        location TEXT DEFAULT '',
        status TEXT DEFAULT 'checked_in',
        notes TEXT DEFAULT ''
      )
    ''');

    // جدول العمليات المعلقة (للمزامنة عند عودة الاتصال)
    // Pending sync operations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sync (
        id TEXT PRIMARY KEY,
        tableName TEXT NOT NULL,
        operation TEXT NOT NULL,
        docId TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');
  }

  /// ترقية قاعدة البيانات - Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS patients');
      await db.execute('DROP TABLE IF EXISTS cases');
      await db.execute('DROP TABLE IF EXISTS inventory');
      await db.execute('DROP TABLE IF EXISTS logs');
      await db.execute('DROP TABLE IF EXISTS settings');
      await db.execute('DROP TABLE IF EXISTS shifts');
      await db.execute('DROP TABLE IF EXISTS attendance');
      await db.execute('DROP TABLE IF EXISTS pending_sync');
      await _onCreate(db, newVersion);
    }
  }

  // --- عمليات عامة - Generic Operations ---

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertBatch(String table, List<Map<String, dynamic>> dataList) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final data in dataList) {
        await txn.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // --- عمليات خاصة - Specific Operations ---

  Future<void> saveUser(Map<String, dynamic> user) async {
    await insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    return await getById('users', id);
  }

  Future<void> saveCase(Map<String, dynamic> caseMap) async {
    await insert('cases', caseMap);
  }

  Future<List<Map<String, dynamic>>> getAllCases() async {
    final db = await database;
    return await db.query('cases', orderBy: 'createdAt DESC');
  }

  Future<void> deleteCase(String id) async {
    final db = await database;
    await db.delete('cases', where: 'id = ?', whereArgs: [id]);
  }

  /// جلب عدد المستخدمين - Get users count
  Future<int> getUsersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// جلب عدد الحالات (المرضى) - Get cases count
  Future<int> getPatientsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cases');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getShiftsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM shifts');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getInventoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM inventory');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getProceduresCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM procedures');
    return result.first['count'] as int? ?? 0;
  }

  /// إنشاء نسخة احتياطية - Create backup (stub)
  Future<String> createBackup() async {
    final dbPath = await _getDatabasePath();
    final appDir = await getApplicationSupportDirectory();
    final backupPath = p.join(appDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await File(dbPath).copy(backupPath);
    return backupPath;
  }
}
