import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Notifications Screen
// Реальные уведомления через NotificationService + FCM
// ============================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc = NotificationService.instance;
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Подписываемся на новые уведомления пока экран открыт
    _svc.onNewNotification = (n) {
      if (mounted) setState(() => _notifications.insert(0, n));
    };
  }

  @override
  void dispose() {
    _svc.onNewNotification = null;
    super.dispose();
  }

  Future<void> _load() async {
    await _svc.seedDemoIfEmpty();
    final list = await _svc.getAll();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  Future<void> _markAllRead() async {
    await _svc.markAllRead();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWithRead(true)).toList();
    });
  }

  Future<void> _delete(String id) async {
    await _svc.deleteOne(id);
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  Future<void> _markRead(String id) async {
    await _svc.markRead(id);
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWithRead(true) : n)
          .toList();
    });
  }

  Color _dotColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning: return KmColors.warning;
      case NotificationType.success: return KmColors.success;
      case NotificationType.error:   return KmColors.error;
      case NotificationType.info:    return KmColors.info;
    }
  }

  Color _cardBorder(NotificationType type, bool unread) {
    if (!unread) return KmColors.border;
    switch (type) {
      case NotificationType.warning: return const Color(0x50C8A96E);
      case NotificationType.success: return const Color(0x505AB87A);
      case NotificationType.error:   return const Color(0x50E05A5A);
      case NotificationType.info:    return const Color(0x505A8FE0);
    }
  }

  String _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.warning: return '⚠️';
      case NotificationType.success: return '✅';
      case NotificationType.error:   return '❌';
      case NotificationType.info:    return 'ℹ️';
    }
  }

  String _timeAgo(BuildContext context, DateTime time) {
    final now  = DateTime.now();
    final diff = now.difference(time);
    final l10n = AppLocalizations.of(context);
    if (diff.inMinutes < 1)  return l10n.get('justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.get('minAgo')}';
    if (diff.inHours   < 24) return '${diff.inHours} ${l10n.get('hAgo')}';
    if (diff.inDays    < 7)  return '${diff.inDays} ${l10n.get('dAgo')}';
    final lang = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM', lang == 'en' ? 'en_US' : 'ru_RU').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Шапка ──────────────────────────────────────
            KmScreenHeader(
              title:    l10n.get('notifications'),
              subtitle: l10n.get('notificationsHistory'),
              showBack: true,
              onBack:   () => Navigator.of(context).pop(),
              trailing: unreadCount > 0
                  ? TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        l10n.get('markAllRead'),
                        style: KmTextStyles.caption.copyWith(
                          color: KmColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),

            // ── Контент ────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: KmColors.accent, strokeWidth: 1.5))
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔔',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(l10n.get('noNotifications'),
                                  style: KmTextStyles.bodyMedium.copyWith(
                                      color: KmColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final n = _notifications[i];
                            return _NotificationCard(
                              notification: n,
                              timeLabel: _timeAgo(ctx, n.time),
                              dotColor:   _dotColor(n.type),
                              borderColor: _cardBorder(n.type, !n.isRead),
                              typeIcon:   _typeIcon(n.type),
                              l10n: l10n,
                              onTap: () => _markRead(n.id),
                              onDismiss: () => _delete(n.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Карточка уведомления ──────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeLabel,
    required this.dotColor,
    required this.borderColor,
    required this.typeIcon,
    required this.l10n,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final String timeLabel;
  final Color dotColor;
  final Color borderColor;
  final String typeIcon;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: KmColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(KmRadius.lg),
        ),
        child: const Icon(Icons.delete_outline,
            color: KmColors.error, size: 20),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? KmColors.surface2
                : KmColors.surface2.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка типа
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(typeIcon,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get(notification.title),
                      style: KmTextStyles.bodyMedium.copyWith(
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 6, top: 1),
                        decoration: BoxDecoration(
                          color: unread
                              ? dotColor
                              : KmColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        unread
                            ? timeLabel
                            : l10n.get('read'),
                        style: KmTextStyles.caption,
                      ),
                    ]),
                  ],
                ),
              ),
              // Индикатор непрочитанного
              if (unread)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}