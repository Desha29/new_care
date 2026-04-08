import 'package:flutter_bloc/flutter_bloc.dart';

class GlobalErrorState {
  final String? message;
  final bool isError;
  final DateTime? timestamp;

  GlobalErrorState({this.message, this.isError = false, this.timestamp});
}

class ErrorCubit extends Cubit<GlobalErrorState> {
  ErrorCubit() : super(GlobalErrorState());

  void showError(String message) {
    emit(GlobalErrorState(
      message: message,
      isError: true,
      timestamp: DateTime.now(),
    ));
  }

  void clearError() {
    emit(GlobalErrorState(isError: false));
  }
}
