import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Telemetry Screen
// Google Maps + GPS + Reverse Geocoding + маршруты поездок
// ============================================================

const _mapStyle = '''
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

// Абая 8А, Алматы — позиция машины по умолчанию
const _almatyFallback = LatLng(43.25666, 76.94461);

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key, this.showBackButton = false});
  final bool showBackButton;

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final _repo = MockVehicleRepository();

  // Данные
  TelemetrySummary? _summary;
  List<TripRecord> _trips = [];
  bool _loading = true;

  // GPS
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _locationGranted = false;
  bool _locationLoading = false;
  String _currentAddress = '';

  // Карта
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  int? _selectedTripIndex;

  // Флаг — следить за GPS или пользователь двигает карту вручную
  bool _followGps = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initLocation();
  }

  // ── Данные репозитория ────────────────────────────────────

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getTelemetry(),
      _repo.getRecentTrips(),
    ]);
    if (!mounted) return;
    setState(() {
      _summary        = results[0] as TelemetrySummary;
      _trips          = results[1] as List<TripRecord>;
      _loading        = false;
      if (_currentAddress.isEmpty) {
        _currentAddress = _summary!.currentAddress;
      }
    });

    // Сразу ставим маркер машины на mock-позицию (Абая 8А)
    // Он будет перезаписан реальным GPS если тот придёт из Казахстана
    _placeVehicleMarker(_summary!.position, _summary!.currentAddress);

    // Камера сразу на позицию машины
    final controller = await _mapCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _summary!.position, zoom: 15)));
  }

  // Ставит/обновляет маркер машины не трогая маршрутные маркеры
  void _placeVehicleMarker(LatLng pos, String address) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId == const MarkerId('vehicle'));
      _markers.add(Marker(
        markerId: const MarkerId('vehicle'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(40),
        infoWindow: InfoWindow(title: 'KM Jaqin A523KM', snippet: address),
        zIndexInt: 2,
      ));
    });
  }

  // ── GPS + Reverse Geocoding ───────────────────────────────

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    if (mounted) setState(() { _locationGranted = true; _locationLoading = true; });

    // Первое получение координат
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

    // Непрерывные обновления каждые 10м
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) => _onPositionUpdate(pos));
  }

  Future<void> _onPositionUpdate(Position pos) async {
    if (!mounted) return;
    if (pos.latitude == 0.0 && pos.longitude == 0.0) return;

    final inKazakhstan = pos.latitude >= 40.5 && pos.latitude <= 55.5 &&
        pos.longitude >= 50.0 && pos.longitude <= 87.5;

    if (!inKazakhstan) {
      // Эмулятор без локации — используем mock (Абая 8А)
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
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
          parts.add(p.thoroughfare!);
        } else if (p.street != null && p.street!.isNotEmpty) {
          parts.add(p.street!);
        }
        if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) {
          parts.add(p.subThoroughfare!);
        }
        if (parts.isEmpty && p.subLocality != null && p.subLocality!.isNotEmpty) {
          parts.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          parts.add(p.locality!);
        } else if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          parts.add(p.administrativeArea!);
        }
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _currentAddress  = address;
    });
    _placeVehicleMarker(latLng, address);

    if (_followGps) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  // ── Маршрут поездки — toggle: повторный тап снимает выбор ──

  void _showTripRoute(int tripIndex) {
    // Повторный тап на уже выбранный маршрут — сбрасываем, показываем машину
    if (_selectedTripIndex == tripIndex) {
      setState(() {
        _selectedTripIndex = null;
        _polylines.clear();
        _markers
          ..removeWhere((m) => m.markerId == const MarkerId('trip_start'))
          ..removeWhere((m) => m.markerId == const MarkerId('trip_end'));
      });
      _goToCurrentLocation(); // возвращаемся к позиции машины
      return;
    }

    if (tripIndex >= _trips.length) return;
    final trip = _trips[tripIndex];
    if (trip.routePoints.isEmpty) return;

    setState(() {
      _selectedTripIndex = tripIndex;
      _polylines.clear();
      _markers
        ..removeWhere((m) => m.markerId == const MarkerId('trip_start'))
        ..removeWhere((m) => m.markerId == const MarkerId('trip_end'));

      _polylines.add(Polyline(
        polylineId: const PolylineId('last_trip'),
        points: trip.routePoints,
        color: const Color(0xFFC8A96E),
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));

      _markers
        ..add(Marker(
          markerId: const MarkerId('trip_start'),
          position: trip.routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: AppLocalizations.of(context).get(trip.from)),
          zIndexInt: 1,
        ))
        ..add(Marker(
          markerId: const MarkerId('trip_end'),
          position: trip.routePoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: AppLocalizations.of(context).get(trip.to)),
          zIndexInt: 1,
        ));
    });

    // При показе маршрута — отключаем слежение за GPS чтобы камера не прыгала
    _followGps = false;
    _fitRouteBounds(trip.routePoints);
  }

  void _fitRouteBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    final controller = await _mapCompleter.future;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.002, minLng - 0.002),
          northeast: LatLng(maxLat + 0.002, maxLng + 0.002),
        ),
        60,
      ),
    );
  }

  // ── Зум ──────────────────────────────────────────────────

  Future<void> _zoomIn() async {
    final controller = await _mapCompleter.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = await _mapCompleter.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  // ── Кнопка «моя позиция» ──────────────────────────────────

  Future<void> _goToCurrentLocation() async {
    _followGps = true;

    LatLng target;
    double zoom = 16;

    // Если реальный GPS в Казахстане — используем его
    final hasRealPos = _currentPosition != null &&
        !(_currentPosition!.latitude == 0.0 && _currentPosition!.longitude == 0.0);
    final inKz = hasRealPos &&
        _currentPosition!.latitude >= 40.5 && _currentPosition!.latitude <= 55.5 &&
        _currentPosition!.longitude >= 50.0 && _currentPosition!.longitude <= 87.5;

    if (inKz) {
      target = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    } else if (_summary != null) {
      // Fallback: mock-позиция ул. Абая 8А
      target = _summary!.position;
    } else {
      target = _almatyFallback;
      zoom = 13;
    }

    final controller = await _mapCompleter.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom)));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  CameraPosition get _initialCamera => CameraPosition(
        target: _summary?.position ?? _almatyFallback,
        zoom: 13,
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: KmColors.background,
        body: Center(child: CircularProgressIndicator(
            color: KmColors.accent, strokeWidth: 1.5)),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KmColors.background,
      body: CustomScrollView(
        // ✅ Передаём жесты карты — чтобы карта внутри скролла двигалась
        scrollBehavior: const MaterialScrollBehavior(),
        slivers: [
          if (widget.showBackButton)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: KmScreenHeader(
                    title: l10n.get('telemetryTitle'),
                    subtitle: l10n.get('telemetrySubtitle'),
                    showBack: true,
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: _MapSection(
              initialCamera: _initialCamera,
              markers: _markers,
              polylines: _polylines,
              currentAddress: _currentAddress,
              locationGranted: _locationGranted,
              locationLoading: _locationLoading,
              mapStyle: _mapStyle,
              onMapCreated: (controller) {
                _mapController = controller;
                if (!_mapCompleter.isCompleted) {
                  _mapCompleter.complete(controller);
                }
              },
              onCameraMove: (_) { _followGps = false; },
              onLocateTap: _goToCurrentLocation,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            sliver: SliverToBoxAdapter(
              child: _TripStatsRow(summary: _summary!),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KmSectionLabel(l10n.get('recentTrips')),
                  _TripsList(
                    trips: _trips,
                    selectedIndex: _selectedTripIndex,
                    onTripSelected: _showTripRoute,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Секция карты ──────────────────────────────────────────────

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
        // ── Google Map ────────────────────────────────────
        GoogleMap(
          initialCameraPosition: initialCamera,
          onMapCreated: onMapCreated,
          onCameraMove: onCameraMove,
          markers: markers,
          polylines: polylines,
          mapType: MapType.normal,
          style: mapStyle,
          myLocationEnabled: false,   // отключаем — показывает GPS эмулятора (США)
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

        // Градиент сверху
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

        // Градиент снизу
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

        // ── Адрес сверху слева + кнопка геолокации ───────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Адресный блок
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
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 11, height: 11,
                                child: CircularProgressIndicator(
                                  color: KmColors.accent,
                                  strokeWidth: 1.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.get('locationSearching'),
                                  style: KmTextStyles.caption),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.get('currentLocation').toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 8,
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
                                style: KmTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка «моя позиция»
                _MapButton(
                  icon: Icons.my_location_rounded,
                  onTap: onLocateTap,
                ),
              ],
            ),
          ),
        ),

        // ── Кнопки зума справа снизу ──────────────────────
        Positioned(
          right: 16,
          bottom: 70,
          child: Column(
            children: [
              _MapButton(icon: Icons.add_rounded, onTap: onZoomIn),
              const SizedBox(height: 6),
              _MapButton(icon: Icons.remove_rounded, onTap: onZoomOut),
            ],
          ),
        ),

        // Предупреждение «нет разрешения»
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
                Expanded(
                  child: Text(
                    l10n.get('locationPermissionDenied'),
                    style: KmTextStyles.caption,
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Кнопка управления картой (tap + hold) ─────────────────────

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
    widget.onTap(); // первое срабатывание сразу
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
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _startHold();
      },
      onTapUp: (_) => _stopHold(),
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
            color: _pressed
                ? KmColors.accent
                : const Color(0x40C8A96E),
            width: _pressed ? 1.0 : 0.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(widget.icon,
            color: _pressed ? KmColors.accent : KmColors.accent,
            size: 20),
      ),
    );
  }
}

// ── Статистика ────────────────────────────────────────────────

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

// ── Список поездок ────────────────────────────────────────────

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
        if (_expanded.contains(i)) {
          _expanded.remove(i);
        } else {
          _expanded.add(i);
        }
      });

  String _dateLabel(BuildContext ctx, DateTime date) {
    final l10n = AppLocalizations.of(ctx);
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return l10n.get('today');
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month) {
      return l10n.get('yesterday');
    }
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
        final i          = e.key;
        final t          = e.value;
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
                      : isOpen
                          ? const Color(0x40C8A96E)
                          : KmColors.border,
                  width: isSelected ? 1.0 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок строки
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${l10n.get(t.from)} → ${l10n.get(t.to)}',
                            style: KmTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w500)),
                      ),
                      Row(children: [
                        Text(_dateLabel(context, t.date),
                            style: KmTextStyles.caption),
                        const SizedBox(width: 4),
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16, color: KmColors.textMuted,
                        ),
                      ]),
                    ],
                  ),
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
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${l10n.get('ecoScore')}: ${t.ecoScore}',
                        style: KmTextStyles.caption),
                    const Spacer(),
                    // ── Кнопка «Показать на карте» ─────────
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
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route_rounded,
                                size: 11,
                                color: isSelected
                                    ? KmColors.accent : KmColors.accentDim),
                            const SizedBox(width: 4),
                            Text(
                              l10n.get('showOnMap'),
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? KmColors.accent : KmColors.accentDim,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  // ── Детали поездки (раскрытие) ────────────
                  if (isOpen) ...[
                    const SizedBox(height: 12),
                    const Divider(
                        color: KmColors.border,
                        thickness: 0.5,
                        height: 0),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.0,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 8,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.get('ecoScore'),
                            style: KmTextStyles.caption),
                        Text('${t.ecoScore}/100',
                            style: KmTextStyles.caption.copyWith(
                              color: t.ecoScore >= 85
                                  ? KmColors.success : KmColors.warning,
                            )),
                      ],
                    ),
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
        Text(label,
            style: KmTextStyles.caption,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value,
            style: KmTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}