import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/enums/case_status.dart';
import '../../../cases/data/models/case_model.dart';

import 'package:uuid/uuid.dart';

part 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final FirebaseService _firebaseService;

  InvoiceCubit({FirebaseService? firebaseService, CaseModel? initialCase})
    : _firebaseService = firebaseService ?? FirebaseService.instance,
      super(InvoiceState.initial(initialCase: initialCase));

  // Add Procedure (Service)

  void addProcedure(ServiceItem service) {
    final updatedServices = List<ServiceItem>.from(state.services)
      ..add(service);
    _updatePrices(updatedServices, state.supplies);
  }

  // Remove Procedure
  void removeProcedure(ServiceItem service) {
    final updatedServices = List<ServiceItem>.from(state.services)
      ..remove(service);
    _updatePrices(updatedServices, state.supplies);
  }

  // Add Supply (المستلزمات)
  void addSupply(SupplyUsed supply) {
    final updatedSupplies = List<SupplyUsed>.from(state.supplies)..add(supply);
    _updatePrices(state.services, updatedSupplies);
  }

  // Remove Supply
  void removeSupply(SupplyUsed supply) {
    final updatedSupplies = List<SupplyUsed>.from(state.supplies)
      ..remove(supply);
    _updatePrices(state.services, updatedSupplies);
  }

  // Auto-calculate Total Price immediately
  void _updatePrices(List<ServiceItem> services, List<SupplyUsed> supplies) {
    double total = 0;
    for (var s in services) {
      total += s.total;
    }
    for (var s in supplies) {
      total += s.total;
    }
    emit(
      state.copyWith(services: services, supplies: supplies, totalPrice: total),
    );
  }

  // Submit Invoice (Save Case, Decrease Stock, and record Income)
  Future<void> submitInvoice({
    required String patientName,
    required String patientPhone,
    String patientAddress = '',
    int patientAge = 0,
    String patientGender = 'male',
    String medicalHistory = '',
    String notes = '',
  }) async {
    emit(state.copyWith(status: InvoiceStatus.loading));

    try {
      final caseId = const Uuid().v4();
      final allInventory = await _firebaseService.getAllInventory();

      // 1. Decrease inventory stock for each supply used
      for (var supply in state.supplies) {
        try {
          final inventoryItem = allInventory.firstWhere(
            (i) => i.id == supply.inventoryId,
          );
          if (inventoryItem.quantity >= supply.quantity) {
            final updatedItem = inventoryItem.copyWith(
              quantity:
                  inventoryItem.quantity - supply.quantity, // Deducting Stock
              updatedAt: DateTime.now(),
            );
            await _firebaseService.updateInventoryItem(updatedItem);
          } else {
            throw Exception('Not enough stock for ${supply.name}');
          }
        } catch (e) {
          if (e is StateError) {
            throw Exception('Item ${supply.name} not found in inventory');
          }
          rethrow;
        }
      }

      // 2. Create the Case (which automatically acts as an invoice/income)
      final newCase = CaseModel(
        id: caseId,
        patientName: patientName,
        patientAge: patientAge,
        patientGender: patientGender,
        patientPhone: patientPhone,
        patientAddress: patientAddress,
        medicalHistory: medicalHistory,
        services: state.services,
        suppliesUsed: state.supplies,
        totalPrice: state.totalPrice, // Automatically calculated final price
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        caseDate: DateTime.now(),
        notes: notes,
        caseType: CaseType.inCenter,
        status: CaseStatus.completed,
      );

      await _firebaseService.createCase(newCase);

      emit(state.copyWith(status: InvoiceStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: InvoiceStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
