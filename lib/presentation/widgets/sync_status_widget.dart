import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/sync_service.dart';
import '../../l10n/app_localizations.dart';

// ============================================================
// KM DRIVE — SyncStatusWidget
// Показывает статус подключения и синхронизации
// ============================================================

class SyncStatusBar extends StatefulWidget {
  const SyncStatusBar({super.key});

  @override
  State<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends State<SyncStatusBar> {
  SyncStatus _status = SyncService.instance.status;
  String _connType = '';
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = SyncService.instance.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    _loadConnType();
  }

  Future<void> _loadConnType() async {
    final t = await SyncService.instance.getConnectionType();
    if (mounted) setState(() => _connType = t);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Color color;
    IconData icon;
    String label;

    switch (_status) {
      case SyncStatus.synced:
        color = KmColors.success;
        icon  = Icons.cloud_done_rounded;
        label = l10n.get('syncSynced');
        break;
      case SyncStatus.syncing:
        color = KmColors.accent;
        icon  = Icons.sync_rounded;
        label = l10n.get('syncSyncing');
        break;
      case SyncStatus.offline:
        color = KmColors.textMuted;
        icon  = Icons.cloud_off_rounded;
        label = l10n.get('syncOffline');
        break;
      case SyncStatus.error:
        color = KmColors.warning;
        icon  = Icons.cloud_off_rounded;
        label = l10n.get('syncError');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _status == SyncStatus.syncing
            ? SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: color))
            : Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
          fontFamily: 'DMSans', fontSize: 11,
          fontWeight: FontWeight.w500, color: color)),
        if (_connType.isNotEmpty && _status == SyncStatus.synced) ...[
          const SizedBox(width: 5),
          Container(width: 3, height: 3,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(_connType, style: TextStyle(
            fontFamily: 'DMSans', fontSize: 10, color: color)),
        ],
      ]),
    );
  }
}

/// Полноценный экран настроек уведомлений и синхронизации
class NetworkStatusCard extends StatefulWidget {
  const NetworkStatusCard({super.key});

  @override
  State<NetworkStatusCard> createState() => _NetworkStatusCardState();
}

class _NetworkStatusCardState extends State<NetworkStatusCard> {
  SyncStatus _syncStatus = SyncService.instance.status;
  ConnectivityResult _connectivity = ConnectivityResult.none;
  StreamSubscription? _syncSub;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    _syncSub = SyncService.instance.statusStream.listen((s) {
      if (mounted) { setState(() => _syncStatus = s); }
    });
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _connectivity =
            results.isNotEmpty ? results.first : ConnectivityResult.none);
      }
    });
    _init();
  }

  Future<void> _init() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _connectivity =
          r.isNotEmpty ? r.first : ConnectivityResult.none);
    }
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  String _connLabel(AppLocalizations l10n) {
    switch (_connectivity) {
      case ConnectivityResult.wifi:     return 'Wi-Fi';
      case ConnectivityResult.mobile:   return '4G/5G';
      case ConnectivityResult.ethernet: return 'Ethernet';
      default:                          return l10n.get('syncOffline');
    }
  }

  IconData _connIcon() {
    switch (_connectivity) {
      case ConnectivityResult.wifi:   return Icons.wifi_rounded;
      case ConnectivityResult.mobile: return Icons.signal_cellular_alt_rounded;
      default:                        return Icons.wifi_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = _connectivity != ConnectivityResult.none;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.cloud_sync_rounded, color: KmColors.accent, size: 18),
          const SizedBox(width: 8),
          Text(l10n.get('syncTitle'), style: KmTextStyles.labelLarge),
          const Spacer(),
          const SyncStatusBar(),
        ]),
        const SizedBox(height: 12),
        const Divider(color: KmColors.border, height: 0, thickness: 0.5),
        const SizedBox(height: 12),

        // Connection type
        _Row(
          icon: _connIcon(),
          color: isOnline ? KmColors.success : KmColors.textMuted,
          label: l10n.get('syncConnection'),
          value: _connLabel(l10n),
        ),
        const SizedBox(height: 10),

        // Firebase sync
        _Row(
          icon: Icons.storage_rounded,
          color: _syncStatus == SyncStatus.synced
              ? KmColors.success : KmColors.textMuted,
          label: 'Firebase Firestore',
          value: _syncStatus == SyncStatus.synced
              ? l10n.get('syncSynced')
              : _syncStatus == SyncStatus.syncing
                  ? l10n.get('syncSyncing')
                  : l10n.get('syncOffline'),
        ),
        const SizedBox(height: 10),

        // Push notifications
        _Row(
          icon: Icons.notifications_active_rounded,
          color: KmColors.accent,
          label: l10n.get('syncPush'),
          value: l10n.get('syncPushActive'),
        ),
        const SizedBox(height: 10),

        // Topics
        _Row(
          icon: Icons.topic_rounded,
          color: KmColors.info,
          label: l10n.get('syncTopics'),
          value: 'km_drive_all · km_service_reminders',
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color,
      required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: KmTextStyles.bodySmall)),
      Text(value, style: KmTextStyles.caption.copyWith(color: color)),
    ]);
  }
}