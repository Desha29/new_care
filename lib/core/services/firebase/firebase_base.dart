import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
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

  /// مساعد لإنشاء بث آمن متوافق مع ويندوز
  /// Helper to create a safe stream compatible with Windows
  Stream<QuerySnapshot<Object?>> safeStream(Query query) {
    if (kIsWeb || !Platform.isWindows) {
      return query.snapshots();
    }

    // على ويندوز، نستخدم السحب الدوري (Polling) لتجنب انهيار النظام بسبب الخيوط البرمجية (Threads)
    // On Windows, use periodic polling to avoid native thread crashes
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => query.get())
        .asBroadcastStream();
  }

  /// مساعد لإنشاء بث لمستند واحد بشكل آمن
  /// Helper to create a safe stream for a single document
  Stream<DocumentSnapshot<Object?>> safeDocStream(DocumentReference docRef) {
    if (kIsWeb || !Platform.isWindows) {
      return docRef.snapshots();
    }

    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => docRef.get())
        .asBroadcastStream();
  }
}
