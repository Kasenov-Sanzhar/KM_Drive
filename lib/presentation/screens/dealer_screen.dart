import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Dealer Screen
// Официальный дилерский центр KM Motors Алматы
// ============================================================

class DealerScreen extends StatelessWidget {
  const DealerScreen({super.key});

  // ── Данные дилера ─────────────────────────────────────────

  static const _phone      = '+7 (727) 123-45-67';
  static const _whatsApp   = '+77271234567';
  static const _address    = 'Алматы, ул. Розыбакиева, 247';
  static const _addressEn  = 'Almaty, Rozybakiev St, 247';
  static const _mapsUrl    = 'geo:43.2220,76.9080?q=KM+Motors+Almaty';

  static const _hours = [
    ('Пн – Пт', '09:00 – 19:00'),
    ('Суббота',  '09:00 – 18:00'),
    ('Воскресенье', 'Выходной'),
  ];

  static const _services = [
    ('🔧', 'Техническое обслуживание',     'ТО-1, ТО-2, межсезонное ТО'),
    ('🛠️', 'Гарантийный ремонт',           'Все виды гарантийных работ'),
    ('🛞', 'Шинный центр',                  'Замена, балансировка, хранение'),
    ('🔋', 'Диагностика и электрика',        'OBD, ECU, ремонт электрики'),
    ('🚗', 'Кузовной ремонт',               'Рихтовка, покраска, полировка'),
    ('📦', 'Оригинальные запчасти',          'Склад KM Motors и под заказ'),
  ];

  static const _offers = [
    _DealerOffer(
      '🎁',
      'ТО при покупке',
      'Первое ТО бесплатно при покупке нового KM',
      KmColors.accent,
      Color(0x18C8A96E),
    ),
    _DealerOffer(
      '⭐',
      'Программа лояльности',
      'Накапливайте баллы KM Points за каждый визит',
      KmColors.info,
      Color(0x185A8FE0),
    ),
    _DealerOffer(
      '📅',
      'Онлайн-запись',
      'Скидка 5% при записи через KM Drive',
      KmColors.success,
      Color(0x1859C172),
    ),
  ];

  // Удалено неиспользуемое поле _manager

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Шапка ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: KmScreenHeader(
                  title: l10n.get('dealerTitle'),
                  subtitle: l10n.get('dealerSubtitle'),
                  showBack: true,
                ),
              ),
            ),

            // ── Карта-заглушка + лого ─────────────────────────
            SliverToBoxAdapter(
              child: _DealerMapBanner(address: l10n.get('dealerAddress') == 'Address'
                  ? _addressEn : _address),
            ),

            // ── Контактные кнопки ─────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _ContactButtons(l10n: l10n),
              ),
            ),

            // ── Адрес и режим работы ──────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _InfoCard(l10n: l10n),
              ),
            ),

            // ── Персональный менеджер ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _ManagerCard(l10n: l10n),
              ),
            ),

            // ── Услуги ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KmSectionLabel(l10n.get('dealerServices')),
                    const _ServicesGrid(),
                  ],
                ),
              ),
            ),

            // ── Спецпредложения ──────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KmSectionLabel(l10n.get('dealerOffers')),
                    ..._offers.map((o) => Padding(
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

// ── Баннер карты ─────────────────────────────────────────────

class _DealerMapBanner extends StatelessWidget {
  const _DealerMapBanner({required this.address});
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
          // Сетка
          ClipRRect(
            borderRadius: BorderRadius.circular(KmRadius.lg),
            child: const CustomPaint(
              size: Size(double.infinity, 180),
              painter: _DealerMapPainter(),
            ),
          ),

          // Затемнение снизу
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

          // Маркер
          const Center(
            child: SizedBox(
              width: 44, 
              height: 44,
              child: Center(
                child: Text(
                  'KM',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 14, 
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF08080A), 
                    letterSpacing: 2
                  ),
                ),
              ),
            ),
          ),

          // Адрес снизу
          Positioned(
            bottom: 12, left: 14, right: 14,
            child: Row(children: [
              const Icon(Icons.location_on, color: KmColors.accent, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: KmTextStyles.caption.copyWith(
                    color: KmColors.textSecondary
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DealerMapPainter extends CustomPainter {
  const _DealerMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x0AC8A96E)..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Дороги
    final road = Paint()
      ..color = const Color(0x14FFFFFF)..strokeWidth = 10..strokeCap = StrokeCap.round;
    final road2 = Paint()
      ..color = const Color(0x0AFFFFFF)..strokeWidth = 6..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), road);
    canvas.drawLine(Offset(size.width * 0.4, 0),
        Offset(size.width * 0.4, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), road2);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.7, size.height), road2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Кнопки связи ─────────────────────────────────────────────

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({required this.l10n});
  final AppLocalizations l10n;

  void _copyPhone(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: DealerScreen._phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '${DealerScreen._phone} скопирован',
          style: KmTextStyles.caption,
        ),
        backgroundColor: KmColors.surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Позвонить
      Expanded(
        child: _ContactBtn(
          icon: Icons.phone_rounded,
          label: l10n.get('dealerCall'),
          color: KmColors.accent,
          bg: const Color(0x1AC8A96E),
          border: const Color(0x40C8A96E),
          onTap: () => _copyPhone(context),
        ),
      ),
      const SizedBox(width: 10),
      // WhatsApp
      Expanded(
        child: _ContactBtn(
          icon: Icons.chat_bubble_rounded,
          label: l10n.get('dealerWhatsApp'),
          color: KmColors.success,
          bg: const Color(0x1A59C172),
          border: const Color(0x4059C172),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: DealerScreen._whatsApp));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '${DealerScreen._whatsApp} скопирован',
                  style: KmTextStyles.caption,
                ),
                backgroundColor: KmColors.surface2,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      // Маршрут
      Expanded(
        child: _ContactBtn(
          icon: Icons.directions_rounded,
          label: l10n.get('dealerRoute'),
          color: KmColors.info,
          bg: const Color(0x1A5A8FE0),
          border: const Color(0x405A8FE0),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: DealerScreen._mapsUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ссылка на карте скопирована', 
                  style: KmTextStyles.caption
                ),
                backgroundColor: KmColors.surface2,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final Color border;
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
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans', 
                fontSize: 10,
                fontWeight: FontWeight.w500, 
                color: color
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Адрес и часы ─────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    l10n.get('dealerAddress'),
                    style: KmTextStyles.labelSmall
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    DealerScreen._address,
                    style: KmTextStyles.bodyMedium
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'м. Аль-Фараби, авт. 103, 125',
                    style: KmTextStyles.caption
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),
          const KmDivider(),
          const SizedBox(height: 16),

          // Телефон
          Row(children: [
            const Icon(Icons.phone_outlined, color: KmColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('dealerPhone'), 
                    style: KmTextStyles.labelSmall
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    DealerScreen._phone, 
                    style: KmTextStyles.bodyMedium
                  ),
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
                  Text(
                    l10n.get('dealerHours'), 
                    style: KmTextStyles.labelSmall
                  ),
                  const SizedBox(height: 6),
                  ...DealerScreen._hours.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          h.$1, 
                          style: KmTextStyles.caption
                        ),
                      ),
                      Text(
                        h.$2,
                        style: KmTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: h.$2 == 'Выходной'
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
          width: 52, 
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x18C8A96E),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x40C8A96E), width: 0.5),
          ),
          child: const Center(
            child: Text(
              '👔', 
              style: TextStyle(fontSize: 22)
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('dealerManager'),
                style: KmTextStyles.labelSmall.copyWith(
                  color: KmColors.accent
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Алибек Сейтжанов', 
                style: KmTextStyles.bodyMedium
              ),
              const Text(
                'Персональный менеджер', 
                style: KmTextStyles.caption
              ),
            ],
          ),
        ),
        // Кнопка позвонить менеджеру
        GestureDetector(
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '+7 (707) 987-65-43'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '+7 (707) 987-65-43 скопирован',
                  style: KmTextStyles.caption
                ),
                backgroundColor: KmColors.surface2,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            width: 40, 
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x18C8A96E),
              borderRadius: BorderRadius.circular(KmRadius.sm),
              border: Border.all(color: const Color(0x40C8A96E), width: 0.5),
            ),
            child: const Icon(
              Icons.phone_rounded,
              color: KmColors.accent, 
              size: 18
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Услуги ───────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: DealerScreen._services.map((s) {
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
                  Text(
                    s.$2, 
                    style: KmTextStyles.labelSmall,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.$3, 
                    style: KmTextStyles.caption,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Спецпредложения ──────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final _DealerOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: offer.bg,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
          color: offer.color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, 
          height: 42,
          decoration: BoxDecoration(
            color: offer.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(KmRadius.sm),
          ),
          child: Center(
            child: Text(
              offer.icon, 
              style: const TextStyle(fontSize: 20)
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: KmTextStyles.bodyMedium.copyWith(
                  color: offer.color
                ),
              ),
              const SizedBox(height: 3),
              Text(
                offer.description, 
                style: KmTextStyles.bodySmall
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DealerOffer {
  const _DealerOffer(
    this.icon, 
    this.title, 
    this.description, 
    this.color, 
    this.bg
  );
  
  final String icon;
  final String title;
  final String description;
  final Color color;
  final Color bg;
}