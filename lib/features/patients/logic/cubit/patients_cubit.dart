import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/models/patient_model.dart';

part 'patients_state.dart';

class PatientsCubit extends Cubit<PatientsState> {
  final FirebaseService _firebaseService;

  PatientsCubit()
      : _firebaseService = FirebaseService.instance,
        super(PatientsInitial());

  Future<void> loadPatients() async {
    emit(PatientsLoading());
    try {
      final isConnected = await ConnectivityService.instance.checkConnection();
      final patients = await _firebaseService.getAllPatients();
      
      emit(PatientsLoaded(
        patients: patients,
        isOffline: !isConnected,
      ));
    } catch (e) {
      emit(PatientsError('خطأ في تحميل المرضى: $e'));
    }
  }

  Future<void> addPatient(PatientModel patient) async {
    try {
      await _firebaseService.createPatient(patient);
      loadPatients();
    } catch (e) {
      emit(PatientsError('خطأ في إضافة المريض: $e'));
    }
  }

  Future<void> updatePatient(PatientModel patient) async {
    try {
      await _firebaseService.updatePatient(patient);
      loadPatients();
    } catch (e) {
      emit(PatientsError('خطأ في تحديث المريض: $e'));
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      await _firebaseService.deletePatient(patientId);
      loadPatients();
    } catch (e) {
      emit(PatientsError('خطأ في حذف المريض: $e'));
    }
  }
}
