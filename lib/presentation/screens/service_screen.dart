import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/firestore_vehicle_repository.dart';
import '../../data/services/booking_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'service_booking_screen.dart';

// ============================================================
// KM DRIVE — Service Screen v2
// ТО, история, рекомендации, активные записи, отзывы
// ============================================================

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FirestoreVehicleRepository();
  NextServiceInfo?    _nextService;
  List<ServiceRecord> _history = [];
  List<BookingEntry>  _bookings = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await BookingService.instance.seedIfEmpty();
    final results = await Future.wait([
      _repo.getNextService(),
      _repo.getServiceHistory(),
      BookingService.instance.getAll(),
    ]);
    if (mounted) {
      setState(() {
        _nextService = results[0] as NextServiceInfo;
        _history     = results[1] as List<ServiceRecord>;
        _bookings    = results[2] as List<BookingEntry>;
        _loading     = false;
      });
    }
  }

  Future<void> _cancelBooking(String id) async {
    await BookingService.instance.cancel(id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).get('bookingCanceled'),
            style: KmTextStyles.bodySmall),
        backgroundColor: KmColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

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
    final activeBookings = _bookings.where(
        (b) => b.status == 'pending' || b.status == 'confirmed').toList();
    final doneBookings = _bookings.where(
        (b) => b.status == 'done').toList();
    final allPastBookings = _bookings.where(
        (b) => b.status == 'done' || b.status == 'canceled').toList();

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: KmScreenHeader(
              title:    l10n.get('serviceTitle'),
              subtitle: l10n.get('serviceSubtitle'),
              trailing: _BookBtn(onReturn: _loadData),
            ),
          ),

          // ── Tabs ─────────────────────────────────────────
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
              labelStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 12,
                  fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 12),
              tabs: [
                Tab(text: l10n.get('serviceTitle')),
                Tab(text: l10n.get('svcHistoryShort')),
                Tab(text: l10n.get('svcRecommTitle')),
              ],
            ),
          ),

          Expanded(child: TabBarView(
            controller: _tabs,
            children: [
              // ── Tab 1: Обзор ─────────────────────────────
              _buildOverviewTab(l10n, activeBookings, doneBookings),
              // ── Tab 2: История ───────────────────────────
              _buildHistoryTab(l10n, allPastBookings),
              // ── Tab 3: Рекомендации ──────────────────────
              _buildRecommTab(l10n),
            ],
          )),
        ]),
      ),
    );
  }

  // ── Tab 1: Overview ────────────────────────────────────────

  Widget _buildOverviewTab(AppLocalizations l10n,
      List<BookingEntry> active, List<BookingEntry> done) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Next service card
        _NextServiceCard(info: _nextService!),
        const SizedBox(height: 16),

        // Active booking
        if (active.isNotEmpty) ...[
          KmSectionLabel(l10n.get('bookingActive')),
          const SizedBox(height: 8),
          ...active.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActiveBookingCard(
              booking: b,
              l10n: l10n,
              onCancel: () => _showCancelDialog(b.id),
            ),
          )),
          const SizedBox(height: 8),
        ],

        // Recent history (last 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            l10n.get('serviceHistory'),
            style: KmTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: KmColors.textPrimary),
            softWrap: true,
          ),
        ),
        _ServiceHistoryList(
          records: _history.take(3).toList(),
          bookings: done.take(2).toList(),
          l10n: l10n,
          onReview: (id) => _showReviewSheet(id),
        ),
      ]),
    );
  }

  // ── Tab 2: History ─────────────────────────────────────────

  Widget _buildHistoryTab(AppLocalizations l10n, List<BookingEntry> allPast) {
    final all = [
      // Only show done/scheduled/recommended that are actual history
      // Exclude pure recommended (no date booked) from history view
      ..._history
          .where((r) => r.status != ServiceStatus.recommended)
          .map((r) => _HistoryItem.fromRecord(r)),
      ...allPast.map((b) => _HistoryItem.fromBooking(b)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (all.isEmpty) {
      return Center(child: Text(l10n.get('noData'),
          style: KmTextStyles.bodySmall.copyWith(color: KmColors.textMuted)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: _ExpandableHistoryList(
          items: all, l10n: l10n,
          onReview: (id) => _showReviewSheet(id)),
    );
  }

  // ── Tab 3: Recommendations ─────────────────────────────────

  Widget _buildRecommTab(AppLocalizations l10n) {
    final recommendations = [
      _Recommendation('🛞', l10n.get('svcNextTire'),    l10n.get('svcNextTireDesc'),
          urgency: 0, kmLeft: 2300),
      _Recommendation('🛑', l10n.get('svcNextBrake'),   l10n.get('svcNextBrakeDesc'),
          urgency: 1, kmLeft: 2000),
      _Recommendation('🌬️', l10n.get('svcNextFilters'), l10n.get('svcNextFiltersDesc'),
          urgency: 0, kmLeft: 4500),
      _Recommendation('💧', l10n.get('svcNextFluid'),   l10n.get('svcNextFluidDesc'),
          urgency: 0, kmLeft: 8000),
    ]..sort((a, b) => a.kmLeft.compareTo(b.kmLeft));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      itemCount: recommendations.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KmColors.overlayAccent,
                borderRadius: BorderRadius.circular(KmRadius.lg),
                border: Border.all(color: KmColors.accentDim, width: 0.5),
              ),
              child: Row(children: [
                const Text('📊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.get('svcRecommTitle'),
                        style: KmTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(l10n.get('svcRecommSubtitle'),
                        style: KmTextStyles.caption),
                  ],
                )),
              ]),
            ),
          );
        }
        final r = recommendations[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecommCard(
            rec: r, l10n: l10n,
            onBook: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ServiceBookingScreen())).then((_) => _loadData()),
          ),
        );
      },
    );
  }

  void _showCancelDialog(String id) {
    final l10n = AppLocalizations.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: KmColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KmRadius.xl),
          side: const BorderSide(color: KmColors.border, width: 0.5)),
      title: Text(l10n.get('bookingCancelConfirm'),
          style: KmTextStyles.bodyLarge, textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('bookingCancelBtn'),
              style: const TextStyle(color: KmColors.textMuted,
                  fontFamily: 'DMSans', fontSize: 14))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: KmColors.error,
              foregroundColor: Colors.white),
          onPressed: () { Navigator.pop(context); _cancelBooking(id); },
          child: Text(l10n.get('bookingCancel'),
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 14))),
      ],
    ));
  }

  void _showReviewSheet(String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KmColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReviewSheet(
        l10n: AppLocalizations.of(context),
        onSubmit: (rating, text) async {
          Navigator.pop(context);
          await BookingService.instance.saveReview(bookingId, rating, text);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).get('svcReviewSent'),
                  style: KmTextStyles.bodySmall),
              backgroundColor: KmColors.surface2,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }
}

// ── Next Service Card ─────────────────────────────────────────

class _NextServiceCard extends StatelessWidget {
  const _NextServiceCard({required this.info});
  final NextServiceInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KmAccentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.get('nextService').toUpperCase(),
            style: KmTextStyles.labelMedium.copyWith(color: KmColors.accent)),
        const SizedBox(height: 8),
        Text(KmFormatters.date(info.date), style: KmTextStyles.displaySmall),
        const SizedBox(height: 4),
        Text(
          '${l10n.get('throughKm')} ${KmFormatters.kilometers(info.remainingKm)} '
          '${l10n.get('orDays')} ${info.remainingDays} ${l10n.get('days')}',
          style: KmTextStyles.bodySmall),
        const SizedBox(height: 14),
        KmProgressBar(value: info.progress, height: 3.5),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0 ${l10n.get('km')}', style: KmTextStyles.caption),
          Text('${(info.progress * 100).toInt()}% ${l10n.get('passed')}',
              style: KmTextStyles.caption),
          Text(KmFormatters.kilometers(info.intervalKm),
              style: KmTextStyles.caption),
        ]),
      ]),
    );
  }
}

// ── Active Booking Card ───────────────────────────────────────

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard({
      required this.booking, required this.l10n, required this.onCancel});
  final BookingEntry booking;
  final AppLocalizations l10n;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KmColors.overlayAccent,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.accent, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(booking.serviceIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.serviceName, style: KmTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${booking.date.day}.${booking.date.month.toString().padLeft(2,'0')}'
                '.${booking.date.year} · ${booking.time}',
                style: KmTextStyles.caption.copyWith(color: KmColors.accent)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: KmColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(l10n.get('bookingActive'),
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 10,
                    color: KmColors.success, fontWeight: FontWeight.w600)),
          ),
        ]),
        if (booking.extras.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('+ ${booking.extras.join(', ')}',
              style: KmTextStyles.caption),
        ],
        if (booking.reminderEnabled) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.notifications_active_rounded,
                color: KmColors.success, size: 12),
            const SizedBox(width: 4),
            Text(l10n.get('bookingReminderOn'),
                style: KmTextStyles.caption.copyWith(color: KmColors.success)),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(
            '${booking.priceKzt ~/ 1000} 000 ₸',
            style: KmTextStyles.bodyMedium.copyWith(color: KmColors.accent))),
          GestureDetector(
            onTap: onCancel,
            child: Text(l10n.get('bookingCancel'),
                style: KmTextStyles.caption.copyWith(color: KmColors.error))),
        ]),
      ]),
    );
  }
}

// ── History unified item model ────────────────────────────────

class _HistoryItem {
  _HistoryItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.mileage,
    required this.price,
    required this.statusLabel,
    required this.statusColor,
    this.details = const [],
    this.bookingId,
    this.rating,
    this.comment,
    this.master,
    this.center,
    this.nextKm,
    this.time,
  });

  factory _HistoryItem.fromRecord(ServiceRecord r) => _HistoryItem(
    icon: r.icon, title: r.title, date: r.date,
    mileage: r.mileageKm, price: r.priceKzt ?? 0,
    statusLabel: r.status.l10nKey,
    statusColor: r.status == ServiceStatus.done
        ? KmColors.success
        : KmColors.warning,
    details: r.worksDone,
    master: r.master,
    center: r.center,
    nextKm: r.nextKm,
    // Allow review for done records (use record id as bookingId)
    bookingId: r.status == ServiceStatus.done ? 'record_\${r.id}' : null,
    time: null,
  );

  factory _HistoryItem.fromBooking(BookingEntry b) => _HistoryItem(
    icon: b.serviceIcon, title: b.serviceName, date: b.date,
    mileage: 0, price: b.priceKzt,
    statusLabel: b.status == 'done' ? 'statusDone' : 'statusCanceled',
    statusColor: b.status == 'done' ? KmColors.success : KmColors.textMuted,
    details: b.extras,
    bookingId: b.id,
    rating: b.rating,
    comment: b.comment.isNotEmpty ? b.comment : null,
    master: b.master.isNotEmpty ? b.master : null,
    center: b.center.isNotEmpty ? b.center : null,
    nextKm: null,
    time: b.time,
  );

  final String icon;
  final String title;
  final DateTime date;
  final int mileage;
  final int price;
  final String statusLabel;
  final Color statusColor;
  final List<String> details;
  final String? bookingId;
  final int? rating;
  final String? comment;
  final String? master;
  final String? center;
  final int? nextKm;
  final String? time;
}

// ── History Item Card ─────────────────────────────────────────


// ── Expandable history list (used in both Overview and History tabs) ──────────

class _ExpandableHistoryList extends StatefulWidget {
  const _ExpandableHistoryList({
    required this.items,
    required this.l10n,
    required this.onReview,
  });
  final List<_HistoryItem> items;
  final AppLocalizations l10n;
  final void Function(String) onReview;

  @override
  State<_ExpandableHistoryList> createState() => _ExpandableHistoryListState();
}

class _ExpandableHistoryListState extends State<_ExpandableHistoryList> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.items.asMap().entries.map((e) {
        final i    = e.key;
        final item = e.value;
        final open = _expanded.contains(i);
        return Column(children: [
          _HistoryItemCard(
            item: item, l10n: widget.l10n,
            isExpanded: open,
            onTap: () => setState(() =>
                open ? _expanded.remove(i) : _expanded.add(i)),
            onReview: item.bookingId != null
                ? () => widget.onReview(item.bookingId!) : null,
          ),
          if (i < widget.items.length - 1) const KmDivider(),
        ]);
      }).toList(),
    );
  }
}

class _ServiceHistoryList extends StatefulWidget {
  const _ServiceHistoryList({
    required this.records,
    required this.bookings,
    required this.l10n,
    required this.onReview,
  });
  final List<ServiceRecord> records;
  final List<BookingEntry> bookings;
  final AppLocalizations l10n;
  final void Function(String) onReview;

  @override
  State<_ServiceHistoryList> createState() => _ServiceHistoryListState();
}

class _ServiceHistoryListState extends State<_ServiceHistoryList> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final items = [
      ...widget.records.map(_HistoryItem.fromRecord),
      ...widget.bookings.map(_HistoryItem.fromBooking),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        final isOpen = _expanded.contains(i);
        return Column(children: [
          _HistoryItemCard(
            item: item, l10n: widget.l10n, isExpanded: isOpen,
            onTap: () => setState(() =>
                isOpen ? _expanded.remove(i) : _expanded.add(i)),
            onReview: item.bookingId != null
                ? () => widget.onReview(item.bookingId!) : null,
          ),
          if (i < items.length - 1) const KmDivider(),
        ]);
      }).toList(),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({
    required this.item,
    required this.l10n,
    this.isExpanded = false,
    this.onTap,
    this.onReview,
  });
  final _HistoryItem item;
  final AppLocalizations l10n;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            vertical: 14, horizontal: isExpanded ? 12 : 0),
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFF111318) : Colors.transparent,
          borderRadius: BorderRadius.circular(isExpanded ? KmRadius.md : 0),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: KmColors.surface3,
                  borderRadius: BorderRadius.circular(KmRadius.md)),
              child: Center(child: Text(item.icon,
                  style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tryGet(item.title) ?? item.title,
                    style: KmTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '${KmFormatters.dateShort(item.date)}'
                  '${item.mileage > 0 ? ' · ${KmFormatters.kilometers(item.mileage)}' : ''}',
                  style: KmTextStyles.caption),
                if (item.price > 0) ...[
                  const SizedBox(height: 2),
                  Text(KmFormatters.tenge(item.price),
                      style: KmTextStyles.caption
                          .copyWith(color: KmColors.accentDim)),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  KmBadge(
                    item.statusLabel.startsWith('status')
                        ? l10n.get(item.statusLabel) : l10n.get(item.statusLabel),
                    color: item.statusColor,
                    bg: item.statusColor.withValues(alpha: 0.12),
                  ),
                  if (item.rating != null) ...[
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) => Icon(
                      i < item.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: KmColors.accent, size: 12)),
                  ],
                  const Spacer(),
                  if (onTap != null)
                    Icon(isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                        size: 16, color: KmColors.textMuted),
                ]),
              ],
            )),
          ]),

          if (isExpanded) ...[
            const SizedBox(height: 14),
            const Divider(color: KmColors.border, thickness: 0.5, height: 0),
            const SizedBox(height: 12),
            // Works done
            Text(l10n.get('svcWorksDone'),
                style: KmTextStyles.bodySmall.copyWith(
                    color: KmColors.accent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (item.details.isEmpty)
              Text(l10n.get('svcNoWorks'),
                  style: KmTextStyles.caption)
            else
              ...item.details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(
                    item.statusLabel == 'statusCanceled'
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    color: item.statusLabel == 'statusCanceled'
                        ? KmColors.textMuted
                        : KmColors.success,
                    size: 14),
                  const SizedBox(width: 6),
                  // d might be an l10n key or a plain string
                  Expanded(child: Text(
                    l10n.tryGet(d) ?? d,
                    style: KmTextStyles.bodySmall)),
                ]),
              )),
            const SizedBox(height: 10),
            // Date / Time / Master / Center / NextKm — unified block
            const Divider(color: KmColors.border, thickness: 0.5, height: 0),
            const SizedBox(height: 8),
            _DetailRow(l10n.get('serviceDate'), KmFormatters.dateShort(item.date)),
            if (item.time != null) ...[
              const SizedBox(height: 4),
              _DetailRow(l10n.get('bookingTimeLabel'), item.time!),
            ],
            if (item.master != null) ...[
              const SizedBox(height: 4),
              _DetailRow(l10n.get('svcMasterLabel'), item.master!),
            ],
            if (item.center != null) ...[
              const SizedBox(height: 4),
              _DetailRow(l10n.get('svcCenterLabel'), item.center!),
            ],
            if (item.nextKm != null) ...[
              const SizedBox(height: 4),
              _DetailRow(l10n.get('svcNextKmLabel'),
                  KmFormatters.kilometers(item.nextKm!)),
            ],
            if (item.center == null && item.master == null && item.time == null
                && item.mileage == 0) ...[
              const SizedBox(height: 4),
              Text(l10n.get('svcNoInfoYet'),
                  style: KmTextStyles.caption
                      .copyWith(color: KmColors.textMuted)),
            ],
            const SizedBox(height: 6),
            // Comment
            if (item.comment != null && item.comment!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KmColors.surface2,
                  borderRadius: BorderRadius.circular(KmRadius.sm),
                ),
                child: Text('💬 ${item.comment}',
                    style: KmTextStyles.caption),
              ),
              const SizedBox(height: 8),
            ],
            // Leave review
            if (onReview != null && item.rating == null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KmColors.accent, width: 0.5),
                    foregroundColor: KmColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KmRadius.sm)),
                  ),
                  child: Text(l10n.get('svcLeaveReview'),
                      style: const TextStyle(fontFamily: 'DMSans',
                          fontSize: 12, color: KmColors.accent)),
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}

// ── Recommendation Card ───────────────────────────────────────

class _Recommendation {
  const _Recommendation(this.icon, this.title, this.desc,
      {required this.urgency, required this.kmLeft});
  final String icon;
  final String title;
  final String desc;
  final int urgency; // 0=upcoming 1=soon 2=overdue
  final int kmLeft;
}

class _RecommCard extends StatelessWidget {
  const _RecommCard({required this.rec, required this.l10n, required this.onBook});
  final _Recommendation rec;
  final AppLocalizations l10n;
  final VoidCallback onBook;

  Color get _urgencyColor => rec.urgency == 2 ? KmColors.error
      : rec.urgency == 1 ? KmColors.warning : KmColors.textMuted;

  String get _urgencyLabel => rec.urgency == 2 ? l10n.get('svcOverdue')
      : rec.urgency == 1 ? l10n.get('svcUpcoming') : l10n.get('svcDue');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
          color: rec.urgency > 0
              ? _urgencyColor.withValues(alpha: 0.3) : KmColors.border,
          width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _urgencyColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(KmRadius.sm),
          ),
          child: Center(child: Text(rec.icon,
              style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec.title, style: KmTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(rec.desc, style: KmTextStyles.bodySmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              KmBadge(_urgencyLabel,
                  color: _urgencyColor,
                  bg: _urgencyColor.withValues(alpha: 0.12)),
              Text('${rec.kmLeft} ${l10n.get('svcKmLeft')}',
                  style: KmTextStyles.caption),
            ]),
          ],
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onBook,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: KmColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(KmRadius.sm),
              border: Border.all(color: KmColors.accentDim, width: 0.5),
            ),
            child: Text(l10n.get('svcBookNow'),
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 11,
                    fontWeight: FontWeight.w600, color: KmColors.accent),
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
    );
  }
}

// ── Review sheet ──────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.l10n, required this.onSubmit});
  final AppLocalizations l10n;
  final void Function(int rating, String text) onSubmit;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: KmColors.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(l10n.get('svcLeaveReview'),
            style: KmTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        // Stars
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: KmColors.accent, size: 36),
            ),
          )),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: KmColors.surface2,
              borderRadius: BorderRadius.circular(KmRadius.md),
              border: Border.all(color: KmColors.border, width: 0.5)),
          child: TextField(
            controller: _ctrl,
            maxLines: 3,
            style: KmTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: l10n.get('svcReviewHint'),
              hintStyle: KmTextStyles.caption,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _rating == 0 ? null : () => widget.onSubmit(_rating, _ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: KmColors.accent,
              foregroundColor: KmColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KmRadius.md)),
            ),
            child: Text(l10n.get('svcReviewSent'),
                style: const TextStyle(fontFamily: 'DMSans', fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Misc widgets ──────────────────────────────────────────────

class _BookBtn extends StatelessWidget {
  const _BookBtn({required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServiceBookingScreen()),
      ).then((_) => onReturn()),
      icon: const Text('🔧', style: TextStyle(fontSize: 14)),
      label: Text(AppLocalizations.of(context).get('book')),
      style: ElevatedButton.styleFrom(
        backgroundColor: KmColors.accent,
        foregroundColor: KmColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 12,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90,
          child: Text(label, style: KmTextStyles.bodySmall
              .copyWith(color: KmColors.textMuted))),
      Expanded(child: Text(value, style: KmTextStyles.bodySmall
          .copyWith(fontWeight: FontWeight.w600))),
    ]);
  }
}