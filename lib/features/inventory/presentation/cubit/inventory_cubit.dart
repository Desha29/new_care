import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notifications/case_change_notifier.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/models/inventory_model.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final IInventoryRepository _inventoryRepository;
  StreamSubscription? _caseChangeSubscription;

  InventoryCubit({required IInventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository,
      super(InventoryInitial()) {
    _setupCaseChangeListener();
  }

  /// Listen to case changes and reload inventory automatically
  /// (since cases deduct inventory supplies)
  void _setupCaseChangeListener() {
    _caseChangeSubscription = CaseChangeNotifier().onCaseChanged.listen((
      event,
    ) {
      // Reload inventory when any case is added, updated, or deleted
      if (state is InventoryLoaded) {
        loadInventory(force: true);
      }
    });
  }

  @override
  Future<void> close() {
    _caseChangeSubscription?.cancel();
    return super.close();
  }

  Future<void> loadInventory({bool force = false}) async {
    if (!force && state is InventoryLoaded) return;

    emit(InventoryLoading());
    try {
      final items = await _inventoryRepository.getAllInventory();
      emit(InventoryLoaded(items: items));
    } catch (e) {
      emit(InventoryError('خطأ في تحميل المخزون: ${e.toString()}'));
    }
  }

  void searchInventory(String query) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      emit(InventoryLoaded(items: currentState.items, searchQuery: query));
    }
  }

  Future<void> addOrUpdateItem(InventoryModel item) async {
    try {
      await _inventoryRepository.updateInventoryItem(item);
      DataChangeNotifier().notifyLocalDataChanged();
      loadInventory(force: true);
    } catch (e) {
      emit(InventoryError('خطأ في التعديل: ${e.toString()}'));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _inventoryRepository.deleteInventoryItem(id);
      DataChangeNotifier().notifyLocalDataChanged();
      loadInventory(force: true);
    } catch (e) {
      emit(InventoryError('خطأ في الحذف: ${e.toString()}'));
    }
  }
}
