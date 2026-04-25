import 'dart:developer';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local/local_log_service.dart';
import '../../../../core/services/network/connectivity_service.dart';
import '../../../../core/services/sync/sync_manager.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../data/models/case_model.dart';
import '../../domain/repositories/cases_repository.dart';
import 'cases_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CasesCubit extends Cubit<CasesState> {
  final ICasesRepository _casesRepository;
  final SyncManager _syncManager;

  CasesCubit({
    required ICasesRepository casesRepository,
    SyncManager? syncManager,
  }) : _casesRepository = casesRepository,
       _syncManager = syncManager ?? SyncManager.instance,
       super(CasesInitial());

  StreamSubscription? _casesSub;

  @override
  Future<void> close() {
    _casesSub?.cancel();
    return super.close();
  }

  Future<void> loadCases({String? nurseId, bool force = false}) async {
    if (!force && state is CasesLoaded) return;

    emit(CasesLoading());
    _casesSub?.cancel();
    _casesSub = _casesRepository
        .streamAllCases(nurseId: nurseId)
        .listen(
          (cases) {
            final sortedCases = List<CaseModel>.from(cases)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (state is CasesLoaded) {
              final s = state as CasesLoaded;
              emit(s.copyWith(cases: sortedCases));
            } else {
              emit(CasesLoaded(cases: sortedCases));
            }
          },
          onError: (e) {
            emit(CasesError('خطأ في تحميل الحالات: ${e.toString()}'));
          },
        );
  }

  void searchCases(String query) {
    if (state is CasesLoaded) {
      final currentState = state as CasesLoaded;
      emit(CasesLoaded(cases: currentState.cases, searchQuery: query));
    }
  }

  /// إضافة حالة مع خصم مخزون ومزامنة - Add case with inventory deduction & sync
  Future<void> addCase(CaseModel newCase) async {
    try {
      // 1. Get Firebase Auth info on main thread BEFORE async operations
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';
      final uName = currentUser?.displayName ?? 'مستخدم';

      // 2. خصم المخزون أولاً
      final isConnected = await ConnectivityService.instance.checkConnection();

      for (var supply in newCase.suppliesUsed) {
        try {
          if (isConnected) {
            // Use repository for inventory operations via sync manager
            await _syncManager.addPendingOperation(
              tableName: 'inventory',
              operation: 'deduct',
              docId: supply.inventoryId,
              data: {'quantity': supply.quantity},
            );
          } else {
            await _syncManager.addPendingOperation(
              tableName: 'inventory',
              operation: 'deduct',
              docId: supply.inventoryId,
              data: {'quantity': supply.quantity},
            );
          }
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

      // 5. Brief delay to ensure local DB write completes
      await Future.delayed(const Duration(milliseconds: 200));

      // 6. Notify all screens about case addition (dashboard, reports, financials, etc)
      CaseChangeNotifier().notifyCaseAdded(newCase.id);

      // 7. Reload cases
      loadCases(force: true);
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

      // Brief delay to ensure local DB write completes
      await Future.delayed(const Duration(milliseconds: 200));

      // Notify all screens about case update
      CaseChangeNotifier().notifyCaseUpdated(updatedCase.id);

      loadCases(force: true);
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

      final isConnected = await ConnectivityService.instance.checkConnection();
      if (isConnected) {
        await _casesRepository.deleteCase(c.id);
      } else {
        await _syncManager.addPendingOperation(
          tableName: 'cases',
          operation: 'delete',
          docId: c.id,
          data: {},
        );
      }

      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'delete_case',
        actionLabel: 'حذف حالة',
        targetType: 'case',
        targetId: c.id,
        details: 'تم حذف حالة ${c.patientName}',
      );

      // Brief delay to ensure local DB write completes
      await Future.delayed(const Duration(milliseconds: 200));

      // Notify all screens about case deletion
      CaseChangeNotifier().notifyCaseDeleted(c.id);

      loadCases(force: true);
    } catch (e) {
      emit(CasesError('خطأ في حذف الحالة: ${e.toString()}'));
    }
  }
}
