import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — About Screen
// ============================================================

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: l10n.get('settingsAbout'),
                subtitle: l10n.get('aboutVersion'),
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverToBoxAdapter(
                child: _AboutContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── App card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: KmColors.cardGradient,
            borderRadius: BorderRadius.circular(KmRadius.xl),
            border: Border.all(color: KmColors.accentDim, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: KmColors.overlayAccent,
                    borderRadius: BorderRadius.circular(KmRadius.md),
                    border: Border.all(color: KmColors.accentDim, width: 0.5),
                  ),
                  child: const Center(
                    child: Text('KM',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: KmColors.accent, letterSpacing: 3,
                        )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.get('aboutTitle'),
                          style: KmTextStyles.displaySmall),
                      Text(l10n.get('aboutVersion'),
                          style: KmTextStyles.caption),
                      Text(l10n.get('aboutDeveloper'),
                          style: KmTextStyles.caption),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const KmDivider(),
              const SizedBox(height: 14),
              Text(l10n.get('aboutDesc'),
                  style: KmTextStyles.bodySmall.copyWith(height: 1.6)),
              const SizedBox(height: 12),
              Row(children: [
                _InfoChip(Icons.phone_android, l10n.get('aboutPlatforms')),
                const SizedBox(width: 8),
                _InfoChip(Icons.language, l10n.get('aboutLanguages')),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Feature sections ──────────────────────────────
        const _FeatureSection(
          icon: '🚗', titleKey: 'aboutSec1',
          featureKeys: ['aboutF1_1','aboutF1_2','aboutF1_3','aboutF1_4'],
        ),
        const _FeatureSection(
          icon: '📡', titleKey: 'aboutSec2',
          featureKeys: ['aboutF2_1','aboutF2_2','aboutF2_3','aboutF2_4'],
        ),
        const _FeatureSection(
          icon: '⚙️', titleKey: 'aboutSec3',
          featureKeys: ['aboutF3_1','aboutF3_2','aboutF3_3','aboutF3_4'],
        ),
        const _FeatureSection(
          icon: '🔧', titleKey: 'aboutSec4',
          featureKeys: ['aboutF4_1','aboutF4_2','aboutF4_3','aboutF4_4'],
        ),
        const _FeatureSection(
          icon: '🆘', titleKey: 'aboutSec5',
          featureKeys: ['aboutF5_1','aboutF5_2','aboutF5_3'],
        ),
        const _FeatureSection(
          icon: '🔗', titleKey: 'aboutSec6',
          featureKeys: ['aboutF6_1','aboutF6_2','aboutF6_3'],
        ),

        const SizedBox(height: 8),

        // ── Reviews ───────────────────────────────────────
        KmSectionLabel(l10n.get('aboutReviews')),
        const SizedBox(height: 8),
        const _ReviewCard(
          textKey: 'aboutReview1',
          authorKey: 'aboutReview1Author',
        ),
        const SizedBox(height: 10),
        const _ReviewCard(
          textKey: 'aboutReview2',
          authorKey: 'aboutReview2Author',
        ),

        const SizedBox(height: 24),

        // ── Support ───────────────────────────────────────
        KmSectionLabel(l10n.get('aboutSupport')),
        const SizedBox(height: 8),
        _SupportRow(Icons.phone_outlined,     l10n.get('aboutPhone')),
        const SizedBox(height: 8),
        _SupportRow(Icons.email_outlined,     l10n.get('aboutEmail')),
        const SizedBox(height: 8),
        _SupportRow(Icons.send_outlined,      l10n.get('aboutTelegram')),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KmColors.surface3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: KmColors.textMuted),
        const SizedBox(width: 5),
        Text(label,
            style: KmTextStyles.caption.copyWith(fontSize: 11)),
      ]),
    );
  }
}

class _FeatureSection extends StatefulWidget {
  const _FeatureSection({
    required this.icon,
    required this.titleKey,
    required this.featureKeys,
  });
  final String icon;
  final String titleKey;
  final List<String> featureKeys;

  @override
  State<_FeatureSection> createState() => _FeatureSectionState();
}

class _FeatureSectionState extends State<_FeatureSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _expanded ? const Color(0xFF141520) : KmColors.surface2,
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(
              color: _expanded ? KmColors.accentDim : KmColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(widget.icon,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.get(widget.titleKey),
                      style: KmTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: KmColors.textMuted, size: 18,
                ),
              ]),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const KmDivider(),
                const SizedBox(height: 10),
                ...widget.featureKeys.map((k) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: KmColors.success, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(l10n.get(k),
                                style: KmTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.textKey, required this.authorKey});
  final String textKey;
  final String authorKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.get(textKey),
              style: KmTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic, height: 1.6)),
          const SizedBox(height: 8),
          Text(l10n.get(authorKey),
              style: KmTextStyles.caption
                  .copyWith(color: KmColors.accent)),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value,
              style: KmTextStyles.caption),
          backgroundColor: KmColors.surface2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: KmColors.border, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, color: KmColors.accent, size: 18),
          const SizedBox(width: 12),
          Text(value, style: KmTextStyles.bodySmall
              .copyWith(color: KmColors.textPrimary)),
          const Spacer(),
          const Icon(Icons.copy_outlined,
              color: KmColors.textMuted, size: 14),
        ]),
      ),
    );
  }
}
