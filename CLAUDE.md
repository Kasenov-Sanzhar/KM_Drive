# CLAUDE.md — KM Drive

Официальное мобильное приложение **KM Motors (Kassenov Motors)** для владельцев автомобилей.
Алматы, Казахстан | Дипломный проект.

---

## Проект

| | |
|---|---|
| **Платформа** | Flutter (iOS + Android) |
| **Dart SDK** | `>=3.0.0 <4.0.0` |
| **Версия** | `1.0.0+1` |
| **Package** | `km_drive` |
| **Firebase** | Auth, Firestore, Messaging (FCM) |
| **Карты** | Google Maps Flutter + Geolocator |
| **Локализация** | RU / KK / EN (l10n через `AppLocalizations`) |

---

## Команды

```bash
# Запуск
flutter run

# Сборка
flutter build apk --release
flutter build ios --release

# Анализ и тесты
flutter analyze
flutter test

# Очистка
flutter clean && flutter pub get

# Обновление локализации (при изменении l10n)
flutter gen-l10n
```

---

## Архитектура

```
lib/
├── main.dart                        # Entry point, Firebase init, LocaleScope
├── firebase_options.dart
│
├── core/
│   ├── constants/app_constants.dart
│   ├── locale/locale_scope.dart     # InheritedWidget для смены языка
│   ├── theme/app_theme.dart         # KmColors, KmTextStyles, KmTheme, KmRadius, KmSpacing
│   └── utils/
│       ├── date_formatter.dart
│       └── formatters.dart
│
├── data/
│   ├── models/models.dart           # Все модели данных (один файл)
│   ├── repositories/
│   │   ├── vehicle_repository.dart          # IVehicleRepository + MockVehicleRepository
│   │   └── firestore_vehicle_repository.dart
│   └── services/
│       ├── auth_service.dart        # Firebase Auth + VIN
│       ├── booking_service.dart
│       ├── notification_service.dart
│       ├── push_service.dart        # FCM
│       └── sync_service.dart        # Firestore + connectivity
│
├── l10n/
│   └── app_localizations.dart      # Локализация (RU/KK/EN)
│
└── presentation/
    ├── screens/                     # Все экраны
    └── widgets/                     # Переиспользуемые виджеты
```

**Паттерн данных:** Repository + Service. Экраны обращаются к репозиторию через `IVehicleRepository`. Текущая реализация — `MockVehicleRepository` (600ms задержка для реалистичного UX). Firestore-репозиторий подготовлен для продакшна.

**Локализация:** все строки в UI — l10n-ключи. Обращение через `AppLocalizationsScope.of(context).get('key')`. Прямые строки в виджетах недопустимы.

---

## Дизайн-система

Все константы живут в `lib/core/theme/app_theme.dart`. Использовать только их — не хардкодить цвета, отступы и радиусы.

```dart
// Цвета
KmColors.background   // #08080A — основной фон
KmColors.surface      // #111113
KmColors.surface2     // #18181C — карточки
KmColors.surface3     // #1E1E24
KmColors.accent       // #C8A96E — золотой акцент (primary)
KmColors.accentLight  // #E8C97E
KmColors.textPrimary  // #F0EDE8
KmColors.textSecondary// #9A9498
KmColors.textMuted    // #6B6875
KmColors.border       // #2A2A30

// Шрифты
KmTextStyles.displayLarge   // CormorantGaramond 42px — заголовки
KmTextStyles.bodyMedium     // DMSans 16px — основной текст
KmTextStyles.labelMedium    // DMSans 12px, letterSpacing 1.8 — метки/капс

// Отступы
KmSpacing.xs = 4   KmSpacing.sm = 8   KmSpacing.md = 16
KmSpacing.lg = 24  KmSpacing.xl = 32  KmSpacing.xxl = 48

// Радиусы
KmRadius.sm = 8   KmRadius.md = 12   KmRadius.lg = 16   KmRadius.xl = 20
```

**Тема:** только dark mode (`KmTheme.dark`). Light mode не предусмотрен.

---

## Стиль кода

- **Язык комментариев:** русский (комментарии в коде на русском, как в оригинале)
- **Const-first:** всегда добавляй `const` где возможно
- **Именование:** `camelCase` для переменных, `PascalCase` для классов, `snake_case` для файлов
- **Модели:** `const` конструкторы + `copyWith` где нужна мутация
- **Enum extensions:** добавлять `l10nKey` и `label` (fallback EN) как в `VehicleSystemStatus`
- **Lint:** `package:flutter_lints/flutter.yaml` — запускать `flutter analyze` перед коммитом
- **Импорты:** порядок — dart, flutter, packages, local
- **Strings в UI:** только l10n-ключи, никаких хардкод-строк в виджетах
- **Файл моделей:** все модели в одном `models.dart` (существующее соглашение)

---

## Правила для Claude

### ✅ Делать

- Следовать существующей структуре — не вводить новые паттерны (BLoC, Riverpod, Provider) без явной просьбы
- Использовать только `KmColors`, `KmTextStyles`, `KmSpacing`, `KmRadius` — никаких магических чисел
- Добавлять `l10nKey` для любых новых enum-значений, которые отображаются в UI
- Писать mock-данные через `static get samples` / `static get sample` как в моделях
- Имитировать задержку сети: `await Future.delayed(const Duration(milliseconds: 600))` в MockRepository
- Сохранять стиль шапок файлов: `// === KM DRIVE — [Раздел] / [Описание] ===`
- Комментировать на русском языке

### ❌ Не делать

- Не вводить state management библиотеки (Riverpod, BLoC, GetX) — проект на `setState` + `InheritedWidget`
- Не создавать отдельные файлы для каждой модели — все модели в `models.dart`
- Не хардкодить строки в виджетах — только l10n-ключи
- Не хардкодить цвета (`Color(0xFF...)`) и отступы (`SizedBox(height: 16)`) вне `app_theme.dart`
- Не добавлять light theme — проект только dark mode
- Не менять шрифты — только `CormorantGaramond` (заголовки) и `DMSans` (текст)
- Не трогать `firebase_options.dart` — авто-генерируется FlutterFire CLI
- Не писать тесты для mock-репозитория — он временный, до подключения реального API

---

## Firebase

- **Auth:** Email/password + VIN validation (`AuthService`)
- **Firestore:** синхронизация через `SyncService` с мониторингом connectivity
- **FCM:** push-уведомления через `PushService` + `NotificationService`
- **Background handler:** `firebaseBackgroundHandler` зарегистрирован в `main()`

---

## Локализация

Поддерживаемые локали: `ru` (по умолчанию), `kk`, `en`.
Смена языка через `LocaleScope` + `SharedPreferences` (ключ `app_locale`).
Форматирование дат через `DateFormatter.initialize(locale)` при смене языка.

---

## Заметки

- Проект — дипломная работа, mock-данные заменяются на реальный KM Connect API в продакшне
- Автомобиль по умолчанию: KM Jaqin 2.0T Premium, VIN `KMXJQ200L2400523`, госномер `A523KM`
- Геолокация привязана к Алматы (координаты реальных улиц города)
- Ориентация экрана: только портрет (`portraitUp` + `portraitDown`)
