import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// KM DRIVE — BookingService
// Хранит активные записи и историю в SharedPreferences
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
    'id': id,
    'serviceKey': serviceKey,
    'serviceName': serviceName,
    'serviceIcon': serviceIcon,
    'date': date.toIso8601String(),
    'time': time,
    'priceKzt': priceKzt,
    'extras': extras,
    'comment': comment,
    'reminderEnabled': reminderEnabled,
    'status': status,
    'center': center,
    'master': master,
    'rating': rating,
    'review': review,
  };

  factory BookingEntry.fromJson(Map<String, dynamic> j) => BookingEntry(
    id:              j['id'] as String,
    serviceKey:      j['serviceKey'] as String,
    serviceName:     j['serviceName'] as String,
    serviceIcon:     j['serviceIcon'] as String,
    date:            DateTime.parse(j['date'] as String),
    time:            j['time'] as String,
    priceKzt:        j['priceKzt'] as int,
    extras:          List<String>.from(j['extras'] as List),
    comment:         j['comment'] as String,
    reminderEnabled: j['reminderEnabled'] as bool,
    status:          j['status'] as String,
    center:          j['center'] as String? ?? '',
    master:          j['master'] as String? ?? '',
    rating:          j['rating'] as int?,
    review:          j['review'] as String?,
  );
}

class BookingService {
  BookingService._();
  static final instance = BookingService._();

  static const _key = 'km_bookings_v1';

  Future<List<BookingEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      try { return BookingEntry.fromJson(jsonDecode(s) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<BookingEntry>().toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<BookingEntry?> getActive() async {
    final all = await getAll();
    try {
      return all.firstWhere((b) =>
        b.status == 'pending' || b.status == 'confirmed');
    } catch (_) { return null; }
  }

  Future<void> save(BookingEntry entry) async {
    final all = await getAll();
    all.removeWhere((b) => b.id == entry.id);
    all.add(entry);
    await _persist(all);
  }

  Future<void> cancel(String id) async {
    final all = await getAll();
    for (final b in all) {
      if (b.id == id) b.status = 'canceled';
    }
    await _persist(all);
  }

  Future<void> saveReview(String id, int rating, String review) async {
    final all = await getAll();
    for (final b in all) {
      if (b.id == id) { b.rating = rating; b.review = review; b.status = 'done'; }
    }
    await _persist(all);
  }

  Future<void> _persist(List<BookingEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key,
        list.map((b) => jsonEncode(b.toJson())).toList());
  }

  /// Сброс демо-данных (для обновления)
  Future<void> clearDemo() async {
    final all = await getAll();
    final noDemo = all.where((b) => !b.id.startsWith('demo_')).toList();
    await _persist(noDemo);
  }

  static const _demoVersion = 4; // увеличивай при изменении демо-данных
  static const _versionKey  = 'km_bookings_demo_v';

  /// Демо-данные: создаёт при первом запуске или при обновлении версии
  Future<void> seedIfEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_versionKey) ?? 0;
    final all = await getAll();

    // Обновляем только если демо устарело
    if (savedVersion < _demoVersion) {
      await clearDemo(); // удаляем старые демо
    } else if (all.isNotEmpty) {
      return; // демо актуально, пропускаем
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