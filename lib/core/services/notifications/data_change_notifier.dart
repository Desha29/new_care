import 'dart:async';

/// Notifies all screens when a bulk data operation happens (e.g. cloud download)
/// This is separate from CaseChangeNotifier which only fires for individual case CRUD.
/// DataChangeNotifier fires when the entire local database has been refreshed from
/// the cloud, so ALL screens need to reload their data.
class DataChangeNotifier {
  static final DataChangeNotifier _instance = DataChangeNotifier._internal();

  final _controller = StreamController<DataChangeEvent>.broadcast();

  DataChangeNotifier._internal();

  factory DataChangeNotifier() => _instance;

  /// Stream of data change events
  Stream<DataChangeEvent> get onDataChanged => _controller.stream;

  /// Notify all listeners that data was downloaded from cloud
  void notifyCloudDownloadCompleted() {
    _controller.add(
      DataChangeEvent(
        type: DataChangeType.cloudDownload,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Notify all listeners that a full sync was completed
  void notifyFullSyncCompleted() {
    _controller.add(
      DataChangeEvent(
        type: DataChangeType.fullSync,
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}

enum DataChangeType { cloudDownload, fullSync }

class DataChangeEvent {
  final DataChangeType type;
  final DateTime timestamp;

  DataChangeEvent({
    required this.type,
    required this.timestamp,
  });
}
