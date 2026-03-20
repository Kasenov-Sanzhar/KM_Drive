import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
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
  // Background isolate needs its own Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance._saveNotification(_fromRemote(message));
}

AppNotification _fromRemote(RemoteMessage msg) {
  final data = msg.data;
  return AppNotification(
    id: msg.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
    title: msg.notification?.title ?? data['title'] as String? ?? 'notif_generic',
    body:  msg.notification?.body  ?? data['body']  as String? ?? '',
    type:  _typeOf(data['type'] as String? ?? 'info'),
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

class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _prefsKey  = 'km_notifications_v2';
  static const _channelId = 'km_drive_high';


  // ── Listeners — поддерживают несколько подписчиков ─────────

  final _newListeners  = <String, void Function(AppNotification)>{};
  final _listListeners = <String, void Function()>{};

  void addNewNotificationListener(String key, void Function(AppNotification) cb) {
    _newListeners[key] = cb;
  }
  void removeNewNotificationListener(String key) => _newListeners.remove(key);

  void addListChangedListener(String key, void Function() cb) {
    _listListeners[key] = cb;
  }
  void removeListChangedListener(String key) => _listListeners.remove(key);

  void _notifyNew(AppNotification n) {
    for (final cb in _newListeners.values) { cb(n); }
  }
  void _notifyChanged() {
    for (final cb in _listListeners.values) { cb(); }
  }

  // Legacy single-callback support (backward compat)
  set onNewNotification(void Function(AppNotification)? cb) {
    if (cb == null) { _newListeners.remove('_legacy'); }
    else            { _newListeners['_legacy'] = cb; }
  }
  set onListChanged(void Function()? cb) {
    if (cb == null) { _listListeners.remove('_legacy'); }
    else            { _listListeners['_legacy'] = cb; }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
  }

  // ── Инициализация ─────────────────────────────────────────

  Future<void> init() async {
    // Track app lifecycle to avoid showing system notification when app is open
    WidgetsBinding.instance.addObserver(this);

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
      // 1. Update UI immediately — no waiting
      _notifyNew(n);
      // 2. Persist in background
      _saveNotification(n);
      // 3. Show system banner in background (doesn't block UI)
      Future.microtask(() => _showLocal(msg));
    });

    // Background tap — пользователь нажал на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      await _saveNotification(_fromRemote(msg).copyWithRead(true));
    });

    // Terminated — приложение запущено по тапу на уведомление
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      final n = _fromRemote(initial).copyWithRead(false);
      await _saveNotification(n);
      // Notify after slight delay — listeners register after init
      Future.delayed(const Duration(milliseconds: 500), () => _notifyNew(n));
    }

    // Подписка на топики для рассылки
    await _fcm.subscribeToTopic('km_drive_all');
    await _fcm.subscribeToTopic('km_service_reminders');
  }



  // ── Публичный API ─────────────────────────────────────────

  Future<String?> getToken() => _fcm.getToken();

  /// Called from PushService when FCM message arrives
  Future<void> saveFromFCM({
    required String title,
    String body = '',
    required Map<String, dynamic> data,
  }) async {
    final type = _typeFromData(data);
    final n = AppNotification(
      id:     DateTime.now().millisecondsSinceEpoch.toString(),
      title:  title,
      body:   body,
      time:   DateTime.now(),
      type:   type,
      isRead: false,
    );
    await _saveNotification(n);
    _notifyNew(n);
  }

  NotificationType _typeFromData(Map<String, dynamic> data) {
    final t = data['type'] as String? ?? '';
    switch (t) {
      case 'warning': return NotificationType.warning;
      case 'success': return NotificationType.success;
      case 'error':   return NotificationType.error;
      default:        return NotificationType.info;
    }
  }

  /// Saves notification without blocking UI — fire-and-forget
  void saveNotificationLocal(AppNotification n) {
    _saveNotification(n); // async, not awaited
    _notifyNew(n);
    _notifyChanged();
  }

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
    _notifyChanged();
  }

  Future<void> markAllRead() async {
    final list = await getAll();
    await _persist(list.map((n) => n.copyWithRead(true)).toList());
    _notifyChanged();
  }

  Future<void> deleteOne(String id) async {
    final list = await getAll();
    await _persist(list.where((n) => n.id != id).toList());
    _notifyChanged();
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
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}