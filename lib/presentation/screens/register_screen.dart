import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'app_shell.dart';

// ============================================================
// KM DRIVE — Register Screen
// ============================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _vinCtrl      = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;

  // Field errors
  String? _emailError;
  String? _vinError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  // VIN state
  bool _vinLoading = false;
  bool _vinValid   = false;
  Map<String, dynamic>? _carData;
  Timer? _vinDebounce;

  // Password rules
  List<PasswordRule> _rules = [];

  AppLocalizations? _l10n;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _vinCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _vinDebounce?.cancel();
    super.dispose();
  }

  // ── VIN debounce check ────────────────────────────────────

  void _onVinChanged(String val) {
    _vinDebounce?.cancel();
    setState(() { _vinValid = false; _carData = null; _vinError = null; });
    if (val.trim().length < 5) return;

    _vinDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _vinLoading = true);
      final result = await AuthService.instance.checkVin(val.trim());
      if (!mounted) return;
      setState(() {
        _vinLoading = false;
        if (result.valid) {
          _vinValid  = true;
          _carData   = result.carData;
          _vinError  = null;
        } else {
          _vinValid  = false;
          _carData   = null;
          _vinError  = _vinErrorText(result.error);
        }
      });
    });
  }

  String _vinErrorText(String? code) {
    switch (code) {
      case 'not_found':     return _l10n!.get('authVinNotFound');
      case 'already_taken': return _l10n!.get('authVinTaken');
      case 'network':       return _l10n!.get('authNetworkError');
      default:              return _l10n!.get('authVinInvalid');
    }
  }

  // ── Password rules update ─────────────────────────────────

  void _onPasswordChanged(String val) {
    setState(() {
      _rules         = PasswordValidator.validate(val);
      _passwordError = null;
      _confirmError  = null;
    });
  }

  // ── Validate & Register ───────────────────────────────────

  Future<void> _register() async {
    final l10n = _l10n!;
    setState(() {
      _emailError   = null;
      _vinError     = null;
      _passwordError = null;
      _confirmError  = null;
      _generalError  = null;
    });

    bool valid = true;

    // Email
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _emailError = l10n.get('authFillAll'); valid = false;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(email)) {
      _emailError = l10n.get('authEmailInvalid'); valid = false;
    }

    // VIN
    if (_vinCtrl.text.trim().isEmpty) {
      _vinError = l10n.get('authFillAll'); valid = false;
    } else if (!_vinValid) {
      _vinError = _vinError ?? l10n.get('authVinNotFound'); valid = false;
    }

    // Password
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _passwordError = l10n.get('authFillAll'); valid = false;
    } else if (!PasswordValidator.isValid(pass)) {
      _passwordError = l10n.get('authPasswordWeak'); valid = false;
    }

    // Confirm
    if (_confirmCtrl.text != pass) {
      _confirmError = l10n.get('authPasswordMismatch'); valid = false;
    }

    if (!valid) { setState(() {}); return; }

    setState(() => _loading = true);
    final result = await AuthService.instance.register(
      email:    email,
      password: pass,
      vin:      _vinCtrl.text.trim().toUpperCase(),
      carData:  _carData ?? {},
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false);
    } else {
      setState(() {
        _generalError = _errorText(result.error);
        if (result.error == AuthError.emailAlreadyInUse) {
          _emailError = l10n.get('authEmailTaken');
        }
      });
    }
  }

  String _errorText(AuthError? e) {
    switch (e) {
      case AuthError.emailAlreadyInUse: return _l10n!.get('authEmailTaken');
      case AuthError.networkError:      return _l10n!.get('authNetworkError');
      default:                          return _l10n!.get('authUnknownError');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _l10n = l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: Column(children: [
          // Back header
          KmScreenHeader(
            title:    l10n.get('authRegister'),
            subtitle: l10n.get('authRegisterSubtitle'),
            showBack: true,
            onBack:   () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Email ──────────────────────────────────
                  KmAuthTextField(
                    controller:  _emailCtrl,
                    label:       l10n.get('authEmail'),
                    hint:        l10n.get('authEmailHint'),
                    icon:        Icons.email_outlined,
                    error:       _emailError != null,
                    keyboardType: TextInputType.emailAddress,
                    onChanged:   (_) => setState(() => _emailError = null),
                  ),
                  if (_emailError != null) _ErrorText(_emailError!),

                  const SizedBox(height: 14),

                  // ── VIN ────────────────────────────────────
                  _VinField(
                    controller: _vinCtrl,
                    l10n:       l10n,
                    loading:    _vinLoading,
                    valid:      _vinValid,
                    error:      _vinError,
                    carData:    _carData,
                    onChanged:  _onVinChanged,
                  ),

                  const SizedBox(height: 14),

                  // ── Пароль ─────────────────────────────────
                  KmAuthTextField(
                    controller: _passwordCtrl,
                    label:      l10n.get('authPassword'),
                    hint:       l10n.get('authPasswordHint'),
                    icon:       Icons.lock_outline_rounded,
                    error:      _passwordError != null,
                    obscure:    _obscurePass,
                    onChanged:  _onPasswordChanged,
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      child: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: KmColors.textMuted, size: 20)),
                  ),
                  if (_passwordError != null) _ErrorText(_passwordError!),

                  // ── Password rules ─────────────────────────
                  if (_passwordCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _PasswordRules(rules: _rules, lang: lang),
                  ],

                  const SizedBox(height: 14),

                  // ── Подтверждение пароля ───────────────────
                  KmAuthTextField(
                    controller: _confirmCtrl,
                    label:      l10n.get('authConfirmPassword'),
                    hint:       l10n.get('authPasswordHint'),
                    icon:       Icons.lock_outline_rounded,
                    error:      _confirmError != null,
                    obscure:    _obscureConfirm,
                    onChanged:  (_) => setState(() => _confirmError = null),
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: KmColors.textMuted, size: 20)),
                  ),
                  if (_confirmError != null) _ErrorText(_confirmError!),

                  // ── General error ──────────────────────────
                  if (_generalError != null) ...[
                    const SizedBox(height: 8),
                    _ErrorText(_generalError!),
                  ],

                  const SizedBox(height: 28),

                  // ── Кнопка ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KmColors.accent,
                        foregroundColor: KmColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KmRadius.md)),
                        disabledBackgroundColor:
                            KmColors.accent.withValues(alpha: 0.5),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: KmColors.background))
                          : Text(l10n.get('authCreateAccount'),
                              style: const TextStyle(
                                  fontFamily: 'DMSans', fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── VIN field with validation state ──────────────────────────

class _VinField extends StatelessWidget {
  const _VinField({
    required this.controller,
    required this.l10n,
    required this.loading,
    required this.valid,
    required this.error,
    required this.carData,
    required this.onChanged,
  });

  final TextEditingController controller;
  final AppLocalizations l10n;
  final bool loading;
  final bool valid;
  final String? error;
  final Map<String, dynamic>? carData;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError  = error != null;
    final borderColor = hasError ? KmColors.error
        : valid ? KmColors.success : KmColors.border;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.get('authVin'),
          style: KmTextStyles.caption.copyWith(
              color: hasError ? KmColors.error
                  : valid ? KmColors.success
                  : KmColors.textSecondary)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: hasError
              ? KmColors.error.withValues(alpha: 0.06)
              : valid
                  ? KmColors.success.withValues(alpha: 0.04)
                  : KmColors.surface2,
          borderRadius: BorderRadius.circular(KmRadius.md),
          border: Border.all(color: borderColor,
              width: (hasError || valid) ? 1.0 : 0.5),
        ),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(Icons.directions_car_outlined,
                color: hasError ? KmColors.error
                    : valid ? KmColors.success : KmColors.textMuted,
                size: 18)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged:  onChanged,
              autofillHints: const [],
              style:      KmTextStyles.bodyMedium,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText:       l10n.get('authVinHint'),
                hintStyle:      KmTextStyles.caption,
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(right: 12),
            child: loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: KmColors.accent))
              : valid
                  ? const Icon(Icons.check_circle_rounded,
                      color: KmColors.success, size: 18)
                  : hasError
                      ? const Icon(Icons.cancel_rounded,
                          color: KmColors.error, size: 18)
                      : const SizedBox.shrink()),
        ]),
      ),
      if (hasError) _ErrorText(error!),
      // Show car data when VIN is valid
      if (valid && carData != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KmColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(KmRadius.sm),
            border: Border.all(
                color: KmColors.success.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: KmColors.success, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${carData!['model'] ?? ''} ${carData!['year'] ?? ''} · '
              '${carData!['color'] ?? ''}',
              style: KmTextStyles.bodySmall
                  .copyWith(color: KmColors.success),
            )),
          ]),
        ),
      ],
    ]);
  }
}

// ── Password rules widget ─────────────────────────────────────

class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.rules, required this.lang});
  final List<PasswordRule> rules;
  final String lang;

  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_constructors
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KmColors.surface2,
        borderRadius: BorderRadius.circular(KmRadius.sm),
        border: Border.all(color: KmColors.border, width: 0.5),
      ),
      child: Column(
        children: rules.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Icon(
              r.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: r.passed ? KmColors.success : KmColors.error,
              size: 14),
            const SizedBox(width: 8),
            Text(r.getLabel(lang),
                style: KmTextStyles.caption.copyWith(
                    color: r.passed ? KmColors.success : KmColors.error)),
          ]),
        )).toList(),
      ),
    );
  }
}

// ── Error text ────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: KmColors.error, size: 13),
        const SizedBox(width: 5),
        Expanded(child: Text(text,
            style: KmTextStyles.caption
                .copyWith(color: KmColors.error))),
      ]),
    );
  }
}