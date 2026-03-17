import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'settings_detail_screen.dart';
import 'dealer_screen.dart';
import 'warranty_screen.dart';

// ============================================================
// KM DRIVE — Profile Screen
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = MockVehicleRepository();
  VehicleModel? _vehicle;

  @override
  void initState() {
    super.initState();
    _repo.getVehicle().then((v) {
      if (mounted) setState(() => _vehicle = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    _ProfileHeader(vehicle: _vehicle),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _BrandSection()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(child: _SettingsMenu()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              sliver: SliverToBoxAdapter(child: _Footer()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.vehicle});
  final VehicleModel? vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: KmColors.cardGradient,
              shape: BoxShape.circle,
              border: Border.all(color: KmColors.accentDim, width: 0.5),
            ),
            child: const Center(
              child: Text('KM',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 22, fontWeight: FontWeight.w500,
                  color: KmColors.accent, letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.get('owner'),
              style: KmTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
          Text(
            vehicle != null
                ? '${vehicle!.model} · ${vehicle!.plateNumber}'
                : '...',
            style: KmTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KmBadge('Premium', color: KmColors.accent, bg: KmColors.overlayAccent),
              SizedBox(width: 8),
              KmBadge('KG-6', color: KmColors.info, bg: Color(0x1A5A8FE0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KmSectionLabel(l10n.get('aboutCompany')),
        KmAccentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: KmColors.accentDim, width: 0.5),
                    borderRadius: BorderRadius.circular(KmRadius.xs),
                  ),
                  child: Text(KmBrand.shortName.toUpperCase(),
                      style: KmTextStyles.labelMedium.copyWith(
                          color: KmColors.accent, letterSpacing: 3, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Text(l10n.get('headquarters'), style: KmTextStyles.caption),
              ]),
              const SizedBox(height: 12),
              Text(l10n.get('tagline'), style: KmTextStyles.bodyLarge),
              const SizedBox(height: 8),
              Text(l10n.get('vision'), style: KmTextStyles.bodySmall),
              const SizedBox(height: 14),
              const KmDivider(),
              const SizedBox(height: 14),
              Text(
                '${l10n.get('focusUntil')} ${KmBrand.strategyYear} ${l10n.get('year')}'.toUpperCase(),
                style: KmTextStyles.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.get('strategyTagline'), style: KmTextStyles.bodySmall),
              const SizedBox(height: 10),
              Text(
                '${l10n.get('platform')} ${KmBrand.platformName}'.toUpperCase(),
                style: KmTextStyles.labelSmall.copyWith(color: KmColors.accent),
              ),
              const SizedBox(height: 6),
              ...KmBrand.techDna.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      const Text('·',
                          style: TextStyle(color: KmColors.accentDim, fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.get(t), style: KmTextStyles.caption)),
                    ]),
                  )),
              const SizedBox(height: 12),
              const KmDivider(),
              const SizedBox(height: 12),
              Text(l10n.get('modelLineup').toUpperCase(),
                  style: KmTextStyles.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: KmBrand.modelLineup
                    .map((m) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: KmColors.surface3,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KmColors.border, width: 0.5),
                          ),
                          child: Text(m['name']!,
                              style: KmTextStyles.labelSmall.copyWith(
                                  color: KmColors.textSecondary, letterSpacing: 0.5)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  static const List<_MenuItem> _items = [
    _MenuItem('🔔', 'settingsNotifications', 'settingsNotificationsDesc', 'settingsNotificationsBody', 'notifications'),
    _MenuItem('🌍', 'settingsLanguage',      'settingsLanguageDesc',      'settingsLanguageBody',      'language'),
    _MenuItem('🔒', 'settingsSecurity',      'settingsSecurityDesc',      'settingsSecurityBody',      'security'),
    _MenuItem('📞', 'settingsDealer',        'settingsDealerDesc',        'settingsDealerBody',        'dealer'),
    _MenuItem('📄', 'settingsWarranty',      'settingsWarrantyDesc',      'settingsWarrantyBody',      'warranty'),
    _MenuItem('ℹ️', 'settingsAbout',         'appName',                   'settingsAboutBody',         'about'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KmSectionLabel(l10n.get('settings')),
        Container(
          decoration: BoxDecoration(
            color: KmColors.surface2,
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: KmColors.border, width: 0.5),
          ),
          child: Column(
            children: _items.asMap().entries.map((e) => Column(
                  children: [
                    _MenuRow(item: e.value),
                    if (e.key < _items.length - 1) const KmDivider(),
                  ],
                )).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final label = l10n.get(item.labelKey);
    final value = item.routeKey == 'about'
        ? '${l10n.get("appName")} ${KmBrand.appVersion}'
        : l10n.get(item.valueKey);
    final body  = item.bodyKey != null ? l10n.get(item.bodyKey!) : value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          switch (item.routeKey) {
            case 'notifications':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              break;
            case 'language':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()));
              break;
            // ✅ Дилерский центр — полноценная страница
            case 'dealer':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DealerScreen()));
              break;
            // ✅ Гарантия — полноценная страница с документом
            case 'warranty':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WarrantyScreen()));
              break;
            default:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsDetailScreen(
                  title: label, subtitle: value, body: body),
              ));
          }
        },
        borderRadius: BorderRadius.circular(KmRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Text(item.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: KmTextStyles.bodyMedium),
                  Text(value, style: KmTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KmColors.textMuted, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.labelKey, this.valueKey, this.bodyKey, this.routeKey);
  final String icon;
  final String labelKey;
  final String valueKey;
  final String? bodyKey;
  final String routeKey;
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(l10n.get('mission'),
            style: KmTextStyles.caption.copyWith(fontStyle: FontStyle.italic, height: 1.7),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          '${l10n.get('appName')} ${KmBrand.appVersion} · '
          '${KmBrand.buildYear}\n${l10n.get('headquarters')}',
          style: KmTextStyles.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}