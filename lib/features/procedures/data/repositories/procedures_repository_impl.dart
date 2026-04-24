import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/procedures_repository.dart';
import '../models/procedure_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// تنفيذ مستودع الإجراءات (الجيل الثاني) - Procedures Repository Implementation v2
/// Reliable, offline-first medical procedures management.
class ProceduresRepositoryImpl implements IProceduresRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createProcedure(ProcedureModel procedure) async {
    await _local.insert('procedures', procedure.toSqliteMap());
    await _sync.enqueue(
      tableName: 'procedures',
      operation: 'create',
      docId: procedure.id,
      data: procedure.toMap(),
    );
  }

  @override
  Future<void> updateProcedure(ProcedureModel procedure) async {
    await _local.insert('procedures', procedure.toSqliteMap());
    await _sync.enqueue(
      tableName: 'procedures',
      operation: 'update',
      docId: procedure.id,
      data: procedure.toMap(),
    );
  }

  @override
  Future<void> deleteProcedure(String id) async {
    await _local.delete('procedures', where: 'id = ?', whereArgs: [id]);
    await _sync.enqueue(
      tableName: 'procedures',
      operation: 'delete',
      docId: id,
      data: {},
    );
  }

  @override
  Future<List<ProcedureModel>> getAllProcedures() async {
    try {
      final results = await _local.database.then((db) => db.query('procedures'));
      if (results.isNotEmpty) {
        return results.map((m) => ProcedureModel.fromMap(m, m['id'] as String)).toList();
      }
    } catch (e) {
      // If table is corrupted or schema mismatched, try to recreate it
      final db = await _local.database;
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
    }
    
    // Fallback to remote or initial load
    final remoteItems = await _remote.getAllProcedures();
    for (var item in remoteItems) {
      try {
        await _local.insert('procedures', item.toSqliteMap());
      } catch (e) {
        // Final fallback
      }
    }
    return remoteItems;
  }

  @override
  Future<int> getProceduresCount() async {
    return await _local.getProceduresCount();
  }

  @override
  Future<List<ProcedureModel>> getUpdatedProcedures(DateTime lastSync) async {
    return await _remote.getUpdatedProcedures(lastSync);
  }

  @override
  Stream<List<ProcedureModel>> streamProcedures() {
    return _remote.safeStream(FirebaseFirestore.instance.collection('procedures')).map(
      (snapshot) => snapshot.docs
          .map((doc) => ProcedureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}
