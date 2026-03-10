import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
// ✅ Плоский импорт (splash и shell в одной папке screens/)
import 'app_shell.dart';

// ============================================================
// KM DRIVE — Splash Screen
// Анимированный экран загрузки с логотипом KM Motors
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppShell(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Stack(
          children: [
            // Фоновый glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    colors: [Color(0x14C8A96E), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
              ),
            ),

            // Центральный блок
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Логотип
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const Column(
                        children: [
                          Text(
                            'KM',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 64,
                              fontWeight: FontWeight.w300,
                              color: KmColors.accent,
                              letterSpacing: 12,
                              height: 1,
                            ),
                          ),
                          Text(
                            'DRIVE',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: KmColors.textMuted,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Слоган
                  FadeTransition(
                    opacity: _taglineFade,
                    child: const Column(
                      children: [
                        Text(
                          KmBrand.tagline,
                          style: KmTextStyles.bodySmall,
                        ),
                        SizedBox(height: 6),
                        Text(
                          KmBrand.headquarters,
                          style: KmTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Прогресс
                  FadeTransition(
                    opacity: _taglineFade,
                    child: SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          minHeight: 1.5,
                          backgroundColor: KmColors.surface3,
                          valueColor: const AlwaysStoppedAnimation(
                            KmColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Версия внизу
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: const Text(
                  '${KmBrand.fullName} · v${KmBrand.appVersion}',
                  style: KmTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
