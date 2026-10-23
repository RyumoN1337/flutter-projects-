import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Работа с Firebase Cloud Messaging + показ уведомлений на устройстве.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lab7_channel',
    'Lab 7 notifications',
    description: 'Уведомления лабораторной работы 7',
    importance: Importance.high,
  );

  String? fcmToken;

  Future<void> init() async {
    // 1. Разрешение на уведомления (Android 13+ / iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // 2. Локальные уведомления
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    // 3. FCM токен устройства
    try {
      fcmToken = await _fcm.getToken();
      debugPrint('FCM TOKEN: $fcmToken');
      _fcm.onTokenRefresh.listen((t) => fcmToken = t);
    } catch (e) {
      debugPrint('Не удалось получить FCM token: $e');
    }

    // 4. Push, пришедший пока приложение открыто (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      showNotification(
        title: n?.title ?? 'Новое уведомление',
        body: n?.body ?? '',
      );
    });

    // 5. Нажатие на push, когда приложение было в фоне
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Opened from notification: ${message.messageId}');
    });
  }

  /// Показывает уведомление в шторке устройства.
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'lab7_channel',
        'Lab 7 notifications',
        channelDescription: 'Уведомления лабораторной работы 7',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
