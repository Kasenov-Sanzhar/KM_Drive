import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/push_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import '../widgets/sync_status_widget.dart';

// ============================================================
// KM DRIVE — Notifications & Sync Settings Screen
// Вкладки: История уведомлений | Push-настройки | Синхронизация
// ============================================================

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(children: [
          KmScreenHeader(
            title:    l10n.get('notifSettingsTitle'),
            subtitle: l10n.get('notifSettingsSubtitle'),
            showBack: true,
            onBack:   () => Navigator.of(context).pop(),
          ),

          // ── Tabs ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            decoration: BoxDecoration(
              color: KmColors.surface2,
              borderRadius: BorderRadius.circular(KmRadius.md),
              border: Border.all(color: KmColors.border, width: 0.5),
            ),
            child: TabBar(
              controller: _tabs,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: KmColors.accent,
                borderRadius: BorderRadius.circular(KmRadius.md),
              ),
              labelColor: KmColors.background,
              unselectedLabelColor: KmColors.textMuted,
              labelStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 11,
                  fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 11),
              tabs: [
                Tab(text: l10n.get('notifTabHistory')),
                Tab(text: l10n.get('notifTabPush')),
                Tab(text: l10n.get('notifTabSync')),
              ],
            ),
          ),

          Expanded(child: TabBarView(
            controller: _tabs,
            children: [
              _HistoryTab(),
              _PushTab(),
              _SyncTab(),
            ],
          )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 1 — История уведомлений (старый NotificationsScreen)
// ══════════════════════════════════════════════════════════════

class _HistoryTab extends StatefulWidget {
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _svc = NotificationService.instance;
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _svc.addNewNotificationListener('history_tab', (n) {
      if (mounted) setState(() => _notifications.insert(0, n));
    });
    _svc.addListChangedListener('history_tab', () async {
      if (!mounted) return;
      final list = await _svc.getAll();
      if (mounted) setState(() => _notifications = list);
    });
    _load();
  }

  @override
  void dispose() {
    _svc.removeNewNotificationListener('history_tab');
    _svc.removeListChangedListener('history_tab');
    super.dispose();
  }

  Future<void> _load() async {
    // seed + getAll run together, but show spinner while waiting
    await _svc.seedDemoIfEmpty();
    final list = await _svc.getAll();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWithRead(true)).toList();
    });
    _svc.markAllRead(); // background
  }

  void _delete(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
    _svc.deleteOne(id); // background
  }

  void _markRead(String id) {
    // Update UI immediately
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWithRead(true) : n)
          .toList();
    });
    // Persist in background — no await
    _svc.markRead(id);
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
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
    final unread = _notifications.where((n) => !n.isRead).length;

    return Column(children: [
      if (unread > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _markAllRead,
              child: Text(l10n.get('markAllRead'),
                  style: KmTextStyles.caption.copyWith(color: KmColors.accent)),
            ),
          ),
        ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: KmColors.accent, strokeWidth: 1.5))
            : _notifications.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🔔', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(l10n.get('noNotifications'),
                        style: KmTextStyles.bodyMedium
                            .copyWith(color: KmColors.textMuted)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final n = _notifications[i];
                      return _NotifCard(
                        notification: n,
                        timeLabel:   _timeAgo(n.time),
                        dotColor:    _dotColor(n.type),
                        borderColor: _cardBorder(n.type, !n.isRead),
                        typeIcon:    _typeIcon(n.type),
                        l10n:        l10n,
                        onTap:       () => _markRead(n.id),
                        onDismiss:   () => _delete(n.id),
                      );
                    },
                  ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 2 — Push-настройки
// ══════════════════════════════════════════════════════════════

class _PushTab extends StatefulWidget {
  @override
  State<_PushTab> createState() => _PushTabState();
}

class _PushTabState extends State<_PushTab> {
  bool _pushAll     = true;
  bool _pushService = true;
  bool _pushWarning = true;
  bool _pushSync    = true;
  bool _pushPromo   = false;

  String? _fcmToken;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _fcmToken = PushService.instance.fcmToken;
  }

  void _copyToken() {
    if (_fcmToken == null) return;
    // Non-blocking clipboard write
    Clipboard.setData(ClipboardData(text: _fcmToken!));
    setState(() => _copied = true);
    // Reset icon after 2s without blocking UI
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _sendTest() {
    final l10n = AppLocalizations.of(context);

    // 1. In-app notification — immediate
    final testNotif = AppNotification(
      id:     DateTime.now().millisecondsSinceEpoch.toString(),
      title:  l10n.get('notifTestTitle'),
      body:   l10n.get('notifTestBody'),
      type:   NotificationType.info,
      time:   DateTime.now(),
      isRead: false,
    );
    NotificationService.instance.saveNotificationLocal(testNotif);

    // 2. Fake system banner overlay (demonstrates push UI without platform channel)
    _showFakeBanner(
      title: l10n.get('notifTestTitle'),
      body:  l10n.get('notifTestBody'),
    );
  }

  OverlayEntry? _bannerEntry;

  void _showFakeBanner({required String title, required String body}) {
    _bannerEntry?.remove();
    final overlay = Overlay.of(context);
    _bannerEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16,
        child: _FakePushBanner(
          title: title,
          body:  body,
          onDismiss: () {
            _bannerEntry?.remove();
            _bannerEntry = null;
          },
        ),
      ),
    );
    overlay.insert(_bannerEntry!);
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _bannerEntry?.remove();
      _bannerEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 60),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Переключатели ──────────────────────────────────
        _SwitchTile(icon: '🔔', label: l10n.get('notifAll'),
            subtitle: l10n.get('notifAllDesc'), value: _pushAll,
            onChanged: (v) => setState(() {
              _pushAll = v;
              if (!v) { _pushService = false; _pushWarning = false;
                        _pushSync = false; _pushPromo = false; }
            })),
        const SizedBox(height: 8),
        _SwitchTile(icon: '🔧', label: l10n.get('notifService'),
            subtitle: l10n.get('notifServiceDesc'),
            value: _pushService && _pushAll, enabled: _pushAll,
            onChanged: (v) => setState(() => _pushService = v)),
        const SizedBox(height: 8),
        _SwitchTile(icon: '⚠️', label: l10n.get('notifWarnings'),
            subtitle: l10n.get('notifWarningsDesc'),
            value: _pushWarning && _pushAll, enabled: _pushAll,
            onChanged: (v) => setState(() => _pushWarning = v)),
        const SizedBox(height: 8),
        _SwitchTile(icon: '🔄', label: l10n.get('notifSyncNotif'),
            subtitle: l10n.get('notifSyncNotifDesc'),
            value: _pushSync && _pushAll, enabled: _pushAll,
            onChanged: (v) => setState(() => _pushSync = v)),
        const SizedBox(height: 8),
        _SwitchTile(icon: '🎁', label: l10n.get('notifPromo'),
            subtitle: l10n.get('notifPromoDesc'),
            value: _pushPromo && _pushAll, enabled: _pushAll,
            onChanged: (v) => setState(() => _pushPromo = v)),

        const SizedBox(height: 20),

        // ── Тест ───────────────────────────────────────────
        KmSectionLabel(l10n.get('notifTestSection')),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pushAll ? _sendTest : null,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(l10n.get('notifTestBtn')),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: KmColors.accent, width: 0.5),
              foregroundColor: KmColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KmRadius.md)),
              textStyle: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── FCM токен ──────────────────────────────────────
        KmSectionLabel(l10n.get('notifTokenSection')),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KmColors.surface2,
            borderRadius: BorderRadius.circular(KmRadius.md),
            border: Border.all(color: KmColors.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.get('notifTokenDesc'), style: KmTextStyles.caption),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(
                _fcmToken ?? l10n.get('notifTokenLoading'),
                style: KmTextStyles.caption.copyWith(
                    fontFamily: 'monospace', color: KmColors.accentDim),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _copyToken,
                child: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: _copied ? KmColors.success : KmColors.accent,
                  size: 18)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 3 — Синхронизация
// ══════════════════════════════════════════════════════════════

class _SyncTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 60),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const NetworkStatusCard(),
        const SizedBox(height: 20),

        // Topics
        KmSectionLabel(l10n.get('syncTopics')),
        _TopicRow(topic: 'km_drive_all',         desc: l10n.get('topicAll')),
        const SizedBox(height: 6),
        _TopicRow(topic: 'km_service_reminders', desc: l10n.get('topicService')),
        const SizedBox(height: 6),
        _TopicRow(topic: 'km_updates',           desc: l10n.get('topicUpdates')),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon, required this.label, required this.subtitle,
    required this.value, required this.onChanged, this.enabled = true,
  });
  final String icon, label, subtitle;
  final bool value, enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value && enabled
              ? KmColors.accent.withValues(alpha: 0.06) : KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(
            color: value && enabled ? KmColors.accentDim : KmColors.border,
            width: 0.5),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: KmTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: KmTextStyles.caption),
            ])),
          Switch.adaptive(
            value: value && enabled, onChanged: enabled ? onChanged : null,
            activeThumbColor: KmColors.accent,
            activeTrackColor: KmColors.accentDim),
        ]),
      ),
    );
  }
}

class _TopicRow extends StatefulWidget {
  const _TopicRow({required this.topic, required this.desc});
  final String topic, desc;

  @override
  State<_TopicRow> createState() => _TopicRowState();
}

class _TopicRowState extends State<_TopicRow> {
  bool _subscribed = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.rss_feed_rounded,
            color: _subscribed ? KmColors.success : KmColors.textMuted,
            size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.topic, style: KmTextStyles.bodySmall
                .copyWith(fontFamily: 'monospace', fontSize: 11)),
            Text(widget.desc, style: KmTextStyles.caption),
          ])),
        GestureDetector(
          onTap: () async {
            if (_subscribed) {
              await PushService.instance.unsubscribeFromTopic(widget.topic);
            } else {
              await PushService.instance.subscribeToTopic(widget.topic);
            }
            if (mounted) setState(() => _subscribed = !_subscribed);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _subscribed
                  ? KmColors.success.withValues(alpha: 0.12) : KmColors.surface3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _subscribed
                    ? KmColors.success.withValues(alpha: 0.3) : KmColors.border,
                width: 0.5)),
            child: Text(_subscribed ? 'ON' : 'OFF',
                style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _subscribed ? KmColors.success : KmColors.textMuted)),
          ),
        ),
      ]),
    );
  }
}

// ── Notification card — expandable ────────────────────────────

class _NotifCard extends StatefulWidget {
  const _NotifCard({
    required this.notification, required this.timeLabel,
    required this.dotColor, required this.borderColor,
    required this.typeIcon, required this.l10n,
    required this.onTap, required this.onDismiss,
  });

  final AppNotification notification;
  final String timeLabel, typeIcon;
  final Color dotColor, borderColor;
  final AppLocalizations l10n;
  final VoidCallback onTap, onDismiss;

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _expanded = false;

  String _typeName(AppLocalizations l10n) {
    switch (widget.notification.type) {
      case NotificationType.warning: return l10n.get('notifTypeWarning');
      case NotificationType.success: return l10n.get('notifTypeSuccess');
      case NotificationType.error:   return l10n.get('notifTypeError');
      case NotificationType.info:    return l10n.get('notifTypeInfo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final n      = widget.notification;
    final l10n   = widget.l10n;
    final unread = !n.isRead;
    final body   = n.body.isNotEmpty ? l10n.tryGet(n.body) ?? n.body : '';

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: KmColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(KmRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: KmColors.error, size: 20),
      ),
      onDismissed: (_) => widget.onDismiss(),
      child: GestureDetector(
        onTap: () {
          widget.onTap(); // mark read
          setState(() => _expanded = !_expanded);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? KmColors.surface2
                : KmColors.surface2.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: widget.borderColor, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header row ──────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(widget.typeIcon,
                    style: const TextStyle(fontSize: 18))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.get(n.title),
                      style: KmTextStyles.bodyMedium.copyWith(
                          fontWeight: unread
                              ? FontWeight.w600 : FontWeight.w400)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 6, top: 1),
                        decoration: BoxDecoration(
                            color: unread
                                ? widget.dotColor : KmColors.textMuted,
                            shape: BoxShape.circle)),
                    Text(unread ? widget.timeLabel : l10n.get('read'),
                        style: KmTextStyles.caption),
                  ]),
                ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (unread) Container(width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                        color: widget.dotColor, shape: BoxShape.circle)),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18, color: KmColors.textMuted),
              ]),
            ]),

            // ── Expanded details ──────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: KmColors.border, height: 0, thickness: 0.5),
              const SizedBox(height: 10),

              // Full body text
              if (body.isNotEmpty) ...[
                Text(body, style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
                const SizedBox(height: 10),
              ],

              // Meta: status + type
              Row(children: [
                Expanded(child: _MetaRow(
                    label: l10n.get('notifStatus'),
                    value: unread
                        ? l10n.get('notifStatusUnread')
                        : l10n.get('notifStatusRead'),
                    color: unread ? widget.dotColor : KmColors.textMuted)),
                Expanded(child: _MetaRow(
                    label: l10n.get('notifType'),
                    value: _typeName(l10n),
                    color: widget.dotColor)),
              ]),

              // Action button
              if (n.actionKey != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: widget.dotColor.withValues(alpha: 0.5),
                          width: 0.5),
                      foregroundColor: widget.dotColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KmRadius.sm)),
                      textStyle: const TextStyle(fontFamily: 'DMSans',
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(l10n.get(n.actionKey!)),
                  ),
                ),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: KmTextStyles.caption.copyWith(color: KmColors.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: KmTextStyles.bodySmall.copyWith(color: color,
          fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Fake push banner (overlay) ────────────────────────────────

class _FakePushBanner extends StatefulWidget {
  const _FakePushBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
  });
  final String title, body;
  final VoidCallback onDismiss;

  @override
  State<_FakePushBanner> createState() => _FakePushBannerState();
}

class _FakePushBannerState extends State<_FakePushBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(
        begin: const Offset(0, -1), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KmColors.accent.withValues(alpha: 0.3),
                    width: 0.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000),
                      blurRadius: 20, offset: Offset(0, 4)),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: KmColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🔔', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Text('KM Drive',
                          style: TextStyle(fontFamily: 'DMSans', fontSize: 11,
                              color: KmColors.textMuted)),
                      const Spacer(),
                      Text('сейчас',
                          style: KmTextStyles.caption
                              .copyWith(color: KmColors.textMuted)),
                    ]),
                    const SizedBox(height: 2),
                    Text(widget.title,
                        style: const TextStyle(fontFamily: 'DMSans',
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: KmColors.textPrimary)),
                    if (widget.body.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(widget.body,
                          style: KmTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}