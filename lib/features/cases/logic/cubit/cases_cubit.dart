import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../data/models/case_model.dart';
import 'cases_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CasesCubit extends Cubit<CasesState> {
  final SyncManager _syncManager;

  CasesCubit()
      : _syncManager = SyncManager.instance,
        super(CasesInitial());

  Future<void> loadCases() async {
    emit(CasesLoading());
    try {
      final cases = await FirebaseService.instance.getAllCases();
      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(CasesLoaded(cases: cases));
    } catch (e) {
      emit(CasesError('خطأ في تحميل الحالات: ${e.toString()}'));
    }
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
      // 1. خصم المخزون أولاً
      final isConnected = await ConnectivityService.instance.checkConnection();

      for (var supply in newCase.suppliesUsed) {
        try {
          if (isConnected) {
            final inventory = await FirebaseService.instance.getAllInventory();
            final item = inventory.firstWhere((i) => i.id == supply.inventoryId);
            if (item.quantity >= supply.quantity) {
              final updatedItem = item.copyWith(
                quantity: item.quantity - supply.quantity,
                updatedAt: DateTime.now(),
              );
              await _syncManager.saveInventoryWithSync(updatedItem, isNew: false);
            }
          } else {
            // في حالة عدم الاتصال: سجل العملية للمزامنة لاحقاً
            await _syncManager.addPendingOperation(
              tableName: 'inventory',
              operation: 'deduct',
              docId: supply.inventoryId,
              data: {'quantity': supply.quantity},
            );
          }
        } catch (_) {}
      }

      // 2. حفظ الحالة مع مزامنة
      await _syncManager.saveCaseWithSync(newCase, isNew: true);

      // 3. تسجيل النشاط
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
      
      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'add_case',
        actionLabel: 'إضافة حالة',
        targetType: 'case',
        targetId: newCase.id,
        details: 'تم إضافة حالة جديدة بنجاح للمريض ${newCase.patientName} - المبلغ: ${newCase.totalPrice}',
      );

      // 4. إعادة تحميل
      loadCases();
    } catch (e) {
      emit(CasesError('خطأ في إضافة الحالة: ${e.toString()}'));
    }
  }

  /// تحديث حالة - Update case
  Future<void> updateCase(CaseModel updatedCase) async {
    try {
      await _syncManager.saveCaseWithSync(updatedCase, isNew: false);

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';

      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'update_case',
        actionLabel: 'تعديل حالة',
        targetType: 'case',
        targetId: updatedCase.id,
        details: 'تم تعديل حالة المريض ${updatedCase.patientName}',
      );

      loadCases();
    } catch (e) {
      emit(CasesError('خطأ في تعديل الحالة: ${e.toString()}'));
    }
  }

  /// حذف حالة - Delete case
  Future<void> deleteCase(CaseModel c) async {
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      if (isConnected) {
        await FirebaseService.instance.deleteCase(c.id);
      } else {
        await _syncManager.addPendingOperation(
          tableName: 'cases',
          operation: 'delete',
          docId: c.id,
          data: {},
        );
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';

      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'delete_case',
        actionLabel: 'حذف حالة',
        targetType: 'case',
        targetId: c.id,
        details: 'تم حذف حالة ${c.patientName}',
      );

      loadCases();
    } catch (e) {
      emit(CasesError('خطأ في حذف الحالة: ${e.toString()}'));
    }
  }
}
