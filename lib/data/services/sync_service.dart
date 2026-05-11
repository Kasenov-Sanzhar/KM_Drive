import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';

// ============================================================
// KM DRIVE — SyncService
// Синхронизация данных автомобиля с Firestore в реальном времени
// Заглушка: при отсутствии авторизации — работает в offline-режиме
// ============================================================

enum SyncStatus { syncing, synced, offline, error }

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  SyncStatus _status = SyncStatus.offline;
  SyncStatus get status => _status;

  // Текущие данные из Firestore (заглушка если нет соединения)
  VehicleModel? _vehicleData;
  VehicleModel? get vehicleData => _vehicleData;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  StreamSubscription? _connectivitySub;
  StreamSubscription? _firestoreSub;

  // ── Инициализация ─────────────────────────────────────────

  Future<void> init() async {
    // Слушаем изменения сети
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) => _onConnectivityChange(results),
    );

    // Проверяем начальное состояние сети
    final result = await Connectivity().checkConnectivity();
    await _onConnectivityChange(result);
  }

  Future<void> _onConnectivityChange(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (!hasNetwork) {
      _setStatus(SyncStatus.offline);
      _firestoreSub?.cancel();
      return;
    }

    // Есть сеть — пробуем синхронизацию
    await _startSync();
  }

  // ── Синхронизация с Firestore ─────────────────────────────

  Future<void> _startSync() async {
    _setStatus(SyncStatus.syncing);

    try {
      // Синхронизируем только реальных (email) пользователей
      if (_auth.currentUser == null || _auth.currentUser!.isAnonymous) {
        _setStatus(SyncStatus.offline);
        return;
      }

      final uid = _auth.currentUser!.uid;

      // Подписываемся на данные автомобиля в реальном времени
      _firestoreSub?.cancel();
      _firestoreSub = _firestore
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .snapshots()
          .listen(
            (snap) => _onVehicleSnapshot(snap),
            onError: (_) => _setStatus(SyncStatus.offline),
          );

      _setStatus(SyncStatus.synced);
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService] error: \$e');
      _setStatus(SyncStatus.offline);
    }
  }

  void _onVehicleSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) {
      // Документа нет — пишем заглушку
      _seedInitialData();
      return;
    }
    _setStatus(SyncStatus.synced);
  }

  // Создаём начальные данные автомобиля в Firestore
  Future<void> _seedInitialData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .set({
        'vin':         'KZ1GF7ES2PA123456',
        'model':       'KM Jaqin 2.0T Premium',
        'color':       'Deep Navy',
        'year':        2024,
        'mileageKm':   3847,
        'fuelPercent': 72.0,
        'lastSyncAt':  FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Push-уведомления — подписка на топики ─────────────────

  /// Обновляет данные пробега и топлива в Firestore
  Future<void> updateTelemetry({
    required double fuelPercent,
    required int mileageKm,
    required double batteryVolts,
    required double engineTempC,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .update({
        'fuelPercent':   fuelPercent,
        'mileageKm':     mileageKm,
        'batteryVolts':  batteryVolts,
        'engineTempC':   engineTempC,
        'lastSyncAt':    FieldValue.serverTimestamp(),
      });
    } catch (_) {} // Offline — игнорируем, данные сохранены локально
  }

  // syncBooking перенесён в BookingService.save() → Firestore direct write

  // ── Подключение / статус сети ─────────────────────────────

  /// Текстовое описание типа соединения
  Future<String> getConnectionType() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.wifi))    return 'Wi-Fi';
    if (results.contains(ConnectivityResult.mobile))  return '4G/5G';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Нет соединения';
  }

  Future<bool> get isOnline async {
    final r = await Connectivity().checkConnectivity();
    return r.any((c) => c != ConnectivityResult.none);
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _firestoreSub?.cancel();
    _statusController.close();
  }
}