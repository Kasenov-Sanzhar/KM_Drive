import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ============================================================
// KM DRIVE — KmCarVisual
// KM Jaqin: премиальный кроссовер с coupé-линией крыши
// Длинный капот, покатая крыша, острая плечевая линия, мускулистые арки
// ============================================================

class KmCarVisual extends StatefulWidget {
  const KmCarVisual({
    super.key,
    required this.modelName,
    required this.plateNumber,
    required this.year,
    this.height = 200,
  });

  final String modelName;
  final String plateNumber;
  final int year;
  final double height;

  @override
  State<KmCarVisual> createState() => _KmCarVisualState();
}

class _KmCarVisualState extends State<KmCarVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(children: [
        Positioned(
          top: 10, right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.modelName.toUpperCase(),
                style: KmTextStyles.labelMedium.copyWith(
                  color: KmColors.accent, letterSpacing: 2.5, fontSize: 11,
                ),
              ),
              Text(
                '${widget.year} · ${widget.plateNumber}',
                style: KmTextStyles.caption,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0, left: 20, right: 20,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (_, __) => Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color.fromARGB(
                      (28 * _glow.value).round(), 0xC8, 0xA9, 0x6E),
                    Colors.transparent,
                  ],
                  radius: 0.65,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14, left: 0, right: 0,
          child: LayoutBuilder(
            builder: (_, c) => CustomPaint(
              size: Size(c.maxWidth, widget.height - 30),
              painter: const _JaqinSilhouettePainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 12, left: 16, right: 16,
          child: Container(
            height: 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent, Color(0x44C8A96E), Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Силуэт KM Jaqin по описанию:
/// Длинный капот, короткие свесы | Плавно ниспадающая крыша (coupé)
/// Мощная корма с покатым задним стеклом | Острая плечевая линия
/// Выраженные колёсные арки | Линия Jaqin на задних стойках
/// Низкая широкая посадка | Агрессивный перед | Светодиодная полоса сзади
class _JaqinSilhouettePainter extends CustomPainter {
  const _JaqinSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const margin = 0.06;
    final L = w * margin;
    final R = w * (1 - margin);
    final cw = R - L;

    final gY = h - 2.0;
    final sillY = h - 42.0;
    final beltY = h - 88.0;
    final roofPeakY = h - 132.0;
    final roofRearY = h - 118.0;

    final fWx = L + cw * 0.78;
    final rWx = L + cw * 0.22;
    const wr = 26.0;
    const ar = wr + 10.0;

    // Тень
    canvas.drawOval(
      Rect.fromLTRB(rWx + wr, gY - 1, fWx - wr, gY + 5),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Кузов: длинный капот, coupé-крыша, мощная корма ─────
    final body = Path();
    body.moveTo(L + 6, gY - wr + 2);
    body.lineTo(L + 2, sillY + 2);
    // Задняя часть: мощные крылья, расширяющиеся книзу
    body.cubicTo(L - 2, sillY - 2, L + 8, beltY + 18, L + 28, beltY + 2);
    // Линия Jaqin: характерный изгиб на задней стойке
    body.cubicTo(L + 40, roofRearY + 8, L + 48, roofRearY - 4, L + 58, roofRearY);
    // Coupé-крыша: плавно ниспадающая
    body.cubicTo(L + 90, roofRearY - 6, L + 130, roofPeakY + 4, R - 55, roofPeakY);
    body.cubicTo(R - 38, roofPeakY + 6, R - 18, beltY + 14, R - 8, beltY + 4);
    // Агрессивный наклон капота
    body.cubicTo(R + 2, beltY - 6, R + 2, sillY + 2, R, sillY);
    body.lineTo(R - 2, gY - wr - 2);
    // Нижняя линия: порог
    body.lineTo(fWx + ar + 2, gY - 2);
    body.arcTo(
      Rect.fromCircle(center: Offset(fWx, gY), radius: ar + 4),
      0.06, -(math.pi - 0.12), false,
    );
    body.lineTo(rWx + ar + 2, gY - 2);
    body.arcTo(
      Rect.fromCircle(center: Offset(rWx, gY), radius: ar + 4),
      0.06, -(math.pi - 0.12), false,
    );
    body.lineTo(L + 6, gY - wr + 2);
    body.close();

    canvas.drawPath(body, Paint()..color = const Color(0xFF1A1C2A));
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF2C2F44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── Мускулистые накладки арок ───────────────────────────
    for (final cx in [fWx, rWx]) {
      canvas.drawPath(
        Path()..addArc(
          Rect.fromCircle(center: Offset(cx, gY), radius: ar + 6),
          math.pi + 0.2, -(math.pi - 0.4),
        ),
        Paint()
          ..color = const Color(0xFF0B0C12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Стёкла (покатое заднее, лобовое) ────────────────────
    final glFill = Paint()..color = const Color(0xFF0C0E1C);
    final glAccent = Paint()..color = const Color(0x0AC8A96E);
    final glStroke = Paint()
      ..color = const Color(0x18C8A96E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Заднее окно (покатое, coupé)
    final rearGlass = Path()
      ..moveTo(L + 42, roofRearY + 6)
      ..cubicTo(L + 52, roofRearY + 2, L + 58, roofRearY, L + 62, beltY + 10)
      ..lineTo(L + 32, beltY + 6)
      ..close();
    canvas.drawPath(rearGlass, glFill);
    canvas.drawPath(rearGlass, glAccent);
    canvas.drawPath(rearGlass, glStroke);

    // Боковое окно
    final sideGlass = Path()
      ..moveTo(L + 66, beltY + 6)
      ..lineTo(L + 66, roofRearY + 2)
      ..lineTo(R - 60, roofPeakY + 4)
      ..lineTo(R - 56, beltY + 6)
      ..close();
    canvas.drawPath(sideGlass, glFill);
    canvas.drawPath(sideGlass, glAccent);
    canvas.drawPath(sideGlass, glStroke);

    // Лобовое (агрессивный наклон)
    final windshield = Path()
      ..moveTo(R - 58, roofPeakY + 6)
      ..cubicTo(R - 48, roofPeakY + 14, R - 20, beltY + 16, R - 10, beltY + 6)
      ..lineTo(R - 56, beltY + 6)
      ..close();
    canvas.drawPath(windshield, glFill);
    canvas.drawPath(windshield, glAccent);
    canvas.drawPath(windshield, glStroke);

    // B-стойка
    canvas.drawLine(
      Offset(L + 62, roofRearY + 2),
      Offset(L + 62, beltY + 6),
      Paint()..color = const Color(0xFF10111E)..strokeWidth = 6,
    );

    // ── Острая плечевая линия ───────────────────────────────
    canvas.drawLine(
      Offset(L + 30, beltY + 4),
      Offset(R - 10, beltY + 4),
      Paint()
        ..color = const Color(0x28C8A96E)
        ..strokeWidth = 1.0,
    );

    // ── Перед: узкие хищные фары, решётка (шестиугольник) ───
    final drlY = beltY + 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(R - 2, drlY, 5, 20), const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0xCCE8D080)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(R - 2, drlY + 20, 10, 2), const Radius.circular(1),
      ),
      Paint()..color = const Color(0x77E8D080),
    );

    // ── Зад: светодиодная полоса во всю ширину, спойлер ─────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(L - 4, beltY + 10, cw * 0.35, 4), const Radius.circular(1),
      ),
      Paint()
        ..color = const Color(0x99E05A5A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    canvas.drawLine(
      Offset(L + 38, roofRearY + 2),
      Offset(L + 52, roofRearY - 2),
      Paint()
        ..color = const Color(0x40C8A96E)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // ── Патрубки выхлопа (интегрированные) ───────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(L + 4, gY - 8, 6, 4), const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF252530),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(L + 14, gY - 8, 6, 4), const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF252530),
    );

    // ── Колёса ───────────────────────────────────────────────
    _drawWheel(canvas, Offset(fWx, gY), wr);
    _drawWheel(canvas, Offset(rWx, gY), wr);
  }

  void _drawWheel(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF07070A));
    canvas.drawCircle(c, r,
      Paint()..color = const Color(0xFF181820)..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawCircle(c, r * 0.64, Paint()..color = const Color(0xFF1C1E30));
    canvas.drawCircle(c, r * 0.64,
      Paint()..color = const Color(0x55C8A96E)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    for (int i = 0; i < 5; i++) {
      final a = (i * 2 * math.pi / 5) - math.pi / 2;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * 4, c.dy + math.sin(a) * 4),
        Offset(c.dx + math.cos(a) * r * 0.56, c.dy + math.sin(a) * r * 0.56),
        Paint()..color = const Color(0xFF3C3E52)..strokeWidth = 2.2..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF282A3C));
    canvas.drawCircle(c, 4,
      Paint()..color = const Color(0x80C8A96E)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    canvas.drawCircle(c, r,
      Paint()..color = const Color(0xFF222234)..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
