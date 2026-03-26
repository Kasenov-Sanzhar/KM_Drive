import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';
import 'app_shell.dart';

// ============================================================
// KM DRIVE — Login Screen
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _loading         = false;
  bool _hasError        = false;
  String _errorMsg      = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _hasError = false; _errorMsg = ''; });
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() { _hasError = true; _errorMsg = _l10n!.get('authFillAll'); });
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.instance.signIn(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      setState(() {
        _hasError = true;
        _errorMsg = _errorText(result.error);
      });
    }
  }

  String _errorText(AuthError? e) {
    switch (e) {
      case AuthError.invalidCredentials:
      case AuthError.wrongPassword:
        return _l10n!.get('authWrongCredentials');
      case AuthError.networkError:
        return _l10n!.get('authNetworkError');
      default:
        return _l10n!.get('authUnknownError');
    }
  }

  AppLocalizations? _l10n;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _l10n = l10n;

    return Scaffold(
      backgroundColor: KmColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Логотип ──────────────────────────────────
                const Center(
                  child: Column(children: [
                    Text('KM', style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 56, fontWeight: FontWeight.w300,
                      color: KmColors.accent, letterSpacing: 10, height: 1)),
                    Text('DRIVE', style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: KmColors.textMuted, letterSpacing: 6)),
                  ]),
                ),

                const SizedBox(height: 40),

                Text(l10n.get('authSignIn'),
                    style: KmTextStyles.displaySmall),
                const SizedBox(height: 4),
                Text(l10n.get('authSignInSubtitle'),
                    style: KmTextStyles.bodySmall),

                const SizedBox(height: 32),

                // ── Email ────────────────────────────────────
                KmAuthTextField(
                  controller: _emailCtrl,
                  label:       l10n.get('authEmail'),
                  hint:        l10n.get('authEmailHint'),
                  icon:        Icons.email_outlined,
                  error:       _hasError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged:   (_) => setState(() => _hasError = false),
                ),

                const SizedBox(height: 12),

                // ── Пароль ───────────────────────────────────
                KmAuthTextField(
                  controller:  _passwordCtrl,
                  label:       l10n.get('authPassword'),
                  hint:        l10n.get('authPasswordHint'),
                  icon:        Icons.lock_outline_rounded,
                  error:       _hasError,
                  obscure:     _obscurePassword,
                  onChanged:   (_) => setState(() => _hasError = false),
                  suffix: GestureDetector(
                    onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: KmColors.textMuted, size: 20),
                  ),
                ),

                // ── Ошибка ───────────────────────────────────
                if (_hasError && _errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: KmColors.error, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_errorMsg,
                        style: KmTextStyles.caption
                            .copyWith(color: KmColors.error))),
                  ]),
                ],

                const SizedBox(height: 28),

                // ── Кнопка входа ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
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
                        : Text(l10n.get('authSignInBtn'),
                            style: const TextStyle(fontFamily: 'DMSans',
                                fontSize: 14, fontWeight: FontWeight.w600,
                                letterSpacing: 1.4)),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Разделитель ──────────────────────────────
                Row(children: [
                  const Expanded(child: Divider(
                      color: KmColors.border, thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(l10n.get('authOr'),
                        style: KmTextStyles.caption)),
                  const Expanded(child: Divider(
                      color: KmColors.border, thickness: 0.5)),
                ]),

                const SizedBox(height: 20),

                // ── Кнопка регистрации ───────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: KmColors.accent, width: 0.8),
                      foregroundColor: KmColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KmRadius.md)),
                    ),
                    child: Text(l10n.get('authRegisterBtn'),
                        style: const TextStyle(fontFamily: 'DMSans',
                            fontSize: 14, fontWeight: FontWeight.w500,
                            letterSpacing: 1.2, color: KmColors.accent)),
                  ),
                ),

                const SizedBox(height: 32),

                const Center(child: Text(
                  'KM Motors · Алматы, Казахстан',
                  style: KmTextStyles.caption)),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}