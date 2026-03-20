import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/common_widgets.dart';
import '../widgets/sync_status_widget.dart';
import 'notifications_settings_screen.dart';
import '../../data/services/notification_service.dart';
import 'service_booking_screen.dart';
import 'scan_screen.dart';
import 'remote_control_screen.dart';
import 'telemetry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigateToDiagnostics});

  final VoidCallback? onNavigateToDiagnostics;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = MockVehicleRepository();
  VehicleModel? _vehicle;
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    NotificationService.instance.removeNewNotificationListener('dashboard');
    NotificationService.instance.removeListChangedListener('dashboard');
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getVehicle(),
      NotificationService.instance.getAll(),
    ]);
    if (mounted) {
      setState(() {
        _vehicle       = results[0] as VehicleModel;
        _notifications = results[1] as List<AppNotification>;
        _loading       = false;
      });
    }
    // Live updates from FCM while dashboard is visible
    NotificationService.instance.addNewNotificationListener('dashboard', (n) {
      if (mounted) setState(() => _notifications.insert(0, n));
    });
    // Reload when notifications deleted/read in history screen
    NotificationService.instance.addListChangedListener('dashboard', () async {
      if (!mounted) return;
      final list = await NotificationService.instance.getAll();
      if (mounted) setState(() => _notifications = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: KmColors.accent, strokeWidth: 1.5))
            : _DashboardContent(
                vehicle: _vehicle!,
                notifications: _notifications,
                onNavigateToDiagnostics: widget.onNavigateToDiagnostics,
              ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.vehicle,
    required this.notifications,
    this.onNavigateToDiagnostics,
  });

  final VehicleModel vehicle;
  final List<AppNotification> notifications;
  final VoidCallback? onNavigateToDiagnostics;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  // Показатели обновляются после сканирования
  late VehicleSystemStatus _engineStatus;
  late VehicleSystemStatus _tiresStatus;
  late double _fuelPercent;
  late int _mileageKm;

  @override
  void initState() {
    super.initState();
    _syncFromVehicle();
    // Слушаем завершение сканирования
    final prev = ScanResultsNotifier.onResultsUpdated;
    ScanResultsNotifier.onResultsUpdated = () {
      prev?.call();
      if (mounted) _updateFromScan();
    };
  }

  void _syncFromVehicle() {
    _engineStatus = widget.vehicle.engineStatus;
    _tiresStatus  = widget.vehicle.tiresStatus;
    _fuelPercent  = widget.vehicle.fuelPercent;
    _mileageKm    = widget.vehicle.mileageKm;
  }

  void _updateFromScan() {
    final results = ScanResultsNotifier.lastResults;
    if (results == null) return;
    // Определяем статус двигателя и тормозов по OBD
    final hasEngineWarn  = results.any((r) => r.code == 'B2799');
    final hasBrakeWarn   = results.any((r) => r.code == 'C0045');
    setState(() {
      _engineStatus = hasEngineWarn
          ? VehicleSystemStatus.warning
          : VehicleSystemStatus.ok;
      _tiresStatus = hasBrakeWarn
          ? VehicleSystemStatus.warning
          : VehicleSystemStatus.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sh = mq.size.height;
    final carH = sh < 700 ? 130.0 : sh < 800 ? 150.0 : 170.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Заголовок ─────────────────────────────────────
        _Header(vehicle: widget.vehicle),

        // ── Машина — высота адаптивная ────────────────────
        SizedBox(height: carH, child: _CarHero(vehicle: widget.vehicle)),

        // ── Статус сети ───────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: SyncStatusBar(),
          ),
        ),
        const SizedBox(height: 4),

        // ── Статусная полоска ─────────────────────────────
        _StatusStrip(
          fuelPercent:  _fuelPercent,
          engineStatus: _engineStatus,
          mileageKm:    _mileageKm,
          tiresStatus:  _tiresStatus,
        ),

        // ── Прокручиваемый контент ────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KmSectionLabel(
                    AppLocalizations.of(context).get('quickActions')),
                const SizedBox(height: 8),
                _QuickActionsGrid(
                  onNavigateToDiagnostics: widget.onNavigateToDiagnostics,
                ),
                const SizedBox(height: 20),
                _NotificationsSection(notifications: widget.notifications),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Заголовок ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.get('welcome').toUpperCase(),
              style: KmTextStyles.labelMedium),
          const SizedBox(height: 2),
          Text(l10n.get('appName'), style: KmTextStyles.displayMedium),
          const SizedBox(height: 2),
          Text('${vehicle.model} · ${vehicle.color}',
              style: KmTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ── Герой-секция ──────────────────────────────────────────────

class _CarHero extends StatelessWidget {
  const _CarHero({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/km_jaqin.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
        // Свечение под колёсами
        Positioned(
          bottom: 14, left: 80, right: 80,
          child: Container(
            height: 0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF888896).withValues(alpha: 0.5),
                  blurRadius: 22,
                  spreadRadius: 9,
                ),
              ],
            ),
          ),
        ),
        // Fade снизу
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [KmColors.background, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Статусная полоска ─────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.fuelPercent,
    required this.engineStatus,
    required this.mileageKm,
    required this.tiresStatus,
  });

  final double fuelPercent;
  final VehicleSystemStatus engineStatus;
  final int mileageKm;
  final VehicleSystemStatus tiresStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Адаптивный шрифт: на узких экранах меньше
    final sw = MediaQuery.of(context).size.width;
    final valSize = sw < 360 ? 16.0 : sw < 400 ? 18.0 : 20.0;
    final lblSize = sw < 360 ? 8.0  : sw < 400 ? 9.0  : 10.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: KmColors.border, width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            KmMetricCell(
              value: '${fuelPercent.toInt()}%',
              label: l10n.get('fuel'),
              valueColor: fuelPercent < 30
                  ? KmColors.error : KmColors.warning,
              valueSize: valSize,
              labelSize: lblSize,
            ),
            const _VDiv(),
            KmMetricCell(
              value: l10n.get(engineStatus.l10nKey),
              label: l10n.get('engine'),
              valueColor: engineStatus.isOk
                  ? KmColors.success : KmColors.warning,
              valueSize: valSize,
              labelSize: lblSize,
            ),
            const _VDiv(),
            KmMetricCell(
              value: KmFormatters.kilometers(mileageKm),
              label: l10n.get('mileage'),
              valueSize: valSize,
              labelSize: lblSize,
            ),
            const _VDiv(),
            KmMetricCell(
              value: l10n.get(tiresStatus.l10nKey),
              label: l10n.get('tires'),
              valueColor: tiresStatus.isOk
                  ? KmColors.success : KmColors.warning,
              valueSize: valSize,
              labelSize: lblSize,
            ),
          ]),
        ),
      ),
    );
  }
}

class _VDiv extends StatelessWidget {
  const _VDiv();
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: KmColors.border,
      );
}

// ── Быстрые действия ─────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.onNavigateToDiagnostics});

  final VoidCallback? onNavigateToDiagnostics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _QuickGrid(children: [
        KmQuickActionButton(
          icon: '🔧',
          label: l10n.get('bookService'),
          subtitle: l10n.get('nearestDate'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const ServiceBookingScreen()),
          ),
        ),
        KmQuickActionButton(
          icon: '🔐',
          label: l10n.get('remoteControl'),
          subtitle: l10n.get('remoteControlSubtitle'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RemoteControlScreen(),
            ),
          ),
        ),
        KmQuickActionButton(
          icon: '🗺️',
          label: l10n.get('currentLocation'),
          subtitle: l10n.get('onMap'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TelemetryScreen(showBackButton: true),
            ),
          ),
        ),
        KmQuickActionButton(
          icon: '🆘',
          label: l10n.get('sosTitle'),
          subtitle: l10n.get('sosSubtitle'),
          isDanger: true,
          onTap: () => showDialog(
            context: context,
            builder: (_) => const _SosDialog(),
          ),
        ),
    ]);
  }
}

// ── Auto-height 2-column grid ────────────────────────────────

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < children.length ? children[i + 1] : const SizedBox(),
            ),
          ],
        ),
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

class _SosDialog extends StatelessWidget {
  const _SosDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: KmColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KmRadius.xl),
        side: const BorderSide(color: Color(0x4DE05A5A), width: 0.5),
      ),
      title: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(
              color: Color(0x1FE05A5A), shape: BoxShape.circle),
          child: const Center(
              child: Text('🆘', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 12),
        Text(l10n.get('sosTitle'), style: KmTextStyles.displaySmall),
      ]),
      content: Text(l10n.get('sosBody'),
          style: KmTextStyles.bodySmall, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('sosCancel'),
              style: const TextStyle(
                  color: KmColors.textMuted, fontFamily: 'DMSans')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: KmColors.error),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('sosConfirm')),
        ),
      ],
    );
  }
}

// ── Уведомления ──────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({required this.notifications});
  final List<AppNotification> notifications;

  @override
  State<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState
    extends State<_NotificationsSection> {
  final Set<String> _expanded = {};

  void _toggle(String id) => setState(() {
        if (_expanded.contains(id)) {
          _expanded.remove(id);
        } else {
          _expanded.add(id);
        }
      });

  Color _dotColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning: return KmColors.warning;
      case NotificationType.success: return KmColors.success;
      case NotificationType.error:   return KmColors.error;
      case NotificationType.info:    return KmColors.info;
    }
  }

  String _typeName(AppLocalizations l10n, NotificationType t) {
    switch (t) {
      case NotificationType.warning: return l10n.get('notifWarning');
      case NotificationType.success: return l10n.get('notifSuccess');
      case NotificationType.error:   return l10n.get('notifError');
      case NotificationType.info:    return l10n.get('notifInfo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            KmSectionLabel(l10n.get('notifications')),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NotificationsSettingsScreen()),
              ),
              child: Text(l10n.get('all'),
                  style: KmTextStyles.labelSmall
                      .copyWith(color: KmColors.accent)),
            ),
          ],
        ),
        ...widget.notifications.map((n) {
          final isOpen = _expanded.contains(n.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _toggle(n.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KmColors.surface2,
                  borderRadius: BorderRadius.circular(KmRadius.lg),
                  border: Border.all(
                    color: isOpen
                        ? const Color(0x40C8A96E)
                        : KmColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              color: _dotColor(n.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l10n.get(n.title),
                              style: KmTextStyles.bodyMedium,
                              maxLines: isOpen ? null : 1,
                              overflow: isOpen
                                  ? null
                                  : TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: KmColors.textMuted,
                        ),
                      ],
                    ),
                    if (isOpen) ...[
                      const SizedBox(height: 10),
                      const Divider(
                          color: KmColors.border,
                          thickness: 0.5,
                          height: 0),
                      const SizedBox(height: 10),
                      Row(children: [
                        SizedBox(
                          width: 64,
                          child: Text(l10n.get('status'),
                              style: KmTextStyles.caption),
                        ),
                        Text(
                          n.isRead
                              ? l10n.get('read')
                              : l10n.get('new'),
                          style: KmTextStyles.bodySmall,
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        SizedBox(
                          width: 64,
                          child: Text(l10n.get('type'),
                              style: KmTextStyles.caption),
                        ),
                        Text(_typeName(l10n, n.type),
                            style: KmTextStyles.bodySmall),
                      ]),
                      if (n.type == NotificationType.warning) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ServiceBookingScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: KmColors.accent, width: 0.5),
                              foregroundColor: KmColors.accent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      KmRadius.sm)),
                            ),
                            child: Text(l10n.get('bookServiceBtn'),
                                style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: KmColors.accent)),
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: Text(
                          n.isRead
                              ? l10n.get('read')
                              : l10n.get('justNow'),
                          style: KmTextStyles.caption,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}