// ============================================================
// KM DRIVE — KASSENOV MOTORS
// Алматы, Казахстан | Eurasia Premium Automotive
// ============================================================

/// Бренд-константы KM Motors (Kassenov Motors)
abstract class KmBrand {
  KmBrand._();

  static const String appName = 'KM Drive';
  static const String fullName = 'Kassenov Motors';
  static const String shortName = 'KM Motors';
  static const String tagline = 'Лучшее качество за минимальную цену';
  static const String vision =
      'Инженерное совершенство, рождённое в Казахстане';
  static const String mission =
      'Мы создаём не просто транспорт. Мы создаём доверие. '
      'Мы создаём будущее на дорогах.';
  static const String headquarters = 'Алматы, Казахстан';
  static const String strategyTagline =
      'Технологичный. Эмоциональный. Доступный.';
  static const int strategyYear = 2030;

  static const List<Map<String, String>> modelLineup = [
    {'id': 'adal',    'name': 'KM Adal',           'type': 'Компактный премиум',    'segment': 'B-класс'},
    {'id': 's5',      'name': 'KM S5',              'type': 'Бизнес-седан',          'segment': 'E-класс'},
    {'id': 'maya',    'name': 'KM Maya',            'type': 'Флагманский седан',     'segment': 'S-класс'},
    {'id': 'jaqin',   'name': 'KM Jaqin',           'type': 'Премиальный кроссовер', 'segment': 'SUV'},
    {'id': 'astre',   'name': 'KM Prime Astre',     'type': 'Гиперкар',              'segment': 'Prime'},
    {'id': 'vedette', 'name': 'KM Prime La Vedette','type': 'Суперкар',              'segment': 'Prime'},
    {'id': 'fidele',  'name': 'KM Prime Fidèle',    'type': 'GT-модель',             'segment': 'Prime'},
  ];

  static const String platformName = 'KG-6';

  static const List<String> techDna = [
    'Платформа KG-6',
    'Цифровые двойники в производстве',
    'IIoT и предиктивная аналитика',
    'Омниканальные продажи KM Connect',
  ];

  static const String appVersion = '1.0.0';
  static const String buildYear = '2025';
}

/// Строковые константы интерфейса
abstract class KmStrings {
  KmStrings._();

  static const String navHome         = 'Главная';
  static const String navDiagnostics  = 'Диагностика';
  static const String navService      = 'Сервис';
  static const String navTelemetry    = 'Карта';
  static const String navSubscriptions = 'Подписки';
  static const String navProfile      = 'Профиль';

  static const String welcome         = 'Добро пожаловать';
  static const String quickActions    = 'Быстрые действия';
  static const String notifications   = 'Уведомления';

  static const String diagnosticsTitle    = 'Диагностика';
  static const String diagnosticsSubtitle = 'Удалённый мониторинг систем';
  static const String vehicleHealth       = 'Состояние';
  static const String systemsTitle        = 'Системы автомобиля';
  static const String scanVehicle         = 'Сканировать';

  static const String serviceTitle    = 'Сервис';
  static const String serviceSubtitle = 'История и планирование ТО';
  static const String nextService     = 'Следующее ТО';
  static const String serviceHistory  = 'История обслуживания';
  static const String bookService     = 'Запись на ТО';

  static const String telemetryTitle   = 'Телематика';
  static const String currentLocation  = 'Местоположение';
  static const String onMap            = 'На карте';
  static const String recentTrips      = 'Последние поездки';

  static const String subscriptionsTitle    = 'Подписки';
  static const String subscriptionsSubtitle = 'Дополнительные функции автомобиля';
  static const String activeSubscription    = 'Активно';
  static const String inactiveSubscription  = 'Не активно';

  static const String sosTitle   = 'Экстренная помощь';
  static const String sosSubtitle = 'Вызов экстренной службы';
  static const String sosConfirm = 'Подтвердить вызов';
  static const String sosCancel  = 'Отмена';

  static const String statusOk          = 'OK';
  static const String statusDone        = 'Выполнено';
  static const String statusScheduled   = 'Запланировать';
  static const String statusRecommended = 'Рекомендуется';

  static const String unitKmDay  = 'км / день';
  static const String unitHours  = 'ч за рулём';
}

abstract class KmValues {
  KmValues._();
  static const double defaultServiceInterval = 10000.0;
}