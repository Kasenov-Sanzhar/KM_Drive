import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'service_booking_screen.dart';

// ============================================================
// KM DRIVE — Service Screen
// ============================================================

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _repo = MockVehicleRepository();
  NextServiceInfo? _nextService;
  List<ServiceRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getNextService(),
      _repo.getServiceHistory(),
    ]);
    if (mounted) {
      setState(() {
        _nextService = results[0] as NextServiceInfo;
        _history     = results[1] as List<ServiceRecord>;
        _loading     = false;
      });
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

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: KmScreenHeader(
                  title: l10n.get('serviceTitle'),
                  subtitle: l10n.get('serviceSubtitle'),
                  trailing: _BookButton(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: _NextServiceCard(info: _nextService!),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KmSectionLabel(l10n.get('serviceHistory')),
                    _ServiceHistoryList(records: _history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServiceBookingScreen()),
      ),
      icon: const Text('🔧', style: TextStyle(fontSize: 14)),
      label: Text(AppLocalizations.of(context).get('book')),
      style: ElevatedButton.styleFrom(
        backgroundColor: KmColors.accent,
        foregroundColor: KmColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(
            fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Следующее ТО ─────────────────────────────────────────────

class _NextServiceCard extends StatelessWidget {
  const _NextServiceCard({required this.info});
  final NextServiceInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KmAccentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.get('nextService').toUpperCase(),
              style: KmTextStyles.labelMedium.copyWith(color: KmColors.accent)),
          const SizedBox(height: 8),
          Text(KmFormatters.date(info.date), style: KmTextStyles.displaySmall),
          const SizedBox(height: 4),
          Text(
            '${l10n.get('throughKm')} ${KmFormatters.kilometers(info.remainingKm)} '
            '${l10n.get('orDays')} ${info.remainingDays} ${l10n.get('days')}',
            style: KmTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          KmProgressBar(value: info.progress, height: 3.5),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 ${l10n.get('km')}', style: KmTextStyles.caption),
              Text('${(info.progress * 100).toInt()}% ${l10n.get('passed')}',
                  style: KmTextStyles.caption),
              Text(KmFormatters.kilometers(info.intervalKm),
                  style: KmTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── История обслуживания ─────────────────────────────────────

class _ServiceHistoryList extends StatefulWidget {
  const _ServiceHistoryList({required this.records});
  final List<ServiceRecord> records;

  @override
  State<_ServiceHistoryList> createState() => _ServiceHistoryListState();
}

class _ServiceHistoryListState extends State<_ServiceHistoryList> {
  final Set<int> _expanded = {};

  void _toggle(int i) => setState(() {
        if (_expanded.contains(i)) {
          _expanded.remove(i);
        } else {
          _expanded.add(i);
        }
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.records.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final isOpen = _expanded.contains(i);

        return Column(
          children: [
            _ServiceRecordItem(
              record: r,
              isExpanded: isOpen,
              onTap: () => _toggle(i),
            ),
            if (i < widget.records.length - 1) const KmDivider(),
          ],
        );
      }).toList(),
    );
  }
}

class _ServiceRecordItem extends StatelessWidget {
  const _ServiceRecordItem({
    required this.record,
    required this.isExpanded,
    required this.onTap,
  });

  final ServiceRecord record;
  final bool isExpanded;
  final VoidCallback onTap;

  _BadgeStyle _badgeStyle(AppLocalizations l10n) {
    switch (record.status) {
      case ServiceStatus.done:
        return _BadgeStyle(KmColors.success, KmColors.overlaySuccess, l10n.get('statusDone'));
      case ServiceStatus.scheduled:
        return _BadgeStyle(KmColors.warning, KmColors.overlayAccent, l10n.get('statusScheduled'));
      case ServiceStatus.recommended:
        return _BadgeStyle(KmColors.warning, KmColors.overlayAccent, l10n.get('statusRecommended'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final badge = _badgeStyle(l10n);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFF111318) : Colors.transparent,
          borderRadius: BorderRadius.circular(isExpanded ? KmRadius.md : 0),
        ),
        child: Padding(
          padding: isExpanded
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: KmColors.surface3,
                      borderRadius: BorderRadius.circular(KmRadius.md),
                    ),
                    child: Center(
                        child: Text(record.icon,
                            style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.title, style: KmTextStyles.bodyMedium),
                        const SizedBox(height: 3),
                        Text(
                          record.status == ServiceStatus.done
                              ? '${KmFormatters.dateShort(record.date)} · ${KmFormatters.kilometers(record.mileageKm)}'
                              : record.description ?? KmFormatters.date(record.date),
                          style: KmTextStyles.caption,
                        ),
                        if (record.priceKzt != null) ...[
                          const SizedBox(height: 2),
                          Text(KmFormatters.tenge(record.priceKzt!),
                              style: KmTextStyles.caption.copyWith(
                                  color: KmColors.accentDim)),
                        ],
                        const SizedBox(height: 6),
                        Row(children: [
                          KmBadge(badge.label, color: badge.color, bg: badge.bg),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16, color: KmColors.textMuted,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Раскрытые детали ────────────────────────
              if (isExpanded) ...[
                const SizedBox(height: 14),
                const Divider(color: KmColors.border, thickness: 0.5, height: 0),
                const SizedBox(height: 14),

                // Детали записи
                _DetailRow(l10n.get('serviceDate'),
                    KmFormatters.date(record.date)),
                const SizedBox(height: 8),
                _DetailRow(l10n.get('serviceMileage'),
                  KmFormatters.kilometers(record.mileageKm)),
                if (record.priceKzt != null) ...[
                  const SizedBox(height: 8),
                  _DetailRow(l10n.get('servicePrice'),
                      KmFormatters.tenge(record.priceKzt!)),
                ],
                if (record.description != null &&
                    record.status != ServiceStatus.done) ...[
                  const SizedBox(height: 8),
                  _DetailRow('', record.description!, multiline: true),
                ],
                // No detailed "worksDone" list in the model; use description if present.

                // Кнопка для scheduled/recommended
                if (record.status != ServiceStatus.done) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ServiceBookingScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KmColors.accent,
                        foregroundColor: KmColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KmRadius.md)),
                      ),
                      child: Text(l10n.get('serviceSchedule'),
                          style: const TextStyle(
                              fontFamily: 'DMSans', fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.multiline = false});
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    if (multiline) {
      return Text(value, style: KmTextStyles.bodySmall);
    }
    return Row(children: [
      SizedBox(
        width: 100,
        child: Text(label, style: KmTextStyles.caption),
      ),
      Expanded(
        child: Text(value,
            style: KmTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w500)),
      ),
    ]);
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.color, this.bg, this.label);
  final Color color;
  final Color bg;
  final String label;
}