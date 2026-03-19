import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';


// ── Тёмный стиль карты ────────────────────────────────────────
const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a0a0c"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4a4a5a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0a0c"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212138"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#3a3a55"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e1e38"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#c8a96e","lightness":-60}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#060608"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0d0d14"}]}
]
''';

// Абая 8А — позиция машины по умолчанию (эмулятор)
const _kAlmaty = LatLng(43.25666, 76.94461);

const _kTelGoogleApiKey = 'AIzaSyC-26zwrGkcAkEE5TXMKPuWq0FJMyxXtNk';

// ============================================================
// KM DRIVE — Telemetry Screen v2
// Tabs: Overview | Engine/ECU | Tires | Trips + GPS map
// ============================================================

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key, this.showBackButton = false});
  final bool showBackButton;

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MockVehicleRepository();

  VehicleModel?     _vehicle;
  TelemetrySummary? _summary;
  List<TripRecord>  _trips = [];
  bool _loading = true;

  // ── Live simulation fields ─────────────────────────────────
  Timer? _liveTimer;
  final double _liveFuel     = 72.0;
  double _liveBattery  = 12.8;
  double _liveTemp     = 91.0;
  double _liveOil      = 75.0;
  int    _liveRpm      = 0;
  int    _liveTick     = 0;

  late TabController _tabs;

  // GPS / Map
  GoogleMapController? _mapCtrl;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  final Set<Marker>   _markers  = {};
  final Set<Polyline> _polylines = {};
  int?   _selectedTrip;
  bool   _followGps    = true;
  bool   _locationGranted = false;
  bool   _locationLoading = false;
  String _currentAddress  = '';
  StreamSubscription<Position>? _posStream;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadData();
    _initLocation();
    _startLiveSimulation();
  }

  Future<void> _loadData() async {
    final r = await Future.wait([
      _repo.getVehicle(),
      _repo.getTelemetry(),
      _repo.getRecentTrips(),
    ]);
    if (!mounted) return;
    final v = r[0] as VehicleModel;
    final s = r[1] as TelemetrySummary;
    final t = r[2] as List<TripRecord>;
    setState(() {
      _vehicle  = v;
      _summary  = s;
      _trips    = t;
      _loading  = false;
      if (_currentAddress.isEmpty) _currentAddress = s.currentAddress;
    });
    // Сразу ставим маркер на Абая 8А (заглушка)
    _placeVehicleMarker(s.position, s.currentAddress);
    // Камера на позицию машины
    final ctrl = await _mapCompleter.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: s.position, zoom: 15)));
  }

  void _startLiveSimulation() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _liveTick++;
      setState(() {
        // Двигатель заглушен — топливо не расходуется
        // _liveFuel остаётся неизменным
        _liveBattery  = 12.8 + ((_liveTick % 6) - 3) * 0.07;
        if (_liveTemp < 91) {
          _liveTemp = (_liveTemp + 1.5).clamp(0, 105);
        } else {
          _liveTemp = 91.0 + ((_liveTick % 4) - 2) * 0.8;
        }
        _liveOil = (_liveOil - 0.01).clamp(0, 100);
        // Двигатель заглушен — обороты 0
        _liveRpm   = 0;
      });
    });
  }

  Future<void> _initLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    if (mounted) setState(() { _locationGranted = true; _locationLoading = true; });

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _onPositionUpdate(pos);
    } catch (_) {}

    if (mounted) setState(() => _locationLoading = false);

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) => _onPositionUpdate(pos));
  }

  Future<void> _onPositionUpdate(Position pos) async {
    if (!mounted) return;
    if (pos.latitude == 0.0 && pos.longitude == 0.0) return;

    // Эмулятор обычно даёт координаты США — используем mock Абая 8А
    final inKazakhstan = pos.latitude >= 40.5 && pos.latitude <= 55.5 &&
        pos.longitude >= 50.0 && pos.longitude <= 87.5;

    if (!inKazakhstan) {
      if (_summary != null) {
        _placeVehicleMarker(_summary!.position, _summary!.currentAddress);
        if (_followGps) {
          final ctrl = await _mapCompleter.future;
          ctrl.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _summary!.position, zoom: 15)));
        }
      }
      return;
    }

    final latLng = LatLng(pos.latitude, pos.longitude);
    String address = _currentAddress;
    try {
      final placemarks = await placemarkFromCoordinates(
          pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.thoroughfare?.isNotEmpty == true) { parts.add(p.thoroughfare!); }
        else if (p.street?.isNotEmpty == true) { parts.add(p.street!); }
        if (p.subThoroughfare?.isNotEmpty == true) { parts.add(p.subThoroughfare!); }
        if (parts.isEmpty && p.subLocality?.isNotEmpty == true) { parts.add(p.subLocality!); }
        if (p.locality?.isNotEmpty == true) { parts.add(p.locality!); }
        else if (p.administrativeArea?.isNotEmpty == true) { parts.add(p.administrativeArea!); }
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _currentAddress = address);
    _placeVehicleMarker(latLng, address);
    if (_followGps) {
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  void _placeVehicleMarker(LatLng pos, String addr) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId == const MarkerId('vehicle'));
      _markers.add(Marker(
        markerId: const MarkerId('vehicle'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(40), // golden-orange
        infoWindow: InfoWindow(title: 'KM Jaqin A523KM', snippet: addr),
        zIndexInt: 2,
      ));
    });
  }

  void _showTrip(int idx) {
    if (_selectedTrip == idx) {
      setState(() {
        _selectedTrip = null;
        _polylines.clear();
        _markers
          ..removeWhere((m) => m.markerId == const MarkerId('trip_start'))
          ..removeWhere((m) => m.markerId == const MarkerId('trip_end'));
      });
      _goToCurrentLocation();
      return;
    }
    if (idx >= _trips.length) return;
    final trip = _trips[idx];
    if (trip.routePoints.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    // Place start/end markers immediately
    setState(() {
      _selectedTrip = idx;
      _markers
        ..removeWhere((m) => m.markerId == const MarkerId('trip_start'))
        ..removeWhere((m) => m.markerId == const MarkerId('trip_end'))
        ..add(Marker(
          markerId: const MarkerId('trip_start'),
          position: trip.routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: l10n.get(trip.from)),
          zIndexInt: 1,
        ))
        ..add(Marker(
          markerId: const MarkerId('trip_end'),
          position: trip.routePoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: l10n.get(trip.to)),
          zIndexInt: 1,
        ));
    });
    _followGps = false;
    _fitBounds([trip.routePoints.first, trip.routePoints.last]);
    // Build real route via Directions API
    _buildDirectionsRoute(trip.routePoints.first, trip.routePoints.last);
  }

  Future<void> _buildDirectionsRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${from.latitude},${from.longitude}'
      '&destination=${to.latitude},${to.longitude}'
      '&mode=driving&language=ru'
      '&key=$_kTelGoogleApiKey',
    );
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final encoded = routes[0]['overview_polyline']['points'] as String;
            final pts = _decodePolyline(encoded);
            if (mounted) {
              setState(() {
                _polylines
                  ..clear()
                  ..add(Polyline(
                    polylineId: const PolylineId('last_trip'),
                    points: pts,
                    color: const Color(0xFFC8A96E),
                    width: 4,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ));
              });
              _fitBounds(pts);
            }
            return;
          }
        }
      }
    } catch (_) {}
    // Fallback: straight line between points
    if (mounted) {
      setState(() {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('last_trip'),
            points: [from, to],
            color: const Color(0xFFC8A96E),
            width: 4,
          ));
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final pts = <LatLng>[];
    int idx = 0, lat = 0, lng = 0;
    while (idx < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(idx++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(idx++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return pts;
  }

  Future<void> _fitBounds(List<LatLng> pts) async {
    if (pts.isEmpty || _mapCtrl == null) return;
    final ctrl = _mapCtrl!;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.002, minLng - 0.002),
        northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
      ),
      60,
    ));
  }

  void _zoomIn() {
    _mapCtrl?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapCtrl?.animateCamera(CameraUpdate.zoomOut());
  }

  void _goToCurrentLocation() {
    _followGps = true;
    final target = _summary?.position ?? _kAlmaty;
    _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15)));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _posStream?.cancel();
    _liveTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: KmColors.background,
        body: Center(child: CircularProgressIndicator(
            color: KmColors.accent, strokeWidth: 1.5)));
    }

    final v = _vehicle!;
    final s = _summary!;

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: KmScreenHeader(
                title:    l10n.get('telemetryTitle'),
                subtitle: l10n.get('telemetrySubtitle'),
                showBack: widget.showBackButton,
                onBack:   () => Navigator.of(context).pop(),
              ),
            ),

            // ── Tabs ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: KmColors.surface2,
                borderRadius: BorderRadius.circular(KmRadius.md),
                border: Border.all(color: KmColors.border, width: 0.5),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: KmColors.accent,
                  borderRadius: BorderRadius.circular(KmRadius.md),
                ),
                labelColor: KmColors.background,
                unselectedLabelColor: KmColors.textMuted,
                labelStyle: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 11,
                    fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 11),
                tabs: [
                  Tab(text: l10n.get('telTabOverview')),
                  Tab(text: l10n.get('telTabEngine')),
                  Tab(text: l10n.get('telTabTires')),
                  Tab(text: l10n.get('telTabTrips')),
                ],
              ),
            ),

            // ── Tab content ───────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(vehicle: v, summary: s,
                    address: _currentAddress.isEmpty ? s.currentAddress : _currentAddress,
                    liveFuel: _liveFuel, liveBattery: _liveBattery,
                    liveTemp: _liveTemp, liveOil: _liveOil),
                  _EngineTab(vehicle: v, liveRpm: _liveRpm, liveTemp: _liveTemp),
                  _TiresTab(vehicle: v),
                  _TripsTab(
                    trips: _trips,
                    summary: s,
                    markers: _markers,
                    polylines: _polylines,
                    vehiclePos: _summary?.position ?? _kAlmaty,
                    selectedTrip: _selectedTrip,
                    onTripTap: _showTrip,
                    onMapCreated: (c) {
                      _mapCtrl = c;
                      if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
                    },
                    onMapTap: () => setState(() => _followGps = false),
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onLocateTap: _goToCurrentLocation,
                    locationGranted: _locationGranted,
                    locationLoading: _locationLoading,
                    currentAddress: _currentAddress,
                    mapStyle: _kMapStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Overview
// ══════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.vehicle,
    required this.summary,
    required this.address,
    required this.liveFuel,
    required this.liveBattery,
    required this.liveTemp,
    required this.liveOil,
  });
  final VehicleModel vehicle;
  final TelemetrySummary summary;
  final String address;
  final double liveFuel;
  final double liveBattery;
  final double liveTemp;
  final double liveOil;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Estimate range: ~10L per 100km, tank ~60L
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location ─────────────────────────────────
          _SectionCard(
            icon: '📍',
            title: l10n.get('currentLocation'),
            child: Row(children: [
              const Icon(Icons.location_on, color: KmColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(address, style: KmTextStyles.bodySmall)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Main metrics grid ─────────────────────────
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _MetricTile(
                icon: '⛽',
                label: l10n.get('telFuel'),
                value: '${liveFuel.toInt()}%',
                subValue: l10n.get('telEngineOff'),
                subLabel: l10n.get('telRangeKm'),
                progress: liveFuel / 100,
                color: liveFuel >= 70
                    ? KmColors.success
                    : liveFuel >= 30
                        ? KmColors.warning
                        : KmColors.error,
              ),
              _MetricTile(
                icon: '🔋',
                label: l10n.get('telBattery'),
                value: '${liveBattery.toStringAsFixed(1)} ${l10n.get('telBatteryVolts')}',
                subValue: l10n.get('telBattRange'),
                subLabel: l10n.get('telNormal'),
                progress: ((liveBattery - 11.5) / 3.2).clamp(0, 1),
                color: liveBattery >= 12.4
                    ? KmColors.success
                    : liveBattery >= 12.0
                        ? KmColors.warning
                        : KmColors.error,
              ),
              _MetricTile(
                icon: '🛣️',
                label: l10n.get('telMileage'),
                value: KmFormatters.kilometers(vehicle.mileageKm),
                subValue: '+${summary.dailyKm.toInt()} ${l10n.get('telOilKm')}',
                subLabel: l10n.get('telDailyKm'),
                progress: null,
                color: KmColors.textPrimary,
              ),
              _MetricTile(
                icon: '🌡️',
                label: l10n.get('telEngineTemp'),
                value: '${liveTemp.toInt()}°C',
                subValue: l10n.get('telEngTempRange'),
                subLabel: l10n.get('telNormal'),
                progress: ((liveTemp - 60) / 80).clamp(0, 1),
                color: liveTemp > 110
                    ? KmColors.error
                    : liveTemp > 105
                        ? KmColors.warning
                        : liveTemp >= 80
                            ? KmColors.success
                            : KmColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Today stats ───────────────────────────────
          _SectionCard(
            icon: '📊',
            title: l10n.get('telTabOverview'),
            child: Column(children: [
              _StatRow(l10n.get('telDailyKm'),
                  '${summary.dailyKm.toInt()} ${l10n.get('telOilKm')}'),
              _StatRow(l10n.get('telDriveTime'),
                  '${summary.driveHours.toStringAsFixed(1)} ч'),
              _StatRow(l10n.get('telAvgSpeed'),
                  '${summary.avgSpeedKmh.toInt()} ${l10n.get('kmh')}'),
              _StatRow(l10n.get('telMaxSpeed'),
                  '${summary.maxSpeedKmh.toInt()} ${l10n.get('kmh')}'),
              _StatRow(l10n.get('telFuelUsed'),
                  '${summary.fuelUsedL.toStringAsFixed(1)} л'),
              _StatRow(l10n.get('telEcoScore'),
                  '${summary.ecoScore}/100', valueColor: _ecoColor(summary.ecoScore)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Oil ───────────────────────────────────────
          _SectionCard(
            icon: '🔧',
            title: l10n.get('telOil'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(l10n.get('telOil'),
                      style: KmTextStyles.bodySmall)),
                  Text('${liveOil.toInt()}%',
                      style: KmTextStyles.bodySmall.copyWith(
                          color: _oilColor(liveOil),
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                KmProgressBar(value: liveOil / 100,
                    height: 4, color: _oilColor(liveOil)),
                const SizedBox(height: 6),
                Text('${l10n.get('telOilRange')} 1 200 ${l10n.get('telOilKm')}',
                    style: KmTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _ecoColor(int s) =>
      s >= 80 ? KmColors.success : s >= 60 ? KmColors.warning : KmColors.error;
  Color _oilColor(double p) =>
      p > 75 ? KmColors.success    // масло свежее
             : p > 50 ? KmColors.warning  // скоро замена
                      : KmColors.error;   // срочно менять
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Engine / ECU
// ══════════════════════════════════════════════════════════════

class _EngineTab extends StatelessWidget {
  const _EngineTab({
    required this.vehicle,
    required this.liveRpm,
    required this.liveTemp,
  });
  final VehicleModel vehicle;
  final int    liveRpm;
  final double liveTemp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Demo DTC codes linked to scan results
    final dtcs = [
      const DtcCode(code: 'C0045', systemKey: 'telDtcBrakes',
          descKey: 'dtcAbs', severity: VehicleSystemStatus.warning),
      const DtcCode(code: 'B2799', systemKey: 'telDtcElectro',
          descKey: 'dtcBcm', severity: VehicleSystemStatus.warning),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── RPM + Speed gauge row ─────────────────────
          Row(children: [
            Expanded(child: _GaugeCard(
              icon: '⚡',
              label: l10n.get('telRpm'),
              value: '$liveRpm',
              unit: 'RPM',
              progress: (liveRpm / 7000).clamp(0, 1),
              color: liveRpm > 5000
                  ? KmColors.error
                  : liveRpm > 3500
                      ? KmColors.warning
                      : KmColors.success,
            )),

          ]),
          const SizedBox(height: 12),

          // ── Engine temperature ────────────────────────
          _SectionCard(
            icon: '🌡️',
            title: l10n.get('telEngineTitle'),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(l10n.get('telEngineTemp'),
                    style: KmTextStyles.bodySmall)),
                Text('${liveTemp.toInt()}°C',
                    style: KmTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: liveTemp > 110
                            ? KmColors.error
                            : liveTemp > 105
                                ? KmColors.warning
                                : KmColors.success)),
              ]),
              const SizedBox(height: 8),
              KmProgressBar(
                  value: ((liveTemp - 60) / 80).clamp(0, 1),
                  height: 5,
                  color: liveTemp > 110 ? KmColors.error
                      : liveTemp > 105 ? KmColors.warning
                      : liveTemp >= 80 ? KmColors.success
                      : KmColors.warning),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                const Text('60°C', style: KmTextStyles.caption),
                Text(l10n.get('telEngTempRange'),
                    style: KmTextStyles.caption
                        .copyWith(color: KmColors.success)),
                const Text('140°C', style: KmTextStyles.caption),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // ── ECU Systems ───────────────────────────────
          _SectionCard(
            icon: '📡',
            title: l10n.get('telEcuTitle'),
            child: Column(children: [
              _ecuRow('⚙️', l10n.get('diagEngine'), vehicle.engineStatus, l10n),
              const Divider(color: KmColors.border, height: 16, thickness: 0.5),
              _ecuRow('🔋', l10n.get('diagBattery'),
                  liveTemp >= 80 && liveTemp <= 105
                      ? VehicleSystemStatus.ok
                      : VehicleSystemStatus.warning, l10n),
              const Divider(color: KmColors.border, height: 16, thickness: 0.5),
              _ecuRow('🌡️', l10n.get('diagCooling'),
                  liveTemp <= 105
                      ? VehicleSystemStatus.ok
                      : VehicleSystemStatus.warning, l10n),
              const Divider(color: KmColors.border, height: 16, thickness: 0.5),
              _ecuRow('🛑', l10n.get('diagBrakes'), VehicleSystemStatus.warning, l10n),
              const Divider(color: KmColors.border, height: 16, thickness: 0.5),
              _ecuRow('📡', l10n.get('diagElectro'), VehicleSystemStatus.warning, l10n),
              const Divider(color: KmColors.border, height: 16, thickness: 0.5),
              _ecuRow('💨', l10n.get('diagSuspension'), vehicle.tiresStatus, l10n),
            ]),
          ),
          const SizedBox(height: 12),

          // ── DTC Codes ─────────────────────────────────
          _SectionCard(
            icon: '⚠️',
            title: l10n.get('telDtcTitle'),
            child: Column(
              children: dtcs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KmColors.overlayAccent,
                    borderRadius: BorderRadius.circular(KmRadius.md),
                    border: Border.all(color: KmColors.accentDim, width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: KmColors.surface3,
                        borderRadius: BorderRadius.circular(KmRadius.xs),
                      ),
                      child: Text(d.code,
                          style: KmTextStyles.caption.copyWith(
                              color: KmColors.warning,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.get(d.systemKey),
                              style: KmTextStyles.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(l10n.get(d.descKey),
                              style: KmTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.warning_amber_rounded,
                        color: KmColors.warning, size: 16),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _ecuRow(String icon, String name, VehicleSystemStatus status,
    AppLocalizations l10n) {
  final color = status == VehicleSystemStatus.ok
      ? KmColors.success
      : status == VehicleSystemStatus.warning
          ? KmColors.warning
          : KmColors.error;
  final label = status == VehicleSystemStatus.ok
      ? l10n.get('telStatusOk')
      : status == VehicleSystemStatus.warning
          ? l10n.get('telStatusWarn')
          : l10n.get('telStatusCrit');

  return Row(children: [
    Text(icon, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 10),
    Expanded(child: Text(name, style: KmTextStyles.bodySmall)),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'DMSans', fontSize: 11,
              fontWeight: FontWeight.w600, color: color)),
    ),
  ]);
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — Tires
// ══════════════════════════════════════════════════════════════

class _TiresTab extends StatelessWidget {
  const _TiresTab({required this.vehicle});
  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tp = vehicle.tirePressure;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(
        children: [
          // ── Car diagram with tire indicators ─────────
          _TireDiagram(tp: tp, l10n: l10n),
          const SizedBox(height: 16),

          // ── Detail cards ──────────────────────────────
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _TireCard(label: l10n.get('telTireFL'),
                  value: tp.frontLeft, l10n: l10n),
              _TireCard(label: l10n.get('telTireFR'),
                  value: tp.frontRight, l10n: l10n),
              _TireCard(label: l10n.get('telTireRL'),
                  value: tp.rearLeft, l10n: l10n),
              _TireCard(label: l10n.get('telTireRR'),
                  value: tp.rearRight, l10n: l10n),
            ],
          ),
          const SizedBox(height: 12),

          // ── Legend ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KmColors.surface2,
              borderRadius: BorderRadius.circular(KmRadius.lg),
              border: Border.all(color: KmColors.border, width: 0.5),
            ),
            child: Column(children: [
              _LegendRow(KmColors.success, '2.0–2.8 ${l10n.get('telTireBar')}',
                  l10n.get('telNormal')),
              const SizedBox(height: 6),
              _LegendRow(KmColors.warning, '1.8–2.0 / 2.8–3.0 ${l10n.get('telTireBar')}',
                  l10n.get('telStatusWarn')),
              const SizedBox(height: 6),
              _LegendRow(KmColors.error, '< 1.8 / > 3.0 ${l10n.get('telTireBar')}',
                  l10n.get('telStatusCrit')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _TireDiagram extends StatelessWidget {
  const _TireDiagram({required this.tp, required this.l10n});
  final TirePressure tp;
  final AppLocalizations l10n;

  Color _c(double p) => p >= 2.0 && p <= 2.8
      ? KmColors.success
      : p >= 1.8 && p < 2.0 || p > 2.8 && p <= 3.0
          ? KmColors.warning
          : KmColors.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.xl),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(children: [
        Text(l10n.get('telTirePressure'),
            style: KmTextStyles.labelMedium.copyWith(
                color: KmColors.accent)),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            // Car silhouette placeholder
            Container(
              width: 120, height: 70,
              decoration: BoxDecoration(
                color: KmColors.surface3,
                borderRadius: BorderRadius.circular(KmRadius.md),
                border: Border.all(color: KmColors.border, width: 0.5),
              ),
              child: const Center(child: Text('🚗',
                  style: TextStyle(fontSize: 32))),
            ),
            // FL
            Positioned(top: 0, left: 0,
                child: _TireIndicator(tp.frontLeft.toStringAsFixed(1), _c(tp.frontLeft))),
            // FR
            Positioned(top: 0, right: 0,
                child: _TireIndicator(tp.frontRight.toStringAsFixed(1), _c(tp.frontRight))),
            // RL
            Positioned(bottom: 0, left: 0,
                child: _TireIndicator(tp.rearLeft.toStringAsFixed(1), _c(tp.rearLeft))),
            // RR
            Positioned(bottom: 0, right: 0,
                child: _TireIndicator(tp.rearRight.toStringAsFixed(1), _c(tp.rearRight))),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.get('telTireBar'),
            style: KmTextStyles.caption),
      ]),
    );
  }
}

class _TireIndicator extends StatelessWidget {
  const _TireIndicator(this.value, this.color);
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(value,
          style: TextStyle(
              fontFamily: 'DMSans', fontSize: 12,
              fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _TireCard extends StatelessWidget {
  const _TireCard({
    required this.label,
    required this.value,
    required this.l10n,
  });
  final String label;
  final double value;
  final AppLocalizations l10n;

  Color get _color => value >= 2.0 && value <= 2.8
      ? KmColors.success
      : value >= 1.8 ? KmColors.warning : KmColors.error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: KmTextStyles.caption),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value.toStringAsFixed(1),
                style: KmTextStyles.numeralMedium.copyWith(color: _color)),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l10n.get('telTireBar'),
                  style: KmTextStyles.caption),
            ),
          ]),
          KmProgressBar(value: (value / 3.2).clamp(0, 1), height: 3),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(this.color, this.range, this.label);
  final Color color;
  final String range;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(range, style: KmTextStyles.caption)),
      Text(label, style: KmTextStyles.caption.copyWith(color: color)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 4 — Trips + GPS map
// ══════════════════════════════════════════════════════════════

class _TripsTab extends StatelessWidget {
  const _TripsTab({
    required this.trips,
    required this.summary,
    required this.markers,
    required this.polylines,
    required this.vehiclePos,
    required this.selectedTrip,
    required this.onTripTap,
    required this.onMapCreated,
    required this.onMapTap,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocateTap,
    required this.locationGranted,
    required this.locationLoading,
    required this.currentAddress,
    required this.mapStyle,
  });

  final List<TripRecord>  trips;
  final TelemetrySummary  summary;
  final Set<Marker>       markers;
  final Set<Polyline>     polylines;
  final LatLng            vehiclePos;
  final int?              selectedTrip;
  final void Function(int)              onTripTap;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onMapTap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocateTap;
  final bool   locationGranted;
  final bool   locationLoading;
  final String currentAddress;
  final String mapStyle;

  CameraPosition get _initialCamera => CameraPosition(target: vehiclePos, zoom: 15);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        // ── Full-width map ────────────────────────────
        SliverToBoxAdapter(
          child: _MapSection(
            initialCamera: _initialCamera,
            markers: markers,
            polylines: polylines,
            currentAddress: currentAddress,
            mapStyle: mapStyle,
            locationGranted: locationGranted,
            locationLoading: locationLoading,
            onMapCreated: onMapCreated,
            onCameraMove: (_) => onMapTap(),
            onLocateTap: onLocateTap,
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
          ),
        ),
        // ── Stats row ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverToBoxAdapter(
            child: _TripStatsRow(summary: summary),
          ),
        ),
        // ── Trips list ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KmSectionLabel(l10n.get('recentTrips')),
                _TripsList(
                  trips: trips,
                  selectedIndex: selectedTrip,
                  onTripSelected: onTripTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google Map section ────────────────────────────────────────

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.initialCamera,
    required this.markers,
    required this.polylines,
    required this.currentAddress,
    required this.mapStyle,
    required this.locationGranted,
    required this.locationLoading,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onLocateTap,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final CameraPosition initialCamera;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String currentAddress;
  final String mapStyle;
  final bool locationGranted;
  final bool locationLoading;
  final void Function(GoogleMapController) onMapCreated;
  final void Function(CameraPosition) onCameraMove;
  final VoidCallback onLocateTap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 340,
      child: Stack(children: [
        // ── Google Map ────────────────────────────────
        GoogleMap(
          initialCameraPosition: initialCamera,
          onMapCreated: onMapCreated,
          onCameraMove: onCameraMove,
          markers: markers,
          polylines: polylines,
          mapType: MapType.normal,
          style: mapStyle.isNotEmpty ? mapStyle : null,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
          mapToolbarEnabled: false,
          trafficEnabled: false,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),

        // Gradient top
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xDD0A0A0C), Colors.transparent],
              ),
            ),
          ),
        ),

        // Gradient bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF0A0A0C), Colors.transparent],
              ),
            ),
          ),
        ),

        // Address + locate button
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xEA0A0A0C),
                      borderRadius: BorderRadius.circular(KmRadius.sm),
                      border: Border.all(
                          color: const Color(0x40C8A96E), width: 0.5),
                    ),
                    child: locationLoading
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(
                              width: 11, height: 11,
                              child: CircularProgressIndicator(
                                  color: KmColors.accent, strokeWidth: 1.3),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.get('locationSearching'),
                                style: KmTextStyles.caption),
                          ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.get('currentLocation').toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'DMSans', fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: KmColors.accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentAddress.isEmpty
                                    ? l10n.get('locationSearching')
                                    : currentAddress,
                                style: KmTextStyles.bodySmall
                                    .copyWith(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                _MapButton(
                    icon: Icons.my_location_rounded, onTap: onLocateTap),
              ],
            ),
          ),
        ),

        // Zoom buttons
        Positioned(
          right: 16, bottom: 70,
          child: Column(children: [
            _MapButton(icon: Icons.add_rounded, onTap: onZoomIn),
            const SizedBox(height: 6),
            _MapButton(icon: Icons.remove_rounded, onTap: onZoomOut),
          ]),
        ),

        // No permission warning
        if (!locationGranted && !locationLoading)
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xEE1A1208),
                borderRadius: BorderRadius.circular(KmRadius.sm),
                border: Border.all(
                    color: const Color(0x60C8A96E), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.location_off_rounded,
                    color: KmColors.warning, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.get('locationPermissionDenied'),
                    style: KmTextStyles.caption)),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Map button (tap + hold) ───────────────────────────────────

class _MapButton extends StatefulWidget {
  const _MapButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_MapButton> createState() => _MapButtonState();
}

class _MapButtonState extends State<_MapButton> {
  Timer? _holdTimer;
  bool _pressed = false;

  void _startHold() {
    widget.onTap();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      widget.onTap();
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _pressed = false);
  }

  @override
  void dispose() { _holdTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _startHold(); },
      onTapUp:   (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF1A1A24)
              : const Color(0xEA0A0A0C),
          borderRadius: BorderRadius.circular(KmRadius.sm),
          border: Border.all(
            color: _pressed ? KmColors.accent : const Color(0x40C8A96E),
            width: _pressed ? 1.0 : 0.5,
          ),
          boxShadow: const [BoxShadow(
              color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(widget.icon, color: KmColors.accent, size: 20),
      ),
    );
  }
}

// ── Trip stats row ────────────────────────────────────────────

class _TripStatsRow extends StatelessWidget {
  const _TripStatsRow({required this.summary});
  final TelemetrySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          KmMetricCell(
              value: '${summary.dailyKm.toInt()}',
              label: l10n.get('unitKmDay')),
          _VDivider(),
          KmMetricCell(
              value: KmFormatters.driveTime(summary.driveHours),
              label: l10n.get('unitHours')),
          _VDivider(),
          KmMetricCell(
            value: '${summary.ecoScore}',
            label: l10n.get('ecoScore'),
            valueColor: summary.ecoScore >= 80
                ? KmColors.success : KmColors.warning,
          ),
        ]),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5,
    margin: const EdgeInsets.symmetric(vertical: 12),
    color: KmColors.border,
  );
}

// ── Trips list ────────────────────────────────────────────────

class _TripsList extends StatefulWidget {
  const _TripsList({
    required this.trips,
    required this.onTripSelected,
    this.selectedIndex,
  });
  final List<TripRecord> trips;
  final void Function(int) onTripSelected;
  final int? selectedIndex;

  @override
  State<_TripsList> createState() => _TripsListState();
}

class _TripsListState extends State<_TripsList> {
  final Set<int> _expanded = {};

  void _toggle(int i) => setState(() {
    if (_expanded.contains(i)) { _expanded.remove(i); } else { _expanded.add(i); }
  });

  String _dateLabel(BuildContext ctx, DateTime date) {
    final l10n = AppLocalizations.of(ctx);
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return l10n.get('today');
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month) return l10n.get('yesterday');
    return KmFormatters.dateShort(date);
  }

  String _ecoRating(AppLocalizations l10n, int score) {
    if (score >= 90) return l10n.get('ecoExcellent');
    if (score >= 80) return l10n.get('ecoGood');
    if (score >= 65) return l10n.get('ecoAvg');
    return l10n.get('ecoPoor');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: widget.trips.asMap().entries.map((e) {
        final i = e.key;
        final t = e.value;
        final isOpen     = _expanded.contains(i);
        final isSelected = widget.selectedIndex == i;
        final avgSpeed   = t.durationMin > 0
            ? (t.distanceKm / (t.durationMin / 60)).toStringAsFixed(0)
            : '0';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _toggle(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KmColors.surface2,
                borderRadius: BorderRadius.circular(KmRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? KmColors.accent
                      : isOpen ? const Color(0x40C8A96E) : KmColors.border,
                  width: isSelected ? 1.0 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Expanded(child: Text(
                      '${l10n.get(t.from)} → ${l10n.get(t.to)}',
                      style: KmTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500))),
                    Row(children: [
                      Text(_dateLabel(context, t.date),
                          style: KmTextStyles.caption),
                      const SizedBox(width: 4),
                      Icon(
                        isOpen ? Icons.keyboard_arrow_up_rounded
                               : Icons.keyboard_arrow_down_rounded,
                        size: 16, color: KmColors.textMuted),
                    ]),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    '${t.distanceKm.toStringAsFixed(1)} ${l10n.get('km')} · '
                    '${t.durationMin} ${l10n.get('min')} · '
                    '${KmFormatters.fuelConsumption(t.fuelConsumption)}',
                    style: KmTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: t.ecoScore >= 85
                            ? KmColors.success : KmColors.warning,
                        shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${l10n.get('ecoScore')}: ${t.ecoScore}',
                        style: KmTextStyles.caption),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => widget.onTripSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x30C8A96E)
                              : const Color(0x14C8A96E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? KmColors.accent
                                : const Color(0x40C8A96E),
                            width: 0.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.route_rounded, size: 11,
                              color: isSelected
                                  ? KmColors.accent : KmColors.accentDim),
                          const SizedBox(width: 4),
                          Text(l10n.get('showOnMap'),
                              style: TextStyle(
                                fontFamily: 'DMSans', fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? KmColors.accent : KmColors.accentDim,
                                letterSpacing: 0.3)),
                        ]),
                      ),
                    ),
                  ]),
                  if (isOpen) ...[
                    const SizedBox(height: 12),
                    const Divider(color: KmColors.border,
                        thickness: 0.5, height: 0),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.0,
                      mainAxisSpacing: 10, crossAxisSpacing: 8,
                      children: [
                        _StatCell(l10n.get('tripDistance'),
                            '${t.distanceKm.toStringAsFixed(1)} ${l10n.get('km')}'),
                        _StatCell(l10n.get('tripDuration'),
                            '${t.durationMin} ${l10n.get('min')}'),
                        _StatCell(l10n.get('avgSpeed'),
                            '$avgSpeed ${l10n.get('kmh')}'),
                        _StatCell(l10n.get('fuelUsed'),
                            KmFormatters.fuelConsumption(t.fuelConsumption)),
                        _StatCell(l10n.get('ecoRating'),
                            _ecoRating(l10n, t.ecoScore)),
                        _StatCell(l10n.get('date'),
                            KmFormatters.dateShort(t.date)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      Text(l10n.get('ecoScore'), style: KmTextStyles.caption),
                      Text('${t.ecoScore}/100',
                          style: KmTextStyles.caption.copyWith(
                            color: t.ecoScore >= 85
                                ? KmColors.success : KmColors.warning)),
                    ]),
                    const SizedBox(height: 4),
                    KmProgressBar(value: t.ecoScore / 100),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: KmTextStyles.caption,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value, style: KmTextStyles.bodySmall
            .copyWith(fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final String icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(title, style: KmTextStyles.labelLarge),
          ]),
          const SizedBox(height: 10),
          const Divider(color: KmColors.border, height: 0, thickness: 0.5),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.subLabel,
    required this.progress,
    required this.color,
  });
  final String icon;
  final String label;
  final String value;
  final String subValue;
  final String subLabel;
  final double? progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: KmTextStyles.caption),
          ]),
          Text(value,
              style: KmTextStyles.numeralSmall.copyWith(
                  color: color, fontSize: 20)),
          if (progress != null) ...[
            KmProgressBar(value: progress!.clamp(0, 1), height: 3, color: color),
            const SizedBox(height: 2),
          ],
          Row(children: [
            Expanded(child: Text(subLabel, style: KmTextStyles.caption,
                overflow: TextOverflow.ellipsis)),
            Text(subValue, style: KmTextStyles.caption
                .copyWith(color: color)),
          ]),
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
  });
  final String icon;
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: KmTextStyles.caption),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value,
                style: KmTextStyles.numeralMedium.copyWith(color: color)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: KmTextStyles.caption)),
          ]),
          const SizedBox(height: 6),
          KmProgressBar(value: progress.clamp(0, 1), height: 4),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: KmTextStyles.bodySmall)),
        Text(value,
            style: KmTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? KmColors.textPrimary)),
      ]),
    );
  }
}