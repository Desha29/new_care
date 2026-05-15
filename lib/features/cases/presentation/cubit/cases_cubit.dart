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
    if (state is CasesLoaded) {
      final s = state as CasesLoaded;
      _loadCasesInternal(
        force: true,
        timeFilter: s.timeFilter,
        customStartDate: s.customStartDate,
        customEndDate: s.customEndDate,
      );
    } else {
      _loadCasesInternal(force: true);
    }
  }

  /// تحميل الحالات من الشاشة - Load cases from screen (sets/resets filter)
  Future<void> loadCases({
    String? nurseId, 
    bool force = false,
    TimeFilter timeFilter = TimeFilter.all,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    _activeNurseId = nurseId;
    await _loadCasesInternal(
      force: force, 
      timeFilter: timeFilter,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
  }

  /// تحميل الحالات الفعلي - Actual case loading
  Future<void> _loadCasesInternal({
    bool force = false,
    TimeFilter timeFilter = TimeFilter.all,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    if (!force && state is CasesLoaded && (state as CasesLoaded).timeFilter == timeFilter && (state as CasesLoaded).customStartDate == customStartDate && (state as CasesLoaded).customEndDate == customEndDate) return;

    emit(CasesLoading());
    try {
      final dateRange = _getDateRange(timeFilter, customStartDate, customEndDate);
      
      final result = await _casesRepository.getCasesPaginated(
        nurseId: _activeNurseId,
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        limit: 20,
      );

      emit(CasesLoaded(
        cases: result.items,
        timeFilter: timeFilter,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      ));
    } catch (e) {
      emit(CasesError('خطأ في تحميل الحالات: ${e.toString()}'));
    }
  }

  /// تحميل المزيد من الحالات - Load more cases (Pagination)
  Future<void> loadMoreCases() async {
    if (state is! CasesLoaded) return;
    final currentState = state as CasesLoaded;
    
    if (currentState.isLoadingMore || !currentState.hasMore || currentState.lastDocument == null) return;

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final dateRange = _getDateRange(
        currentState.timeFilter,
        currentState.customStartDate,
        currentState.customEndDate,
      );
      
      final result = await _casesRepository.getCasesPaginated(
        nurseId: _activeNurseId,
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        startAfter: currentState.lastDocument,
        limit: 20,
      );

      emit(currentState.copyWith(
        cases: [...currentState.cases, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
        lastDocument: result.lastDocument,
      ));
    } catch (e) {
      log('Error loading more cases: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Map<String, DateTime?> _getDateRange(TimeFilter filter, [DateTime? customStart, DateTime? customEnd]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (filter) {
      case TimeFilter.today:
        return {
          'start': today,
          'end': today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        };
      case TimeFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'start': yesterday,
          'end': today.subtract(const Duration(milliseconds: 1)),
        };
      case TimeFilter.last7Days:
        return {
          'start': today.subtract(const Duration(days: 7)),
          'end': today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        };
      case TimeFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        return {
          'start': startOfMonth,
          'end': nextMonth.subtract(const Duration(milliseconds: 1)),
        };
      case TimeFilter.thisYear:
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31, 23, 59, 59, 999),
        };
      case TimeFilter.custom:
        if (customStart != null && customEnd != null) {
          return {
            'start': customStart,
            'end': DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59, 999),
          };
        }
        return {'start': null, 'end': null};
      case TimeFilter.all:
        return {'start': null, 'end': null};
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

  void filterByProcedure(String? procedureName) {
    if (state is CasesLoaded) {
      final s = state as CasesLoaded;
      emit(s.copyWith(procedureFilter: procedureName, clearProcedureFilter: procedureName == null));
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
