import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/procedure_model.dart';
import 'procedures_state.dart';

class ProceduresCubit extends Cubit<ProceduresState> {
  ProceduresCubit() : super(ProceduresInitial());

  Future<void> loadProcedures() async {
    emit(ProceduresLoading());
    try {
      final procedures = await FirebaseService.instance.getAllProcedures();
      emit(ProceduresLoaded(procedures: procedures));
    } catch (e) {
      emit(ProceduresError('خطأ في تحميل الإجراءات: ${e.toString()}'));
    }
  }

  void searchProcedures(String query) {
    if (state is ProceduresLoaded) {
      final currentState = state as ProceduresLoaded;
      emit(ProceduresLoaded(procedures: currentState.procedures, searchQuery: query));
    }
  }

  Future<void> addProcedure(ProcedureModel p) async {
    try {
      await FirebaseService.instance.createProcedure(p);
      loadProcedures();
    } catch (e) {
      emit(ProceduresError('خطأ في إضافة الإجراء: ${e.toString()}'));
    }
  }

  Future<void> deleteProcedure(String id) async {
    try {
      await FirebaseService.instance.deleteProcedure(id);
      loadProcedures();
    } catch (e) {
      emit(ProceduresError('خطأ في حذف الإجراء: ${e.toString()}'));
    }
  }
}
