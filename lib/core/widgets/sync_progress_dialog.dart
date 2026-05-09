import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_care/core/constants/app_colors.dart';
import 'package:new_care/core/services/sync/sync_manager.dart';
import 'package:new_care/core/services/sync/sync_progress.dart';



/// ديالوج تقدم المزامنة - Sync Progress Dialog
/// Shows real-time sync progress with beautiful animations
class SyncProgressDialog extends StatefulWidget {
  final String title;

  const SyncProgressDialog({
    super.key,
    this.title = 'جاري المزامنة',
  });

  /// عرض ديالوج المزامنة - Show the sync progress dialog
  static Future<void> show(BuildContext context,
      {String title = 'جاري المزامنة'}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => SyncProgressDialog(title: title),
    );
  }

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog>
    with TickerProviderStateMixin {
  StreamSubscription<SyncProgress>? _sub;
  SyncProgress _current = const SyncProgress(message: 'جاري التحضير...');
  final List<_CompletedStep> _completedSteps = [];
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    // Spin animation for the sync icon
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _sub = SyncManager.instance.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          // Add completed step to history
          if (_current.message.isNotEmpty &&
              _current.message != progress.message) {
            _completedSteps.add(_CompletedStep(
              icon: _current.icon,
              message: _current.message,
            ));
            // Keep only last 6 steps
            if (_completedSteps.length > 6) {
              _completedSteps.removeAt(0);
            }
          }
          _current = progress;
        });

        // Auto-close on done/error after short delay
        if (progress.isDone || progress.isError) {
          _spinController.stop();
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              _buildHeaderIcon(),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: 18),

              // Current step
              _buildCurrentStep(),

              // Step history
              if (_completedSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildStepHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    // Done state
    if (_current.isDone) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.statusCompletedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.statusCompleted,
                size: 44,
              ),
            ),
          );
        },
      );
    }

    // Error state
    if (_current.isError) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: AppColors.statusCancelledBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_rounded,
          color: AppColors.error,
          size: 44,
        ),
      );
    }

    // Syncing state - spinning icon
    return RotationTransition(
      turns: _spinController,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.secondary.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.sync_rounded,
          color: AppColors.primary,
          size: 44,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _current.progress;
    final isDone = _current.isDone;
    final isError = _current.isError;

    final Color activeColor = isDone
        ? AppColors.success
        : isError
            ? AppColors.error
            : AppColors.primary;

    return Column(
      children: [
        // Progress info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Step counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_current.currentStep} / ${_current.totalSteps}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ),
            // Percentage
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Animated progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Stack(
              children: [
                // Background track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: isDone
                          ? const LinearGradient(
                              colors: [
                                AppColors.statusCompleted,
                                Color(0xFF34D399),
                              ],
                            )
                          : isError
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.error,
                                    Color(0xFFF87171),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    final isDone = _current.isDone;
    final isError = _current.isError;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_current.message),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.statusCompletedBg
              : isError
                  ? AppColors.statusCancelledBg
                  : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.statusCompleted.withValues(alpha: 0.2)
                : isError
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Step icon/emoji
            Text(
              _current.icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 12),
            // Step message
            Expanded(
              child: Text(
                _current.message,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? AppColors.statusCompleted
                      : isError
                          ? AppColors.error
                          : AppColors.textPrimary,
                ),
              ),
            ),
            // Loading indicator for active step
            if (!isDone && !isError)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            // Done icon
            if (isDone)
              const Icon(
                Icons.check_rounded,
                color: AppColors.statusCompleted,
                size: 22,
              ),
            // Error icon
            if (isError)
              const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHistory() {
    return Column(
      children: _completedSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        // Fade older steps
        final opacity = 0.4 + (index / _completedSteps.length) * 0.6;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: AppColors.statusCompleted,
                ),
                const SizedBox(width: 8),
                Text(
                  step.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.message,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Completed step model for history display
class _CompletedStep {
  final String icon;
  final String message;

  const _CompletedStep({required this.icon, required this.message});
}
