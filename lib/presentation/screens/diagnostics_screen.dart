import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'scan_screen.dart';

// ============================================================
// KM DRIVE — Diagnostics Screen
// Показывает результаты OBD сканирования
// ============================================================

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MockVehicleRepository();
  VehicleModel? _vehicle;
  List<DiagnosticSystem> _systems = [];
  List<ScanResult>? _scanResults;
  bool _loading = true;

  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );
    // ✅ Подписываемся на обновления из ScanScreen
    ScanResultsNotifier.onResultsUpdated = () {
      if (mounted) {
        setState(() {
          _scanResults = ScanResultsNotifier.lastResults;
        });
      }
    };
    // Проверяем есть ли уже результаты
    _scanResults = ScanResultsNotifier.lastResults;
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
        _loading = false;
      });
      _scoreAnimController.forward();
    }
  }

  @override
  void dispose() {
    // Снимаем подписку при уничтожении
    if (ScanResultsNotifier.onResultsUpdated != null) {
      ScanResultsNotifier.onResultsUpdated = null;
    }
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: KmColors.background,
        body: Center(child: CircularProgressIndicator(
            color: KmColors.accent, strokeWidth: 1.5)),
      );
    }

    final l10n = AppLocalizations.of(context);

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
            _HealthRing(
              score: _vehicle!.healthScore,
              animation: _scoreAnimation,
            ),
            const SizedBox(height: 16),
            // ✅ Если есть результаты сканирования — показываем их
            Expanded(
              child: _scanResults != null
                  ? _ScanResultsList(
                      results: _scanResults!,
                      systems: _systems,
                      l10n: l10n,
                    )
                  : _SystemsList(systems: _systems),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Кольцо здоровья ─────────────────────────────────────────

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score, required this.animation});

  final double score;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 180, height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: _RingPainter(
                progress: (score / 100) * animation.value,
                score: score,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(score * animation.value).toInt()}',
                    style: KmTextStyles.numeralLarge),
                Text(l10n.get('vehicleHealth').toUpperCase(),
                    style: KmTextStyles.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.score});
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

    canvas.drawCircle(center, radius,
      Paint()..color = KmColors.surface3..style = PaintingStyle.stroke..strokeWidth = 9);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [KmColors.accent, _trackColor],
        ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ── Список результатов сканирования ─────────────────────────

class _ScanResultsList extends StatelessWidget {
  const _ScanResultsList({
    required this.results,
    required this.systems,
    required this.l10n,
  });

  final List<ScanResult> results;
  final List<DiagnosticSystem> systems;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final okCount   = results.where((r) => r.status == ScanStatus.ok).length;
    final warnCount = results.where((r) => r.status == ScanStatus.warning).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        // Баннер — результат последнего сканирования
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
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
                  Text(l10n.get('scanDone'), style: KmTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    '$okCount ${l10n.get('scanOk')} · $warnCount ${l10n.get('scanWarn')}',
                    style: KmTextStyles.caption,
                  ),
                ],
              ),
            ),
            // Кнопка обновить
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x20C8A96E),
                  borderRadius: BorderRadius.circular(KmRadius.sm),
                  border: Border.all(color: const Color(0x40C8A96E), width: 0.5),
                ),
                child: Text(l10n.get('scanAgain').replaceAll('\n', ' '),
                    style: const TextStyle(
                        fontFamily: 'DMSans', fontSize: 9,
                        color: KmColors.accent, letterSpacing: 0.5)),
              ),
            ),
          ]),
        ),

        const KmSectionLabel('OBD'),
        ...results.map((r) {
          final isWarn = r.status == ScanStatus.warning;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
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
                Text(isWarn ? '⚠️' : '✓',
                    style: TextStyle(
                        fontSize: 14,
                        color: isWarn ? KmColors.warning : KmColors.success)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.system, style: KmTextStyles.bodySmall),
                      if (r.note != null) ...[
                        const SizedBox(height: 2),
                        Text(l10n.get(r.note!), style: KmTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                if (r.code != null)
                  Text(r.code!,
                      style: KmTextStyles.caption.copyWith(
                          color: KmColors.warning, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }),

        const SizedBox(height: 16),
        KmSectionLabel(l10n.get('systemsTitle')),
        ...systems.asMap().entries.map((e) => Column(
              children: [
                _SystemRow(system: e.value),
                if (e.key < systems.length - 1) const KmDivider(),
              ],
            )),
      ],
    );
  }
}

// ── Стандартный список систем (без сканирования) ─────────────

class _SystemsList extends StatelessWidget {
  const _SystemsList({required this.systems});
  final List<DiagnosticSystem> systems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: systems.length + 1,
      separatorBuilder: (_, __) => const KmDivider(),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KmSectionLabel(l10n.get('systemsTitle')),
          );
        }
        return _SystemRow(system: systems[i - 1]);
      },
    );
  }
}

class _SystemRow extends StatelessWidget {
  const _SystemRow({required this.system});
  final DiagnosticSystem system;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: Text(system.icon, style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(system.name, style: KmTextStyles.bodyMedium),
              if (system.note != null) ...[
                const SizedBox(height: 2),
                Text(system.note!, style: KmTextStyles.caption),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: KmProgressBar(value: system.healthPercent / 100),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(KmFormatters.percent(system.healthPercent),
              style: KmTextStyles.bodySmall, textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}