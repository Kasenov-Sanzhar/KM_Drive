import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Dealer Screen v4
// In-app route via Google Directions API + GPS like Telemetry
// ============================================================

// ── Constants ─────────────────────────────────────────────────

const _kGoogleApiKey = 'AIzaSyC-26zwrGkcAkEE5TXMKPuWq0FJMyxXtNk';
// Абая 8А — заглушка когда нет реального GPS (эмулятор)
const _kAlmaty = LatLng(43.242194, 76.949400); // пр. Абая, 8А — Университет Международного Бизнеса

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

// ── Dealer model ──────────────────────────────────────────────

enum DealerType { sales, service, both }

class _Dealer {
  const _Dealer({
    required this.id,
    required this.addrKey,
    required this.phone,
    required this.wa,
    required this.pos,
    required this.type,
    required this.hours,
    required this.isOpen,
    required this.km,
  });
  final String     id;
  final String     addrKey;
  final String     phone;
  final String     wa;
  final LatLng     pos;
  final DealerType type;
  final String     hours;
  final bool       isOpen;
  final double     km;
}

const _kDealers = [
  _Dealer(id:'d1', addrKey:'dealerAddressVal', phone:'+77271234567', wa:'77271234567',
      pos:LatLng(43.2220,76.9080), type:DealerType.both, hours:'09:00–20:00', isOpen:true, km:1.2),
  _Dealer(id:'d2', addrKey:'dealerAddr2',     phone:'+77272345678', wa:'77272345678',
      pos:LatLng(43.2510,76.9340), type:DealerType.service, hours:'08:00–19:00', isOpen:true, km:3.8),
  _Dealer(id:'d3', addrKey:'dealerAddr3',     phone:'+77273456789', wa:'77273456789',
      pos:LatLng(43.2050,76.8750), type:DealerType.sales, hours:'10:00–21:00', isOpen:false, km:5.1),
  _Dealer(id:'d4', addrKey:'dealerAddr4',     phone:'+77274567890', wa:'77274567890',
      pos:LatLng(43.2680,76.9620), type:DealerType.both, hours:'09:00–20:00', isOpen:true, km:6.4),
];

// ── Screen ────────────────────────────────────────────────────

class DealerScreen extends StatefulWidget {
  const DealerScreen({super.key});
  @override
  State<DealerScreen> createState() => _DealerScreenState();
}

class _DealerScreenState extends State<DealerScreen>
    with SingleTickerProviderStateMixin {

  // ── Map
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapCtrl;
  final Set<Marker>   _markers   = {};
  final Set<Polyline> _polylines = {};

  // ── Tabs
  late TabController _tabs;

  // ── Selection & filter
  _Dealer? _selected;
  int      _filter = 0; // 0=all 1=service 2=sales

  // ── Route state
  bool _routeBuilding = false;
  bool _routeBuilt    = false;
  LatLng? _routeDest;    // destination of current route

  // ── GPS (identical to TelemetryScreen)
  LatLng  _userPos     = _kAlmaty;
  String  _userAddress = 'пр. Абая, 8А, Алматы'; // UIB
  StreamSubscription<Position>? _posStream;

  // ── Search
  final _searchCtrl = TextEditingController();
  String  _searchQuery  = '';
  LatLng? _searchResult; // coords of last search result
  String  _searchLabel  = '';

  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAllMarkers());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _posStream?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // GPS — same as TelemetryScreen
  // ══════════════════════════════════════════════════════════

  Future<void> _initLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) { _fallbackPos(); return; }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) { _fallbackPos(); return; }
    }
    if (perm == LocationPermission.deniedForever) { _fallbackPos(); return; }


    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15)),
      );
      await _onPos(pos);
    } catch (_) { _fallbackPos(); }

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 20),
    ).listen(_onPos);
  }

  void _fallbackPos() {
    // Reset to Абая 8А and rebuild everything
    _userPos = _kAlmaty;
    _userAddress = 'пр. Абая, 8А, Алматы';
    if (mounted) {
      _rebuildAllMarkers();
    }
  }

  Future<void> _onPos(Position pos) async {
    if (!mounted) return;
    if (pos.latitude == 0 && pos.longitude == 0) return;

    // Emulator → US coords → use Абая 8А
    final inKz = pos.latitude >= 40.5 && pos.latitude <= 55.5 &&
        pos.longitude >= 50.0 && pos.longitude <= 87.5;

    if (!inKz) {
      // Emulator — use Абая 8А
      _userPos = _kAlmaty;
      _userAddress = 'пр. Абая, 8А, Алматы';
      _rebuildAllMarkers();
      return;
    }

    final ll = LatLng(pos.latitude, pos.longitude);
    String addr = _userAddress;
    try {
      final pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (pm.isNotEmpty) {
        final p = pm.first;
        final parts = <String>[];
        if (p.thoroughfare?.isNotEmpty == true) { parts.add(p.thoroughfare!); }
        else if (p.street?.isNotEmpty == true) { parts.add(p.street!); }
        if (p.subThoroughfare?.isNotEmpty == true) { parts.add(p.subThoroughfare!); }
        if (parts.isEmpty && p.subLocality?.isNotEmpty == true) { parts.add(p.subLocality!); }
        if (p.locality?.isNotEmpty == true) { parts.add(p.locality!); }
        else if (p.administrativeArea?.isNotEmpty == true) { parts.add(p.administrativeArea!); }
        if (parts.isNotEmpty) { addr = parts.join(', '); }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() { _userPos = ll; _userAddress = addr; });
    _placeUserMarker(ll, addr);
  }

  void _placeUserMarker(LatLng pos, String addr) {
    if (!mounted) return;
    setState(() {
      _userPos = pos;
      _userAddress = addr;
      _markers.removeWhere((m) => m.markerId == const MarkerId('user'));
      _markers.add(Marker(
        markerId: const MarkerId('user'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Вы здесь', snippet: addr),
        zIndexInt: 3,
      ));
    });
  }

  // ══════════════════════════════════════════════════════════
  // Markers
  // ══════════════════════════════════════════════════════════

  void _rebuildAllMarkers() {
    if (!mounted) return;
    final ms = <Marker>{};

    // User
    ms.add(Marker(
      markerId: const MarkerId('user'),
      position: _userPos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: 'Вы здесь', snippet: _userAddress),
      zIndexInt: 3,
    ));

    // Search result pin
    if (_searchResult != null) {
      ms.add(Marker(
        markerId: const MarkerId('search'),
        position: _searchResult!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: _searchLabel),
        zIndexInt: 4,
      ));
    }

    // Dealer markers (filtered)
    for (final d in _visibleDealers) {
      final isSel = _selected?.id == d.id;
      ms.add(Marker(
        markerId: MarkerId(d.id),
        position: d.pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          d.isOpen
              ? (isSel ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueYellow)
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(title: 'KM Motors',
            snippet: '${d.hours} • ${d.km} км'),
        zIndexInt: isSel ? 2 : 1,
        onTap: () => _selectDealer(d),
      ));
    }

    setState(() { _markers.clear(); _markers.addAll(ms); });
  }

  List<_Dealer> get _visibleDealers {
    var list = _kDealers.toList();
    if (_filter == 1) { list = list.where((d) => d.type != DealerType.sales).toList(); }
    if (_filter == 2) { list = list.where((d) => d.type != DealerType.service).toList(); }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final l10n = AppLocalizations.of(context);
      list = list.where((d) =>
          l10n.get(d.addrKey).toLowerCase().contains(q) ||
          'km motors'.contains(q)).toList();
    }
    list.sort((a, b) => a.km.compareTo(b.km));
    return list;
  }

  void _selectDealer(_Dealer d) {
    setState(() { _selected = d; _routeBuilt = false; _polylines.clear(); });
    _rebuildAllMarkers();
    _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: d.pos, zoom: 15)));
  }

  void _changeFilter(int v) {
    setState(() {
      _filter = v;
      if (_selected != null &&
          !_visibleDealers.any((d) => d.id == _selected!.id)) {
        _selected = null;
        _polylines.clear();
        _routeBuilt = false;
      }
    });
    _rebuildAllMarkers();
  }

  // ══════════════════════════════════════════════════════════
  // Route via Google Directions API → polyline on map
  // ══════════════════════════════════════════════════════════

  Future<void> _buildRoute(LatLng dest) async {
    if (_routeBuilding) return;
    setState(() { _routeBuilding = true; _polylines.clear(); _routeBuilt = false; });

    final origin = '${_userPos.latitude},${_userPos.longitude}';
    final destination = '${dest.latitude},${dest.longitude}';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin'
      '&destination=$destination'
      '&mode=driving'
      '&language=ru'
      '&key=$_kGoogleApiKey',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final status = data['status'] as String;
        if (status == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final encoded = routes[0]['overview_polyline']['points'] as String;
            final pts = _decodePolyline(encoded);
            if (mounted) {
              setState(() {
                _routeBuilt   = true;
                _routeDest    = dest;
                _routeBuilding = false;
                _polylines
                  ..clear()
                  ..add(Polyline(
                    polylineId: const PolylineId('route'),
                    points: pts,
                    color: KmColors.accent,
                    width: 4,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    jointType: JointType.round,
                  ));
              });
              _fitBounds([_userPos, dest]);
            }
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: show error
    if (mounted) {
      setState(() => _routeBuilding = false);
      _snack('Не удалось построить маршрут');
    }
  }

  void _clearRoute() {
    setState(() { _polylines.clear(); _routeBuilt = false; _routeDest = null; });
  }

  // Google encoded polyline decoder
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
    if (pts.isEmpty) return;
    final ctrl = await _mapCompleter.future;
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
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      ), 60));
  }

  // ══════════════════════════════════════════════════════════
  // Search with geocoding → pin + optional route
  // ══════════════════════════════════════════════════════════

  Future<void> _searchAndGo(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searchQuery = query);
    _rebuildAllMarkers();

    try {
      final locs = await locationFromAddress('$query, Алматы, Казахстан');
      if (locs.isNotEmpty && mounted) {
        final ll = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() { _searchResult = ll; _searchLabel = query; });
        _rebuildAllMarkers();
        final c = await _mapCompleter.future;
        c.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: ll, zoom: 16)));
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // Phone / WhatsApp
  // ══════════════════════════════════════════════════════════

  void _showCall(_Dealer d) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: KmColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CallSheet(
        phone: d.phone, l10n: l10n,
        onCall: () async {
          Navigator.pop(context);
          await launchUrl(Uri(scheme: 'tel', path: d.phone));
        },
      ),
    );
  }

  void _showWa(_Dealer d) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: KmColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WaSheet(
        phone: d.wa, l10n: l10n,
        onOpen: () async {
          Navigator.pop(context);
          final app = Uri.parse('whatsapp://send?phone=${d.wa}');
          final web = Uri.parse('https://api.whatsapp.com/send?phone=${d.wa}');
          if (await canLaunchUrl(app)) {
            await launchUrl(app);
          } else if (await canLaunchUrl(web)) {
            await launchUrl(web, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) _snack(l10n.get('dealerWaNotInstalled'));
          }
        },
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: KmTextStyles.bodySmall),
      backgroundColor: KmColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: KmScreenHeader(
            title: l10n.get('dealerMapTitle'),
            subtitle: l10n.get('dealerMapSubtitle'),
            showBack: true,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
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
                borderRadius: BorderRadius.circular(KmRadius.md)),
            labelColor: KmColors.background,
            unselectedLabelColor: KmColors.textMuted,
            labelStyle: const TextStyle(fontFamily:'DMSans', fontSize:11, fontWeight:FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontFamily:'DMSans', fontSize:11),
            tabs: [
              Tab(text: l10n.get('dealerTabMap')),
              Tab(text: l10n.get('dealerTabList')),
              Tab(text: l10n.get('dealerTabInfo')),
            ],
          ),
        ),
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [_mapTab(l10n), _listTab(l10n), _infoTab(l10n)],
        )),
      ])),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1 — Map
  // ══════════════════════════════════════════════════════════

  Widget _mapTab(AppLocalizations l10n) {
    return Stack(children: [
      // ── Map ──────────────────────────────────────────────
      GoogleMap(
        initialCameraPosition: const CameraPosition(
            target: LatLng(43.235, 76.920), zoom: 12),
        onMapCreated: (c) {
          _mapCtrl = c;
          if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
          // Move camera to Алматы and place markers immediately
          c.animateCamera(CameraUpdate.newCameraPosition(
              const CameraPosition(target: _kAlmaty, zoom: 12)));
          _rebuildAllMarkers();
        },
        onTap: (_) => setState(() => _selected = null),
        markers:   _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        style: _kMapStyle,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),

      // Top gradient
      Positioned(top:0, left:0, right:0,
        child: Container(height:110,
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xDD0A0A0C), Colors.transparent])))),

      // Bottom gradient
      Positioned(bottom:0, left:0, right:0,
        child: Container(height:80,
          decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Color(0xFF0A0A0C), Colors.transparent])))),

      // ── Search ───────────────────────────────────────────
      Positioned(top:12, left:16, right:72,
        child: _SearchBar(
          controller: _searchCtrl,
          hint: l10n.get('dealerSearchHint'),
          onChanged: (v) => setState(() => _searchQuery = v),
          onSubmit: _searchAndGo,
        ),
      ),

      // ── Map buttons ──────────────────────────────────────
      Positioned(top:12, right:16,
        child: Column(children: [
          _MapBtn(icon: Icons.my_location_rounded, onTap: () async {
            final c = await _mapCompleter.future;
            c.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: _userPos, zoom: 15)));
          }),
          const SizedBox(height:6),
          _MapBtn(icon: Icons.add_rounded, onTap: () async {
            final c = await _mapCompleter.future;
            c.animateCamera(CameraUpdate.zoomIn());
          }),
          const SizedBox(height:6),
          _MapBtn(icon: Icons.remove_rounded, onTap: () async {
            final c = await _mapCompleter.future;
            c.animateCamera(CameraUpdate.zoomOut());
          }),
        ]),
      ),

      // ── Filter chips ─────────────────────────────────────
      Positioned(top:64, left:16, right:16,
        child: Row(children: [
          _Chip(l10n.get('dealerAllCenters'), _filter==0, () => _changeFilter(0)),
          const SizedBox(width:6),
          _Chip(l10n.get('dealerService'),    _filter==1, () => _changeFilter(1)),
          const SizedBox(width:6),
          _Chip(l10n.get('dealerSales'),      _filter==2, () => _changeFilter(2)),
        ]),
      ),

      // ── Search result route button ────────────────────────
      if (_searchResult != null && _selected == null)
        Positioned(bottom:16, left:16, right:16,
          child: _SearchRouteCard(
            label: _searchLabel,
            routeBuilt: _routeBuilt && _routeDest == _searchResult,
            routeBuilding: _routeBuilding,
            l10n: l10n,
            onRoute: () => _buildRoute(_searchResult!),
            onClear: () {
              _clearRoute();
              setState(() { _searchResult = null; _searchLabel = ''; });
              _rebuildAllMarkers();
            },
          ),
        ),

      // ── Selected dealer card ──────────────────────────────
      if (_selected != null)
        Positioned(bottom:16, left:16, right:16,
          child: _DealerCard(
            dealer: _selected!,
            l10n: l10n,
            routeBuilt: _routeBuilt && _routeDest == _selected!.pos,
            routeBuilding: _routeBuilding,
            onRoute: () => _buildRoute(_selected!.pos),
            onClearRoute: _clearRoute,
            onCall: () => _showCall(_selected!),
            onWa:   () => _showWa(_selected!),
          ),
        ),

      // ── Mini cards (nothing selected) ────────────────────
      if (_selected == null && _searchResult == null)
        Positioned(bottom:0, left:0, right:0,
          child: SizedBox(height:110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16,10,16,8),
              itemCount: _visibleDealers.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right:8),
                child: _MiniCard(d: _visibleDealers[i],
                    onTap: () => _selectDealer(_visibleDealers[i])),
              ),
            ),
          ),
        ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2 — List
  // ══════════════════════════════════════════════════════════

  Widget _listTab(AppLocalizations l10n) {
    final list = _visibleDealers;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24,12,24,0),
        child: Column(children: [
          _SearchBar(
            controller: _searchCtrl, hint: l10n.get('dealerSearchHint'),
            onChanged: (v) => setState(() => _searchQuery = v),
            onSubmit: (v) { setState(() => _searchQuery = v); _rebuildAllMarkers(); },
          ),
          const SizedBox(height:8),
          Row(children: [
            _Chip(l10n.get('dealerAllCenters'), _filter==0, () => _changeFilter(0)),
            const SizedBox(width:6),
            _Chip(l10n.get('dealerService'),    _filter==1, () => _changeFilter(1)),
            const SizedBox(width:6),
            _Chip(l10n.get('dealerSales'),      _filter==2, () => _changeFilter(2)),
          ]),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(l10n.get('dealerNoResults'),
                style: KmTextStyles.bodySmall.copyWith(color: KmColors.textMuted)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24,12,24,100),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final d = list[i];
                  final sel = _selected?.id == d.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom:10),
                    child: GestureDetector(
                      onTap: () { _selectDealer(d); _tabs.animateTo(0); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds:200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel ? KmColors.overlayAccent : KmColors.surface2,
                          borderRadius: BorderRadius.circular(KmRadius.lg),
                          border: Border.all(
                              color: sel ? KmColors.accent : KmColors.border,
                              width: sel ? 1.0 : 0.5)),
                        child: Row(children: [
                          Container(width:44, height:44,
                            decoration: BoxDecoration(color: KmColors.surface3,
                                borderRadius: BorderRadius.circular(KmRadius.sm)),
                            child: Center(child: Text(
                              d.type==DealerType.service ? '🔧'
                                  : d.type==DealerType.sales ? '🚗' : '⭐',
                              style: const TextStyle(fontSize:20)))),
                          const SizedBox(width:12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KM Motors', style: KmTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                              Text(l10n.get(d.addrKey), style: KmTextStyles.caption,
                                  maxLines:1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height:4),
                              Row(children: [
                                _StatusBadge(isOpen: d.isOpen, l10n: l10n),
                                const SizedBox(width:6),
                                Text('${d.km} ${l10n.get('dealerKm')}',
                                    style: KmTextStyles.caption),
                                const SizedBox(width:4),
                                Text('• ${d.hours}', style: KmTextStyles.caption),
                              ]),
                            ],
                          )),
                          Column(children: [
                            GestureDetector(onTap: () => _showCall(d),
                              child: const Icon(Icons.phone_rounded,
                                  color: KmColors.success, size:20)),
                            const SizedBox(height:8),
                            GestureDetector(onTap: () => _buildRoute(d.pos),
                              child: const Icon(Icons.navigation_rounded,
                                  color: KmColors.accent, size:20)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3 — Info
  // ══════════════════════════════════════════════════════════

  Widget _infoTab(AppLocalizations l10n) {
    final hours = [
      (l10n.get('dealerHrMF'),  l10n.get('dealerHrMFVal')),
      (l10n.get('dealerHrSat'), l10n.get('dealerHrSatVal')),
      (l10n.get('dealerHrSun'), l10n.get('dealerHrSunVal')),
    ];
    final services = [
      ('🔧',l10n.get('dSvc1Name'),l10n.get('dSvc1Desc')),
      ('🛠️',l10n.get('dSvc2Name'),l10n.get('dSvc2Desc')),
      ('🛞',l10n.get('dSvc3Name'),l10n.get('dSvc3Desc')),
      ('🔋',l10n.get('dSvc4Name'),l10n.get('dSvc4Desc')),
      ('🚗',l10n.get('dSvc5Name'),l10n.get('dSvc5Desc')),
      ('📦',l10n.get('dSvc6Name'),l10n.get('dSvc6Desc')),
    ];
    final offers = [
      (KmColors.accent,   const Color(0x18C8A96E),'🎁',l10n.get('dOffer1Title'),l10n.get('dOffer1Desc')),
      (KmColors.info,     const Color(0x185A8FE0),'⭐',l10n.get('dOffer2Title'),l10n.get('dOffer2Desc')),
      (KmColors.success,  const Color(0x1859C172),'📅',l10n.get('dOffer3Title'),l10n.get('dOffer3Desc')),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24,12,24,100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Call + WhatsApp (no route button on info tab)
        Row(children: [
          Expanded(child: _CBtn(Icons.phone_rounded, l10n.get('dealerCall'),
              KmColors.success, () => _showCall(_kDealers.first))),
          const SizedBox(width:10),
          Expanded(child: _CBtn(Icons.chat_rounded, 'WhatsApp',
              const Color(0xFF25D366), () => _showWa(_kDealers.first))),
        ]),
        const SizedBox(height:16),

        _InfoCard('🕐', l10n.get('dealerHours'),
          Column(children: hours.map((h) => Padding(
            padding: const EdgeInsets.only(bottom:6),
            child: Row(children: [
              Expanded(child: Text(h.$1, style: KmTextStyles.bodySmall)),
              Text(h.$2, style: KmTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600, color: KmColors.accent)),
            ]),
          )).toList()),
        ),
        const SizedBox(height:12),

        KmSectionLabel(l10n.get('dealerServices')),
        const SizedBox(height:8),
        GridView.count(
          crossAxisCount:3, shrinkWrap:true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing:8, crossAxisSpacing:8, childAspectRatio:1.1,
          children: services.map((s) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: KmColors.surface2,
                borderRadius: BorderRadius.circular(KmRadius.md),
                border: Border.all(color: KmColors.border, width:0.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s.$1, style: const TextStyle(fontSize:22)),
              const SizedBox(height:4),
              Text(s.$2, style: KmTextStyles.caption,
                  textAlign: TextAlign.center, maxLines:2,
                  overflow: TextOverflow.ellipsis),
            ]),
          )).toList(),
        ),
        const SizedBox(height:16),

        KmSectionLabel(l10n.get('dealerOffers')),
        const SizedBox(height:8),
        ...offers.map((o) => Padding(
          padding: const EdgeInsets.only(bottom:8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: o.$2,
                borderRadius: BorderRadius.circular(KmRadius.lg),
                border: Border.all(color: o.$1.withValues(alpha:0.3), width:0.5)),
            child: Row(children: [
              Text(o.$3, style: const TextStyle(fontSize:24)),
              const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.$4, style: KmTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600, color: o.$1)),
                  Text(o.$5, style: KmTextStyles.caption),
                ])),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widgets
// ══════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint,
      required this.onChanged, required this.onSubmit});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0xEA0A0A0C),
      borderRadius: BorderRadius.circular(KmRadius.md),
      border: Border.all(color: const Color(0x40C8A96E), width:0.5)),
    child: Row(children: [
      const SizedBox(width:12),
      const Icon(Icons.search, color: KmColors.accent, size:18),
      const SizedBox(width:8),
      Expanded(child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmit,
        textInputAction: TextInputAction.search,
        style: KmTextStyles.bodySmall,
        decoration: InputDecoration(
            hintText: hint, hintStyle: KmTextStyles.caption,
            border: InputBorder.none, isDense: true),
      )),
      GestureDetector(
        onTap: () => onSubmit(controller.text),
        child: Container(width:36, height:44, color: Colors.transparent,
          child: const Icon(Icons.arrow_forward_rounded,
              color: KmColors.accent, size:18)),
      ),
      if (controller.text.isNotEmpty)
        GestureDetector(
          onTap: () { controller.clear(); onChanged(''); },
          child: const Padding(padding: EdgeInsets.only(right:8),
            child: Icon(Icons.close, color: KmColors.textMuted, size:16)),
        ),
    ]),
  );
}

class _MapBtn extends StatefulWidget {
  const _MapBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_MapBtn> createState() => _MapBtnState();
}
class _MapBtnState extends State<_MapBtn> {
  Timer? _t; bool _p = false;
  void _start() { widget.onTap(); _t = Timer.periodic(const Duration(milliseconds:120), (_) => widget.onTap()); setState(() => _p = true); }
  void _stop()  { _t?.cancel(); if (mounted) setState(() => _p = false); }
  @override void dispose() { _t?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _start(), onTapUp: (_) => _stop(), onTapCancel: _stop,
    child: AnimatedContainer(
      duration: const Duration(milliseconds:80),
      width:40, height:40,
      decoration: BoxDecoration(
        color: _p ? const Color(0xFF1A1A24) : const Color(0xEA0A0A0C),
        borderRadius: BorderRadius.circular(KmRadius.sm),
        border: Border.all(color: _p ? KmColors.accent : const Color(0x40C8A96E),
            width: _p ? 1.0 : 0.5),
        boxShadow: const [BoxShadow(color:Color(0x33000000), blurRadius:6, offset:Offset(0,2))]),
      child: Icon(widget.icon, color: KmColors.accent, size:20),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.active, this.onTap);
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds:150),
      padding: const EdgeInsets.symmetric(horizontal:10, vertical:5),
      decoration: BoxDecoration(
        color: active ? KmColors.accent : const Color(0xEA0A0A0C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? KmColors.accent : const Color(0x40C8A96E), width:0.5)),
      child: Text(label, style: TextStyle(
        fontFamily:'DMSans', fontSize:11, fontWeight: FontWeight.w600,
        color: active ? KmColors.background : KmColors.textSecondary)),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOpen, required this.l10n});
  final bool isOpen; final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal:6, vertical:2),
    decoration: BoxDecoration(
      color: isOpen ? KmColors.success.withValues(alpha:0.12)
                    : KmColors.error.withValues(alpha:0.12),
      borderRadius: BorderRadius.circular(20)),
    child: Text(
      isOpen ? l10n.get('dealerOpen') : l10n.get('dealerClosed'),
      style: TextStyle(fontFamily:'DMSans', fontSize:10, fontWeight:FontWeight.w600,
          color: isOpen ? KmColors.success : KmColors.error)),
  );
}

class _DealerCard extends StatelessWidget {
  const _DealerCard({required this.dealer, required this.l10n,
      required this.routeBuilt, required this.routeBuilding,
      required this.onRoute, required this.onClearRoute,
      required this.onCall, required this.onWa});
  final _Dealer dealer;
  final AppLocalizations l10n;
  final bool routeBuilt, routeBuilding;
  final VoidCallback onRoute, onClearRoute, onCall, onWa;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xEE0A0A0C),
      borderRadius: BorderRadius.circular(KmRadius.xl),
      border: Border.all(color: KmColors.accentDim, width:0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KM Motors', style: KmTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w700)),
          Text(l10n.get(dealer.addrKey), style: KmTextStyles.caption,
              maxLines:1, overflow: TextOverflow.ellipsis),
        ])),
        _StatusBadge(isOpen: dealer.isOpen, l10n: l10n),
      ]),
      const SizedBox(height:4),
      Text('${dealer.km} ${l10n.get('dealerKm')} • ~${(dealer.km*3).toInt()} ${l10n.get('dealerMin')} ${l10n.get('dealerDriving')}',
          style: KmTextStyles.caption),
      const SizedBox(height:10),
      Row(children: [
        Expanded(child: _ActionBtn(
          icon: Icons.phone_rounded, label: l10n.get('dealerCallCenter'),
          color: KmColors.success, onTap: onCall)),
        const SizedBox(width:6),
        Expanded(child: _ActionBtn(
          icon: Icons.chat_rounded, label: 'WhatsApp',
          color: const Color(0xFF25D366), onTap: onWa)),
        const SizedBox(width:6),
        Expanded(child: routeBuilding
            ? _LoadingBtn()
            : _ActionBtn(
                icon: routeBuilt ? Icons.close_rounded : Icons.navigation_rounded,
                label: routeBuilt ? l10n.get('dealerClearRoute') : l10n.get('dealerRoute'),
                color: routeBuilt ? KmColors.error : KmColors.accent,
                onTap: routeBuilt ? onClearRoute : onRoute)),
      ]),
    ]),
  );
}

class _SearchRouteCard extends StatelessWidget {
  const _SearchRouteCard({required this.label, required this.routeBuilt,
      required this.routeBuilding, required this.l10n,
      required this.onRoute, required this.onClear});
  final String label;
  final bool routeBuilt, routeBuilding;
  final AppLocalizations l10n;
  final VoidCallback onRoute, onClear;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xEE0A0A0C),
      borderRadius: BorderRadius.circular(KmRadius.xl),
      border: Border.all(color: const Color(0x40C8A96E), width:0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.location_on, color: KmColors.accent, size:16),
        const SizedBox(width:6),
        Expanded(child: Text(label, style: KmTextStyles.bodySmall
            .copyWith(fontWeight: FontWeight.w600),
            maxLines:1, overflow: TextOverflow.ellipsis)),
        GestureDetector(onTap: onClear,
          child: const Icon(Icons.close, color: KmColors.textMuted, size:18)),
      ]),
      const SizedBox(height:10),
      Row(children: [
        Expanded(child: routeBuilding
            ? _LoadingBtn()
            : _ActionBtn(
                icon: routeBuilt ? Icons.close_rounded : Icons.navigation_rounded,
                label: routeBuilt ? l10n.get('dealerClearRoute') : l10n.get('dealerRoute'),
                color: routeBuilt ? KmColors.error : KmColors.accent,
                onTap: routeBuilt ? onClear : onRoute)),
      ]),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical:10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: color.withValues(alpha:0.4), width:0.5)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size:14),
        const SizedBox(width:5),
        Text(label, style: TextStyle(fontFamily:'DMSans', fontSize:11,
            fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

class _LoadingBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical:10),
    decoration: BoxDecoration(
      color: KmColors.accent.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(KmRadius.md),
      border: Border.all(color: KmColors.accentDim, width:0.5)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width:12, height:12,
          child: CircularProgressIndicator(strokeWidth:1.5, color:KmColors.accent)),
      SizedBox(width:6),
      Text('...', style: TextStyle(fontFamily:'DMSans', fontSize:11,
          color: KmColors.accent)),
    ]),
  );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.d, required this.onTap});
  final _Dealer d; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:180, padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xEE0A0A0C),
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: const Color(0x40C8A96E), width:0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(d.type==DealerType.service ? '🔧' : '🚗',
                style: const TextStyle(fontSize:14)),
            const SizedBox(width:6),
            Expanded(child: Text('KM Motors',
                style: KmTextStyles.bodySmall.copyWith(fontWeight:FontWeight.w600),
                maxLines:1, overflow: TextOverflow.ellipsis)),
          ]),
          Text(l10n.get(d.addrKey), style: KmTextStyles.caption,
              maxLines:1, overflow: TextOverflow.ellipsis),
          const SizedBox(height:4),
          Row(children: [
            Container(width:6, height:6,
                decoration: BoxDecoration(
                  color: d.isOpen ? KmColors.success : KmColors.error,
                  shape: BoxShape.circle)),
            const SizedBox(width:4),
            Text(d.isOpen ? l10n.get('dealerOpen') : l10n.get('dealerClosed'),
                style: KmTextStyles.caption.copyWith(
                    color: d.isOpen ? KmColors.success : KmColors.error)),
            const SizedBox(width:6),
            Text('${d.km} ${l10n.get('dealerKm')}', style: KmTextStyles.caption),
          ]),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.icon, this.title, this.child);
  final String icon, title; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width:0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize:16)),
        const SizedBox(width:8),
        Text(title, style: KmTextStyles.labelLarge),
      ]),
      const SizedBox(height:10),
      const Divider(color: KmColors.border, height:0, thickness:0.5),
      const SizedBox(height:10),
      child,
    ]),
  );
}

class _CBtn extends StatelessWidget {
  const _CBtn(this.icon, this.label, this.color, this.onTap);
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical:14),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: color.withValues(alpha:0.3), width:0.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size:22),
        const SizedBox(height:4),
        Text(label, style: KmTextStyles.caption.copyWith(color: color),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Bottom sheets ─────────────────────────────────────────────

class _CallSheet extends StatelessWidget {
  const _CallSheet({required this.phone, required this.l10n,
      required this.onCall});
  final String phone; final AppLocalizations l10n;
  final VoidCallback onCall;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24,20,24,40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width:40, height:4,
          decoration: BoxDecoration(color: KmColors.border,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(height:20),
      Container(width:52, height:52,
          decoration: BoxDecoration(
              color: KmColors.success.withValues(alpha:0.12), shape: BoxShape.circle),
          child: const Icon(Icons.phone_rounded, color:KmColors.success, size:26)),
      const SizedBox(height:12),
      Text(l10n.get('dealerCallTitle'),
          style: KmTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height:4),
      const Text('KM Motors', style: KmTextStyles.caption),
      const SizedBox(height:20),
      GestureDetector(
        onTap: onCall,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical:16),
          decoration: BoxDecoration(
            color: KmColors.success.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: KmColors.success.withValues(alpha:0.4), width:0.5)),
          child: Column(children: [
            Text(phone, style: KmTextStyles.numeralSmall
                .copyWith(color:KmColors.success, fontSize:22),
                textAlign: TextAlign.center),
            const SizedBox(height:4),
            Text(l10n.get('dealerCallTitle'),
                style: KmTextStyles.caption.copyWith(color:KmColors.success)),
          ]),
        ),
      ),
      const SizedBox(height:10),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.get('subCancelBtn'),
            style: KmTextStyles.bodySmall.copyWith(color:KmColors.textMuted)),
      ),
    ]),
  );
}

class _WaSheet extends StatelessWidget {
  const _WaSheet({required this.phone, required this.l10n, required this.onOpen});
  final String phone; final AppLocalizations l10n;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24,20,24,40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width:40, height:4,
          decoration: BoxDecoration(color: KmColors.border,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(height:20),
      const SizedBox(width:52, height:52,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: Color(0x1F25D366), shape: BoxShape.circle),
          child: Center(child: Text('💬', style: TextStyle(fontSize:26))),
        ),
      ),
      const SizedBox(height:12),
      Text('WhatsApp',
          style: KmTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height:4),
      const Text('KM Motors', style: KmTextStyles.caption),
      const SizedBox(height:20),
      GestureDetector(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical:16),
          decoration: BoxDecoration(
            color: const Color(0x1F25D366),
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: const Color(0x5025D366), width:0.5)),
          child: Column(children: [
            Text(l10n.get('dealerWaMsg'),
                style: KmTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF25D366), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height:4),
            Text('+$phone',
                style: KmTextStyles.caption.copyWith(color: const Color(0xFF25D366))),
          ]),
        ),
      ),
      const SizedBox(height:10),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.get('subCancelBtn'),
            style: KmTextStyles.bodySmall.copyWith(color:KmColors.textMuted)),
      ),
    ]),
  );
}