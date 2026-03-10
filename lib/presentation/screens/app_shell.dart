import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'package:km_drive/presentation/screens/diagnostics_screen.dart';
import 'package:km_drive/presentation/screens/profile_screen.dart';
import 'package:km_drive/presentation/screens/service_screen.dart';
import 'package:km_drive/presentation/screens/telemetry_screen.dart';
import '../../core/theme/app_theme.dart';
import 'dart:math' as math;

// ============================================================
// KM DRIVE — App Shell
// Нижняя навигация с SVG-иконками (кастомный Paint)
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ✅ Передаём callback — после сканирования переключит таб на Диагностику
          DashboardScreen(onNavigateToDiagnostics: () => _navigateTo(1)),
          const DiagnosticsScreen(),
          const ServiceScreen(),
          const TelemetryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _KmBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Нижняя навигация ─────────────────────────────────────────

class _KmBottomNav extends StatefulWidget {
  const _KmBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_KmBottomNav> createState() => _KmBottomNavState();
}

class _KmBottomNavState extends State<_KmBottomNav> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: KmColors.surface,
        border: Border(
          top: BorderSide(color: KmColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: _tabs.asMap().entries.map((e) {
              final i = e.key;
              final tab = e.value;
              final label = l10n.get(tab.labelKey);
              final active = i == widget.currentIndex;
              final isPressed = _pressedIndex == i;
              
              return Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressedIndex = i),
                  onTapUp: (_) => setState(() => _pressedIndex = null),
                  onTapCancel: () => setState(() => _pressedIndex = null),
                  onTap: () => widget.onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Эффект свечения вокруг всей кнопки при нажатии
                        if (isPressed)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: KmColors.accent.withAlpha((0.3 * 255).round()),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        
                        // Эффект свечения для активной иконки
                        if (active && !isPressed)
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: KmColors.accent.withAlpha((0.15 * 255).round()),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Иконка
                            CustomPaint(
                              size: const Size(28, 28),
                              painter: _IconPainter(
                                icon: tab.icon,
                                color: active ? KmColors.accent : KmColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 10,
                                letterSpacing: 0.3,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                color: active ? KmColors.accent : KmColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static const _tabs = [
    _Tab(_NavIcon.home, 'navHome'),
    _Tab(_NavIcon.diagnostics, 'navDiagnostics'),
    _Tab(_NavIcon.service, 'navService'),
    _Tab(_NavIcon.telemetry, 'navTelemetry'),
    _Tab(_NavIcon.profile, 'navProfile'),
  ];
}

// ── Кастомные иконки (CustomPainter) ─────────────────────────

enum _NavIcon { home, diagnostics, service, telemetry, profile }

class _Tab {
  const _Tab(this.icon, this.labelKey);
  final _NavIcon icon;
  final String labelKey;
}

class _IconPainter extends CustomPainter {
  const _IconPainter({
    required this.icon,
    required this.color,
  });

  final _NavIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (icon) {
      // ── Главная: домик ──────────────────────────────────────
      case _NavIcon.home:
        // Крыша
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.1, h * 0.5)
            ..lineTo(w * 0.5, h * 0.08)
            ..lineTo(w * 0.9, h * 0.5),
          p,
        );

        // Стены
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.18, h * 0.5)
            ..lineTo(w * 0.18, h * 0.92)
            ..lineTo(w * 0.82, h * 0.92)
            ..lineTo(w * 0.82, h * 0.5),
          p,
        );

        // Дверь
        canvas.drawRect(
          Rect.fromLTWH(w * 0.4, h * 0.65, w * 0.2, h * 0.27),
          p,
        );

        // Ручка двери
        canvas.drawCircle(
          Offset(w * 0.55, h * 0.78),
          w * 0.03,
          p,
        );
        break;

      // ── Диагностика: пульс ──────────────────────────────────
      case _NavIcon.diagnostics:
        // Круг
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.4, p);

        // Линия пульса
        final pulsePath = Path()
          ..moveTo(w * 0.2, h * 0.5)
          ..lineTo(w * 0.35, h * 0.5)
          ..lineTo(w * 0.42, h * 0.3)
          ..lineTo(w * 0.5, h * 0.7)
          ..lineTo(w * 0.58, h * 0.4)
          ..lineTo(w * 0.65, h * 0.5)
          ..lineTo(w * 0.8, h * 0.5);

        canvas.drawPath(pulsePath, p..strokeWidth = 2.2);
        break;

      // ── Сервис: шестеренка ─────────────────────────────────
      case _NavIcon.service:
        final center = Offset(w * 0.5, h * 0.5);
        final radius = w * 0.2;
        const teeth = 8;
        
        // Основная окружность
        canvas.drawCircle(center, radius, p);
        
        // Внутреннее отверстие
        canvas.drawCircle(center, w * 0.08, p);
        
        // Зубья шестеренки
        for (int i = 0; i < teeth; i++) {
          final angle = i * 2 * math.pi / teeth;
          
          // Наружный зуб
          final outerX = center.dx + (radius + w * 0.06) * math.cos(angle);
          final outerY = center.dy + (radius + w * 0.06) * math.sin(angle);
          
          // Внутренняя точка зуба
          final innerX = center.dx + radius * math.cos(angle);
          final innerY = center.dy + radius * math.sin(angle);
          
          canvas.drawLine(
            Offset(innerX, innerY),
            Offset(outerX, outerY),
            p..strokeWidth = 2.2,
          );
          
          // Соседние зубья для формирования впадин
          if (i < teeth - 1) {
            final nextAngle = (i + 1) * 2 * math.pi / teeth;
            final nextInnerX = center.dx + radius * math.cos(nextAngle);
            final nextInnerY = center.dy + radius * math.sin(nextAngle);
            
            canvas.drawLine(
              Offset(innerX, innerY),
              Offset(nextInnerX, nextInnerY),
              p..strokeWidth = 2.0,
            );
          }
        }
        
        // Замыкающий зуб
        const lastAngle = (teeth - 1) * 2 * math.pi / teeth;
        final lastInnerX = center.dx + radius * math.cos(lastAngle);
        final lastInnerY = center.dy + radius * math.sin(lastAngle);
        final firstInnerX = center.dx + radius * math.cos(0);
        final firstInnerY = center.dy + radius * math.sin(0);
        
        canvas.drawLine(
          Offset(lastInnerX, lastInnerY),
          Offset(firstInnerX, firstInnerY),
          p..strokeWidth = 2.0,
        );
        break;

      // ── Телеметрия: график ─────────────────────────────────
      case _NavIcon.telemetry:
        // Контур
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8),
            Radius.circular(w * 0.1),
          ),
          p,
        );

        // Линии графика
        final chartPath = Path()
          ..moveTo(w * 0.2, h * 0.7)
          ..lineTo(w * 0.35, h * 0.5)
          ..lineTo(w * 0.5, h * 0.6)
          ..lineTo(w * 0.65, h * 0.4)
          ..lineTo(w * 0.8, h * 0.5);

        canvas.drawPath(chartPath, p..strokeWidth = 2.0);

        // Точки на графике
        canvas.drawCircle(Offset(w * 0.2, h * 0.7), w * 0.02, p);
        canvas.drawCircle(Offset(w * 0.35, h * 0.5), w * 0.02, p);
        canvas.drawCircle(Offset(w * 0.5, h * 0.6), w * 0.02, p);
        canvas.drawCircle(Offset(w * 0.65, h * 0.4), w * 0.02, p);
        canvas.drawCircle(Offset(w * 0.8, h * 0.5), w * 0.02, p);
        break;

      // ── Профиль: человек ───────────────────────────────────
      case _NavIcon.profile:
        // Голова
        canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.15, p);

        // Шея
        canvas.drawLine(
          Offset(w * 0.45, h * 0.42),
          Offset(w * 0.45, h * 0.48),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.55, h * 0.42),
          Offset(w * 0.55, h * 0.48),
          p,
        );

        // Плечи и торс
        final bodyPath = Path()
          ..moveTo(w * 0.25, h * 0.85)
          ..cubicTo(
            w * 0.25, h * 0.55,
            w * 0.35, h * 0.48,
            w * 0.5,  h * 0.48,
          )
          ..cubicTo(
            w * 0.65, h * 0.48,
            w * 0.75, h * 0.55,
            w * 0.75, h * 0.85,
          );

        canvas.drawPath(bodyPath, p);

        // Детали лица
        canvas.drawCircle(Offset(w * 0.42, h * 0.23), w * 0.02, p);
        canvas.drawCircle(Offset(w * 0.58, h * 0.23), w * 0.02, p);
        break;
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color;
}