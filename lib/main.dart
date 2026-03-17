import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';

import 'core/locale/locale_scope.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/utils/date_formatter.dart';

const _localeKey = 'app_locale';

// ============================================================
// KM DRIVE — Entry Point
// Kassenov Motors | Алматы, Казахстан
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase инициализация ────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // Init notification service
  await NotificationService.instance.init();
  await NotificationService.instance.seedDemoIfEmpty();

  await initializeDateFormatting('ru_RU', null);
  await initializeDateFormatting('kk_KZ', null);
  await initializeDateFormatting('en_US', null);

  await DateFormatter.initialize('ru_RU');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: KmColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Locale? savedLocale;
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      savedLocale = Locale(code);
      final dateLocale = code == 'ru'
          ? 'ru_RU'
          : code == 'kk'
              ? 'kk_KZ'
              : 'en_US';
      await DateFormatter.initialize(dateLocale);
    }
  } catch (_) {}

  runApp(KmDriveApp(initialLocale: savedLocale ?? const Locale('ru')));
}

class KmDriveApp extends StatefulWidget {
  const KmDriveApp({super.key, this.initialLocale = const Locale('ru')});

  final Locale initialLocale;

  @override
  State<KmDriveApp> createState() => _KmDriveAppState();
}

class _KmDriveAppState extends State<KmDriveApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  Future<void> _onLocaleChanged(Locale locale) async {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    final dateLocale = locale.languageCode == 'ru'
        ? 'ru_RU'
        : locale.languageCode == 'kk'
            ? 'kk_KZ'
            : 'en_US';
    await DateFormatter.initialize(dateLocale);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      locale: _locale,
      onLocaleChanged: _onLocaleChanged,
      child: AppLocalizationsScope(
        locale: AppLocalizations(_locale),
        child: MaterialApp(
          title: 'KM Drive',
          debugShowCheckedModeBanner: false,
          theme: KmTheme.dark,
          locale: _locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru'),
            Locale('kk'),
            Locale('en'),
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}