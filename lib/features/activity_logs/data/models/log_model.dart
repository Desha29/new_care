import 'package:equatable/equatable.dart';

/// نموذج سجل الأنشطة - Activity Log Model
class LogModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String action; // نوع الإجراء (create, update, delete, login, etc.)
  final String actionLabel; // وصف الإجراء بالعربية
  final String targetType; // نوع الهدف (patient, case, inventory, user)
  final String targetId;
  final String details; // تفاصيل إضافية
  final DateTime timestamp;

  const LogModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.action,
    this.actionLabel = '',
    this.targetType = '',
    this.targetId = '',
    this.details = '',
    required this.timestamp,
  });

  /// من Firestore Map
  factory LogModel.fromMap(Map<String, dynamic> map, String id) {
    return LogModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      actionLabel: map['actionLabel'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// إلى Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'action': action,
      'actionLabel': actionLabel,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// إلى SQLite Map
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      ...toMap(),
    };
  }

  /// من SQLite Map
  factory LogModel.fromSqliteMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      actionLabel: map['actionLabel'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// عرض الإجراء بأيقونة
  String get actionEmoji {
    switch (action) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'login':
        return '🔑';
      case 'logout':
        return '🚪';
      case 'backup':
        return '💾';
      case 'restore':
        return '♻️';
      case 'print':
        return '🖨️';
      default:
        return '📋';
    }
  }

  @override
  List<Object?> get props => [id, userId, userName, action, actionLabel, targetType, targetId, details, timestamp];
}
