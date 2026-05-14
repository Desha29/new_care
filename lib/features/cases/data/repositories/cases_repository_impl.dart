
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
    // Read from local only — offline-first, no remote fallback
    final results = await _local.getAllCases();
    var cases = results.map((m) => CaseModel.fromMap(m, m['id'])).toList();

    if (nurseId != null) {
      cases = cases.where((c) => c.nurseId == nurseId).toList();
    }

    return cases;
  }

  @override
  Future<PaginatedResult<CaseModel>> getCasesPaginated({
    String? nurseId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // We prioritize remote for paginated queries to handle large datasets correctly
    // with server-side filters.
    return await _remote.getCasesPaginated(
      nurseId: nurseId,
      limit: limit,
      startAfter: startAfter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<int> getPatientsCount() async {
    return await _local.getPatientsCount();
  }

  @override
  Future<List<CaseModel>> getTodayCases({String? nurseId}) async {
    final all = await getAllCases(nurseId: nurseId);
    final now = DateTime.now();
    return all
        .where(
          (c) =>
              c.caseDate.year == now.year &&
              c.caseDate.month == now.month &&
              c.caseDate.day == now.day,
        )
        .toList();
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
    // Local-only: just emit local data once
    // Remote sync only happens via manual sync buttons
    return Stream.fromFuture(getAllCases(nurseId: nurseId));
  }


  @override
  Stream<List<CaseModel>> streamTodayCases({String? nurseId}) {
    // Local-only: emit today's cases from SQLite
    return Stream.fromFuture(getTodayCases(nurseId: nurseId));
  }
}

