import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_log_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/case_model.dart';
import 'cases_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CasesCubit extends Cubit<CasesState> {
  CasesCubit() : super(CasesInitial());

  Future<void> loadCases() async {
    emit(CasesLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
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

  Future<void> addCase(CaseModel newCase) async {
    try {
      await FirebaseService.instance.createCase(newCase);
      
      // Deduct inventory
      for (var supply in newCase.suppliesUsed) {
        try {
          final inventory = await FirebaseService.instance.getAllInventory();
          final item = inventory.firstWhere((i) => i.id == supply.inventoryId);
          if (item.quantity >= supply.quantity) {
            final updatedItem = item.copyWith(quantity: item.quantity - supply.quantity);
            await FirebaseService.instance.updateInventoryItem(updatedItem);
          }
        } catch (_) {}
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uName = FirebaseAuth.instance.currentUser?.displayName ?? 'مستخدم';
      
      await LocalLogService.instance.logActivity(
        userId: uid,
        userName: uName,
        action: 'add_case',
        actionLabel: 'إضافة حالة',
        targetType: 'case',
        targetId: newCase.id,
        details: 'تم إضافة حالة جديدة بنجاح للمريض ${newCase.patientName}',
      );
      
      loadCases(); // Refresh
    } catch (e) {
      emit(CasesError('خطأ في إضافة الحالة: ${e.toString()}'));
    }
  }

  Future<void> deleteCase(CaseModel c) async {
    try {
      await FirebaseService.instance.deleteCase(c.id);
      loadCases();
    } catch (e) {
      emit(CasesError('خطأ في حذف الحالة: ${e.toString()}'));
    }
  }
}
