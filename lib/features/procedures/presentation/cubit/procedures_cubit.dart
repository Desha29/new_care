import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../domain/repositories/procedures_repository.dart';
import '../../data/models/procedure_model.dart';
import 'procedures_state.dart';

class ProceduresCubit extends Cubit<ProceduresState> {
  final IProceduresRepository _proceduresRepository;

  ProceduresCubit({required IProceduresRepository proceduresRepository})
      : _proceduresRepository = proceduresRepository,
        super(ProceduresInitial());

  Future<void> loadProcedures({bool force = false}) async {
    if (!force && state is ProceduresLoaded) return;

    emit(ProceduresLoading());
    try {
      final procedures = await _proceduresRepository.getAllProcedures();
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
      await _proceduresRepository.createProcedure(p);
      DataChangeNotifier().notifyLocalDataChanged();
      loadProcedures(force: true);
    } catch (e) {
      emit(ProceduresError('خطأ في إضافة الإجراء: ${e.toString()}'));
    }
  }

  Future<void> deleteProcedure(String id) async {
    try {
      await _proceduresRepository.deleteProcedure(id);
      DataChangeNotifier().notifyLocalDataChanged();
      loadProcedures(force: true);
    } catch (e) {
      emit(ProceduresError('خطأ في حذف الإجراء: ${e.toString()}'));
    }
  }
}
