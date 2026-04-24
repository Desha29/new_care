part of 'invoice_cubit.dart';

enum InvoiceStatus { initial, loading, success, error }

class InvoiceState {
  final List<ServiceItem> services;
  final List<SupplyUsed> supplies;
  final double totalPrice;
  final double finalPrice; // In case of discounts
  final double discount;
  final InvoiceStatus status;
  final String? errorMessage;

  InvoiceState({
    required this.services,
    required this.supplies,
    required this.totalPrice,
    required this.finalPrice,
    required this.discount,
    required this.status,
    this.errorMessage,
  });

  factory InvoiceState.initial({CaseModel? initialCase}) {
    return InvoiceState(
      services: initialCase?.services ?? [],
      supplies: initialCase?.suppliesUsed ?? [],
      totalPrice: initialCase?.totalPrice ?? 0.0,
      finalPrice: initialCase?.totalPrice ?? 0.0,
      discount: initialCase?.discount ?? 0.0,
      status: InvoiceStatus.initial,
    );
  }

  InvoiceState copyWith({
    List<ServiceItem>? services,
    List<SupplyUsed>? supplies,
    double? totalPrice,
    double? finalPrice,
    double? discount,
    InvoiceStatus? status,
    String? errorMessage,
  }) {
    return InvoiceState(
      services: services ?? this.services,
      supplies: supplies ?? this.supplies,
      totalPrice: totalPrice ?? this.totalPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
