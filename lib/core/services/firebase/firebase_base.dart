import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// القاعدة الأساسية لمستودعات Firebase - Firebase Repository Base
/// توفر مرجع Firestore المشترك وتوليد المعرفات
abstract class FirebaseBase {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// توليد معرف فريد - Generate unique ID
  String generateId() => _uuid.v4();

  /// تاريخ اليوم بصيغة نصية - Today's date string
  String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
