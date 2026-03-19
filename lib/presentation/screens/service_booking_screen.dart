import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/booking_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Service Booking Screen v2
// Полный функционал: тип услуги, доп.работы, дата/время,
// комментарий, напоминание, сохранение, отмена
// ============================================================

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key, this.preselectedKey});
  final String? preselectedKey;

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  int    _selectedServiceIdx = 0;
  int    _selectedDayIdx     = 0;
  int    _selectedTimeIdx    = -1;
  bool   _reminderEnabled    = true;
  String _selectedCenter     = '';
  final _commentCtrl = TextEditingController();
  final Set<int> _selectedExtras = {};
  bool _saving = false;

  static const _centers = [
    'center1', 'center2', 'center3', 'center4',
  ];

  late final List<_DaySlot> _days;

  static const _times = [
    '09:00', '10:30', '12:00', '14:00', '15:30', '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _buildDays();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _buildDays() {
    final now = DateTime.now();
    _days = List.generate(14, (i) {
      final d = now.add(Duration(days: i + 1));
      return _DaySlot(d.weekday, d.day, d.month, d.year);
    });
  }

  List<_ServiceType> _serviceTypes(AppLocalizations l10n) => [
    _ServiceType('🔧', 'svcOilName',   l10n.get('svcOilName'),   l10n.get('svcOilDesc'),   28000,
        extras: [l10n.get('svcExtFilter'), l10n.get('svcExtPlugs')]),
    _ServiceType('🛞', 'svcTireName',  l10n.get('svcTireName'),  l10n.get('svcTireDesc'),  15000,
        extras: [l10n.get('svcExtBalance'), l10n.get('svcExtAlignment')]),
    _ServiceType('🛑', 'svcBrakeName', l10n.get('svcBrakeName'), l10n.get('svcBrakeDesc'), 22000,
        extras: [l10n.get('svcExtDiscs'), l10n.get('svcExtFluid')]),
    _ServiceType('🔋', 'svcBattName',  l10n.get('svcBattName'),  l10n.get('svcBattDesc'),   8000,
        extras: [l10n.get('svcExtDiag')]),
    _ServiceType('🌡️', 'svcCoolName', l10n.get('svcCoolName'),  l10n.get('svcCoolDesc'),  12000,
        extras: [l10n.get('svcExtThermostat')]),
    _ServiceType('🔍', 'svcDiagName',  l10n.get('svcDiagName'),  l10n.get('svcDiagDesc'),   5000,
        extras: []),
  ];

  String _weekdayShort(AppLocalizations l10n, int weekday) {
    const keys = ['wdMon','wdTue','wdWed','wdThu','wdFri','wdSat','wdSun'];
    return l10n.get(keys[weekday - 1]);
  }

  int get _totalPrice {
    final l10n = AppLocalizations.of(context);
    final services = _serviceTypes(l10n);
    final svc = services[_selectedServiceIdx];
    const extraPrice = 3000;
    return svc.priceKzt + _selectedExtras.length * extraPrice;
  }

  Future<void> _book(AppLocalizations l10n, List<_ServiceType> services) async {
    if (_selectedTimeIdx < 0) {
      _snack(l10n.get('bookingSelectTime'));
      return;
    }
    setState(() => _saving = true);

    final svc = services[_selectedServiceIdx];
    final day = _days[_selectedDayIdx];
    final date = DateTime(day.year, day.month, day.day);
    final time = _times[_selectedTimeIdx];

    final entry = BookingEntry(
      id:              DateTime.now().millisecondsSinceEpoch.toString(),
      serviceKey:      svc.key,
      serviceName:     svc.name,
      serviceIcon:     svc.icon,
      date:            date,
      time:            time,
      priceKzt:        _totalPrice,
      extras:          _selectedExtras.map((i) => svc.extras[i]).toList(),
      comment:         _commentCtrl.text.trim(),
      reminderEnabled: _reminderEnabled,
      status:          'confirmed',
    );

    await BookingService.instance.save(entry);
    setState(() => _saving = false);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        service: svc, day: day,
        weekdayLabel: _weekdayShort(l10n, day.weekday),
        time: time, l10n: l10n, total: _totalPrice,
        extras: _selectedExtras.map((i) => svc.extras[i]).toList(),
        reminder: _reminderEnabled,
        onConfirm: () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: KmTextStyles.bodySmall),
      backgroundColor: KmColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context);
    final services = _serviceTypes(l10n);
    final svc      = services[_selectedServiceIdx];

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 16),
          KmScreenHeader(
            title:    l10n.get('bookingTitle'),
            subtitle: l10n.get('bookingSubtitle'),
            showBack: true,
            onBack:   () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Тип услуги ─────────────────────────────
                  KmSectionLabel(l10n.get('bookingWorkType')),
                  const SizedBox(height: 4),
                  ...List.generate(services.length, (i) {
                    final s = services[i];
                    final active = i == _selectedServiceIdx;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedServiceIdx = i;
                          _selectedExtras.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF1E1F2C) : KmColors.surface2,
                            borderRadius: BorderRadius.circular(KmRadius.lg),
                            border: Border.all(
                              color: active ? KmColors.accent : KmColors.border,
                              width: active ? 1 : 0.5),
                          ),
                          child: Row(children: [
                            Text(s.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: KmTextStyles.bodyMedium),
                                const SizedBox(height: 2),
                                Text(s.description, style: KmTextStyles.caption),
                              ],
                            )),
                            Text('${s.priceKzt ~/ 1000} 000 ₸',
                                style: KmTextStyles.labelSmall
                                    .copyWith(color: KmColors.accent)),
                          ]),
                        ),
                      ),
                    );
                  }),

                  // ── Дополнительные работы ───────────────────
                  if (svc.extras.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    KmSectionLabel(l10n.get('bookingExtras')),
                    const SizedBox(height: 4),
                    ...List.generate(svc.extras.length, (i) {
                      final sel = _selectedExtras.contains(i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (sel) { _selectedExtras.remove(i); }
                            else     { _selectedExtras.add(i); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? KmColors.accent.withValues(alpha: 0.08)
                                  : KmColors.surface2,
                              borderRadius: BorderRadius.circular(KmRadius.md),
                              border: Border.all(
                                color: sel ? KmColors.accent : KmColors.border,
                                width: sel ? 1 : 0.5),
                            ),
                            child: Row(children: [
                              Icon(
                                sel ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: sel ? KmColors.accent : KmColors.textMuted,
                                size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(svc.extras[i],
                                  style: KmTextStyles.bodySmall)),
                              Text('+3 000 ₸', style: KmTextStyles.caption
                                  .copyWith(color: KmColors.accentDim)),
                            ]),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 20),

                  // ── Дата ───────────────────────────────────
                  KmSectionLabel(l10n.get('bookingDateLabel')),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = _days[i];
                        final active = i == _selectedDayIdx;
                        // Gray out weekends
                        final isWeekend = d.weekday >= 6;
                        return GestureDetector(
                          onTap: isWeekend ? null : () => setState(() {
                            _selectedDayIdx  = i;
                            _selectedTimeIdx = -1;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 52,
                            decoration: BoxDecoration(
                              color: active ? KmColors.accent
                                  : isWeekend ? KmColors.surface3
                                  : KmColors.surface2,
                              borderRadius: BorderRadius.circular(KmRadius.md),
                              border: Border.all(
                                color: active ? KmColors.accent : KmColors.border,
                                width: 0.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weekdayShort(l10n, d.weekday),
                                  style: TextStyle(
                                    fontFamily: 'DMSans', fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: active ? KmColors.background
                                        : isWeekend ? KmColors.textMuted
                                        : KmColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text('${d.day}',
                                  style: TextStyle(
                                    fontFamily: 'CormorantGaramond', fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: active ? KmColors.background
                                        : isWeekend ? KmColors.surface3
                                        : KmColors.textPrimary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Время ──────────────────────────────────
                  KmSectionLabel(l10n.get('bookingTimeLabel')),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8, crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                    children: List.generate(_times.length, (i) {
                      final active = i == _selectedTimeIdx;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTimeIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF1E1F2C) : KmColors.surface2,
                            borderRadius: BorderRadius.circular(KmRadius.sm),
                            border: Border.all(
                              color: active ? KmColors.accent : KmColors.border,
                              width: active ? 1 : 0.5),
                          ),
                          child: Text(_times[i], style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: active ? KmColors.accent : KmColors.textSecondary)),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ── Сервисный центр ────────────────────────
                  KmSectionLabel(l10n.get('bookingCenter')),
                  const SizedBox(height: 4),
                  ...List.generate(_centers.length, (i) {
                    final key = _centers[i];
                    final name = l10n.get(key);
                    final sel = _selectedCenter == name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCenter = name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF1E1F2C) : KmColors.surface2,
                            borderRadius: BorderRadius.circular(KmRadius.md),
                            border: Border.all(
                              color: sel ? KmColors.accent : KmColors.border,
                              width: sel ? 1 : 0.5),
                          ),
                          child: Row(children: [
                            Icon(Icons.location_on_outlined,
                                color: sel ? KmColors.accent : KmColors.textMuted,
                                size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(name,
                                style: KmTextStyles.bodySmall.copyWith(
                                    color: sel ? KmColors.accent
                                        : KmColors.textPrimary))),
                            if (sel)
                              const Icon(Icons.check_circle_rounded,
                                  color: KmColors.accent, size: 16),
                          ]),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // ── Комментарий ────────────────────────────
                  KmSectionLabel(l10n.get('bookingComment')),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: KmColors.surface2,
                      borderRadius: BorderRadius.circular(KmRadius.md),
                      border: Border.all(color: KmColors.border, width: 0.5),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      style: KmTextStyles.bodySmall,
                      decoration: InputDecoration(
                        hintText: l10n.get('bookingCommentHint'),
                        hintStyle: KmTextStyles.caption,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Напоминание ────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _reminderEnabled = !_reminderEnabled),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _reminderEnabled
                            ? KmColors.accent.withValues(alpha: 0.08)
                            : KmColors.surface2,
                        borderRadius: BorderRadius.circular(KmRadius.md),
                        border: Border.all(
                          color: _reminderEnabled ? KmColors.accent : KmColors.border,
                          width: _reminderEnabled ? 1 : 0.5),
                      ),
                      child: Row(children: [
                        Icon(
                          _reminderEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          color: _reminderEnabled ? KmColors.accent : KmColors.textMuted,
                          size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(
                          _reminderEnabled
                              ? l10n.get('bookingReminderOn')
                              : l10n.get('bookingReminder'),
                          style: KmTextStyles.bodySmall.copyWith(
                            color: _reminderEnabled
                                ? KmColors.accent : KmColors.textSecondary))),
                        Switch.adaptive(
                          value: _reminderEnabled,
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                          activeThumbColor: KmColors.accent,
                          activeTrackColor: KmColors.accentDim,
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Итог ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141520),
                      borderRadius: BorderRadius.circular(KmRadius.lg),
                      border: Border.all(color: KmColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.get('bookingSelected'),
                                  style: KmTextStyles.caption),
                              const SizedBox(height: 4),
                              Text(svc.name, style: KmTextStyles.bodyMedium),
                              if (_selectedExtras.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _selectedExtras.map((i) => svc.extras[i]).join(', '),
                                  style: KmTextStyles.caption
                                      .copyWith(color: KmColors.accentDim),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                _selectedTimeIdx >= 0
                                    ? '${_days[_selectedDayIdx].day}.${_days[_selectedDayIdx].month.toString().padLeft(2,'0')} · ${_times[_selectedTimeIdx]}'
                                    : l10n.get('bookingTimeNone'),
                                style: KmTextStyles.caption.copyWith(
                                  color: _selectedTimeIdx >= 0
                                      ? KmColors.accent : KmColors.textMuted),
                              ),
                            ],
                          )),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(l10n.get('bookingTotal'),
                                style: KmTextStyles.caption),
                            const SizedBox(height: 2),
                            Text(
                              '${_totalPrice ~/ 1000} 000 ₸',
                              style: KmTextStyles.displaySmall.copyWith(
                                  color: KmColors.accent)),
                          ]),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _book(l10n, services),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KmColors.accent,
                        foregroundColor: KmColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KmRadius.md)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: KmColors.background))
                          : Text(l10n.get('bookingBookBtn'), style: const TextStyle(
                              fontFamily: 'DMSans', fontSize: 14,
                              fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Confirm dialog ────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.service, required this.day, required this.weekdayLabel,
    required this.time, required this.l10n, required this.total,
    required this.extras, required this.reminder, required this.onConfirm,
  });

  final _ServiceType service;
  final _DaySlot day;
  final String weekdayLabel;
  final String time;
  final AppLocalizations l10n;
  final int total;
  final List<String> extras;
  final bool reminder;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '$weekdayLabel, ${day.day}.${day.month.toString().padLeft(2, '0')} · $time';
    return AlertDialog(
      backgroundColor: KmColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KmRadius.xl),
        side: const BorderSide(color: KmColors.border, width: 0.5),
      ),
      title: Column(children: [
        Text(service.icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(l10n.get('bookingConfirmTitle'),
            style: KmTextStyles.displaySmall, textAlign: TextAlign.center),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(service.name, style: KmTextStyles.bodyMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(dateStr, style: KmTextStyles.caption.copyWith(color: KmColors.accent),
            textAlign: TextAlign.center),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('+ ${extras.join(', ')}',
              style: KmTextStyles.caption, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 10),
        Text('${total ~/ 1000} 000 ₸',
            style: KmTextStyles.numeralSmall.copyWith(color: KmColors.accent),
            textAlign: TextAlign.center),
        if (reminder) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.notifications_active_rounded,
                color: KmColors.success, size: 14),
            const SizedBox(width: 4),
            Text(l10n.get('bookingReminderOn'),
                style: KmTextStyles.caption.copyWith(color: KmColors.success)),
          ]),
        ],
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('bookingCancelBtn'),
              style: const TextStyle(color: KmColors.textMuted,
                  fontFamily: 'DMSans', fontSize: 14)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: KmColors.accent,
              foregroundColor: KmColors.background),
          onPressed: onConfirm,
          child: Text(l10n.get('bookingConfirmBtn'),
              style: const TextStyle(fontFamily: 'DMSans', fontSize: 14)),
        ),
      ],
    );
  }
}

// ── Models ────────────────────────────────────────────────────

class _ServiceType {
  const _ServiceType(this.icon, this.key, this.name, this.description,
      this.priceKzt, {this.extras = const []});
  final String icon;
  final String key;
  final String name;
  final String description;
  final int priceKzt;
  final List<String> extras;
}

class _DaySlot {
  const _DaySlot(this.weekday, this.day, this.month, this.year);
  final int weekday;
  final int day;
  final int month;
  final int year;
}