import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/firestore_vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'scan_screen.dart';

// ============================================================
// KM DRIVE — Diagnostics Screen v2
//
// Логика:
//  • Если сканирование ещё не проводилось — показывается
//    встроенный экран запуска (idle), точно как ScanScreen.
//  • Кнопка «Начать» — запускает сканирование прямо здесь.
//  • После сканирования — результаты OBD + кольцо здоровья.
//  • Кнопка «Сканировать снова» сбрасывает и повторяет.
//  • Результаты синхронизированы с ScanResultsNotifier,
//    поэтому открытие с главной (ScanScreen) тоже отражается.
// ============================================================

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with TickerProviderStateMixin {
  final _repo = FirestoreVehicleRepository();

  VehicleModel? _vehicle;
  List<DiagnosticSystem> _systems = [];
  bool _dataLoading = true;

  // ── Сканирование ─────────────────────────────────────────
  _ScanPhase _phase = _ScanPhase.idle;
  double _progress = 0;
  final List<ScanResult> _results = [];

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;

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

    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );

    // Слушаем обновления из внешнего ScanScreen (с главной)
    ScanResultsNotifier.onResultsUpdated = () {
      if (mounted && ScanResultsNotifier.lastResults != null) {
        _applyExternalResults(ScanResultsNotifier.lastResults!);
      }
    };

    // Если уже есть результаты — показываем сразу
    if (ScanResultsNotifier.lastResults != null) {
      _results.addAll(ScanResultsNotifier.lastResults!);
      _phase = _ScanPhase.done;
      _progress = 1.0;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getVehicle(),
      _repo.getDiagnostics(),
    ]);
    if (mounted) {
      setState(() {
        _vehicle = results[0] as VehicleModel;
        _systems = results[1] as List<DiagnosticSystem>;
        _dataLoading = false;
      });
      if (_phase == _ScanPhase.done) {
        _scoreAnimController.forward();
      }
    }
  }

  void _applyExternalResults(List<ScanResult> res) {
    setState(() {
      _results.clear();
      _results.addAll(res);
      _phase = _ScanPhase.done;
      _progress = 1.0;
    });
    _scoreAnimController
      ..reset()
      ..forward();
  }

  List<String> _systemNames(AppLocalizations l10n) => [
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
    _scoreAnimController.reset();

    for (int i = 0; i < systems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
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
      ScanResultsNotifier.lastResults = List.from(_results);
      setState(() {
        _phase = _ScanPhase.done;
        _progress = 1.0;
      });
      _scoreAnimController.forward();
    }
  }

  void _reset() {
    setState(() {
      _phase = _ScanPhase.idle;
      _results.clear();
      _progress = 0;
    });
    _scoreAnimController.reset();
    ScanResultsNotifier.lastResults = null;
  }

  @override
  void dispose() {
    if (ScanResultsNotifier.onResultsUpdated != null) {
      ScanResultsNotifier.onResultsUpdated = null;
    }
    _pulseCtrl.dispose();
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dataLoading) {
      return const Scaffold(
        backgroundColor: KmColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: KmColors.accent, strokeWidth: 1.5),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final systems = _systemNames(l10n);

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            KmScreenHeader(
              title: l10n.get('diagnosticsTitle'),
              subtitle: l10n.get('diagnosticsSubtitle'),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: Column(
                  children: [

                    // ── Индикатор сканирования ────────────
                    _ScanRing(
                      phase: _phase,
                      progress: _progress,
                      pulse: _pulse,
                      score: _vehicle!.healthScore,
                      scoreAnim: _scoreAnimation,
                      l10n: l10n,
                    ),

                    const SizedBox(height: 20),

                    // ── Idle: кнопка запуска ──────────────
                    if (_phase == _ScanPhase.idle) ...[
                      Text(
                        l10n.get('scanPrompt'),
                        style: KmTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startScan(systems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KmColors.accent,
                            foregroundColor: KmColors.background,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(KmRadius.md),
                            ),
                          ),
                          child: Text(
                            l10n.get('scanStart'),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── Scanning / Done: список результатов
                    if (_phase != _ScanPhase.idle) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KmSectionLabel(
                            l10n.get('scanResults')),
                      ),
                      ..._results.map((r) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: _ResultTile(
                                result: r, l10n: l10n),
                          )),

                      // Текущий сканируемый
                      if (_phase == _ScanPhase.scanning &&
                          _results.length < systems.length)
                        _ScanningTile(
                            system: systems[_results.length]),
                    ],

                    // ── Done: итог + кнопки ───────────────
                    if (_phase == _ScanPhase.done) ...[
                      const SizedBox(height: 8),
                      _ScanSummaryBanner(
                          results: _results, l10n: l10n),
                      const SizedBox(height: 16),

                      // Системы автомобиля
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KmSectionLabel(
                            l10n.get('systemsTitle')),
                      ),
                      ..._systems.asMap().entries.map((e) =>
                          Column(children: [
                            _SystemRow(system: e.value),
                            if (e.key < _systems.length - 1)
                              const KmDivider(),
                          ])),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: KmColors.accent,
                                width: 0.5),
                            foregroundColor: KmColors.accent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  KmRadius.md),
                            ),
                          ),
                          child: Text(
                            l10n.get('scanAgain'),
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: KmColors.accent,
                            ),
                          ),
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

// ══════════════════════════════════════════════════════════════
// Виджеты
// ══════════════════════════════════════════════════════════════

// ── Центральное кольцо — idle/scanning/done ───────────────────

class _ScanRing extends StatelessWidget {
  const _ScanRing({
    required this.phase,
    required this.progress,
    required this.pulse,
    required this.score,
    required this.scoreAnim,
    required this.l10n,
  });

  final _ScanPhase phase;
  final double progress;
  final Animation<double> pulse;
  final double score;
  final Animation<double> scoreAnim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Пульсирующий ореол при сканировании
          if (phase == _ScanPhase.scanning)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) {
                final alpha = (60 * pulse.value).round();
                return Container(
                  width: 180 * pulse.value,
                  height: 180 * pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Color.fromARGB(alpha, 0xC8, 0xA9, 0x6E),
                      width: 1,
                    ),
                  ),
                );
              },
            ),

          // Кольцо здоровья после завершения
          if (phase == _ScanPhase.done)
            AnimatedBuilder(
              animation: scoreAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(180, 180),
                painter: _RingPainter(
                  progress: (score / 100) * scoreAnim.value,
                  score: score,
                ),
              ),
            ),

          // Центр
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: phase == _ScanPhase.done
                    ? KmColors.success
                    : KmColors.accent,
                width: 1.5,
              ),
              color: KmColors.surface2,
            ),
            child: Center(
              child: phase == _ScanPhase.idle
                  ? const Text('📡',
                      style: TextStyle(fontSize: 36))
                  : phase == _ScanPhase.done
                      ? AnimatedBuilder(
                          animation: scoreAnim,
                          builder: (_, __) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(score * scoreAnim.value).toInt()}',
                                style: KmTextStyles.numeralLarge,
                              ),
                              Text(
                                l10n
                                    .get('vehicleHealth')
                                    .toUpperCase(),
                                style: KmTextStyles.labelSmall,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: KmTextStyles.displaySmall
                                  .copyWith(
                                      color: KmColors.accent),
                            ),
                            const Text(
                              '...',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                color: KmColors.textMuted,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(
      {required this.progress, required this.score});
  final double progress;
  final double score;

  Color get _trackColor {
    if (score >= 75) return KmColors.success;
    if (score >= 45) return KmColors.warning;
    return KmColors.error;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = KmColors.surface3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    if (progress <= 0) return;

    final rect =
        Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [KmColors.accent, _trackColor],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}

// ── Итоговый баннер ───────────────────────────────────────────

class _ScanSummaryBanner extends StatelessWidget {
  const _ScanSummaryBanner(
      {required this.results, required this.l10n});
  final List<ScanResult> results;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final okCount =
        results.where((r) => r.status == ScanStatus.ok).length;
    final warnCount = results
        .where((r) => r.status == ScanStatus.warning)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warnCount > 0
            ? const Color(0xFF181410)
            : const Color(0xFF0F1A12),
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
          color: warnCount > 0
              ? const Color(0x40C8A96E)
              : const Color(0x4059C172),
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Text(warnCount > 0 ? '⚠️' : '✅',
            style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('scanDone'),
                  style: KmTextStyles.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '$okCount ${l10n.get('scanOk')} · '
                '$warnCount ${l10n.get('scanWarn')}',
                style: KmTextStyles.caption,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Плитка результата ─────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile(
      {required this.result, required this.l10n});
  final ScanResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isWarn = result.status == ScanStatus.warning;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarn
            ? const Color(0xFF1A1510)
            : KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(
          color: isWarn
              ? const Color(0x40C8A96E)
              : KmColors.border,
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Text(
          isWarn ? '⚠️' : '✓',
          style: TextStyle(
            fontSize: 14,
            color:
                isWarn ? KmColors.warning : KmColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.system,
                  style: KmTextStyles.bodySmall),
              if (result.note != null) ...[
                const SizedBox(height: 2),
                Text(l10n.get(result.note!),
                    style: KmTextStyles.caption),
              ],
            ],
          ),
        ),
        if (result.code != null)
          Text(
            result.code!,
            style: KmTextStyles.caption.copyWith(
              color: KmColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
      ]),
    );
  }
}

// ── Плитка «сканируется» ──────────────────────────────────────

class _ScanningTile extends StatelessWidget {
  const _ScanningTile({required this.system});
  final String system;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              color: KmColors.accent, strokeWidth: 1.5),
        ),
        const SizedBox(width: 12),
        Text(system, style: KmTextStyles.bodySmall),
      ]),
    );
  }
}

// ── Строка системы автомобиля ─────────────────────────────────

class _SystemRow extends StatelessWidget {
  const _SystemRow({required this.system});
  final DiagnosticSystem system;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: Text(system.icon,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get(system.name),
                  style: KmTextStyles.bodyMedium),
              if (system.note != null) ...[
                const SizedBox(height: 2),
                Text(l10n.get(system.note!),
                    style: KmTextStyles.caption),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: KmProgressBar(
              value: system.healthPercent / 100),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            KmFormatters.percent(system.healthPercent),
            style: KmTextStyles.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ]),
    );
  }
}

enum _ScanPhase { idle, scanning, done }