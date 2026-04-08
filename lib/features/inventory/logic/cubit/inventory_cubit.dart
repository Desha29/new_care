import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/inventory_model.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit() : super(InventoryInitial());

  Future<void> loadInventory() async {
    emit(InventoryLoading());
    try {
      final items = await FirebaseService.instance.getAllInventory();
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
      await FirebaseService.instance.updateInventoryItem(item);
      loadInventory();
    } catch (e) {
      emit(InventoryError('خطأ في التعديل: ${e.toString()}'));
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await FirebaseService.instance.deleteInventoryItem(id);
      loadInventory();
    } catch (e) {
      emit(InventoryError('خطأ في الحذف: ${e.toString()}'));
    }
  }
}
