import '../models/models.dart';

// ============================================================
// KM DRIVE — Repository Layer
// Абстракция данных (mock-данные для дипломного проекта)
// В продакшне подключается к KM Connect API
// ============================================================

/// Абстрактный интерфейс репозитория автомобиля
abstract class IVehicleRepository {
  Future<VehicleModel> getVehicle();
  Future<List<DiagnosticSystem>> getDiagnostics();
  Future<NextServiceInfo> getNextService();
  Future<List<ServiceRecord>> getServiceHistory();
  Future<TelemetrySummary> getTelemetry();
  Future<List<TripRecord>> getRecentTrips();
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<List<AppNotification>> getNotifications();
  Future<void> toggleSubscription(String subscriptionId, bool isActive);
}

/// Mock-репозиторий с тестовыми данными
/// Имитирует задержку сети для реалистичного UX
class MockVehicleRepository implements IVehicleRepository {
  static const _delay = Duration(milliseconds: 600);

  @override
  Future<VehicleModel> getVehicle() async {
    await Future.delayed(_delay);
    return VehicleModel.sample;
  }

  @override
  Future<List<DiagnosticSystem>> getDiagnostics() async {
    await Future.delayed(_delay);
    return DiagnosticSystem.samples;
  }

  @override
  Future<NextServiceInfo> getNextService() async {
    await Future.delayed(_delay);
    return NextServiceInfo.sample;
  }

  @override
  Future<List<ServiceRecord>> getServiceHistory() async {
    await Future.delayed(_delay);
    return ServiceRecord.samples;
  }

  @override
  Future<TelemetrySummary> getTelemetry() async {
    await Future.delayed(_delay);
    return TelemetrySummary.sample;
  }

  @override
  Future<List<TripRecord>> getRecentTrips() async {
    await Future.delayed(_delay);
    return TripRecord.samples;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    await Future.delayed(_delay);
    return SubscriptionModel.samples;
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(_delay);
    return AppNotification.samples;
  }

  @override
  Future<void> toggleSubscription(String subscriptionId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // В реальном приложении: HTTP PATCH /subscriptions/{id}
  }
}
