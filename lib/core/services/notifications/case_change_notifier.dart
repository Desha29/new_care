import 'dart:async';
import '../../../features/cases/data/models/case_model.dart';

/// Notifies all screens when cases change (add, update, delete)
/// Allows dashboard, financials, reports, and other screens to update without manual refresh
class CaseChangeNotifier {
  static final CaseChangeNotifier _instance = CaseChangeNotifier._internal();

  final _caseChangeController = StreamController<CaseChangeEvent>.broadcast();

  CaseChangeNotifier._internal();

  factory CaseChangeNotifier() {
    return _instance;
  }

  /// Stream of case change events
  Stream<CaseChangeEvent> get onCaseChanged => _caseChangeController.stream;

  /// Notify all listeners that a case was added
  void notifyCaseAdded(String caseId, {bool isLocal = false, CaseModel? model}) {
    _caseChangeController.add(
      CaseChangeEvent(
        type: CaseChangeType.added,
        caseId: caseId,
        timestamp: DateTime.now(),
        isLocal: isLocal,
        model: model,
      ),
    );
  }

  /// Notify all listeners that a case was updated
  void notifyCaseUpdated(String caseId, {bool isLocal = false, CaseModel? model}) {
    _caseChangeController.add(
      CaseChangeEvent(
        type: CaseChangeType.updated,
        caseId: caseId,
        timestamp: DateTime.now(),
        isLocal: isLocal,
        model: model,
      ),
    );
  }

  /// Notify all listeners that a case was deleted
  void notifyCaseDeleted(String caseId, {bool isLocal = false}) {
    _caseChangeController.add(
      CaseChangeEvent(
        type: CaseChangeType.deleted,
        caseId: caseId,
        timestamp: DateTime.now(),
        isLocal: isLocal,
      ),
    );
  }

  void dispose() {
    _caseChangeController.close();
  }
}

enum CaseChangeType { added, updated, deleted }

class CaseChangeEvent {
  final CaseChangeType type;
  final String caseId;
  final DateTime timestamp;
  final bool isLocal;
  final CaseModel? model;

  CaseChangeEvent({
    required this.type,
    required this.caseId,
    required this.timestamp,
    this.isLocal = false,
    this.model,
  });
}
