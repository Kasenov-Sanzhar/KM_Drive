import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Remote Control Screen
// Дистанционное управление KM Jaqin
// Все команды работают с задержкой-заглушкой (нет реальной машины)
// ============================================================

// ── Состояние автомобиля (синглтон) ──────────────────────────

class VehicleControlState {
  VehicleControlState._();
  static final VehicleControlState instance = VehicleControlState._();

  bool doorsLocked   = true;
  bool engineOn      = false;
  bool climateOn     = false;
  double climateTemp = 22.0;
  bool lightsOn      = false;
  // Окна: 0 = закрыто, 100 = полностью открыто
  double windowsFrontLeft  = 0;
  double windowsFrontRight = 0;
  double windowsRearLeft   = 0;
  double windowsRearRight  = 0;
  DateTime lastUpdate = DateTime.now();

  bool get windowsClosed =>
    windowsFrontLeft == 0 && windowsFrontRight == 0 &&
    windowsRearLeft  == 0 && windowsRearRight  == 0;

  double get windowsAvgPercent =>
    (windowsFrontLeft + windowsFrontRight +
     windowsRearLeft  + windowsRearRight) / 4;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb)    => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    lastUpdate = DateTime.now();
    for (final cb in _listeners) { cb(); }
  }

  void setDoors(bool locked)  { doorsLocked  = locked; _notify(); }
  void setEngine(bool on)     { engineOn     = on;     _notify(); }
  void setClimate(bool on)    { climateOn    = on;     _notify(); }
  void setTemp(double t)      { climateTemp  = t;      _notify(); }
  void setLights(bool on)     { lightsOn     = on;     _notify(); }

  void setWindowsFrontLeft(double v)  { windowsFrontLeft  = v; _notify(); }
  void setWindowsFrontRight(double v) { windowsFrontRight = v; _notify(); }
  void setWindowsRearLeft(double v)   { windowsRearLeft   = v; _notify(); }
  void setWindowsRearRight(double v)  { windowsRearRight  = v; _notify(); }

  void setAllWindows(double v) {
    windowsFrontLeft = windowsFrontRight = windowsRearLeft = windowsRearRight = v;
    _notify();
  }
}

// ── Screen ────────────────────────────────────────────────────

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({super.key});

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen>
    with TickerProviderStateMixin {
  final _state = VehicleControlState.instance;

  // Loading state per command
  final Map<String, bool> _loading = {};

  // Find car animation
  late AnimationController _findCtrl;
  late Animation<double> _findAnim;
  bool _finding = false;
  Timer? _findTimer;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _findCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _findAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _findCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _findCtrl.dispose();
    _findTimer?.cancel();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // ── Command simulator (заглушка с задержкой) ──────────────
  Future<void> _send(String key, Future<void> Function() action) async {
    setState(() => _loading[key] = true);
    await Future.delayed(const Duration(milliseconds: 900));
    await action();
    if (mounted) setState(() => _loading[key] = false);
    _showDone();
  }

  void _showDone() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.get('rcDone'), style: KmTextStyles.bodySmall),
      backgroundColor: KmColors.success.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
    ));
  }

  void _startFind() {
    if (_finding) return;
    setState(() => _finding = true);
    _findTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _finding = false);
    });
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    return '${d.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            KmScreenHeader(
              title:    l10n.get('remoteControl'),
              subtitle: l10n.get('remoteControlSubtitle'),
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),

            // ── Status bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _StatusBar(state: _state, l10n: l10n,
                  timeAgo: _timeAgo(_state.lastUpdate)),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  children: [

                    // ── Demo note ────────────────────────
                    _DemoNotice(l10n: l10n),
                    const SizedBox(height: 16),

                    // ── Car visual ───────────────────────
                    _CarVisual(state: _state),
                    const SizedBox(height: 20),

                    // ── Controls grid ────────────────────
                    _ControlGrid(children: [

                        // 🔐 Doors
                        _ControlCard(
                          icon: _state.doorsLocked ? '🔒' : '🔓',
                          title: l10n.get('rcDoors'),
                          status: _state.doorsLocked
                              ? l10n.get('rcDoorsLocked')
                              : l10n.get('rcDoorsUnlocked'),
                          statusColor: _state.doorsLocked
                              ? KmColors.success : KmColors.warning,
                          actionLabel: _state.doorsLocked
                              ? l10n.get('rcUnlock')
                              : l10n.get('rcLock'),
                          loading: _loading['doors'] ?? false,
                          active: !_state.doorsLocked,
                          onTap: () => _send('doors', () async {
                            _state.setDoors(!_state.doorsLocked);
                          }),
                        ),

                        // 🔑 Engine
                        _ControlCard(
                          icon: '🔑',
                          title: l10n.get('rcEngine'),
                          status: _state.engineOn
                              ? l10n.get('rcEngineOn')
                              : l10n.get('rcEngineOff'),
                          statusColor: _state.engineOn
                              ? KmColors.success : KmColors.textMuted,
                          actionLabel: _state.engineOn
                              ? l10n.get('rcEngineStop')
                              : l10n.get('rcEngineStart'),
                          loading: _loading['engine'] ?? false,
                          active: _state.engineOn,
                          danger: _state.engineOn,
                          onTap: () => _send('engine', () async {
                            _state.setEngine(!_state.engineOn);
                          }),
                        ),

                        // 🌡️ Climate
                        _ControlCard(
                          icon: '🌡️',
                          title: l10n.get('rcClimate'),
                          status: _state.climateOn
                              ? '${_state.climateTemp.toInt()}°C'
                              : l10n.get('rcClimateOff'),
                          statusColor: _state.climateOn
                              ? KmColors.info : KmColors.textMuted,
                          actionLabel: _state.climateOn ? l10n.get('rcClimateOff2') : l10n.get('rcClimateOn'),
                          loading: _loading['climate'] ?? false,
                          active: _state.climateOn,
                          onTap: () => _send('climate', () async {
                            _state.setClimate(!_state.climateOn);
                          }),
                          // Long press = temperature
                          extraContent: _state.climateOn
                              ? _TempSlider(
                                  value: _state.climateTemp,
                                  onChanged: (v) {
                                    _state.setTemp(v);
                                  },
                                )
                              : null,
                        ),

                        // 💡 Lights
                        _ControlCard(
                          icon: '💡',
                          title: l10n.get('rcLights'),
                          status: _state.lightsOn
                              ? l10n.get('rcLightsOn')
                              : l10n.get('rcLightsOff'),
                          statusColor: _state.lightsOn
                              ? KmColors.warning : KmColors.textMuted,
                          actionLabel: _state.lightsOn ? l10n.get('rcLightsOff2') : l10n.get('rcLightsOn2'),
                          loading: _loading['lights'] ?? false,
                          active: _state.lightsOn,
                          onTap: () => _send('lights', () async {
                            _state.setLights(!_state.lightsOn);
                          }),
                        ),

                        // 🪟 Windows — with percent control
                        _WindowsCard(
                          state: _state,
                          loading: _loading['windows'] ?? false,
                          l10n: l10n,
                          onSend: _send,
                        ),

                        // 🔍 Find car
                        _ControlCard(
                          icon: '🔍',
                          title: l10n.get('rcFind'),
                          status: _finding
                              ? l10n.get('rcFindActive')
                              : l10n.get('rcFindSubtitle'),
                          statusColor: _finding
                              ? KmColors.accent : KmColors.textMuted,
                          actionLabel: l10n.get('rcFind'),
                          loading: false,
                          active: _finding,
                          onTap: _startFind,
                          pulseAnim: _finding ? _findAnim : null,
                        ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Windows Card with percent sliders ────────────────────────

class _WindowsCard extends StatefulWidget {
  const _WindowsCard({
    required this.state,
    required this.loading,
    required this.l10n,
    required this.onSend,
  });
  final VehicleControlState state;
  final bool loading;
  final AppLocalizations l10n;
  final Future<void> Function(String, Future<void> Function()) onSend;

  @override
  State<_WindowsCard> createState() => _WindowsCardState();
}

class _WindowsCardState extends State<_WindowsCard> {
  bool _expanded = false;

  Color get _color => widget.state.windowsClosed
      ? KmColors.success : KmColors.info;

  @override
  Widget build(BuildContext context) {
    final s   = widget.state;
    final l10n = widget.l10n;
    final avg  = s.windowsAvgPercent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: !s.windowsClosed
            ? KmColors.info.withValues(alpha: 0.05)
            : KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
          color: !s.windowsClosed ? KmColors.info : KmColors.border,
          width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(children: [
            Text(s.windowsClosed ? '🪟' : '🌬️',
                style: const TextStyle(fontSize: 20)),
            const Spacer(),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: !s.windowsClosed ? KmColors.info : KmColors.surface3,
                shape: BoxShape.circle),
            ),
          ]),
          const SizedBox(height: 6),
          Text(l10n.get('rcWindows'),
              style: KmTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600,
                      color: KmColors.textPrimary)),
          const SizedBox(height: 2),
          Text(
            s.windowsClosed
                ? l10n.get('rcWindowsClosed')
                : '${avg.toInt()}%',
            style: KmTextStyles.caption.copyWith(color: _color)),

          const SizedBox(height: 8),

          // Expand/collapse toggle
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: KmColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(KmRadius.sm),
                border: Border.all(
                    color: KmColors.info.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? '▲' : l10n.get('rcWindowsPercent'),
                    style: const TextStyle(fontFamily: 'DMSans',
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: KmColors.info),
                  ),
                ],
              ),
            ),
          ),

          // Sliders (expanded)
          if (_expanded) ...[
            const SizedBox(height: 10),
            // All windows at once
            _WindowSlider(
              label: l10n.get('rcAllWindows'),
              value: avg,
              onChanged: (v) {
                widget.onSend('windows_all', () async => s.setAllWindows(v));
              },
            ),
            const SizedBox(height: 6),
            // Individual
            _WindowSlider(label: 'FL', value: s.windowsFrontLeft,
                onChanged: (v) => widget.onSend('wfl', () async => s.setWindowsFrontLeft(v))),
            _WindowSlider(label: 'FR', value: s.windowsFrontRight,
                onChanged: (v) => widget.onSend('wfr', () async => s.setWindowsFrontRight(v))),
            _WindowSlider(label: 'RL', value: s.windowsRearLeft,
                onChanged: (v) => widget.onSend('wrl', () async => s.setWindowsRearLeft(v))),
            _WindowSlider(label: 'RR', value: s.windowsRearRight,
                onChanged: (v) => widget.onSend('wrr', () async => s.setWindowsRearRight(v))),
          ],
        ],
      ),
    );
  }
}

class _WindowSlider extends StatelessWidget {
  const _WindowSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 26,
            child: Text(label, style: KmTextStyles.caption
                .copyWith(fontSize: 10))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: KmColors.info,
              inactiveTrackColor: KmColors.surface3,
              thumbColor: KmColors.info,
              overlayColor: KmColors.info.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0, max: 100, divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(width: 32,
            child: Text('${value.toInt()}%',
                style: KmTextStyles.caption.copyWith(
                    color: KmColors.info, fontSize: 10),
                textAlign: TextAlign.right)),
      ]),
    );
  }
}

// ── Two-column grid with variable height rows ─────────────────

class _ControlGrid extends StatelessWidget {
  const _ControlGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final a = children[i];
      final b = i + 1 < children.length ? children[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// ── Status bar ────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.state,
    required this.l10n,
    required this.timeAgo,
  });
  final VehicleControlState state;
  final AppLocalizations l10n;
  final String timeAgo;

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
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
            color: KmColors.success, shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.get('rcVehicleReady'),
            style: KmTextStyles.bodySmall
                .copyWith(color: KmColors.success)),
        const Spacer(),
        Text('${l10n.get('rcLastUpdate')}: $timeAgo',
            style: KmTextStyles.caption),
      ]),
    );
  }
}

// ── Demo notice ───────────────────────────────────────────────

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0F5A8FE0),
        borderRadius: BorderRadius.circular(KmRadius.sm),
        border: Border.all(color: const Color(0x335A8FE0), width: 0.5),
      ),
      child: Row(children: [
        const Text('ℹ️', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(l10n.get('rcDemoNote'),
              style: KmTextStyles.caption),
        ),
      ]),
    );
  }
}

// ── Car visual ────────────────────────────────────────────────

class _CarVisual extends StatelessWidget {
  const _CarVisual({required this.state});
  final VehicleControlState state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow when engine on
        if (state.engineOn)
          Container(
            width: 260, height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(80),
              boxShadow: [
                BoxShadow(
                  color: KmColors.success.withValues(alpha: 0.15),
                  blurRadius: 40, spreadRadius: 10,
                ),
              ],
            ),
          ),
        // Car image
        SizedBox(
          height: 120,
          child: Image.asset(
            'assets/images/km_jaqin.png',
            fit: BoxFit.contain,
          ),
        ),
        // Lock indicator
        Positioned(
          top: 4, right: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: state.doorsLocked
                  ? KmColors.success.withValues(alpha: 0.15)
                  : KmColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.doorsLocked ? KmColors.success : KmColors.warning,
                width: 0.5,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                state.doorsLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 11,
                color: state.doorsLocked ? KmColors.success : KmColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                state.doorsLocked ? '🔒' : '🔓',
                style: const TextStyle(fontSize: 10),
              ),
            ]),
          ),
        ),
        // Lights indicator
        if (state.lightsOn)
          Positioned(
            bottom: 8, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KmColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KmColors.warning, width: 0.5),
              ),
              child: const Text('💡', style: TextStyle(fontSize: 10)),
            ),
          ),
        // Engine indicator
        if (state.engineOn)
          Positioned(
            bottom: 8, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KmColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KmColors.success, width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: KmColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('ON',
                    style: KmTextStyles.caption
                        .copyWith(color: KmColors.success, fontSize: 9)),
              ]),
            ),
          ),
      ],
    );
  }
}

// ── Control card ──────────────────────────────────────────────

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.actionLabel,
    required this.loading,
    required this.active,
    required this.onTap,
    this.danger = false,
    this.extraContent,
    this.pulseAnim,
  });

  final String icon;
  final String title;
  final String status;
  final Color statusColor;
  final String actionLabel;
  final bool loading;
  final bool active;
  final bool danger;
  final VoidCallback onTap;
  final Widget? extraContent;
  final Animation<double>? pulseAnim;

  @override
  Widget build(BuildContext context) {
    final borderColor = danger
        ? KmColors.error
        : active
            ? KmColors.accent
            : KmColors.border;
    final bgColor = danger
        ? KmColors.error.withValues(alpha: 0.07)
        : active
            ? KmColors.accent.withValues(alpha: 0.05)
            : KmColors.surface2;
    final btnColor = danger ? KmColors.error : KmColors.accent;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: active ? statusColor : KmColors.surface3,
                shape: BoxShape.circle,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(title, style: KmTextStyles.bodySmall
              .copyWith(fontWeight: FontWeight.w600,
                  color: KmColors.textPrimary)),
          const SizedBox(height: 2),
          Text(status, style: KmTextStyles.caption
              .copyWith(color: statusColor)),
          if (extraContent != null) ...[
            const SizedBox(height: 6),
            extraContent!,
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: loading
                ? Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: btnColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(KmRadius.sm),
                    ),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: btnColor),
                    ),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: btnColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(KmRadius.sm),
                        border: Border.all(
                            color: btnColor.withValues(alpha: 0.3),
                            width: 0.5),
                      ),
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: btnColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );

    if (pulseAnim != null) {
      card = AnimatedBuilder(
        animation: pulseAnim!,
        builder: (_, child) => Transform.scale(
          scale: 0.98 + 0.02 * pulseAnim!.value,
          child: child,
        ),
        child: card,
      );
    }

    return card;
  }
}

// ── Temperature slider ────────────────────────────────────────

class _TempSlider extends StatelessWidget {
  const _TempSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () => onChanged((value - 1).clamp(16, 30)),
        child: const Text('−',
            style: TextStyle(
                fontFamily: 'DMSans', fontSize: 18,
                color: KmColors.info, fontWeight: FontWeight.w700)),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: KmColors.info,
            inactiveTrackColor: KmColors.surface3,
            thumbColor: KmColors.info,
            overlayColor: KmColors.info.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: 16, max: 30, divisions: 14,
            onChanged: onChanged,
          ),
        ),
      ),
      GestureDetector(
        onTap: () => onChanged((value + 1).clamp(16, 30)),
        child: const Text('+',
            style: TextStyle(
                fontFamily: 'DMSans', fontSize: 18,
                color: KmColors.info, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}