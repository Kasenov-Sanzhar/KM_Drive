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
    this.batteryVolts    = 12.8,
    this.engineTempC     = 91.0,
    this.oilLevelPercent = 75.0,
    this.tirePressure    = const TirePressure(),
    this.engineRpm       = 0,
    this.speedKmh        = 0.0,
    this.dtcCodes        = const [],
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
  // ── Расширенная телематика ───────────────────────────────
  final double batteryVolts;    // 12V АКБ, норма 12.4–14.7V
  final double engineTempC;     // Температура охлаждающей жидкости, норма 85–105°C
  final double oilLevelPercent; // Уровень масла 0..100
  final TirePressure tirePressure; // Давление в шинах (бар)
  final int    engineRpm;       // Обороты двигателя
  final double speedKmh;        // Текущая скорость
  final List<DtcCode> dtcCodes; // Коды ошибок OBD

  static const VehicleModel sample = VehicleModel(
    id: 'km-jaqin-001',
    name: 'KM Jaqin',
    model: 'KM Jaqin 2.0T Premium',
    segment: 'segmentSUV',
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

/// Давление в шинах (бар, норма 2.2–2.5)
class TirePressure {
  const TirePressure({
    this.frontLeft  = 2.4,
    this.frontRight = 2.4,
    this.rearLeft   = 2.3,
    this.rearRight  = 2.3,
  });
  final double frontLeft;
  final double frontRight;
  final double rearLeft;
  final double rearRight;

  bool get allOk =>
      [frontLeft, frontRight, rearLeft, rearRight].every((p) => p >= 2.0 && p <= 2.8);

  VehicleSystemStatus get status {
    final pressures = [frontLeft, frontRight, rearLeft, rearRight];
    if (pressures.any((p) => p < 1.8 || p > 3.0)) return VehicleSystemStatus.critical;
    if (pressures.any((p) => p < 2.0 || p > 2.8)) return VehicleSystemStatus.warning;
    return VehicleSystemStatus.ok;
  }
}

/// Код ошибки OBD (DTC)
class DtcCode {
  const DtcCode({
    required this.code,
    required this.systemKey, // l10n key
    required this.descKey,   // l10n key
    this.severity = VehicleSystemStatus.warning,
  });
  final String code;
  final String systemKey;
  final String descKey;
  final VehicleSystemStatus severity;
}

extension VehicleSystemStatusExt on VehicleSystemStatus {
  /// L10n-ключ для перевода статуса
  String get l10nKey {
    switch (this) {
      case VehicleSystemStatus.ok:       return 'statusSystemOk';
      case VehicleSystemStatus.warning:  return 'statusSystemWarning';
      case VehicleSystemStatus.critical: return 'statusSystemCritical';
    }
  }

  /// Fallback label (английский) — используется там где нет BuildContext
  String get label {
    switch (this) {
      case VehicleSystemStatus.ok:       return 'OK';
      case VehicleSystemStatus.warning:  return 'Warning';
      case VehicleSystemStatus.critical: return 'Critical';
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

  // Имена систем хранятся как l10n-ключи, экраны делают l10n.get(system.name)
  static List<DiagnosticSystem> get samples => [
    const DiagnosticSystem(id: 'engine',     name: 'diagEngine',     icon: '⚙️',  healthPercent: 94, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'battery',    name: 'diagBattery',    icon: '🔋',  healthPercent: 88, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'brakes',     name: 'diagBrakes',     icon: '🛑',  healthPercent: 64, status: VehicleSystemStatus.warning, note: 'diagNoteBrakes'),
    const DiagnosticSystem(id: 'cooling',    name: 'diagCooling',    icon: '❄️',  healthPercent: 91, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'suspension', name: 'diagSuspension', icon: '💨',  healthPercent: 79, status: VehicleSystemStatus.ok),
    const DiagnosticSystem(id: 'oil',        name: 'diagOil',        icon: '🌡️', healthPercent: 55, status: VehicleSystemStatus.warning, note: 'diagNoteOil'),
    const DiagnosticSystem(id: 'electro',    name: 'diagElectro',    icon: '📡',  healthPercent: 96, status: VehicleSystemStatus.ok),
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
    this.worksDone = const [],
    this.master,
    this.center,
    this.nextKm,
  });

  final String id;
  final String title;
  final String icon;
  final DateTime date;
  final int mileageKm;
  final ServiceStatus status;
  final String? description;
  final int? priceKzt;
  final List<String> worksDone; // l10n keys or plain strings
  final String? master;
  final String? center;
  final int? nextKm;  // следующее ТО через N км

  // title и description — l10n-ключи
  static List<ServiceRecord> get samples => [
    ServiceRecord(
      id: 'sr-001',
      title: 'srOilChange',
      icon: '🛢️',
      date: DateTime(2024, 9, 12),
      mileageKm: 2647,
      status: ServiceStatus.done,
      priceKzt: 28000,
      worksDone: ['srWork001_1', 'srWork001_2', 'srWork001_3'],
      master: 'Алибек С.',
      center: 'KM Motors — Розыбакиева',
      nextKm: 12647,
    ),
    ServiceRecord(
      id: 'sr-002',
      title: 'srTires',
      icon: '🛞',
      date: DateTime(2024, 10, 28),
      mileageKm: 3102,
      status: ServiceStatus.done,
      priceKzt: 15000,
      worksDone: ['srWork002_1', 'srWork002_2'],
      master: 'Данияр М.',
      center: 'KM Motors — Достык',
    ),
    ServiceRecord(
      id: 'sr-003',
      title: 'srBattery',
      icon: '🔋',
      date: DateTime(2024, 10, 28),
      mileageKm: 3102,
      status: ServiceStatus.done,
      priceKzt: 8000,
      worksDone: ['srWork003_1', 'srWork003_2'],
      master: 'Данияр М.',
      center: 'KM Motors — Достык',
    ),
    ServiceRecord(
      id: 'sr-004',
      title: 'srService2',
      icon: '⚙️',
      date: DateTime(2025, 3, 15),
      mileageKm: 5000,
      status: ServiceStatus.scheduled,
      center: 'KM Motors — Розыбакиева, 247',
    ),
    ServiceRecord(
      id: 'sr-005',
      title: 'srBrakePads',
      icon: '🛑',
      date: DateTime(2025, 3, 15),
      mileageKm: 5000,
      status: ServiceStatus.recommended,
      description: 'srBrakePadsNote',
    ),
  ];
}

/// Статус сервисной записи
enum ServiceStatus { done, scheduled, recommended }

extension ServiceStatusExt on ServiceStatus {
  /// L10n-ключ
  String get l10nKey {
    switch (this) {
      case ServiceStatus.done:        return 'statusDone';
      case ServiceStatus.scheduled:   return 'statusScheduled';
      case ServiceStatus.recommended: return 'statusRecommended';
    }
  }

  /// Fallback (английский)
  String get label {
    switch (this) {
      case ServiceStatus.done:        return 'Done';
      case ServiceStatus.scheduled:   return 'Schedule';
      case ServiceStatus.recommended: return 'Recommended';
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
      id: 'tr-001', from: 'tripWork', to: 'tripHome',
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
      id: 'tr-002', from: 'tripHome', to: 'tripMall',
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
      id: 'tr-003', from: 'tripHome', to: 'tripMedeu',
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
    this.avgSpeedKmh = 42.3,
    this.maxSpeedKmh = 87.0,
    this.fuelUsedL   = 9.6,
  });

  final double dailyKm;
  final double driveHours;
  final int ecoScore;
  final String currentAddress;
  final double latitude;
  final double longitude;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double fuelUsedL;

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
      name: 'subName1',
      priceKzt: 4900,
      features: ['subFeat1_1', 'subFeat1_2', 'subFeat1_3', 'subFeat1_4'],
      isActive: true,
      activeUntil: DateTime(2025, 4, 12),
      icon: '🔗',
    ),
    const SubscriptionModel(
      id: 'telemetry-pro',
      name: 'subName2',
      priceKzt: 2490,
      features: ['subFeat2_1', 'subFeat2_2', 'subFeat2_3'],
      isActive: false,
      icon: '📡',
    ),
    const SubscriptionModel(
      id: 'parking-plus',
      name: 'subName3',
      priceKzt: 1490,
      features: ['subFeat3_1', 'subFeat3_2', 'subFeat3_3'],
      isActive: false,
      icon: '🅿️',
    ),
    SubscriptionModel(
      id: 'ota-priority',
      name: 'subName4',
      priceKzt: 990,
      features: ['subFeat4_1', 'subFeat4_2'],
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
      title: 'notif1',
      type: NotificationType.warning,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n-002',
      title: 'notif2',
      type: NotificationType.success,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'n-003',
      title: 'notif3',
      type: NotificationType.info,
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  // ── Сериализация ─────────────────────────────────────────

  AppNotification copyWithRead(bool read) => AppNotification(
    id: id, title: title, type: type, time: time, isRead: read,
  );

  Map<String, dynamic> toJson() => {
    'id':     id,
    'title':  title,
    'type':   type.name,
    'time':   time.millisecondsSinceEpoch,
    'isRead': isRead,
  };

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
    id:     j['id']    as String,
    title:  j['title'] as String,
    type:   NotificationType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => NotificationType.info,
    ),
    time:   DateTime.fromMillisecondsSinceEpoch(j['time'] as int),
    isRead: (j['isRead'] as bool?) ?? false,
  );
}

enum NotificationType { info, warning, success, error }