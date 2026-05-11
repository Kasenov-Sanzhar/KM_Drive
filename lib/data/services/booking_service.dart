import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// KM DRIVE — BookingService v2
// Primary storage: Firestore (users/{uid}/bookings)
// Fallback/cache:  SharedPreferences
// ============================================================

class BookingEntry {
  BookingEntry({
    required this.id,
    required this.serviceKey,
    required this.serviceName,
    required this.serviceIcon,
    required this.date,
    required this.time,
    required this.priceKzt,
    required this.extras,
    required this.comment,
    required this.reminderEnabled,
    required this.status,
    this.center = '',
    this.master = '',
    this.rating,
    this.review,
  });

  final String id;
  final String serviceKey;
  final String serviceName;
  final String serviceIcon;
  final DateTime date;
  final String time;
  final int priceKzt;
  final List<String> extras;
  final String comment;
  final bool reminderEnabled;
  String status;
  final String center;
  final String master;
  int? rating;
  String? review;

  Map<String, dynamic> toJson() => {
    'id':              id,
    'serviceKey':      serviceKey,
    'serviceName':     serviceName,
    'serviceIcon':     serviceIcon,
    'date':            date.toIso8601String(),
    'time':            time,
    'priceKzt':        priceKzt,
    'extras':          extras,
    'comment':         comment,
    'reminderEnabled': reminderEnabled,
    'status':          status,
    'center':          center,
    'master':          master,
    'rating':          rating,
    'review':          review,
  };

  Map<String, dynamic> toFirestore() => {
    ...toJson(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory BookingEntry.fromJson(Map<String, dynamic> j) => BookingEntry(
    id:              j['id'] as String,
    serviceKey:      j['serviceKey'] as String,
    serviceName:     j['serviceName'] as String,
    serviceIcon:     j['serviceIcon'] as String,
    date:            DateTime.parse(j['date'] as String),
    time:            j['time'] as String,
    priceKzt:        (j['priceKzt'] as num).toInt(),
    extras:          List<String>.from(j['extras'] as List),
    comment:         j['comment'] as String,
    reminderEnabled: j['reminderEnabled'] as bool,
    status:          j['status'] as String,
    center:          j['center'] as String? ?? '',
    master:          j['master'] as String? ?? '',
    rating:          j['rating'] as int?,
    review:          j['review'] as String?,
  );

  factory BookingEntry.fromFirestore(DocumentSnapshot doc) {
    final j = doc.data() as Map<String, dynamic>;
    // Firestore Timestamp → String для date
    final rawDate = j['date'];
    String dateStr;
    if (rawDate is Timestamp) {
      dateStr = rawDate.toDate().toIso8601String();
    } else {
      dateStr = rawDate as String;
    }
    return BookingEntry(
      id:              doc.id,
      serviceKey:      j['serviceKey'] as String? ?? '',
      serviceName:     j['serviceName'] as String? ?? '',
      serviceIcon:     j['serviceIcon'] as String? ?? '🔧',
      date:            DateTime.parse(dateStr),
      time:            j['time'] as String? ?? '',
      priceKzt:        (j['priceKzt'] as num?)?.toInt() ?? 0,
      extras:          List<String>.from(j['extras'] as List? ?? []),
      comment:         j['comment'] as String? ?? '',
      reminderEnabled: j['reminderEnabled'] as bool? ?? false,
      status:          j['status'] as String? ?? 'pending',
      center:          j['center'] as String? ?? '',
      master:          j['master'] as String? ?? '',
      rating:          j['rating'] as int?,
      review:          j['review'] as String?,
    );
  }
}

class BookingService {
  BookingService._();
  static final instance = BookingService._();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _cacheKey = 'km_bookings_cache_v2';

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _bookingsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('bookings');
  }

  // ── Read ──────────────────────────────────────────────────

  /// Загружает все записи. Firestore первичный, cache как fallback.
  Future<List<BookingEntry>> getAll() async {
    final ref = _bookingsRef;
    if (ref != null) {
      try {
        final snap = await ref
            .orderBy('date', descending: true)
            .get();
        final entries = snap.docs
            .map((d) => BookingEntry.fromFirestore(d))
            .toList();
        _persistCache(entries);
        return entries;
      } catch (_) {
        // fall through to cache
      }
    }
    return _fromCache();
  }

  /// Активная (ближайшая pending/confirmed) запись.
  Future<BookingEntry?> getActive() async {
    final all = await getAll();
    final upcoming = all.where((b) =>
        (b.status == 'pending' || b.status == 'confirmed') &&
        b.date.isAfter(DateTime.now().subtract(const Duration(days: 1))));
    if (upcoming.isEmpty) return null;
    return upcoming.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
  }

  // ── Write ─────────────────────────────────────────────────

  /// Сохраняет запись в Firestore + кеш.
  Future<void> save(BookingEntry entry) async {
    // Обновляем кеш сразу (оптимистичный UI)
    final cached = await _fromCache();
    cached.removeWhere((b) => b.id == entry.id);
    cached.add(entry);
    await _persistCache(cached);

    // Пишем в Firestore
    final ref = _bookingsRef;
    if (ref != null) {
      await ref.doc(entry.id).set(
        entry.toFirestore(),
        SetOptions(merge: true),
      );
    }
  }

  /// Отменяет запись.
  Future<void> cancel(String id) async {
    // Кеш
    final cached = await _fromCache();
    for (final b in cached) {
      if (b.id == id) b.status = 'canceled';
    }
    await _persistCache(cached);

    // Firestore
    final ref = _bookingsRef;
    if (ref != null) {
      await ref.doc(id).update({
        'status':    'canceled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Сохраняет отзыв и переводит статус в done.
  Future<void> saveReview(String id, int rating, String review) async {
    // Кеш
    final cached = await _fromCache();
    for (final b in cached) {
      if (b.id == id) {
        b.rating = rating;
        b.review = review;
        b.status = 'done';
      }
    }
    await _persistCache(cached);

    // Firestore
    final ref = _bookingsRef;
    if (ref != null) {
      await ref.doc(id).update({
        'rating':    rating,
        'review':    review,
        'status':    'done',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Cache helpers ─────────────────────────────────────────

  Future<List<BookingEntry>> _fromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_cacheKey) ?? [];
    return raw.map((s) {
      try { return BookingEntry.fromJson(jsonDecode(s) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<BookingEntry>().toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _persistCache(List<BookingEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKey,
        list.map((b) => jsonEncode(b.toJson())).toList());
  }

  // ── Demo data ─────────────────────────────────────────────

  Future<void> clearDemo() async {
    final all = await _fromCache();
    await _persistCache(all.where((b) => !b.id.startsWith('demo_')).toList());
  }

  static const _demoVersion = 4;
  static const _versionKey  = 'km_bookings_demo_v';

  Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_versionKey) ?? 0;
    final all = await _fromCache();

    if (savedVersion < _demoVersion) {
      await clearDemo();
    } else if (all.isNotEmpty) {
      return;
    }
    await prefs.setInt(_versionKey, _demoVersion);

    final now = DateTime.now();
    await save(BookingEntry(
      id: 'demo_1',
      serviceKey: 'svcOilName',
      serviceName: 'Замена масла и фильтров',
      serviceIcon: '🔧',
      date: now.subtract(const Duration(days: 45)),
      time: '10:30',
      priceKzt: 28000,
      extras: [
        'Замена моторного масла 5W-30',
        'Замена масляного фильтра',
        'Замена воздушного фильтра',
      ],
      comment: 'Плановое ТО',
      reminderEnabled: false,
      center: 'KM Motors — Розыбакиева, 247',
      master: 'Алибек С.',
      status: 'done',
      rating: 5,
      review: 'Отличный сервис, всё сделали быстро',
    ));
    await save(BookingEntry(
      id: 'demo_2',
      serviceKey: 'svcTireName',
      serviceName: 'Проверка и балансировка шин',
      serviceIcon: '🛞',
      date: now.subtract(const Duration(days: 120)),
      time: '14:00',
      priceKzt: 15000,
      extras: [
        'Проверка давления и состояния шин',
        'Балансировка всех колёс',
      ],
      comment: '',
      reminderEnabled: false,
      center: 'KM Motors — Достык, 111',
      master: 'Данияр М.',
      status: 'done',
      rating: 4,
      review: '',
    ));
  }
}