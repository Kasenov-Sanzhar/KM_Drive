import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Scan Screen
// Результаты отображаются на странице диагностики
// ============================================================

// Глобальное хранилище результатов сканирования
// (передаётся в DiagnosticsScreen через callback)
class ScanResultsNotifier {
  static List<ScanResult>? lastResults;
  static VoidCallback? onResultsUpdated;
}

class ScanResult {
  const ScanResult({
    required this.system,
    required this.status,
    this.code,
    this.note,
  });
  final String system;
  final ScanStatus status;
  final String? code;
  final String? note;
}

enum ScanStatus { ok, warning }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.onNavigateToDiagnostics});

  // ✅ Callback из AppShell для переключения таба на Диагностику
  final VoidCallback? onNavigateToDiagnostics;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  _ScanPhase _phase = _ScanPhase.idle;
  double _progress = 0;
  final List<ScanResult> _results = [];
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<String> _systems(AppLocalizations l10n) => [
    l10n.get('sysEngine'),
    l10n.get('sysTransmission'),
    l10n.get('sysAbs'),
    l10n.get('sysClimate'),
    l10n.get('sysAirbags'),
    l10n.get('sysElectronics'),
    l10n.get('sysSuspension'),
    l10n.get('sysExhaust'),
  ];

  Future<void> _startScan(List<String> systems) async {
    setState(() {
      _phase = _ScanPhase.scanning;
      _progress = 0;
      _results.clear();
    });

    for (int i = 0; i < systems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / systems.length;
        _results.add(ScanResult(
          system: systems[i],
          status: (i == 2 || i == 5) ? ScanStatus.warning : ScanStatus.ok,
          code: i == 2 ? 'C0045' : i == 5 ? 'B2799' : null,
          note: i == 2 ? 'sysNoteAbs' : i == 5 ? 'sysNoteBcm' : null,
        ));
      });
    }

    if (mounted) {
      // ✅ Сохраняем результаты для DiagnosticsScreen
      ScanResultsNotifier.lastResults = List.from(_results);
      ScanResultsNotifier.onResultsUpdated?.call();
      setState(() => _phase = _ScanPhase.done);
    }
  }

  void _reset() => setState(() {
        _phase = _ScanPhase.idle;
        _results.clear();
        _progress = 0;
      });

  void _goToDiagnostics() {
    // Закрываем ScanScreen, затем переключаем таб на Диагностику
    Navigator.of(context).pop();
    widget.onNavigateToDiagnostics?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final systems = _systems(l10n);

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            KmScreenHeader(
              title: l10n.get('scanTitle'),
              subtitle: l10n.get('scanSubtitle'),
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    _ScanIndicator(phase: _phase, progress: _progress, pulse: _pulse),
                    const SizedBox(height: 24),

                    if (_phase == _ScanPhase.idle) ...[
                      Text(l10n.get('scanPrompt'),
                          style: KmTextStyles.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startScan(systems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KmColors.accent,
                            foregroundColor: KmColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(KmRadius.md)),
                          ),
                          child: Text(l10n.get('scanStart'),
                              style: const TextStyle(
                                  fontFamily: 'DMSans', fontSize: 12,
                                  fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                        ),
                      ),
                    ],

                    if (_phase != _ScanPhase.idle) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KmSectionLabel(l10n.get('scanResults')),
                      ),
                      ..._results.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ResultTile(result: r, l10n: l10n),
                          )),
                      if (_phase == _ScanPhase.scanning &&
                          _results.length < systems.length)
                        _ScanningTile(system: systems[_results.length]),
                    ],

                    if (_phase == _ScanPhase.done) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: KmColors.surface2,
                          borderRadius: BorderRadius.circular(KmRadius.lg),
                          border: Border.all(color: KmColors.border, width: 0.5),
                        ),
                        child: Row(children: [
                          const Text('🎯', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.get('scanDone'), style: KmTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${_results.where((r) => r.status == ScanStatus.ok).length} ${l10n.get('scanOk')} · '
                                  '${_results.where((r) => r.status == ScanStatus.warning).length} ${l10n.get('scanWarn')}',
                                  style: KmTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      // ✅ Кнопка перейти в диагностику
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goToDiagnostics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KmColors.accent,
                            foregroundColor: KmColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(KmRadius.md)),
                          ),
                          child: Text(l10n.get('scanViewDiag'),
                              style: const TextStyle(
                                  fontFamily: 'DMSans', fontSize: 12,
                                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KmColors.accent, width: 0.5),
                            foregroundColor: KmColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(KmRadius.md)),
                          ),
                          child: Text(l10n.get('scanAgain'),
                              style: const TextStyle(
                                  fontFamily: 'DMSans', fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2, color: KmColors.accent)),
                        ),
                      ),
                    ],
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

// ── Виджеты ──────────────────────────────────────────────────

class _ScanIndicator extends StatelessWidget {
  const _ScanIndicator({
    required this.phase,
    required this.progress,
    required this.pulse,
  });

  final _ScanPhase phase;
  final double progress;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: 120, height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (phase == _ScanPhase.scanning)
              AnimatedBuilder(
                animation: pulse,
                builder: (_, __) {
                  final alpha = (60 * pulse.value).round();
                  return Container(
                    width: 120 * pulse.value,
                    height: 120 * pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.fromARGB(alpha, 0xC8, 0xA9, 0x6E),
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: phase == _ScanPhase.done ? KmColors.success : KmColors.accent,
                  width: 1.5,
                ),
                color: KmColors.surface2,
              ),
              child: Center(
                child: phase == _ScanPhase.idle
                    ? const Text('📡', style: TextStyle(fontSize: 32))
                    : phase == _ScanPhase.done
                        ? const Text('✅', style: TextStyle(fontSize: 32))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(progress * 100).toInt()}%',
                                  style: KmTextStyles.displaySmall
                                      .copyWith(color: KmColors.accent)),
                              const Text('...', style: TextStyle(
                                  fontFamily: 'DMSans', fontSize: 10,
                                  color: KmColors.textMuted)),
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

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.l10n});
  final ScanResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isWarn = result.status == ScanStatus.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarn ? const Color(0xFF1A1510) : KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(
          color: isWarn ? const Color(0x40C8A96E) : KmColors.border,
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Text(
          isWarn ? '⚠️' : '✓',
          style: TextStyle(
              fontSize: 14,
              color: isWarn ? KmColors.warning : KmColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.system, style: KmTextStyles.bodySmall),
              if (result.note != null) ...[
                const SizedBox(height: 2),
                Text(l10n.get(result.note!), style: KmTextStyles.caption),
              ],
            ],
          ),
        ),
        if (result.code != null)
          Text(result.code!,
              style: KmTextStyles.caption.copyWith(
                  color: KmColors.warning, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ScanningTile extends StatelessWidget {
  const _ScanningTile({required this.system});
  final String system;

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
        const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(color: KmColors.accent, strokeWidth: 1.5),
        ),
        const SizedBox(width: 12),
        Text(system, style: KmTextStyles.bodySmall),
      ]),
    );
  }
}

enum _ScanPhase { idle, scanning, done }