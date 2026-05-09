/// نموذج تقدم المزامنة - Sync Progress Model
class SyncProgress {
  final String message;
  final String icon;
  final int currentStep;
  final int totalSteps;
  final bool isDone;
  final bool isError;

  const SyncProgress({
    required this.message,
    this.icon = '🔄',
    this.currentStep = 0,
    this.totalSteps = 1,
    this.isDone = false,
    this.isError = false,
  });

  double get progress => totalSteps > 0 ? currentStep / totalSteps : 0;
}
