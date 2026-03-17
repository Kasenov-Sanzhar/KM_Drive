import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Service Booking Screen
// Полная локализация: ru / kk / en
// ============================================================

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  int _selectedServiceIdx = 0;
  int _selectedDayIdx     = 0;
  int _selectedTimeIdx    = -1;

  static const _times = [
    '09:00', '10:30', '12:00', '14:00', '15:30', '17:00',
  ];

  late final List<_DaySlot> _days;

  @override
  void initState() {
    super.initState();
    _buildDays();
  }

  void _buildDays() {
    final now = DateTime.now();
    _days = List.generate(7, (i) {
      final d = now.add(Duration(days: i + 1));
      return _DaySlot(d.weekday, d.day, d.month);
    });
  }

  List<_ServiceType> _serviceTypes(AppLocalizations l10n) => [
    _ServiceType('🔧', l10n.get('svcOilName'),   l10n.get('svcOilDesc'),   28000),
    _ServiceType('🛞', l10n.get('svcTireName'),  l10n.get('svcTireDesc'),  15000),
    _ServiceType('🛑', l10n.get('svcBrakeName'), l10n.get('svcBrakeDesc'), 22000),
    _ServiceType('🔋', l10n.get('svcBattName'),  l10n.get('svcBattDesc'),   8000),
  ];

  String _weekdayShort(AppLocalizations l10n, int weekday) {
    const keys = ['wdMon','wdTue','wdWed','wdThu','wdFri','wdSat','wdSun'];
    return l10n.get(keys[weekday - 1]);
  }

  void _book(AppLocalizations l10n, List<_ServiceType> services) {
    if (_selectedTimeIdx < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('bookingSelectTime'),
              style: KmTextStyles.bodySmall),
          backgroundColor: KmColors.surface2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        service: services[_selectedServiceIdx],
        day: _days[_selectedDayIdx],
        weekdayLabel: _weekdayShort(l10n, _days[_selectedDayIdx].weekday),
        time: _times[_selectedTimeIdx],
        l10n: l10n,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _monthDay(_DaySlot d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context);
    final services = _serviceTypes(l10n);
    final svc      = services[_selectedServiceIdx];

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            KmScreenHeader(
              title:    l10n.get('bookingTitle'),
              subtitle: l10n.get('bookingSubtitle'),
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Тип услуги ────────────────────────────
                    KmSectionLabel(l10n.get('bookingWorkType')),
                    const SizedBox(height: 4),
                    ...List.generate(services.length, (i) {
                      final s      = services[i];
                      final active = i == _selectedServiceIdx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedServiceIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1E1F2C)
                                  : KmColors.surface2,
                              borderRadius: BorderRadius.circular(KmRadius.lg),
                              border: Border.all(
                                color: active ? KmColors.accent : KmColors.border,
                                width: active ? 1 : 0.5,
                              ),
                            ),
                            child: Row(children: [
                              Text(s.icon,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: KmTextStyles.bodyMedium),
                                    const SizedBox(height: 2),
                                    Text(s.description,
                                        style: KmTextStyles.caption),
                                  ],
                                ),
                              ),
                              Text(
                                '${s.priceKzt ~/ 1000} 000 ₸',
                                style: KmTextStyles.labelSmall.copyWith(
                                    color: KmColors.accent),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Дата ──────────────────────────────────
                    KmSectionLabel(l10n.get('bookingDateLabel')),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d      = _days[i];
                          final active = i == _selectedDayIdx;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedDayIdx  = i;
                              _selectedTimeIdx = -1;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 52,
                              decoration: BoxDecoration(
                                color: active
                                    ? KmColors.accent
                                    : KmColors.surface2,
                                borderRadius:
                                    BorderRadius.circular(KmRadius.md),
                                border: Border.all(
                                  color: active
                                      ? KmColors.accent
                                      : KmColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weekdayShort(l10n, d.weekday),
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w500,
                                      color: active
                                          ? KmColors.background
                                          : KmColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontFamily: 'CormorantGaramond',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? KmColors.background
                                          : KmColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Время ─────────────────────────────────
                    KmSectionLabel(l10n.get('bookingTimeLabel')),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                      children: List.generate(_times.length, (i) {
                        final active = i == _selectedTimeIdx;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTimeIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1E1F2C)
                                  : KmColors.surface2,
                              borderRadius:
                                  BorderRadius.circular(KmRadius.sm),
                              border: Border.all(
                                color: active
                                    ? KmColors.accent
                                    : KmColors.border,
                                width: active ? 1 : 0.5,
                              ),
                            ),
                            child: Text(
                              _times[i],
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? KmColors.accent
                                    : KmColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    // ── Итог ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141520),
                        borderRadius: BorderRadius.circular(KmRadius.lg),
                        border: Border.all(
                            color: KmColors.border, width: 0.5),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.get('bookingSelected'),
                                  style: KmTextStyles.caption),
                              const SizedBox(height: 4),
                              Text(svc.name,
                                  style: KmTextStyles.bodyMedium),
                              const SizedBox(height: 2),
                              Text(
                                _selectedTimeIdx >= 0
                                    ? '${_monthDay(_days[_selectedDayIdx])} · ${_times[_selectedTimeIdx]}'
                                    : l10n.get('bookingTimeNone'),
                                style: KmTextStyles.caption.copyWith(
                                  color: _selectedTimeIdx >= 0
                                      ? KmColors.accent
                                      : KmColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${svc.priceKzt ~/ 1000} 000 ₸',
                          style: KmTextStyles.displaySmall.copyWith(
                            color: KmColors.accent,
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _book(l10n, services),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KmColors.accent,
                          foregroundColor: KmColors.background,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KmRadius.md),
                          ),
                        ),
                        child: Text(
                          l10n.get('bookingBookBtn'),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
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

// ── Диалог подтверждения ──────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.service,
    required this.day,
    required this.weekdayLabel,
    required this.time,
    required this.l10n,
    required this.onConfirm,
  });

  final _ServiceType service;
  final _DaySlot day;
  final String weekdayLabel;
  final String time;
  final AppLocalizations l10n;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${day.day}.${day.month.toString().padLeft(2, '0')} · $time';
    return AlertDialog(
      backgroundColor: KmColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KmRadius.xl),
        side: const BorderSide(color: KmColors.border, width: 0.5),
      ),
      title: Column(children: [
        Text(service.icon,
            style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(l10n.get('bookingConfirmTitle'),
            style: KmTextStyles.displaySmall,
            textAlign: TextAlign.center),
      ]),
      content: Text(
        '${service.name}\n$dateStr',
        style: KmTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('bookingCancelBtn'),
              style: const TextStyle(
                  color: KmColors.textMuted,
                  fontFamily: 'DMSans',
                  fontSize: 14)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: KmColors.accent,
              foregroundColor: KmColors.background),
          onPressed: onConfirm,
          child: Text(l10n.get('bookingConfirmBtn'),
              style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 14)),
        ),
      ],
    );
  }
}

// ── Модели ────────────────────────────────────────────────────

class _ServiceType {
  const _ServiceType(this.icon, this.name, this.description, this.priceKzt);
  final String icon;
  final String name;
  final String description;
  final int priceKzt;
}

class _DaySlot {
  const _DaySlot(this.weekday, this.day, this.month);
  final int weekday; // 1=Mon … 7=Sun
  final int day;
  final int month;
}