import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// KM DRIVE — Design System
// Luxury Dark Theme | Kassenov Motors
// Шрифты увеличены для читаемости
// ============================================================

abstract class KmColors {
  KmColors._();

  static const Color background = Color(0xFF08080A);
  static const Color surface    = Color(0xFF111113);
  static const Color surface2   = Color(0xFF18181C);
  static const Color surface3   = Color(0xFF1E1E24);

  static const Color border      = Color(0xFF2A2A30);
  static const Color borderLight = Color(0xFF3A3A42);

  static const Color accent      = Color(0xFFC8A96E);
  static const Color accentLight = Color(0xFFE8C97E);
  static const Color accentDim   = Color(0xFF8A7048);

  static const Color textPrimary   = Color(0xFFF0EDE8);
  static const Color textSecondary = Color(0xFF9A9498);
  static const Color textMuted     = Color(0xFF6B6875);

  static const Color success = Color(0xFF5AB87A);
  static const Color warning = Color(0xFFC8A96E);
  static const Color error   = Color(0xFFE05A5A);
  static const Color info    = Color(0xFF5A8FE0);

  static const Color overlayAccent  = Color(0x1AC8A96E);
  static const Color overlayError   = Color(0x1AE05A5A);
  static const Color overlaySuccess = Color(0x1A5AB87A);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x1FC8A96E), Color(0x05C8A96E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract class KmTextStyles {
  KmTextStyles._();

  // Заголовки: было 36/28/22 → стало 42/34/26
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 42,
    fontWeight: FontWeight.w400,
    color: KmColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: KmColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: KmColors.textPrimary,
  );

  // Цифры: было 48/24/18 → стало 54/28/22
  static const TextStyle numeralLarge = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 54,
    fontWeight: FontWeight.w300,
    color: KmColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle numeralMedium = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: KmColors.textPrimary,
  );

  static const TextStyle numeralSmall = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: KmColors.textPrimary,
  );

  // Основной текст: было 15/13/11 → стало 17/15/13
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: KmColors.textPrimary,
    height: 1.55,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: KmColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: KmColors.textSecondary,
    height: 1.5,
  );

  // Метки: было 12/10/9 → стало 14/12/11
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: KmColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: KmColors.textMuted,
    letterSpacing: 1.8,
    height: 1.0,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: KmColors.textMuted,
    letterSpacing: 2.0,
  );

  // Caption: было 10 → стало 12
  static const TextStyle caption = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KmColors.textMuted,
    height: 1.45,
  );
}

abstract class KmRadius {
  KmRadius._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
}

abstract class KmSpacing {
  KmSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class KmTheme {
  KmTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KmColors.background,
      colorScheme: const ColorScheme.dark(
        primary: KmColors.accent,
        secondary: KmColors.accentLight,
        surface: KmColors.surface,
        error: KmColors.error,
        onPrimary: KmColors.background,
        onSecondary: KmColors.background,
        onSurface: KmColors.textPrimary,
        onError: KmColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: KmTextStyles.displaySmall,
        iconTheme: IconThemeData(color: KmColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KmColors.surface,
        selectedItemColor: KmColors.accent,
        unselectedItemColor: KmColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: KmColors.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KmRadius.lg),
          side: const BorderSide(color: KmColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: KmColors.border,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: const TextTheme(
        displayLarge:  KmTextStyles.displayLarge,
        displayMedium: KmTextStyles.displayMedium,
        displaySmall:  KmTextStyles.displaySmall,
        bodyLarge:     KmTextStyles.bodyLarge,
        bodyMedium:    KmTextStyles.bodyMedium,
        bodySmall:     KmTextStyles.bodySmall,
        labelLarge:    KmTextStyles.labelLarge,
        labelMedium:   KmTextStyles.labelMedium,
        labelSmall:    KmTextStyles.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KmColors.accent,
          foregroundColor: KmColors.background,
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KmRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KmColors.textSecondary,
          side: const BorderSide(color: KmColors.border),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KmRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return KmColors.background;
          return KmColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return KmColors.accent;
          return KmColors.surface3;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}