import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ── Global plan state (простой синглтон без InheritedWidget) ──
class KmPlanState {
  KmPlanState._();
  static final KmPlanState instance = KmPlanState._();

  KmPlan activePlan = KmPlan.start;

  // Listeners для обновления виджетов
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() { for (final cb in _listeners) { cb(); } }

  void setplan(KmPlan plan) {
    activePlan = plan;
    _notify();
  }
}


// ============================================================
// KM DRIVE — Subscriptions Screen
// Три тарифа: START / PRO / ULTIMATE
// ============================================================

enum KmPlan { start, pro, ultimate }

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  KmPlan _activePlan = KmPlanState.instance.activePlan;
  bool _annual = false;

  void _onPlanTap(KmPlan plan) {
    if (plan == _activePlan) return;
    _showConfirm(plan);
  }

  void _showConfirm(KmPlan plan) {
    final l10n = AppLocalizations.of(context);
    final isUpgrade = plan.index > _activePlan.index;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: KmColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KmRadius.xl),
          side: const BorderSide(color: KmColors.border, width: 0.5),
        ),
        title: Text(
          _activePlan == KmPlan.start && plan != KmPlan.start
              ? l10n.get('subConfirmActivate')
              : isUpgrade
                  ? l10n.get('subConfirmChange')
                  : l10n.get('subConfirmDeactivate'),
          style: KmTextStyles.displaySmall,
          textAlign: TextAlign.center,
        ),
        content: Text(
          _planName(l10n, plan),
          style: KmTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(l10n.get('subCancelBtn'),
                style: const TextStyle(
                    color: KmColors.textMuted, fontFamily: 'DMSans')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: KmColors.accent,
                foregroundColor: KmColors.background),
            onPressed: () {
              setState(() {
                _activePlan = plan;
                KmPlanState.instance.setplan(plan);
              });
              Navigator.pop(context);
              final msg = plan == KmPlan.start
                  ? l10n.get('subDeactivatedMsg')
                  : _activePlan == plan
                      ? l10n.get('subActivatedMsg')
                      : l10n.get('subChangedMsg');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(msg, style: KmTextStyles.bodySmall),
                backgroundColor: KmColors.surface2,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Text(l10n.get('subConfirmBtn')),
          ),
        ],
      ),
    );
  }

  String _planName(AppLocalizations l10n, KmPlan p) {
    switch (p) {
      case KmPlan.start:    return l10n.get('subPlanStart');
      case KmPlan.pro:      return l10n.get('subPlanPro');
      case KmPlan.ultimate: return l10n.get('subPlanUltimate');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  title:    l10n.get('subscriptionsTitle'),
                  subtitle: l10n.get('subscriptionsSubtitle'),
                  showBack: true,
                  onBack:   () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // ── Billing toggle ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _BillingToggle(
                  annual: _annual,
                  onChanged: (v) => setState(() => _annual = v),
                  l10n: l10n,
                ),
              ),
            ),

            // ── Special offer banner ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _OfferBanner(l10n: l10n),
              ),
            ),

            // ── Plan cards ────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _PlanCard(
                    plan: KmPlan.start,
                    active: _activePlan == KmPlan.start,
                    annual: _annual,
                    l10n: l10n,
                    onTap: () => _onPlanTap(KmPlan.start),
                    featureKeys: const [
                      'sF1_1','sF1_2','sF1_3','sF1_4','sF1_5','sF1_6','sF1_7',
                    ],
                    color: KmColors.success,
                    badge: null,
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    plan: KmPlan.pro,
                    active: _activePlan == KmPlan.pro,
                    annual: _annual,
                    l10n: l10n,
                    onTap: () => _onPlanTap(KmPlan.pro),
                    featureKeys: const [
                      'sF2_1','sF2_2','sF2_3','sF2_4',
                      'sF2_5','sF2_6','sF2_7','sF2_8',
                    ],
                    color: KmColors.accent,
                    badge: 'POPULAR',
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    plan: KmPlan.ultimate,
                    active: _activePlan == KmPlan.ultimate,
                    annual: _annual,
                    l10n: l10n,
                    onTap: () => _onPlanTap(KmPlan.ultimate),
                    featureKeys: const [
                      'sF3_1','sF3_2','sF3_3','sF3_4',
                      'sF3_5','sF3_6','sF3_7','sF3_8','sF3_9',
                    ],
                    color: KmColors.info,
                    badge: 'PREMIUM',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Billing toggle ────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.annual,
    required this.onChanged,
    required this.l10n,
  });
  final bool annual;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Row(children: [
        Expanded(child: _ToggleBtn(
          label: l10n.get('subMonth'),
          active: !annual,
          onTap: () => onChanged(false),
        )),
        Expanded(child: _ToggleBtn(
          label: '${l10n.get('subYear')} –15%',
          active: annual,
          onTap: () => onChanged(true),
          highlight: true,
        )),
      ]),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.highlight = false,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? KmColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(KmRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active
                ? KmColors.background
                : highlight
                    ? KmColors.accent
                    : KmColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Offer banner ──────────────────────────────────────────────

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0x14C8A96E),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: KmColors.accentDim, width: 0.5),
      ),
      child: Row(children: [
        const Text('🎁', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.get('subUpgrade'),
                  style: KmTextStyles.labelLarge
                      .copyWith(color: KmColors.accent)),
              const SizedBox(height: 2),
              Text(l10n.get('subUpgradeHint'),
                  style: KmTextStyles.caption),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.active,
    required this.annual,
    required this.l10n,
    required this.onTap,
    required this.featureKeys,
    required this.color,
    required this.badge,
  });

  final KmPlan plan;
  final bool active;
  final bool annual;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final List<String> featureKeys;
  final Color color;
  final String? badge;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _expanded = false;

  String _name() {
    switch (widget.plan) {
      case KmPlan.start:    return widget.l10n.get('subPlanStart');
      case KmPlan.pro:      return widget.l10n.get('subPlanPro');
      case KmPlan.ultimate: return widget.l10n.get('subPlanUltimate');
    }
  }

  String _price() {
    final l = widget.l10n;
    switch (widget.plan) {
      case KmPlan.start:    return l.get('subPlanStartPrice');
      case KmPlan.pro:
        return widget.annual ? '33 912 ₸${l.get('subYear')}' : l.get('subPlanProPrice');
      case KmPlan.ultimate:
        return widget.annual ? '67 908 ₸${l.get('subYear')}' : l.get('subPlanUltimatePrice');
    }
  }

  String _desc() {
    switch (widget.plan) {
      case KmPlan.start:    return widget.l10n.get('subPlanStartDesc');
      case KmPlan.pro:      return widget.l10n.get('subPlanProDesc');
      case KmPlan.ultimate: return widget.l10n.get('subPlanUltimateDesc');
    }
  }

  String _icon() {
    switch (widget.plan) {
      case KmPlan.start:    return '🚗';
      case KmPlan.pro:      return '⚡';
      case KmPlan.ultimate: return '👑';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = widget.l10n;
    final active = widget.active;
    final color  = widget.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.07)
            : KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.xl),
        border: Border.all(
          color: active ? color : KmColors.border,
          width: active ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_icon(),
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(_name(),
                                style: KmTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (widget.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(widget.badge!,
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: color,
                                  )),
                            ),
                        ]),
                        Text(_price(),
                            style: KmTextStyles.numeralSmall
                                .copyWith(color: color, fontSize: 20)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(_desc(),
                    style: KmTextStyles.bodySmall),

                const SizedBox(height: 14),

                // ── Features (first 3 always visible) ────
                ...widget.featureKeys.take(3).map((k) =>
                    _FeatureRow(l10n.get(k), color)),

                // ── Expanded features ─────────────────────
                if (_expanded)
                  ...widget.featureKeys.skip(3).map((k) =>
                      _FeatureRow(l10n.get(k), color)),

                // ── Show more button ──────────────────────
                if (widget.featureKeys.length > 3) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expanded = !_expanded),
                    child: Row(children: [
                      Text(
                        _expanded
                            ? '▲  '
                            : '▼  ',
                        style: TextStyle(
                            color: color, fontSize: 10),
                      ),
                      Text(
                        _expanded
                            ? l10n.get('subAll')
                            : '+${widget.featureKeys.length - 3}',
                        style: KmTextStyles.caption
                            .copyWith(color: color),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),

          // ── Action button ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: active
                  ? OutlinedButton(
                      onPressed: widget.plan == KmPlan.start
                          ? null
                          : widget.onTap,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: widget.plan == KmPlan.start
                                ? KmColors.border
                                : color,
                            width: 0.5),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KmRadius.md)),
                      ),
                      child: Text(
                        widget.plan == KmPlan.start
                            ? l10n.get('subCurrent')
                            : l10n.get('subDeactivate'),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.plan == KmPlan.start
                              ? KmColors.textMuted
                              : color,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: KmColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(KmRadius.md)),
                      ),
                      child: Text(
                        l10n.get('subActivate'),
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: KmTextStyles.bodySmall.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}