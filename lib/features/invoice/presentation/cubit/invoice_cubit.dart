import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/case_status.dart';
import '../../../cases/data/models/case_model.dart';
import '../../../procedures/data/models/procedure_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import 'package:uuid/uuid.dart';

part 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final IInvoiceRepository _invoiceRepository;

  InvoiceCubit({required IInvoiceRepository invoiceRepository, CaseModel? initialCase})
    : _invoiceRepository = invoiceRepository,
      super(InvoiceState.initial(initialCase: initialCase));

  // Add Procedure (Service)
  void addProcedure(ServiceItem service) {
    final updatedServices = List<ServiceItem>.from(state.services);
    final existingIndex = updatedServices.indexWhere((s) => s.name == service.name);

    if (existingIndex != -1) {
      final existing = updatedServices[existingIndex];
      updatedServices[existingIndex] = ServiceItem(
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + service.quantity,
        notes: existing.notes,
      );
    } else {
      updatedServices.add(service);
    }
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
    final updatedSupplies = List<SupplyUsed>.from(state.supplies);
    final existingIndex = updatedSupplies.indexWhere((s) => s.inventoryId == supply.inventoryId);

    if (existingIndex != -1) {
      final existing = updatedSupplies[existingIndex];
      updatedSupplies[existingIndex] = SupplyUsed(
        inventoryId: existing.inventoryId,
        name: existing.name,
        quantity: existing.quantity + supply.quantity,
        unitPrice: existing.unitPrice,
      );
    } else {
      updatedSupplies.add(supply);
    }
    _updatePrices(state.services, updatedSupplies);
  }

  // Remove Supply
  void removeSupply(SupplyUsed supply) {
    final updatedSupplies = List<SupplyUsed>.from(state.supplies)
      ..remove(supply);
    _updatePrices(state.services, updatedSupplies);
  }

  // Update all service prices when case type changes (داخل المركز / زيارة منزلية)
  void updateServicePrices(List<ProcedureModel> procedures, CaseType caseType) {
    final updatedServices = state.services.map((s) {
      final proc = procedures.where((p) => p.name == s.name).firstOrNull;
      if (proc != null) {
        final newPrice = caseType == CaseType.inCenter
            ? proc.priceInside
            : proc.priceOutside;
        return ServiceItem(
          name: s.name,
          price: newPrice,
          quantity: s.quantity,
          notes: s.notes,
        );
      }
      return s;
    }).toList();
    _updatePrices(updatedServices, state.supplies);
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
      final allInventory = await _invoiceRepository.getAllInventory();

      // 1. Decrease inventory stock for each supply used
      for (var supply in state.supplies) {
        try {
          final inventoryItem = allInventory.firstWhere(
            (i) => i.id == supply.inventoryId,
          );
          if (inventoryItem.quantity >= supply.quantity) {
            final updatedItem = inventoryItem.copyWith(
              quantity: inventoryItem.quantity - supply.quantity,
              updatedAt: DateTime.now(),
            );
            await _invoiceRepository.updateInventoryItem(updatedItem);
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
        totalPrice: state.totalPrice,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        caseDate: DateTime.now(),
        notes: notes,
        caseType: CaseType.inCenter,
      );

      await _invoiceRepository.createCase(newCase);

      emit(state.copyWith(status: InvoiceStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: InvoiceStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
