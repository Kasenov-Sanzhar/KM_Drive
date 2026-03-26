import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

// ============================================================
// KM DRIVE — Common UI Components
// ============================================================

class KmScreenHeader extends StatelessWidget {
  const KmScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            // ── Увеличенная кнопка «Назад» ────────────────────
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0x18C8A96E),
                        borderRadius: BorderRadius.circular(KmRadius.sm),
                        border: Border.all(
                          color: const Color(0x44C8A96E),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: KmColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context).get('back'),
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: KmColors.accent,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KmTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: KmTextStyles.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class KmSectionLabel extends StatelessWidget {
  const KmSectionLabel(this.text, {super.key, this.topPadding = 0});

  final String text;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 12),
      child: Text(text.toUpperCase(), style: KmTextStyles.labelMedium),
    );
  }
}

class KmAccentCard extends StatelessWidget {
  const KmAccentCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: KmColors.cardGradient,
        borderRadius: BorderRadius.circular(KmRadius.lg),
        border: Border.all(color: const Color(0x66C8A96E), width: 0.5),
      ),
      child: child,
    );
  }
}

class KmCard extends StatelessWidget {
  const KmCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.lg),
          border: Border.all(color: KmColors.border, width: 0.5),
        ),
        child: child,
      ),
    );
  }
}

class KmBadge extends StatelessWidget {
  const KmBadge(this.label, {super.key, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class KmProgressBar extends StatelessWidget {
  const KmProgressBar({
    super.key,
    required this.value,
    this.height = 3.0,
    this.backgroundColor = KmColors.surface3,
    this.color,
  });

  final double value;
  final double height;
  final Color backgroundColor;
  final Color? color;

  Color get _barColor {
    if (color != null) return color!;
    if (value >= 0.75) return KmColors.success;
    if (value >= 0.45) return KmColors.warning;
    return KmColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation(_barColor),
      ),
    );
  }
}

class KmQuickActionButton extends StatelessWidget {
  const KmQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final String icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDanger ? const Color(0x4DE05A5A) : KmColors.border;
    final bgColor     = isDanger ? const Color(0x0FE05A5A) : KmColors.surface2;
    final iconBg      = isDanger ? const Color(0x1FE05A5A) : const Color(0x1AC8A96E);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KmRadius.lg),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(KmRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(KmRadius.sm),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: KmTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDanger ? KmColors.error : KmColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: KmTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KmDivider extends StatelessWidget {
  const KmDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: KmColors.border, thickness: 0.5, height: 1);
  }
}

class KmMetricCell extends StatelessWidget {
  const KmMetricCell({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = KmColors.textPrimary,
    this.valueSize,
    this.labelSize,
  });

  final String value;
  final String label;
  final Color valueColor;
  /// Если null — берётся из темы (numeralSmall = 22)
  final double? valueSize;
  /// Если null — берётся из темы (labelSmall = 11)
  final double? labelSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: KmTextStyles.numeralSmall.copyWith(
                color: valueColor,
                fontSize: valueSize,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: KmTextStyles.labelSmall.copyWith(
                fontSize: labelSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
// ── Auth text field (login + register screens) ────────────────

class KmAuthTextField extends StatelessWidget {
  const KmAuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.error        = false,
    this.obscure      = false,
    this.keyboardType,
    this.onChanged,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool error;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? KmColors.error : KmColors.border;
    final iconColor   = error ? KmColors.error : KmColors.textMuted;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: KmTextStyles.caption
          .copyWith(color: error ? KmColors.error : KmColors.textSecondary)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: error
              ? KmColors.error.withValues(alpha: 0.06)
              : KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: borderColor, width: error ? 1.0 : 0.5),
        ),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, color: iconColor, size: 18)),
          Expanded(
            child: TextField(
              controller:          controller,
              obscureText:         obscure,
              keyboardType:        keyboardType,
              onChanged:           onChanged,
              textCapitalization:  textCapitalization,
              autofillHints:       const [],
              enableSuggestions:   false,
              autocorrect:         false,
              style: KmTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText:       hint,
                hintStyle:      KmTextStyles.caption,
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
                padding: const EdgeInsets.only(right: 12), child: suffix!),
        ]),
      ),
    ]);
  }
}