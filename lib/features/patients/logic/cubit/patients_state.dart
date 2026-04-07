part of 'patients_cubit.dart';

abstract class PatientsState extends Equatable {
  const PatientsState();

  @override
  List<Object?> get props => [];
}

class PatientsInitial extends PatientsState {}

class PatientsLoading extends PatientsState {}

class PatientsLoaded extends PatientsState {
  final List<PatientModel> patients;
  final bool isOffline;

  const PatientsLoaded({
    required this.patients,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [patients, isOffline];
}

class PatientsError extends PatientsState {
  final String message;

  const PatientsError(this.message);

  @override
  List<Object?> get props => [message];
}
