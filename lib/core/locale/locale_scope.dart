import 'package:flutter/material.dart';

class LocaleScope extends InheritedWidget {
  const LocaleScope({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(LocaleScope old) => locale != old.locale;
}
