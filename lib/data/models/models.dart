// ============================================================
// KM DRIVE — Data Models
// Kassenov Motors | Алматы, Казахстан
// ============================================================

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Модель автомобиля владельца
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.name,
    required this.model,
    required this.segment,
    required this.year,
    required this.plateNumber,
    required this.vin,
    required this.color,
    required this.mileageKm,
    required this.fuelPercent,
    required this.engineStatus,
    required this.tiresStatus,
    required this.healthScore,
  });

  final String id;
  final String name;         // Имя модели: KM Jaqin
  final String model;        // Полное: KM Jaqin 2.0T Premium
  final String segment;      // SUV / B-класс / E-класс
  final int    year;
  final String plateNumber;  // A523KM
  final String vin;
  final String color;        // Deep Navy
  final int    mileageKm;
  final double fuelPercent;  // 0..100
  final VehicleSystemStatus engineStatus;
  final VehicleSystemStatus tiresStatus;
  final double healthScore;  // 0..100

  static const VehicleModel sample = VehicleModel(
    id: 'km-jaqin-001',
    name: 'KM Jaqin',
    model: 'KM Jaqin 2.0T Premium',
    segment: 'Премиальный кроссовер',
    year: 2024,
    plateNumber: 'A523KM',
    vin: 'KMXJQ200L2400523',
    color: 'Deep Navy',
    mileageKm: 3847,
    fuelPercent: 72,
    engineStatus: VehicleSystemStatus.ok,
    tiresStatus: VehicleSystemStatus.ok,
    healthScore: 87,
  );
}

/// Статус системы автомобиля
enum VehicleSystemStatus { ok, warning, critical }

extension VehicleSystemStatusExt on VehicleSystemStatus {
  String get label {
    switch (this) {
      case VehicleSystemStatus.ok:       return 'OK';
      case VehicleSystemStatus.warning:  return 'Внимание';
      case VehicleSystemStatus.critical: return 'Критично';
    }
  }

  bool get isOk       => this == VehicleSystemStatus.ok;
  bool get isWarning  => this == VehicleSystemStatus.warning;
  bool get isCritical => this == VehicleSystemStatus.critical;
}

/// Система диагностики
class DiagnosticSystem {
  const DiagnosticSystem({
    required this.id,
    required this.name,
    required this.icon,
    required this.healthPercent,
    required this.status,
    this.note,
  });

  final String id;
  final String name;
  final String icon;
  final double healthPercent; // 0..100
  final VehicleSystemStatus status;
  final String? note;

  static List<DiagnosticSystem> get samples => [
    const DiagnosticSystem(id: 'engine',   name: 'Двигатель',          icon: '⚙️',  healthPercent: 94, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'battery',  name: 'Аккумулятор',        icon: '🔋',  healthPercent: 88, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'brakes',   name: 'Тормозная система',  icon: '🛑',  healthPercent: 64, status: VehicleSystemStatus.warning, note: 'Рекомендована проверка колодок'),
    const DiagnosticSystem(id: 'cooling',  name: 'Система охлаждения', icon: '❄️',  healthPercent: 91, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'suspension',name:'Подвеска',           icon: '💨',  healthPercent: 79, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'oil',      name: 'Моторное масло',     icon: '🌡️', healthPercent: 55, status: VehicleSystemStatus.warning, note: 'Замена через 1 200 км'),
    const DiagnosticSystem(id: 'electro',  name: 'Электроника',        icon: '📡',  healthPercent: 96, status: VehicleSystemStatus.ok),
  ];
}

/// Запись сервисного обслуживания
class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.title,
    required this.icon,
    required this.date,
    required this.mileageKm,
    required this.status,
    this.description,
    this.priceKzt,
  });

  final String id;
  final String title;
  final String icon;
  final DateTime date;
  final int mileageKm;
  final ServiceStatus status;
  final String? description;
  final int? priceKzt;

  static List<ServiceRecord> get samples => [
    ServiceRecord(
      id: 'sr-001',
      title: 'Замена масла и фильтра',
      icon: '🛢️',
      date: DateTime(2024, 9, 12),
      mileageKm: 2647,
      status: ServiceStatus.done,
      priceKzt: 28000,
    ),
    ServiceRecord(
      id: 'sr-002',
      title: 'Шиномонтаж (зима)',
      icon: '🛞',
      date: DateTime(2024, 10, 28),
      mileageKm: 3102,
      status: ServiceStatus.done,
      priceKzt: 15000,
    ),
    ServiceRecord(
      id: 'sr-003',
      title: 'Диагностика АКБ',
      icon: '🔋',
      date: DateTime(2024, 10, 28),
      mileageKm: 3102,
      status: ServiceStatus.done,
      priceKzt: 8000,
    ),
    ServiceRecord(
      id: 'sr-004',
      title: 'ТО-2 (20 000 км)',
      icon: '⚙️',
      date: DateTime(2025, 3, 15),
      mileageKm: 5000,
      status: ServiceStatus.scheduled,
    ),
    ServiceRecord(
      id: 'sr-005',
      title: 'Замена тормозных колодок',
      icon: '🛑',
      date: DateTime(2025, 3, 15),
      mileageKm: 5000,
      status: ServiceStatus.recommended,
      description: 'Износ 36% — рекомендуется при следующем ТО',
    ),
  ];
}

/// Статус сервисной записи
enum ServiceStatus { done, scheduled, recommended }

extension ServiceStatusExt on ServiceStatus {
  String get label {
    switch (this) {
      case ServiceStatus.done:        return 'Выполнено';
      case ServiceStatus.scheduled:   return 'Запланировать';
      case ServiceStatus.recommended: return 'Рекомендуется';
    }
  }
}

/// Следующее ТО
class NextServiceInfo {
  const NextServiceInfo({
    required this.date,
    required this.remainingKm,
    required this.remainingDays,
    required this.intervalKm,
    required this.currentKm,
  });

  final DateTime date;
  final int remainingKm;
  final int remainingDays;
  final int intervalKm;  // Общий интервал (напр. 10000 км)
  final int currentKm;   // Текущий пробег с прошлого ТО

  /// Прогресс 0..1
  double get progress => currentKm / intervalKm;

  static NextServiceInfo get sample => NextServiceInfo(
    date: DateTime(2025, 3, 15),
    remainingKm: 1200,
    remainingDays: 45,
    intervalKm: 10000,
    currentKm: 7200,
  );
}

/// Поездка
class TripRecord {
  const TripRecord({
    required this.id,
    required this.from,
    required this.to,
    required this.date,
    required this.distanceKm,
    required this.durationMin,
    required this.fuelConsumption,
    required this.ecoScore,
    this.routePoints = const [],
  });

  final String id;
  final String from;
  final String to;
  final DateTime date;
  final double distanceKm;
  final int durationMin;
  final double fuelConsumption; // л/100км
  final int ecoScore;           // 0..100

  /// Точки маршрута для отображения на Google Maps.
  /// Реальные координаты улиц Алматы.
  final List<LatLng> routePoints;

  String get routeLabel => '$from → $to';

  static List<TripRecord> get samples => [
    // Работа (пр. Достык) → Дом (мкр. Алатау)
    TripRecord(
      id: 'tr-001', from: 'Работа', to: 'Дом',
      date: DateTime.now(),
      distanceKm: 34.2, durationMin: 41, fuelConsumption: 7.8, ecoScore: 91,
      routePoints: const [
        LatLng(43.2389, 76.9457), // пр. Достык
        LatLng(43.2341, 76.9380),
        LatLng(43.2280, 76.9280),
        LatLng(43.2210, 76.9170),
        LatLng(43.2140, 76.9040),
        LatLng(43.2070, 76.8910),
        LatLng(43.2000, 76.8790),
        LatLng(43.1950, 76.8670),
        LatLng(43.1910, 76.8590),
        LatLng(43.1890, 76.8512), // дом
      ],
    ),
    // Дом → Мега Алматы (пр. Розыбакиева)
    TripRecord(
      id: 'tr-002', from: 'Дом', to: 'Торговый центр',
      date: DateTime.now().subtract(const Duration(days: 1)),
      distanceKm: 12.7, durationMin: 19, fuelConsumption: 8.1, ecoScore: 85,
      routePoints: const [
        LatLng(43.1890, 76.8512),
        LatLng(43.1940, 76.8580),
        LatLng(43.1990, 76.8650),
        LatLng(43.2050, 76.8720),
        LatLng(43.2100, 76.8790),
        LatLng(43.2167, 76.8895), // Мега Алматы
      ],
    ),
    // Дом → Медеу (Алматы горы)
    TripRecord(
      id: 'tr-003', from: 'Дом', to: 'Медеу',
      date: DateTime.now().subtract(const Duration(days: 2)),
      distanceKm: 22.5, durationMin: 35, fuelConsumption: 9.2, ecoScore: 78,
      routePoints: const [
        LatLng(43.1890, 76.8512),
        LatLng(43.1960, 76.8590),
        LatLng(43.2040, 76.8660),
        LatLng(43.2130, 76.8730),
        LatLng(43.2220, 76.8810),
        LatLng(43.2310, 76.8890),
        LatLng(43.2370, 76.8960), // Медеу
      ],
    ),
  ];
}

/// Телематика — сводка за день
class TelemetrySummary {
  const TelemetrySummary({
    required this.dailyKm,
    required this.driveHours,
    required this.ecoScore,
    required this.currentAddress,
    required this.latitude,
    required this.longitude,
  });

  final double dailyKm;
  final double driveHours;
  final int ecoScore;
  final String currentAddress;
  final double latitude;
  final double longitude;

  /// Удобный геттер для передачи в Google Maps
  LatLng get position => LatLng(latitude, longitude);

  static TelemetrySummary get sample => const TelemetrySummary(
    dailyKm: 127,
    driveHours: 2.4,
    ecoScore: 89,
    currentAddress: 'пр. Абая, 8А, Алматы',
    latitude: 43.242194,   // пр. Абая 8А — Университет Международного Бизнеса, у пр. Достык
    longitude: 76.949400,
  );
}

/// Подписка на сервис
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.priceKzt,
    required this.features,
    required this.isActive,
    this.activeUntil,
    this.icon,
  });

  final String id;
  final String name;
  final int priceKzt;
  final List<String> features;
  final bool isActive;
  final DateTime? activeUntil;
  final String? icon;

  SubscriptionModel copyWith({bool? isActive}) => SubscriptionModel(
    id: id, name: name, priceKzt: priceKzt, features: features,
    isActive: isActive ?? this.isActive,
    activeUntil: activeUntil, icon: icon,
  );

  static List<SubscriptionModel> get samples => [
    SubscriptionModel(
      id: 'km-connect-pro',
      name: 'KM Connect Pro',
      priceKzt: 4900,
      features: ['Удалённый запуск', 'Климат-контроль', 'Геозоны', 'Приоритетная поддержка'],
      isActive: true,
      activeUntil: DateTime(2025, 4, 12),
      icon: '🔗',
    ),
    const SubscriptionModel(
      id: 'telemetry-pro',
      name: 'Расширенная телематика',
      priceKzt: 2490,
      features: ['Детальная статистика поездок', 'Оценка стиля вождения', 'Ежемесячные отчёты'],
      isActive: false,
      icon: '📡',
    ),
    const SubscriptionModel(
      id: 'parking-plus',
      name: 'Ассистент парковки+',
      priceKzt: 1490,
      features: ['Поиск парковок', 'Оплата через приложение', 'Навигация к автомобилю'],
      isActive: false,
      icon: '🅿️',
    ),
    SubscriptionModel(
      id: 'ota-priority',
      name: 'OTA Приоритет',
      priceKzt: 990,
      features: ['Первый доступ к обновлениям ПО', 'Ночные обновления без помех'],
      isActive: true,
      activeUntil: DateTime(2025, 12, 31),
      icon: '⬆️',
    ),
  ];
}

/// Уведомление
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final String title;
  final NotificationType type;
  final DateTime time;
  final bool isRead;

  static List<AppNotification> get samples => [
    AppNotification(
      id: 'n-001',
      title: 'ТО через 1 200 км. Запишитесь в сервисный центр.',
      type: NotificationType.warning,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n-002',
      title: 'Обновление ПО v3.2.1 установлено успешно. Платформа KG-6.',
      type: NotificationType.success,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-003',
      title: 'Подписка KM Connect Pro активна до 12 апреля 2025.',
      type: NotificationType.info,
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}

enum NotificationType { info, warning, success, error }