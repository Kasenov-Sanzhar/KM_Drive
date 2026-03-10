import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Notifications Screen
// Полный список уведомлений, открывается из главной и из профиля
// ============================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = MockVehicleRepository();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.getNotifications().then((list) {
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
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

  String _timeAgo(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final l10n = AppLocalizations.of(context);
    if (diff.inMinutes < 1) return l10n.get('justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return DateFormat('d MMM', 'ru_RU').format(time);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: KmColors.background,
        body: SafeArea(
          child: Column(
            children: [
              KmScreenHeader(
                title: AppLocalizations.of(context).get('notifications'),
                subtitle: AppLocalizations.of(context).get('notificationsHistory'),
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: KmColors.accent,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: AppLocalizations.of(context).get('notifications'),
                subtitle: AppLocalizations.of(context).get('notificationsHistory'),
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            if (_notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).get('noNotifications'),
                    style: KmTextStyles.bodyMedium.copyWith(
                      color: KmColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final n = _notifications[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: KmCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _dotColor(n.type),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: KmTextStyles.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.isRead ? AppLocalizations.of(context).get('read') : _timeAgo(ctx, n.time),
                                      style: KmTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _notifications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}