import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../../../core/services/local/sqlite_service.dart';

import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../data/models/case_model.dart';
import '../../domain/repositories/cases_repository.dart';
import 'cases_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/enums/case_status.dart';

class CasesCubit extends Cubit<CasesState> {
  final ICasesRepository _casesRepository;
  final SyncManager _syncManager;
  StreamSubscription? _caseChangeSub;
  String? _activeNurseId; // حفظ فلتر الممرض - Store nurse filter for reloads


  CasesCubit({
    required ICasesRepository casesRepository,
    SyncManager? syncManager,
  }) : _casesRepository = casesRepository,
       _syncManager = syncManager ?? SyncManager.instance,
       super(CasesInitial()) {
    // Listen for external case changes (e.g. outside_cases from nurse app)
    _caseChangeSub = CaseChangeNotifier().onCaseChanged.listen((event) {
      // إعادة تحميل بنفس الفلتر المحفوظ - Reload with the stored filter
      _reloadCases();
    });
  }

  @override
  Future<void> close() {
    _caseChangeSub?.cancel();
    return super.close();
  }

  /// إعادة تحميل داخلي بنفس الفلتر - Internal reload with stored filter
  void _reloadCases() {
    _loadCasesInternal(force: true);
  }

  /// تحميل الحالات من الشاشة - Load cases from screen (sets/resets filter)
  Future<void> loadCases({String? nurseId, bool force = false}) async {
    // دايماً حدّث الفلتر لما الشاشة تستدعي - Always update filter from screen
    _activeNurseId = nurseId;
    await _loadCasesInternal(force: force);

  }

  /// تحميل الحالات الفعلي - Actual case loading
  Future<void> _loadCasesInternal({bool force = false}) async {
    if (!force && state is CasesLoaded) return;

    emit(CasesLoading());
    try {
      final cases = await _casesRepository.getAllCases(nurseId: _activeNurseId);
      final sortedCases = List<CaseModel>.from(cases)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(CasesLoaded(cases: sortedCases));
    } catch (e) {
      emit(CasesError('خطأ في تحميل الحالات: ${e.toString()}'));
    }
  }



  void searchCases(String query) {
    if (state is CasesLoaded) {
      final s = state as CasesLoaded;
      emit(s.copyWith(searchQuery: query));
    }
  }

  void filterByType(CaseType? type) {
    if (state is CasesLoaded) {
      final s = state as CasesLoaded;
      emit(s.copyWith(typeFilter: type, clearTypeFilter: type == null));
    }
  }

  /// إضافة حالة مع خصم مخزون ومزامنة - Add case with inventory deduction & sync
  Future<void> addCase(CaseModel newCase) async {
    try {
      // 1. Get Firebase Auth info on main thread BEFORE async operations
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';
      final uName = currentUser?.displayName ?? 'مستخدم';

      // 2. التحقق من توفر المخزون قبل الخصم - Validate stock availability
      for (var supply in newCase.suppliesUsed) {
        final itemMap = await SqliteService.instance.getById('inventory', supply.inventoryId);
        if (itemMap == null) {
          emit(CasesError('المستلزم "${supply.name}" غير موجود في المخزون'));
          return;
        }
        final currentQty = (itemMap['quantity'] ?? 0) as int;
        if (supply.quantity > currentQty) {
          emit(CasesError(
            'الكمية المطلوبة من "${supply.name}" (${supply.quantity}) أكبر من المتوفر في المخزون ($currentQty)',
          ));
          return;
        }
      }

      // 3. خصم المخزون - Deduct inventory (validated)
      for (var supply in newCase.suppliesUsed) {
        try {
          await _syncManager.addPendingOperation(
            tableName: 'inventory',
            operation: 'deduct',
            docId: supply.inventoryId,
            data: {'quantity': supply.quantity},
          );
        } catch (e) {
          log('[InventoryDeduction] Error: $e');
          rethrow;
        }
      }

      // 3. حفظ الحالة مع مزامنة
      await _syncManager.saveCaseWithSync(newCase, isNew: true);

      // 4. تسجيل النشاط (using previously retrieved user info)
      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'add_case',
        actionLabel: 'إضافة حالة',
        targetType: 'case',
        targetId: newCase.id,
        details:
            'تم إضافة حالة جديدة بنجاح للمريض ${newCase.patientName} - المبلغ: ${newCase.totalPrice}',
      );

      // 5. Update local cases state directly
      if (state is CasesLoaded) {
        final currentState = state as CasesLoaded;
        final updatedCases = [newCase, ...currentState.cases];
        emit(currentState.copyWith(cases: updatedCases));
      } else {
        emit(CasesLoaded(cases: [newCase]));
      }

      // 6. Notify all screens AFTER deductions and state updates are done
      CaseChangeNotifier().notifyCaseAdded(newCase.id);
      DataChangeNotifier().notifyLocalDataChanged();
    } catch (e) {
      emit(CasesError('خطأ: ${e.toString()}'));
    }
  }

  /// تحديث حالة - Update case
  Future<void> updateCase(CaseModel updatedCase) async {
    try {
      // Get Firebase Auth info on main thread BEFORE async operations
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';
      final uName = currentUser?.displayName ?? 'مستخدم';

      await _syncManager.saveCaseWithSync(updatedCase, isNew: false);

      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'update_case',
        actionLabel: 'تعديل حالة',
        targetType: 'case',
        targetId: updatedCase.id,
        details: 'تم تعديل حالة المريض ${updatedCase.patientName}',
      );

      // Notify all screens about case update
      CaseChangeNotifier().notifyCaseUpdated(updatedCase.id);
      DataChangeNotifier().notifyLocalDataChanged();

      // Update local state directly (no re-fetch from Firestore)
      if (state is CasesLoaded) {
        final currentState = state as CasesLoaded;
        final updatedCases = currentState.cases.map((c) {
          return c.id == updatedCase.id ? updatedCase : c;
        }).toList();
        emit(currentState.copyWith(cases: updatedCases));
      }
    } catch (e) {
      emit(CasesError('خطأ في تعديل الحالة: ${e.toString()}'));
    }
  }

  /// حذف حالة - Delete case
  Future<void> deleteCase(CaseModel c) async {
    try {
      // Get Firebase Auth info on main thread BEFORE async operations
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';
      final uName = currentUser?.displayName ?? 'مستخدم';

      // Always delete from local SQLite + queue remote delete
      await _casesRepository.deleteCase(c.id);

      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'delete_case',
        actionLabel: 'حذف حالة',
        targetType: 'case',
        targetId: c.id,
        details: 'تم حذف حالة ${c.patientName}',
      );

      // Notify all screens about case deletion
      CaseChangeNotifier().notifyCaseDeleted(c.id);
      DataChangeNotifier().notifyLocalDataChanged();

      // Update local state directly (no re-fetch from Firestore)
      if (state is CasesLoaded) {
        final currentState = state as CasesLoaded;
        final updatedCases = currentState.cases.where((cs) => cs.id != c.id).toList();
        emit(currentState.copyWith(cases: updatedCases));
      }
    } catch (e) {
      emit(CasesError('خطأ في حذف الحالة: ${e.toString()}'));
    }
  }

}
