import 'dart:async';

/// Notifies all screens when data changes happen (cloud download, local CRUD, etc.)
/// Used by DataStatusScreen to auto-refresh counts, and by UsersScreen to reload
/// after cloud downloads.
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

  /// Notify all listeners that local data was modified (add/update/delete)
  /// Used to refresh DataStatusScreen counts in real-time
  void notifyLocalDataChanged() {
    _controller.add(
      DataChangeEvent(
        type: DataChangeType.localChange,
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}

enum DataChangeType { cloudDownload, fullSync, localChange }

class DataChangeEvent {
  final DataChangeType type;
  final DateTime timestamp;

  DataChangeEvent({
    required this.type,
    required this.timestamp,
  });
}
