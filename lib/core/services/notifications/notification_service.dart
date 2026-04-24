import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

/// التعامل مع الرسائل في الخلفية (يجب أن تكون دالة خارج أي كلاس)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

/// خدمة الإشعارات - Notification Service
/// تدعم FCM للموبايل والإشعارات المحلية لسطح المكتب (Windows)
class NotificationService {
  static NotificationService? _instance;
  
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  /// تهيئة الخدمة
  Future<void> initialize() async {
    // 1. تهيئة الإشعارات المحلية
    await _initLocalNotifications();

    // 2. تهيئة FCM (إذا لم يكن Windows/Desktop لأنه غير مدعوم محلياً في الرزمة الرسمية)
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      await _initFCM();
    }
  }

  /// تهيئة الإشعارات المحلية
  Future<void> _initLocalNotifications() async {
    if (!kIsWeb && Platform.isWindows) {
      // إعداد local_notifier للويندوز
      await localNotifier.setup(
        appName: 'نيو كير',
        shortcutPolicy: ShortcutPolicy.requireCreate, // إنشاء اختصار للإشعارات
      );
      return;
    }

    // إعداد flutter_local_notifications للأنظمة الأخرى
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  /// تهيئة Firebase Cloud Messaging
  Future<void> _initFCM() async {
    try {
      // طلب الصلاحيات
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted FCM permission');
        
        // الحصول على التوكن
        String? token = await _fcm.getToken();
        debugPrint('FCM Token: $token');

        // الاستماع للرسائل في الواجهة
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          if (message.notification != null) {
            showNotification(
              title: message.notification!.title ?? 'إشعار جديد',
              body: message.notification!.body ?? '',
            );
          }
        });

        // الاستماع للرسائل في الخلفية
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('FCM Init Error: $e');
    }
  }

  /// عرض إشعار محلي
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!kIsWeb && Platform.isWindows) {
      // عرض الإشعار على ويندوز
      LocalNotification notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.onShow = () => debugPrint('onShow $title');
      notification.onClose = (closeReason) => debugPrint('onClose $title $closeReason');
      notification.onClick = () => debugPrint('onClick $title');
      
      await notification.show();
      return;
    }

    // عرض الإشعار على المنصات الأخرى
    const androidDetails = AndroidNotificationDetails(
      'new_care_channel_id',
      'إشعارات نيو كير',
      channelDescription: 'قناة الإشعارات الأساسية للنظام',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
