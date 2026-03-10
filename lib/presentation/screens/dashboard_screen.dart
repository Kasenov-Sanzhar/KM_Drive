import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/common_widgets.dart';
import 'notifications_screen.dart';
import 'service_booking_screen.dart';
import 'scan_screen.dart';
import 'telemetry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigateToDiagnostics});

  // ✅ Callback для переключения таба на Диагностику из AppShell
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

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getVehicle(),
      _repo.getNotifications(),
    ]);
    if (mounted) {
      setState(() {
        _vehicle       = results[0] as VehicleModel;
        _notifications = results[1] as List<AppNotification>;
        _loading       = false;
      });
    }
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.vehicle,
    required this.notifications,
    this.onNavigateToDiagnostics,
  });

  final VehicleModel vehicle;
  final List<AppNotification> notifications;
  final VoidCallback? onNavigateToDiagnostics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(vehicle: vehicle),
        _CarHero(vehicle: vehicle),
        _StatusStrip(vehicle: vehicle),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KmSectionLabel(AppLocalizations.of(context).get('quickActions')),
                _QuickActionsGrid(
                  onNavigateToDiagnostics: onNavigateToDiagnostics,
                ),
                const SizedBox(height: 20),
                _NotificationsSection(notifications: notifications),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.get('welcome').toUpperCase(), style: KmTextStyles.labelMedium),
          const SizedBox(height: 4),
          Text(l10n.get('appName'), style: KmTextStyles.displayMedium),
          const SizedBox(height: 2),
          Text('${vehicle.model} · ${vehicle.color}', style: KmTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ── Герой-секция с реальным фото машины ─────────────────────

class _CarHero extends StatelessWidget {
  const _CarHero({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: Stack(
        children: [
          // ── Машина (RGBA — фон прозрачный) ─────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/km_jaqin.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // ── Тонкое свечение под колёсами ───────────────
          Positioned(
            bottom: 16,
            left: 80,
            right: 80,
            child: Container(
              height: 0,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF888896).withValues(alpha: 0.55),
                    blurRadius: 24,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // ── Fade снизу ──────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 30,
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
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: KmColors.border, width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            KmMetricCell(
              value: '${vehicle.fuelPercent.toInt()}%',
              label: l10n.get('fuel'),
              valueColor: vehicle.fuelPercent < 30 ? KmColors.error : KmColors.warning,
            ),
            _VDivider(),
            KmMetricCell(
              value: vehicle.engineStatus.label,
              label: l10n.get('engine'),
              valueColor: vehicle.engineStatus.isOk ? KmColors.success : KmColors.warning,
            ),
            _VDivider(),
            KmMetricCell(
              value: KmFormatters.kilometers(vehicle.mileageKm),
              label: l10n.get('mileage'),
            ),
            _VDivider(),
            KmMetricCell(
              value: vehicle.tiresStatus.label,
              label: l10n.get('tires'),
              valueColor: vehicle.tiresStatus.isOk ? KmColors.success : KmColors.warning,
            ),
          ]),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: KmColors.border,
      );
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.onNavigateToDiagnostics});

  final VoidCallback? onNavigateToDiagnostics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: [
        KmQuickActionButton(
          icon: '🔧',
          label: l10n.get('bookService'),
          subtitle: l10n.get('nearestDate'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceBookingScreen()),
          ),
        ),
        KmQuickActionButton(
          icon: '📡',
          label: l10n.get('scanVehicle'),
          subtitle: l10n.get('scanCar'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScanScreen(
                // ✅ Передаём callback — после сканирования переключит таб
                onNavigateToDiagnostics: onNavigateToDiagnostics,
              ),
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
      ],
    );
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
          decoration: const BoxDecoration(color: Color(0x1FE05A5A), shape: BoxShape.circle),
          child: const Center(child: Text('🆘', style: TextStyle(fontSize: 28))),
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
              style: const TextStyle(color: KmColors.textMuted, fontFamily: 'DMSans')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: KmColors.error),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('sosConfirm')),
        ),
      ],
    );
  }
}

// ── Уведомления (inline expand) ─────────────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({required this.notifications});
  final List<AppNotification> notifications;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final Set<String> _expanded = {};

  void _toggle(String id) => setState(() {
        if (_expanded.contains(id)) { _expanded.remove(id); }
        else { _expanded.add(id); }
      });

  Color _dotColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning: return KmColors.warning;
      case NotificationType.success: return KmColors.success;
      case NotificationType.error:   return KmColors.error;
      case NotificationType.info:    return KmColors.info;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            KmSectionLabel(l10n.get('notifications')),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Text(l10n.get('all'),
                  style: KmTextStyles.labelSmall.copyWith(color: KmColors.accent)),
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
                    color: isOpen ? const Color(0x40C8A96E) : KmColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: _dotColor(n.type), shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(n.title, style: KmTextStyles.bodyMedium,
                            maxLines: isOpen ? null : 1,
                            overflow: isOpen ? null : TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isOpen ? Icons.keyboard_arrow_up_rounded
                               : Icons.keyboard_arrow_down_rounded,
                        size: 17, color: KmColors.textMuted,
                      ),
                    ]),
                    if (isOpen) ...[
                      const SizedBox(height: 10),
                      const Divider(color: KmColors.border, thickness: 0.5, height: 0),
                      const SizedBox(height: 10),
                      Row(children: [
                        SizedBox(width: 64,
                          child: Text(l10n.get('status'), style: KmTextStyles.caption)),
                        Text(n.isRead ? l10n.get('read') : l10n.get('new'),
                            style: KmTextStyles.bodySmall),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        SizedBox(width: 64,
                          child: Text(l10n.get('type'), style: KmTextStyles.caption)),
                        Text(_typeName(l10n, n.type), style: KmTextStyles.bodySmall),
                      ]),
                      if (n.type == NotificationType.warning) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ServiceBookingScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: KmColors.accent, width: 0.5),
                              foregroundColor: KmColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(KmRadius.sm)),
                            ),
                            child: Text(l10n.get('bookServiceBtn'),
                                style: const TextStyle(
                                    fontFamily: 'DMSans', fontSize: 12,
                                    fontWeight: FontWeight.w500, color: KmColors.accent)),
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: Text(n.isRead ? l10n.get('read') : l10n.get('justNow'),
                            style: KmTextStyles.caption),
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

  String _typeName(AppLocalizations l10n, NotificationType t) {
    switch (t) {
      case NotificationType.warning: return l10n.get('notifWarning');
      case NotificationType.success: return l10n.get('notifSuccess');
      case NotificationType.error:   return l10n.get('notifError');
      case NotificationType.info:    return l10n.get('notifInfo');
    }
  }
}