import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ============================================================
// KM DRIVE — Settings Detail Screen
// Экран с информацией по пункту меню настроек (язык, безопасность и т.д.)
// ============================================================

class SettingsDetailScreen extends StatelessWidget {
  const SettingsDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: KmScreenHeader(
                title: title,
                subtitle: subtitle,
                showBack: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverToBoxAdapter(
                child: Text(
                  body,
                  style: KmTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                    color: KmColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
