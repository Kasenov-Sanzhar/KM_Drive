import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// ============================================================
// KM DRIVE — PushService
// Отвечает ТОЛЬКО за:
//   1. Запрос разрешений у пользователя
//   2. Получение FCM токена
//   3. Управление подписками на топики
//   4. Показ системного уведомления в трее (foreground)
//
// FCM onMessage / onMessageOpenedApp — управляет NotificationService
// ============================================================

class PushService {
  PushService._();
  static final instance = PushService._();

  final _fcm    = FirebaseMessaging.instance;
  final _local  = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  static const _channelId = 'km_drive_high';

  // ── Инициализация ─────────────────────────────────────────

  Future<void> init() async {
    await _setupLocalNotifications();
    _permissionGranted = true; // разрешение запрашивает NotificationService
    _fcmToken = await _fcm.getToken();

    // Обновление токена при ротации
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
    });

    // iOS — показывать уведомления когда приложение открыто
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  // ── Локальные уведомления (Android foreground) ────────────

  Future<void> _setupLocalNotifications() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId, 'KM Drive',
        description: 'Уведомления KM Drive',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ── Топики ────────────────────────────────────────────────

  Future<void> subscribeToTopic(String topic)   => _fcm.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) => _fcm.unsubscribeFromTopic(topic);

  // ── Тестовое уведомление ──────────────────────────────────

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, 'KM Drive',
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Не-blocking версия для тестовой кнопки
  // Системное уведомление не показывается когда приложение открыто —
  // in-app уведомление уже добавлено через NotificationService
  void sendTestNotification({
    String title = 'KM Drive',
    String body  = 'Тестовое уведомление',
  }) {
    // no-op when app is in foreground — in-app notification handles it
  }
}