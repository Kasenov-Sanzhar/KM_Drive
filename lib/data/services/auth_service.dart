import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// KM DRIVE — AuthService
// Email/password auth + VIN validation
// ============================================================

enum AuthError {
  invalidCredentials,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidVin,
  networkError,
  unknown,
}

class VinCheckResult {
  const VinCheckResult({
    required this.valid,
    this.carData,
    this.error,
  });
  final bool valid;
  final Map<String, dynamic>? carData;
  final String? error;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static const _sessionKey = 'km_auth_session';

  User? get currentUser => _auth.currentUser;
  bool  get isLoggedIn  =>
      _auth.currentUser != null && !(_auth.currentUser!.isAnonymous);
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Вход ──────────────────────────────────────────────────

  Future<({bool success, AuthError? error})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      await _saveSession(email.trim());
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapError(e.code));
    } catch (_) {
      return (success: false, error: AuthError.networkError);
    }
  }

  // ── Регистрация ────────────────────────────────────────────

  Future<({bool success, AuthError? error})> register({
    required String email,
    required String password,
    required String vin,
    required Map<String, dynamic> carData,
  }) async {
    try {
      // If anonymous session exists — link it to email/password credential
      // This preserves the anonymous uid and avoids creating a new document
      UserCredential cred;
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        final credential = EmailAuthProvider.credential(
            email: email.trim(), password: password);
        cred = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
      }

      final uid = cred.user!.uid;

      // Привязываем VIN к пользователю в Firestore
      await _firestore.collection('users').doc(uid).set({
        'email':     email.trim(),
        'vin':       vin.toUpperCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Копируем данные машины в профиль пользователя
      final vehicleDoc = {
        ...carData,
        'vin':          vin.toUpperCase(),
        'owner':        uid,
        'fuelPercent':  72.0,
        'batteryVolts': 12.8,
        'engineTempC':  91.0,
        'oilLevelPercent': 75.0,
        'healthScore':  87,
        'lastSyncAt':   FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('vehicle')
          .doc('current')
          .set(vehicleDoc);

      // Помечаем VIN как занятый
      await _firestore
          .collection('cars')
          .doc(vin.toUpperCase())
          .update({'owner': uid});

      await _saveSession(email.trim());
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      return (success: false, error: _mapError(e.code));
    } catch (_) {
      return (success: false, error: AuthError.networkError);
    }
  }

  // ── Выход ──────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearSession();
  }

  // ── Проверка VIN ───────────────────────────────────────────

  Future<VinCheckResult> checkVin(String vin) async {
    if (vin.trim().length < 5) {
      return const VinCheckResult(valid: false, error: 'too_short');
    }
    try {
      // Public read — no auth required for cars collection
      final doc = await _firestore
          .collection('cars')
          .doc(vin.trim().toUpperCase())
          .get();

      if (!doc.exists) {
        return const VinCheckResult(valid: false, error: 'not_found');
      }

      final data = doc.data()!;

      // Проверяем не занят ли VIN другим пользователем
      final owner = data['owner'];
      if (owner != null && owner.toString().isNotEmpty) {
        return const VinCheckResult(valid: false, error: 'already_taken');
      }

      return VinCheckResult(valid: true, carData: data);
    } catch (e) {
      // ignore: avoid_print
      print('[AuthService] checkVin error: \$e');
      return const VinCheckResult(valid: false, error: 'network');
    }
  }

  // ── Session persistence ─────────────────────────────────────

  Future<bool> get hasSession async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  Future<void> _saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setString('km_auth_email', email);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove('km_auth_email');
  }

  // ── Error mapping ───────────────────────────────────────────

  AuthError _mapError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
      case 'invalid-credential':
        return AuthError.invalidCredentials;
      case 'wrong-password':
        return AuthError.wrongPassword;
      case 'email-already-in-use':
        return AuthError.emailAlreadyInUse;
      case 'weak-password':
        return AuthError.weakPassword;
      default:
        return AuthError.unknown;
    }
  }
}

// ── Password validation ────────────────────────────────────────

class PasswordValidator {
  static List<PasswordRule> validate(String password) => [
    PasswordRule(
      label:   'Не менее 8 символов',
      labelKk: 'Кемінде 8 таңба',
      labelEn: 'At least 8 characters',
      passed:  password.length >= 8,
    ),
    PasswordRule(
      label:   'Заглавная буква (A–Z)',
      labelKk: 'Бас әріп (A–Z)',
      labelEn: 'Uppercase letter (A–Z)',
      passed:  password.contains(RegExp(r'[A-Z]')),
    ),
    PasswordRule(
      label:   'Строчная буква (a–z)',
      labelKk: 'Кіші әріп (a–z)',
      labelEn: 'Lowercase letter (a–z)',
      passed:  password.contains(RegExp(r'[a-z]')),
    ),
    PasswordRule(
      label:   'Минимум одна цифра',
      labelKk: 'Кемінде бір сан',
      labelEn: 'At least one number',
      passed:  password.contains(RegExp(r'[0-9]')),
    ),
    PasswordRule(
      label:   'Специальный символ (!@#\$%)',
      labelKk: 'Арнайы таңба (!@#\$%)',
      labelEn: 'Special character (!@#\$%)',
      passed:  password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    ),
  ];

  static bool isValid(String password) =>
      validate(password).every((r) => r.passed);
}

class PasswordRule {
  const PasswordRule({
    required this.label,
    required this.labelKk,
    required this.labelEn,
    required this.passed,
  });
  final String label;
  final String labelKk;
  final String labelEn;
  final bool passed;

  String getLabel(String langCode) {
    switch (langCode) {
      case 'kk': return labelKk;
      case 'en': return labelEn;
      default:   return label;
    }
  }
}