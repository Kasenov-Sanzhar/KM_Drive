import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Dealer Screen
// Полная локализация: ru / kk / en
// ============================================================

class DealerScreen extends StatelessWidget {
  const DealerScreen({super.key});

  static const _phone    = '+7 (727) 123-45-67';
  static const _whatsApp = '+77271234567';
  static const _mapsUrl  = 'geo:43.2220,76.9080?q=KM+Motors+Almaty';
  static const _managerPhone = '+7 (707) 987-65-43';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Все данные берём из l10n
    final hours = [
      (l10n.get('dealerHrMF'),  l10n.get('dealerHrMFVal')),
      (l10n.get('dealerHrSat'), l10n.get('dealerHrSatVal')),
      (l10n.get('dealerHrSun'), l10n.get('dealerHrSunVal')),
    ];

    final services = [
      ('🔧', l10n.get('dSvc1Name'), l10n.get('dSvc1Desc')),
      ('🛠️', l10n.get('dSvc2Name'), l10n.get('dSvc2Desc')),
      ('🛞', l10n.get('dSvc3Name'), l10n.get('dSvc3Desc')),
      ('🔋', l10n.get('dSvc4Name'), l10n.get('dSvc4Desc')),
      ('🚗', l10n.get('dSvc5Name'), l10n.get('dSvc5Desc')),
      ('📦', l10n.get('dSvc6Name'), l10n.get('dSvc6Desc')),
    ];

    final offers = [
      _Offer('🎁', l10n.get('dOffer1Title'), l10n.get('dOffer1Desc'),
          KmColors.accent, const Color(0x18C8A96E)),
      _Offer('⭐', l10n.get('dOffer2Title'), l10n.get('dOffer2Desc'),
          KmColors.info, const Color(0x185A8FE0)),
      _Offer('📅', l10n.get('dOffer3Title'), l10n.get('dOffer3Desc'),
          KmColors.success, const Color(0x1859C172)),
    ];

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: KmScreenHeader(
                  title:    l10n.get('dealerTitle'),
                  subtitle: l10n.get('dealerSubtitle'),
                  showBack: true,
                ),
              ),
            ),

            // Карта-заглушка
            SliverToBoxAdapter(
              child: _MapBanner(address: l10n.get('dealerAddressVal')),
            ),

            // Кнопки связи
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _ContactButtons(l10n: l10n),
              ),
            ),

            // Адрес / телефон / часы
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _InfoCard(l10n: l10n, hours: hours),
              ),
            ),

            // Персональный менеджер
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _ManagerCard(l10n: l10n),
              ),
            ),

            // Услуги
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KmSectionLabel(l10n.get('dealerServices')),
                    _ServicesGrid(services: services),
                  ],
                ),
              ),
            ),

            // Спецпредложения
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KmSectionLabel(l10n.get('dealerOffers')),
                    ...offers.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OfferCard(offer: o),
                        )),
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

// ── Карта-заглушка ────────────────────────────────────────────

class _MapBanner extends StatelessWidget {
  const _MapBanner({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1018),
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(KmRadius.lg),
            child: const CustomPaint(
              size: Size(double.infinity, 180),
              painter: _MapPainter(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KmRadius.lg),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC0D1018)],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 44, height: 44,
              child: Center(
                child: Text('KM',
                    style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF08080A),
                        letterSpacing: 2)),
              ),
            ),
          ),
          Positioned(
            bottom: 12, left: 14, right: 14,
            child: Row(children: [
              const Icon(Icons.location_on, color: KmColors.accent, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address,
                    style: KmTextStyles.caption
                        .copyWith(color: KmColors.textSecondary)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()..color = const Color(0x0AC8A96E)..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    final r1 = Paint()
      ..color = const Color(0x14FFFFFF)..strokeWidth = 10..strokeCap = StrokeCap.round;
    final r2 = Paint()
      ..color = const Color(0x0AFFFFFF)..strokeWidth = 6..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), r1);
    canvas.drawLine(Offset(size.width * 0.4, 0),
        Offset(size.width * 0.4, size.height), r1);
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), r2);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.7, size.height), r2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Кнопки связи ─────────────────────────────────────────────

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({required this.l10n});
  final AppLocalizations l10n;

  void _snack(BuildContext ctx, String text) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(text, style: KmTextStyles.bodySmall),
      backgroundColor: KmColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _CBtn(
          icon: Icons.phone_rounded,
          label: l10n.get('dealerCall'),
          color: KmColors.accent,
          bg: const Color(0x1AC8A96E),
          border: const Color(0x40C8A96E),
          onTap: () {
            Clipboard.setData(
                const ClipboardData(text: DealerScreen._phone));
            _snack(context,
                '${DealerScreen._phone} ${l10n.get('phoneCopied')}');
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _CBtn(
          icon: Icons.chat_bubble_rounded,
          label: l10n.get('dealerWhatsApp'),
          color: KmColors.success,
          bg: const Color(0x1A59C172),
          border: const Color(0x4059C172),
          onTap: () {
            Clipboard.setData(
                const ClipboardData(text: DealerScreen._whatsApp));
            _snack(context,
                '${DealerScreen._whatsApp} ${l10n.get('phoneCopied')}');
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _CBtn(
          icon: Icons.directions_rounded,
          label: l10n.get('dealerRoute'),
          color: KmColors.info,
          bg: const Color(0x1A5A8FE0),
          border: const Color(0x405A8FE0),
          onTap: () {
            Clipboard.setData(
                const ClipboardData(text: DealerScreen._mapsUrl));
            _snack(context, l10n.get('mapLinkCopied'));
          },
        ),
      ),
    ]);
  }
}

class _CBtn extends StatelessWidget {
  const _CBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color, bg, border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Адрес / телефон / часы ────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.l10n,
      required this.hours});
  final AppLocalizations l10n;
  final List<(String, String)> hours;

  @override
  Widget build(BuildContext context) {
    final closedVal = l10n.get('dealerHrSunVal');
    return KmAccentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Адрес
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_outlined,
                color: KmColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.get('dealerAddress'),
                      style: KmTextStyles.labelSmall),
                  const SizedBox(height: 3),
                  Text(l10n.get('dealerAddressVal'),
                      style: KmTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(l10n.get('dealerTransport'),
                      style: KmTextStyles.caption),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),
          const KmDivider(),
          const SizedBox(height: 16),

          // Телефон
          Row(children: [
            const Icon(Icons.phone_outlined,
                color: KmColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.get('dealerPhone'),
                      style: KmTextStyles.labelSmall),
                  const SizedBox(height: 3),
                  Text(l10n.get('dealerPhoneVal'),
                      style: KmTextStyles.bodyMedium),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),
          const KmDivider(),
          const SizedBox(height: 16),

          // Часы работы
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.access_time_rounded,
                color: KmColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.get('dealerHours'),
                      style: KmTextStyles.labelSmall),
                  const SizedBox(height: 6),
                  ...hours.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          SizedBox(
                            width: 120,
                            child: Text(h.$1,
                                style: KmTextStyles.caption),
                          ),
                          Text(
                            h.$2,
                            style: KmTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: h.$2 == closedVal
                                  ? KmColors.textMuted
                                  : KmColors.textPrimary,
                            ),
                          ),
                        ]),
                      )),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Менеджер ─────────────────────────────────────────────────

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.l10n});
  final AppLocalizations l10n;

  void _snack(BuildContext ctx) {
    Clipboard.setData(
        const ClipboardData(text: DealerScreen._managerPhone));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(
          '${DealerScreen._managerPhone} ${l10n.get('phoneCopied')}',
          style: KmTextStyles.bodySmall),
      backgroundColor: KmColors.surface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0x18C8A96E),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0x40C8A96E), width: 0.5),
          ),
          child: const Center(
              child: Text('👔',
                  style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('dealerManager'),
                  style: KmTextStyles.labelSmall
                      .copyWith(color: KmColors.accent)),
              const SizedBox(height: 3),
              Text(l10n.get('dealerManagerName'),
                  style: KmTextStyles.bodyMedium),
              Text(l10n.get('dealerManagerRole'),
                  style: KmTextStyles.caption),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _snack(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x18C8A96E),
              borderRadius: BorderRadius.circular(KmRadius.sm),
              border: Border.all(
                  color: const Color(0x40C8A96E), width: 0.5),
            ),
            child: const Icon(Icons.phone_rounded,
                color: KmColors.accent, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ── Услуги ────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.services});
  final List<(String, String, String)> services;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: services.map((s) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KmColors.surface2,
            borderRadius: BorderRadius.circular(KmRadius.md),
            border: Border.all(color: KmColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.$1, style: const TextStyle(fontSize: 18)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2,
                      style: KmTextStyles.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(s.$3,
                      style: KmTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Спецпредложения ───────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final _Offer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: offer.bg,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
            color: offer.color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: offer.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(KmRadius.sm),
          ),
          child: Center(
              child: Text(offer.icon,
                  style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.title,
                  style: KmTextStyles.bodyMedium
                      .copyWith(color: offer.color)),
              const SizedBox(height: 3),
              Text(offer.description,
                  style: KmTextStyles.bodySmall),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Offer {
  const _Offer(
      this.icon, this.title, this.description, this.color, this.bg);
  final String icon, title, description;
  final Color color, bg;
}