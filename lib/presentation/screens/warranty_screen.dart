import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';

// ============================================================
// KM DRIVE — Warranty Screen
// Гарантийный талон KM Jaqin | Kassenov Motors
// ============================================================

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: AppLocalizations.of(context).get('warrantyTitle'),
                subtitle: AppLocalizations.of(context).get('warrantySubtitle'),
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverToBoxAdapter(
                child: _WarrantyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarrantyContent extends StatelessWidget {
  const _WarrantyContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Шапка документа ──────────────────────────────
        _DocHeader(),
        const SizedBox(height: 24),

        // ── 1. Общие положения ────────────────────────────
        _Section(
          number: '1',
          title: l10n.get('wSec1'),
          child: _BodyText(
            l10n.get('wBody1'),
          ),
        ),

        // ── 2. Сроки гарантии ─────────────────────────────
        _Section(
          number: '2',
          title: l10n.get('wSec2'),
          child: _WarrantyTable(
            headers: [l10n.get('wTblType'), l10n.get('wTblTerm'), l10n.get('wTblMileage')],
            rows: [
              [l10n.get('wRow1_1'), l10n.get('wRow1_2'), '150 000 ${l10n.get('km')}'],
              [l10n.get('wRow2_1'), l10n.get('wRow2_2'), l10n.get('wRowUnlim')],
              [l10n.get('wRow3_1'), l10n.get('wRow3_2'), l10n.get('wRowUnlim')],
              [l10n.get('wRow4_1'), l10n.get('wRow4_2'), '120 000 ${l10n.get('km')}'],
            ],
          ),
        ),

        // ── 3. Что покрывает ──────────────────────────────
        _Section(
          number: '3',
          title: l10n.get('wSec3'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                l10n.get('wBody3'),
              ),
              const SizedBox(height: 12),
              _CoverageTable(
                rows: [
                  ['⚙️', l10n.get('wCov1a'), l10n.get('wCov1b')],
                  ['🔄', l10n.get('wCov2a'), l10n.get('wCov2b')],
                  ['❄️', l10n.get('wCov3a'), l10n.get('wCov3b')],
                  ['⚡', l10n.get('wCov4a'), l10n.get('wCov4b')],
                  ['🚗', l10n.get('wCov5a'), l10n.get('wCov5b')],
                  ['🛑', l10n.get('wCov6a'), l10n.get('wCov6b')],
                  ['💨', l10n.get('wCov7a'), l10n.get('wCov7b')],
                  ['🛡️', l10n.get('wCov8a'), l10n.get('wCov8b')],
                  ['🔋', l10n.get('wCov9a'), l10n.get('wCov9b')],
                ],
              ),
            ],
          ),
        ),

        // ── 4. Что не покрывает ───────────────────────────
        _Section(
          number: '4',
          title: l10n.get('wSec4'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubTitle(l10n.get('wSub41')),
              const SizedBox(height: 8),
              ...['wExcl1','wExcl2','wExcl3','wExcl4','wExcl5','wExcl6','wExcl7','wExcl8']
                  .map((k) => _BulletItem(l10n.get(k))),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub42')),
              const SizedBox(height: 8),
              ...['wExcl9','wExcl10','wExcl11','wExcl12','wExcl13','wExcl14','wExcl15']
                  .map((k) => _BulletItem(l10n.get(k))),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub43')),
              const SizedBox(height: 8),
              ...['wAdj1','wAdj2','wAdj3','wAdj4','wAdj5']
                  .map((k) => _BulletItem(l10n.get(k))),
            ],
          ),
        ),

        // ── 5. Условия сохранения ─────────────────────────
        _Section(
          number: '5',
          title: l10n.get('wSec5'),
          child: Column(
            children: [
              ...['wCond1','wCond2','wCond3','wCond4','wCond5','wCond6']
                  .map((k) => _CheckItem(l10n.get(k))),
              const SizedBox(height: 10),
              _WarningBox(l10n.get('wBody5Note')),
            ],
          ),
        ),

        // ── 6. Порядок обслуживания ───────────────────────
        _Section(
          number: '6',
          title: l10n.get('wSec6'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubTitle(l10n.get('wSub61')),
              const SizedBox(height: 8),
              ...[('wProc1', 1), ('wProc2', 2), ('wProc3', 3)]
                  .map((e) => _NumberedItem(l10n.get(e.$1), e.$2)),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub62')),
              const SizedBox(height: 8),
              _TimelineItem(l10n.get('wTime1'), l10n.get('wTime1Val')),
              _TimelineItem(l10n.get('wTime2'), l10n.get('wTime2Val')),
              _TimelineItem(l10n.get('wTime3'), l10n.get('wTime3Val')),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub63')),
              const SizedBox(height: 8),
              _TimelineItem(l10n.get('wTime4'), l10n.get('wTime4Val')),
              _TimelineItem(l10n.get('wTime5'), l10n.get('wTime5Val')),
              const SizedBox(height: 12),
              _InfoBox(l10n.get('wBodyLoaner')),
            ],
          ),
        ),

        // ── 7. Передача гарантии ──────────────────────────
        _Section(
          number: '7',
          title: l10n.get('wSec7'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                l10n.get('wBody7Intro'),
              ),
              const SizedBox(height: 8),
              ...['wTransf1','wTransf2','wTransf3']
                  .map((k) => _BulletItem(l10n.get(k))),
            ],
          ),
        ),

        // ── 8. Особые условия KM Jaqin ────────────────────
        _Section(
          number: '8',
          title: l10n.get('wSec8'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubTitle(l10n.get('wSub81')),
              const SizedBox(height: 8),
              ...['wSpec1','wSpec2','wSpec3']
                  .map((k) => _BulletItem(l10n.get(k))),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub82')),
              const SizedBox(height: 8),
              ...['wSpec4','wSpec5']
                  .map((k) => _BulletItem(l10n.get(k))),
              const SizedBox(height: 12),
              _SubTitle(l10n.get('wSub83')),
              const SizedBox(height: 8),
              ...['wSpec6','wSpec7']
                  .map((k) => _BulletItem(l10n.get(k))),
            ],
          ),
        ),

        // ── 9. Поддержка на дороге ────────────────────────
        _Section(
          number: '9',
          title: l10n.get('wSec9'),
          child: Column(
            children: [
              _ContactRow('📞', l10n.get('wRoad1Label'), '+7 (727) 333-44-55'),
              const SizedBox(height: 8),
              _ContactRow('📱', l10n.get('wRoad2Label'), l10n.get('wRoad2Val')),
              const SizedBox(height: 8),
              _ContactRow('🆘', l10n.get('wRoad3Label'), l10n.get('wRoad3Val')),
            ],
          ),
        ),

        // ── 10. Расширенная гарантия ──────────────────────
        _Section(
          number: '11',
          title: l10n.get('wSec10'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                  l10n.get('wBody10')),
              const SizedBox(height: 12),
              _WarrantyTable(
                headers: [l10n.get('wTblPackage'), l10n.get('wTblTerm'), l10n.get('wTblMileage')],
                rows: [
                  ['Standard', l10n.get('wExt2yr'), '+50 000 ${l10n.get('km')}'],
                  ['Premium', l10n.get('wExt3yr'), '+100 000 ${l10n.get('km')}'],
                  ['Full', l10n.get('wExt5yr'), '+150 000 ${l10n.get('km')}'],
                ],
              ),
              const SizedBox(height: 10),
              _BodyText(
                  l10n.get('wBody10Note')),
            ],
          ),
        ),

        // ── 12. Контакты ──────────────────────────────────
        _Section(
          number: '12',
          title: l10n.get('wSec11'),
          child: Column(
            children: [
              _ContactRow('☎️', l10n.get('wContact1'), '+7 (727) 123-45-67'),
              const SizedBox(height: 8),
              _ContactRow('✉️', l10n.get('wContact2'), 'warranty@km.kz'),
              const SizedBox(height: 8),
              _ContactRow('💻', l10n.get('wContact3'), 'drive@km.kz'),
              const SizedBox(height: 8),
              _ContactRow('🆘', l10n.get('wContact4'), '+7 (727) 333-44-55'),
              const SizedBox(height: 8),
              _ContactRow('📍', l10n.get('wContact5'),
                  l10n.get('wHQ')),
            ],
          ),
        ),

        // ── Подвал документа ─────────────────────────────
        const SizedBox(height: 8),
        const _DocFooter(),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Компоненты
// ════════════════════════════════════════════════════════════

class _DocHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: KmColors.cardGradient,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.accentDim, width: 0.5),
      ),
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
              child: const Text('KM',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KmColors.accent,
                    letterSpacing: 3,
                  )),
            ),
            const SizedBox(width: 10),
            const Text('KASSENOV MOTORS',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 9,
                  letterSpacing: 2,
                  color: KmColors.textMuted,
                )),
          ]),
          const SizedBox(height: 14),
          Text(l10n.get('wDocTitle'),
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: KmColors.textPrimary,
                letterSpacing: 1,
              )),
          const SizedBox(height: 2),
          const Text('KM JAQIN',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                letterSpacing: 3,
                color: KmColors.accent,
              )),
          const SizedBox(height: 14),
          const KmDivider(),
          const SizedBox(height: 12),
          Row(children: [
            const _HeaderCell('VIN', 'KMXJQ200L2400523'),
            const SizedBox(width: 20),
            _HeaderCell(l10n.get('wDocNum'), 'A523KM'),
            const SizedBox(width: 20),
            _HeaderCell(l10n.get('wDocYear'), '2024'),
          ]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 8,
              letterSpacing: 1.5,
              color: KmColors.textMuted,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KmColors.accent,
            )),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: KmColors.overlayAccent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: KmColors.accentDim, width: 0.5),
              ),
              child: Center(
                child: Text(number,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: KmColors.accent,
                    )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: KmColors.textPrimary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
        const KmDivider(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: KmTextStyles.bodySmall.copyWith(
          color: KmColors.textSecondary,
          height: 1.65,
        ));
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: KmColors.textPrimary,
          letterSpacing: 0.3,
        ));
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 4, height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: KmColors.accentDim,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _NumberedItem extends StatelessWidget {
  const _NumberedItem(this.text, this.number);
  final String text;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18, height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: KmColors.accentDim, width: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$number',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      color: KmColors.accent,
                    )),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: KmColors.success, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: KmTextStyles.bodySmall
                    .copyWith(color: KmColors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: KmColors.surface3,
              borderRadius: BorderRadius.circular(KmRadius.xs),
              border: Border.all(color: KmColors.border, width: 0.5),
            ),
            child: Text(value,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KmColors.accent,
                )),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.icon, this.label, this.value);
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: KmTextStyles.caption
                        .copyWith(color: KmColors.textMuted)),
                const SizedBox(height: 1),
                Text(value,
                    style: KmTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyTable extends StatelessWidget {
  const _WarrantyTable({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: KmColors.surface3,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(KmRadius.md),
                topRight: Radius.circular(KmRadius.md),
              ),
            ),
            child: Row(
              children: headers.asMap().entries.map((e) => Expanded(
                flex: e.key == 0 ? 3 : 2,
                child: Text(e.value.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: KmColors.textMuted,
                    )),
              )).toList(),
            ),
          ),
          // Строки
          ...rows.asMap().entries.map((rowEntry) {
            final i = rowEntry.key;
            final row = rowEntry.value;
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                      height: 0,
                      thickness: 0.5,
                      color: KmColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: row.asMap().entries.map((e) => Expanded(
                      flex: e.key == 0 ? 3 : 2,
                      child: Text(e.value,
                          style: KmTextStyles.bodySmall.copyWith(
                            color: e.key == 2
                                ? KmColors.accent
                                : KmColors.textPrimary,
                            fontWeight: e.key == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    )).toList(),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CoverageTable extends StatelessWidget {
  const _CoverageTable({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(
                    height: 0, thickness: 0.5, color: KmColors.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(row[0], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row[1],
                              style: KmTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500)),
                          Text(row[2],
                              style: KmTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_rounded,
                        color: KmColors.success, size: 14),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0F5A8FE0),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: const Color(0x335A8FE0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.caption.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14C8A96E),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.accentDim, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: KmTextStyles.caption
                    .copyWith(color: KmColors.warning, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _DocFooter extends StatelessWidget {
  const _DocFooter();
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(l10n.get('wSignOff'),
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: KmColors.textMuted,
              )),
          const SizedBox(height: 4),
          Text(l10n.get('wSignTeam'),
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: KmColors.accent,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 8),
          const Text(
            'KM Jaqin — ваша уверенность на дорогах на долгие годы.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: KmColors.textMuted,
              letterSpacing: 0.3,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}