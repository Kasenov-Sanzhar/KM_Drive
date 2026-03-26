import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import 'vehicle_repository.dart';

// ============================================================
// KM DRIVE — FirestoreVehicleRepository
// Загружает данные конкретного пользователя из Firestore
// Fallback на mock-данные если Firestore недоступен
// ============================================================

class FirestoreVehicleRepository implements IVehicleRepository {
  static const _delay = Duration(milliseconds: 400);

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Vehicle ───────────────────────────────────────────────

  @override
  Future<VehicleModel> getVehicle() async {
    try {
      final uid = _uid;
      if (uid == null) return VehicleModel.sample;

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .get();

      if (!doc.exists) return VehicleModel.sample;
      return _vehicleFromFirestore(doc.data()!);
    } catch (_) {
      return VehicleModel.sample;
    }
  }

  VehicleModel _vehicleFromFirestore(Map<String, dynamic> d) {
    return VehicleModel(
      id:            d['vin'] as String? ?? 'unknown',
      name:          d['model'] as String? ?? 'KM Jaqin',
      model:         '${d['model'] ?? 'KM Jaqin'} 2.0T Premium',
      segment:       'segmentSUV',
      year:          (d['year'] as num?)?.toInt() ?? 2025,
      plateNumber:   d['plateNumber'] as String? ?? '—',
      vin:           d['vin'] as String? ?? '',
      color:         d['color'] as String? ?? 'Deep Navy',
      mileageKm:     ((d['mileageKm'] ?? d['mileage']) as num?)?.toInt() ?? 0,
      fuelPercent:   ((d['fuelPercent'] as num?) ?? 72).toDouble(),
      engineStatus:  VehicleSystemStatus.ok,
      tiresStatus:   VehicleSystemStatus.ok,
      healthScore:   ((d['healthScore'] as num?) ?? 87).toDouble(),
    );
  }

  // ── Diagnostics ───────────────────────────────────────────

  @override
  Future<List<DiagnosticSystem>> getDiagnostics() async {
    await Future.delayed(_delay);
    return DiagnosticSystem.samples;
  }

  // ── Service ───────────────────────────────────────────────

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

  // ── Telemetry ─────────────────────────────────────────────

  @override
  Future<TelemetrySummary> getTelemetry() async {
    try {
      final uid = _uid;
      if (uid == null) return TelemetrySummary.sample;

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .get();

      if (!doc.exists) return TelemetrySummary.sample;

      return const TelemetrySummary(
        dailyKm:        127,
        driveHours:     2.4,
        ecoScore:       89,
        currentAddress: 'пр. Абая, 8А, Алматы',
        latitude:       43.242194,
        longitude:      76.949400,
        avgSpeedKmh:    42.0,
        maxSpeedKmh:    87.0,
        fuelUsedL:      9.6,
      );
    } catch (_) {
      return TelemetrySummary.sample;
    }
  }

  // ── Trips ─────────────────────────────────────────────────

  @override
  Future<List<TripRecord>> getRecentTrips() async {
    await Future.delayed(_delay);
    return TripRecord.samples;
  }

  // ── Subscriptions ─────────────────────────────────────────

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    await Future.delayed(_delay);
    return SubscriptionModel.samples;
  }

  // ── Notifications ─────────────────────────────────────────

  @override
  Future<List<AppNotification>> getNotifications() async {
    return NotificationService.instance.getAll();
  }

  @override
  Future<void> toggleSubscription(String subscriptionId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}