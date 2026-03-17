import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Subscriptions Screen (локализована)
// ============================================================

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _repo = MockVehicleRepository();
  List<SubscriptionModel> _subscriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subs = await _repo.getSubscriptions();
    if (mounted) {
      setState(() {
        _subscriptions = subs;
        _loading = false;
      });
    }
  }

  Future<void> _toggleSubscription(int index, bool value) async {
    setState(() {
      _subscriptions[index] =
          _subscriptions[index].copyWith(isActive: value);
    });
    await _repo.toggleSubscription(_subscriptions[index].id, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: KmColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: KmColors.accent, strokeWidth: 1.5),
        ),
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
                  title:    l10n.get('subscriptionsTitle'),
                  subtitle: l10n.get('subscriptionsSubtitle'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                  child: _InfoBanner(l10n: l10n)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SubscriptionCard(
                      subscription: _subscriptions[i],
                      l10n: l10n,
                      onToggle: (v) => _toggleSubscription(i, v),
                    ),
                  ),
                  childCount: _subscriptions.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0F5A8FE0),
        borderRadius: BorderRadius.circular(KmRadius.md),
        border: Border.all(color: const Color(0x335A8FE0), width: 0.5),
      ),
      child: Row(children: [
        const Text('ℹ️', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(l10n.get('subsInfoBanner'),
              style: KmTextStyles.caption),
        ),
      ]),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.l10n,
    required this.onToggle,
  });

  final SubscriptionModel subscription;
  final AppLocalizations l10n;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isActive ? KmColors.cardGradient : null,
        color: isActive ? null : KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(
          color: isActive ? const Color(0x738A7048) : KmColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subscription.icon != null) ...[
                Text(subscription.icon!,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.get(subscription.name),
                        style: KmTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w500)),
                    Text(
                      KmFormatters.tenge(subscription.priceKzt,
                          perMonth: true),
                      style: KmTextStyles.numeralSmall
                          .copyWith(color: KmColors.accent, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Switch(value: isActive, onChanged: onToggle),
            ],
          ),

          const SizedBox(height: 10),

          ...subscription.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Container(
                    width: 4, height: 4,
                    margin:
                        const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? KmColors.accent
                          : KmColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                      child: Text(l10n.get(f), style: KmTextStyles.caption)),
                ]),
              )),

          const SizedBox(height: 10),

          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? KmColors.success
                    : KmColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isActive
                  ? subscription.activeUntil != null
                      ? '${l10n.get('subsActiveTill')} '
                        '${KmFormatters.dateShort(subscription.activeUntil!)}'
                      : l10n.get('activeSubscription')
                  : l10n.get('inactiveSubscription'),
              style: KmTextStyles.caption.copyWith(
                color: isActive
                    ? KmColors.success
                    : KmColors.textMuted,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}