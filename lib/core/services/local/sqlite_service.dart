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
        version: 12, // Fixed procedures table NOT NULL constraints
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
        salary REAL DEFAULT 3000.0,
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

    // جدول المصاريف - Expenses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        amount REAL DEFAULT 0,
        category TEXT DEFAULT '',
        date TEXT NOT NULL,
        notes TEXT DEFAULT '',
        createdBy TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
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
        retryCount INTEGER DEFAULT 0,
        lastError TEXT,
        lastAttempt TEXT
      )
    ''');

    // جدول الإجراءات الطبية - Procedures table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS procedures (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        defaultPrice REAL DEFAULT 0,
        priceInside REAL DEFAULT 0,
        priceOutside REAL DEFAULT 0,
        notes TEXT DEFAULT '',
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// ترقية قاعدة البيانات - Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      // Create expenses table if it doesn't exist during upgrade
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL,
          amount REAL DEFAULT 0,
          category TEXT DEFAULT '',
          date TEXT NOT NULL,
          notes TEXT DEFAULT '',
          createdBy TEXT DEFAULT '',
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 10) {
      // Add salary column to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN salary REAL DEFAULT 3000.0');
      } catch (e) {
        // Ignore if column already exists
      }
    }
    if (oldVersion < 12) {
      // Force recreation of procedures table if it's in an inconsistent state
      try {
        await db.execute('DROP TABLE IF EXISTS procedures');
        await db.execute('''
          CREATE TABLE procedures (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            defaultPrice REAL DEFAULT 0,
            priceInside REAL DEFAULT 0,
            priceOutside REAL DEFAULT 0,
            notes TEXT DEFAULT '',
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // Ignore
      }
    }
  }

  /// تنفيذ عملية في معاملة - Run operation in a transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // --- عمليات عامة - Generic Operations ---

  Future<void> insert(String table, Map<String, dynamic> data, {bool overwrite = true}) async {
    final db = await database;
    await db.insert(
      table, 
      data, 
      conflictAlgorithm: overwrite ? ConflictAlgorithm.replace : ConflictAlgorithm.ignore,
    );
  }

  Future<void> update(String table, Map<String, dynamic> data, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<void> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> insertBatch(String table, List<Map<String, dynamic>> dataList) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final data in dataList) {
        batch.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
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
    return await db.query('cases', orderBy: 'caseDate DESC');
  }

  Future<void> deleteCase(String id) async {
    await delete('cases', where: 'id = ?', whereArgs: [id]);
  }

  // --- الإعدادات - Settings Helpers ---

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'id': key,
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  Future<Map<String, String>> getClinicInfo() async {
    final name = await getSetting('clinic_name') ?? 'مركز نيو كير';
    final phone = await getSetting('clinic_phone') ?? '01012345678';
    final address = await getSetting('clinic_address') ?? 'العنوان الافتراضي';
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  Future<void> saveClinicInfo(String name, String phone, String address) async {
    await setSetting('clinic_name', name);
    await setSetting('clinic_phone', phone);
    await setSetting('clinic_address', address);
  }

  Future<DateTime> getLastSync() async {
    final val = await getSetting('last_sync_timestamp');
    if (val == null) return DateTime(2025, 1, 1);
    return DateTime.tryParse(val) ?? DateTime(2025, 1, 1);
  }

  Future<void> updateLastSync() async {
    await setSetting('last_sync_timestamp', DateTime.now().toIso8601String());
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
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getShiftsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM shifts');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getInventoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM inventory');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deductInventory(String id, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE inventory SET quantity = quantity - ? WHERE id = ?',
      [quantity, id],
    );
  }

  Future<int> getProceduresCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM procedures');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_sync');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// إنشاء نسخة احتياطية - Create backup
  Future<String> createBackup() async {
    final dbPath = await _getDatabasePath();
    final appDir = await getApplicationSupportDirectory();
    final backupPath = p.join(appDir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await File(dbPath).copy(backupPath);
    return backupPath;
  }
}
