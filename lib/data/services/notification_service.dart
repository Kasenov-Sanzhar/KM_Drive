import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// ============================================================
// KM DRIVE — Notification Service
// lib/data/services/notification_service.dart
//
// Структура проекта:
//   lib/
//     main.dart
//     data/
//       models/models.dart
//       repositories/vehicle_repository.dart   ← import '../services/...'
//       services/notification_service.dart     ← ЭТОТ ФАЙЛ
//     presentation/screens/                   ← import '../../data/services/...'
// ============================================================

/// Background handler — обязательно top-level функция
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance._saveNotification(_fromRemote(message));
}

AppNotification _fromRemote(RemoteMessage msg) {
  final data = msg.data;
  return AppNotification(
    id: msg.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
    title: msg.notification?.body ??
           msg.notification?.title ??
           data['body'] as String? ??
           'notif_generic',
    type: _typeOf(data['type'] as String? ?? 'info'),
    time: DateTime.now(),
  );
}

NotificationType _typeOf(String s) {
  switch (s) {
    case 'warning': return NotificationType.warning;
    case 'success': return NotificationType.success;
    case 'error':   return NotificationType.error;
    default:        return NotificationType.info;
  }
}

// ── Сервис ────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _prefsKey  = 'km_notifications_v2';
  static const _channelId = 'km_drive_high';

  /// Колбек — вызывается при новом foreground-уведомлении
  void Function(AppNotification)? onNewNotification;

  // ── Инициализация ─────────────────────────────────────────

  Future<void> init() async {
    // Разрешение на уведомления (iOS + Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId, 'KM Drive',
      description: 'KM Drive alerts',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Инициализация локальных уведомлений
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Foreground — приложение открыто
    FirebaseMessaging.onMessage.listen((msg) async {
      final n = _fromRemote(msg);
      await _saveNotification(n);
      _showLocal(msg);
      onNewNotification?.call(n);
    });

    // Background tap — пользователь нажал на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      await _saveNotification(_fromRemote(msg).copyWithRead(true));
    });

    // Terminated — приложение было закрыто
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      await _saveNotification(_fromRemote(initial));
    }

    // Подписка на топики для рассылки
    await _fcm.subscribeToTopic('km_drive_all');
    await _fcm.subscribeToTopic('km_service_reminders');
  }

  // ── Публичный API ─────────────────────────────────────────

  Future<String?> getToken() => _fcm.getToken();

  Future<List<AppNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_prefsKey) ?? [];
    final list  = raw.map((s) {
      try {
        return AppNotification.fromJson(
            jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<AppNotification>().toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  Future<int> unreadCount() async =>
      (await getAll()).where((n) => !n.isRead).length;

  Future<void> markRead(String id) async {
    final list = await getAll();
    await _persist(
        list.map((n) => n.id == id ? n.copyWithRead(true) : n).toList());
  }

  Future<void> markAllRead() async {
    final list = await getAll();
    await _persist(list.map((n) => n.copyWithRead(true)).toList());
  }

  Future<void> deleteOne(String id) async {
    final list = await getAll();
    await _persist(list.where((n) => n.id != id).toList());
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Демо-данные при первом запуске (пока нет реальных push)
  Future<void> seedDemoIfEmpty() async {
    final list = await getAll();
    if (list.isNotEmpty) return;
    await _persist([
      AppNotification(
        id: 'demo-1',
        title: 'notif1',
        type: NotificationType.warning,
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'demo-2',
        title: 'notif2',
        type: NotificationType.success,
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'demo-3',
        title: 'notif3',
        type: NotificationType.info,
        time: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }

  // ── Приватные ─────────────────────────────────────────────

  Future<void> _saveNotification(AppNotification n) async {
    final list = await getAll();
    if (list.any((e) => e.id == n.id)) return; // дедупликация
    list.insert(0, n);
    await _persist(list.take(50).toList());     // максимум 50
  }

  Future<void> _persist(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      list.map((n) => jsonEncode(n.toJson())).toList(),
    );
  }

  void _showLocal(RemoteMessage msg) {
    final notif = msg.notification;
    if (notif == null) return;
    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, 'KM Drive',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}