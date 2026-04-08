import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/connectivity_service.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  StreamSubscription? _subscription;

  ConnectivityCubit() : super(ConnectivityService.instance.isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline) {
    _subscription = ConnectivityService.instance.onConnectivityChanged.listen((isConnected) {
      emit(isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
