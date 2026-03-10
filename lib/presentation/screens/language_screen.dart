import 'package:flutter/material.dart';
import '../../core/locale/locale_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Language Selection Screen
// ============================================================

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _locales = [
    (Locale('ru'), 'Русский'),
    (Locale('kk'), 'Қазақша'),
    (Locale('en'), 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = LocaleScope.of(context);
    final current = scope.locale;

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: l10n.get('settingsLanguage'),
                subtitle: l10n.get('selectLanguage'),
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: _locales.map((e) {
                    final (locale, label) = e;
                    final isSelected = current.languageCode == locale.languageCode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: isSelected
                            ? KmColors.overlayAccent
                            : KmColors.surface2,
                        borderRadius: BorderRadius.circular(KmRadius.lg),
                        child: InkWell(
                          onTap: () {
                            scope.onLocaleChanged(locale);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(KmRadius.lg),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: KmTextStyles.bodyLarge.copyWith(
                                      color: isSelected
                                          ? KmColors.accent
                                          : KmColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: KmColors.accent,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}