import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase/firebase_service.dart';
import '../../../../core/services/local/sqlite_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../domain/repositories/cases_repository.dart';
import '../models/case_model.dart';

/// تنفيذ مستودع الحالات (الجيل الثاني) - Cases Repository Implementation v2
/// Enterprise-grade, offline-first implementation.
class CasesRepositoryImpl implements ICasesRepository {
  final _local = SqliteService.instance;
  final _remote = FirebaseService.instance;
  final _sync = SyncManager.instance;

  @override
  Future<void> createCase(CaseModel caseModel) async {
    // 1. Save locally (immediate UI update)
    await _local.saveCase(caseModel.toSqliteMap());
    // 2. Queue for remote sync
    await _sync.enqueue(
      tableName: 'cases',
      operation: 'create',
      docId: caseModel.id,
      data: caseModel.toMap(),
    );
  }

  @override
  Future<void> updateCase(CaseModel caseModel) async {
    await _local.saveCase(caseModel.toSqliteMap());
    await _sync.enqueue(
      tableName: 'cases',
      operation: 'update',
      docId: caseModel.id,
      data: caseModel.toMap(),
    );
  }

  @override
  Future<void> deleteCase(String caseId) async {
    await _local.deleteCase(caseId);
    await _sync.enqueue(
      tableName: 'cases',
      operation: 'delete',
      docId: caseId,
      data: {}, // No data needed for delete
    );
  }

  @override
  Future<List<CaseModel>> getAllCases({String? nurseId}) async {
    // Read from local for performance and offline support
    final results = await _local.getAllCases();
    var cases = results.map((m) => CaseModel.fromMap(m, m['id'])).toList();
    
    if (nurseId != null) {
      cases = cases.where((c) => c.nurseId == nurseId).toList();
    }
    
    // If local is empty, try fetching from remote and sync down
    if (cases.isEmpty) {
      final remoteCases = await _remote.getAllCases(nurseId: nurseId);
      for (var c in remoteCases) {
        await _local.saveCase(c.toSqliteMap());
      }
      return remoteCases;
    }
    
    return cases;
  }

  @override
  Future<int> getPatientsCount() async {
    return await _local.getPatientsCount();
  }

  @override
  Future<List<CaseModel>> getTodayCases({String? nurseId}) async {
    final all = await getAllCases(nurseId: nurseId);
    final now = DateTime.now();
    return all.where((c) => 
      c.caseDate.year == now.year && 
      c.caseDate.month == now.month && 
      c.caseDate.day == now.day
    ).toList();
  }

  @override
  Future<List<CaseModel>> getNurseCases(String nurseId) async {
    return await getAllCases(nurseId: nurseId);
  }

  @override
  Future<List<CaseModel>> getUpdatedCases(DateTime lastSync) async {
    return await _remote.getUpdatedCases(lastSync);
  }

  @override
  Stream<List<CaseModel>> streamAllCases({String? nurseId}) {
    // We still use Remote streams for real-time multi-user updates
    return _remote.streamAllCases(nurseId: nurseId);
  }

  @override
  Stream<List<CaseModel>> streamTodayCases({String? nurseId}) {
    // For today's cases, we can also use remote stream but it's better to keep it consistent
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = FirebaseFirestore.instance.collection('cases')
        .where('caseDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('caseDate', isLessThan: endOfDay.toIso8601String());

    // We use safeStream helper from remote to avoid Windows crashes
    return _remote.safeStream(query).map((snapshot) {
      var cases = snapshot.docs.map((doc) => CaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      if (nurseId != null) {
        cases = cases.where((c) => c.nurseId == nurseId).toList();
      }
      return cases;
    });
  }
}
