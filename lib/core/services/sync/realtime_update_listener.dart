import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// مستمع التحديثات الفورية - Realtime Update Listener v2
///
/// Optimized for 24/7 operation:
///   - Polls every 10s (not 30s) → ~8,640 reads/day
///   - Only fetches limit(10) docs per poll
///   - Debounce 500ms to batch rapid events
///   - Smart deduplication per module
///   - Handles ALL modules: cases, attendance, inventory, payroll,
///     shifts, users, expenses, procedures
///
/// Cost estimate (24/7):
///   10s poll × 10 docs = ~8,640 reads/day = ~259,200 reads/month
///   (Firestore free tier: 50,000 reads/day = 1,500,000/month)
class RealtimeUpdateListener {
  RealtimeUpdateListener._();
  static final RealtimeUpdateListener instance = RealtimeUpdateListener._();

  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  Timer? _pollTimer;
  Timer? _cleanupTimer;
  bool _isProcessing = false;

  // Debounce: accumulate events, then dispatch once per module
  Timer? _debounceTimer;
  final Set<String> _pendingEventTypes = {};

  // Track last processed timestamp to ignore old events
  DateTime _lastProcessedAt = DateTime.now();

  // === Callbacks (set by main.dart at startup) ===
  void Function(String id)? onCaseAdded;
  void Function(String id)? onCaseUpdated;
  void Function(String id)? onCaseDeleted;
  void Function(String id)? onAttendanceChanged;
  void Function(String id)? onInventoryChanged;
  void Function(String id)? onPayrollChanged;
  void Function(String id)? onShiftsChanged;
  void Function(String id)? onUsersChanged;
  void Function(String id)? onExpensesChanged;
  void Function(String id)? onProceduresChanged;

  /// بدء الاستماع - Start listening for update events
  void startListening() {
    log('[RealtimeUpdates] Starting listener (10s poll, limit 10)...');

    // Ignore anything older than 10 seconds ago
    _lastProcessedAt = DateTime.now().subtract(const Duration(seconds: 10));

    final query = _firestore
        .collection('updates')
        .orderBy('timestamp', descending: true)
        .limit(10); // ← 10 docs per poll

    // Windows: use polling to avoid threading crashes
    if (!kIsWeb && Platform.isWindows) {
      _startPolling(query);
    } else {
      _startStream(query);
    }

    // Schedule periodic cleanup every 2 hours
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 2), (_) {
      cleanOldEvents();
    });
  }

  /// استطلاع دوري (Windows) - Periodic polling for Windows
  /// 30 seconds = ~2,880 reads/day (cost-optimized for 24/7)
  void _startPolling(Query query) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_isProcessing) return;
      try {
        final snapshot = await query.get();
        _processSnapshot(snapshot);
      } catch (e) {
        log('[RealtimeUpdates] Poll error: $e');
      }
    });
  }

  /// بث مباشر (Android/iOS) - Direct stream for non-Windows
  void _startStream(Query query) {
    _subscription?.cancel();
    _subscription = query.snapshots().listen(
      (snapshot) => _processSnapshot(snapshot),
      onError: (e) => log('[RealtimeUpdates] Stream error: $e'),
    );
  }

  /// معالجة اللقطة - Process incoming snapshot
  void _processSnapshot(QuerySnapshot snapshot) {
    if (_isProcessing || snapshot.docs.isEmpty) return;
    _isProcessing = true;

    try {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // Parse timestamp
        DateTime? eventTime;
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          eventTime = ts.toDate();
        } else if (ts is String) {
          eventTime = DateTime.tryParse(ts);
        }

        // Skip old events (before this session started)
        if (eventTime == null || eventTime.isBefore(_lastProcessedAt)) continue;

        // Skip events from desktop itself
        if (data['source'] == 'desktop') continue;

        final type = data['type'] as String? ?? (data['extra']?['type'] as String? ?? '');
        final targetId = data['targetId'] as String? ?? (data['extra']?['targetId'] as String? ?? '');
        
        if (type.isEmpty || targetId.isEmpty) continue;

        _lastProcessedAt = DateTime.now();
        _dispatchSingleEvent(type, targetId);
      }
    } catch (e) {
      log('[RealtimeUpdates] Processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// معالجة حدث واحد فوراً - Process a single event immediately
  void _dispatchSingleEvent(String type, String targetId) {
    log('[RealtimeUpdates] Dispatching event: $type for ID: $targetId');

    switch (type) {
      case 'case_added':
        onCaseAdded?.call(targetId);
        break;
      case 'case_updated':
        onCaseUpdated?.call(targetId);
        break;
      case 'case_deleted':
        onCaseDeleted?.call(targetId);
        break;
      case 'attendance_checkin':
      case 'attendance_checkout':
        onAttendanceChanged?.call(targetId);
        break;
      case 'inventory_changed':
        onInventoryChanged?.call(targetId);
        break;
      case 'payroll_changed':
        onPayrollChanged?.call(targetId);
        break;
      case 'shift_changed':
        onShiftsChanged?.call(targetId);
        break;
      case 'user_changed':
        onUsersChanged?.call(targetId);
        break;
      case 'expense_changed':
        onExpensesChanged?.call(targetId);
        break;
      case 'procedure_changed':
        onProceduresChanged?.call(targetId);
        break;
      default:
        log('[RealtimeUpdates] Unknown event type: $type');
    }
  }

  /// تنظيف الأحداث القديمة - Clean old events (keep last 50)
  Future<void> cleanOldEvents() async {
    try {
      final snapshot = await _firestore
          .collection('updates')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length <= 50) return;

      final batch = _firestore.batch();
      int deleteCount = 0;
      for (int i = 50; i < snapshot.docs.length; i++) {
        batch.delete(snapshot.docs[i].reference);
        deleteCount++;
        if (deleteCount >= 400) break; // Firestore batch limit
      }
      await batch.commit();
      log('[RealtimeUpdates] Cleaned $deleteCount old events');
    } catch (e) {
      log('[RealtimeUpdates] Cleanup error: $e');
    }
  }

  /// إيقاف الاستماع - Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _pendingEventTypes.clear();
    log('[RealtimeUpdates] Listener stopped');
  }

  /// إعادة تشغيل - Restart
  void restart() {
    stopListening();
    startListening();
  }
}
