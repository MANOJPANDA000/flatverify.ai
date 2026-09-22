import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'biometric_login_service.dart';

/// Stores guest reports separately from account-owned reports. Passwords and
/// OTPs are handled only by Firebase and are never written to Hive.
class SessionController extends ChangeNotifier {
  SessionController({BiometricLoginService? biometrics})
    : biometrics = biometrics ?? BiometricLoginService();
  final BiometricLoginService biometrics;
  static final instance = SessionController();
  late Box guestReports;
  late Box reports;
  FirebaseAuth? auth;
  User? user;
  bool entered = false;
  bool credentialAuthenticated = false;
  int _authEpoch = 0;
  bool get biometricEnabled =>
      preferences?.get('biometricEnabled', defaultValue: false) == true;
  bool get rememberSession =>
      preferences?.get('rememberSession', defaultValue: true) == true;
  String? initializationError;
  Box? preferences;
  bool get rememberEmail =>
      preferences?.get('rememberEmail', defaultValue: true) == true;
  String get lastEmail =>
      rememberEmail ? (preferences?.get('lastEmail') as String? ?? '') : '';

  /// Centralized asynchronous access keeps every sign-in entry route aligned
  /// and remains easy to substitute with a delayed source in widget tests.
  Future<String> loadLastEmail() async => lastEmail;

  Future<void> setRememberEmail(bool enabled) async {
    await preferences?.put('rememberEmail', enabled);
    if (!enabled) await preferences?.delete('lastEmail');
    notifyListeners();
  }

  Future<void> rememberSuccessfulEmail(String? email) async {
    if (rememberEmail && email != null && email.isNotEmpty) {
      await preferences?.put('lastEmail', email);
    }
  }

  Future<void> updateName(String name) async {
    final current = user;
    if (current == null) throw StateError('Sign in first.');
    await current.updateDisplayName(name.trim());
    await current.reload();
    user = auth?.currentUser ?? current;
    notifyListeners();
  }

  Future<void> removePhoto() async {
    final current = user;
    if (current == null) throw StateError('Sign in first.');
    await current.updatePhotoURL(null);
    await current.reload();
    user = auth?.currentUser ?? current;
    notifyListeners();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final current = user;
    if (current?.email == null) throw StateError('Email sign-in is required.');
    await current!.reauthenticateWithCredential(
      EmailAuthProvider.credential(
        email: current.email!,
        password: currentPassword,
      ),
    );
    await current.updatePassword(newPassword);
  }

  bool get isGuest => user == null;
  bool get authenticationReady => auth != null;

  Future<void> initialize() async {
    preferences = await Hive.openBox('account_preferences');
    guestReports = await Hive.openBox('guest_session_reports');
    // Guest audits survive restarts and logout. Only explicit deletion removes them.
    reports = guestReports;
    user = null;
    credentialAuthenticated = false;
    entered = preferences?.get('sessionMode') == 'guest';
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if ([apiKey, appId, projectId, senderId].any((value) => value.isEmpty)) {
      return;
    }
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          projectId: projectId,
          messagingSenderId: senderId,
        ),
      );
      auth = FirebaseAuth.instance;
      final restored = auth!.currentUser;
      if (restored != null &&
          (restored.emailVerified || restored.phoneNumber != null)) {
        await restoreUser(restored);
      }
    } catch (_) {
      initializationError =
          'Sign-in could not connect. You can continue as a guest.';
    }
  }

  Future<void> enterGuest() async {
    _authEpoch++;
    // Keep native credentials inaccessible to the guest flow.
    await auth?.signOut();
    user = null;
    credentialAuthenticated = false;
    reports = guestReports;
    await preferences?.put('sessionMode', 'guest');
    entered = true;
    notifyListeners();
  }

  Future<void> setRememberSession(bool value) async {
    await preferences?.put('rememberSession', value);
  }

  Future<void> restoreUser(User restored) async {
    if (['guest', 'signedOut'].contains(preferences?.get('sessionMode'))) {
      return;
    }
    if (biometricEnabled) {
      entered = false;
      return;
    }
    if (!rememberSession) {
      await auth?.signOut();
      return;
    }
    await activateUser(restored, fromCredentials: false);
  }

  Future<String?> biometricButtonLabel() async =>
      biometricEnabled ? biometrics.buttonLabel(auth?.currentUser?.uid) : null;

  Future<void> enableBiometrics() async {
    if (user == null || !credentialAuthenticated) {
      throw const BiometricFailure(
        'Sign in with your password before enabling biometric login.',
      );
    }
    await biometrics.enable(user!.uid);
    await preferences?.put('biometricEnabled', true);
    await setRememberSession(true);
    notifyListeners();
  }

  Future<void> disableBiometrics() async {
    await preferences?.put('biometricEnabled', false);
    await biometrics.disable();
    notifyListeners();
  }

  Future<void> signInWithBiometrics() async {
    final epoch = _authEpoch;
    final current = auth?.currentUser;
    if (!biometricEnabled || current == null) {
      throw const BiometricFailure('Please sign in with your password first.');
    }
    await biometrics.unlock(current.uid);
    if (epoch != _authEpoch) {
      throw const BiometricFailure(
        'Your session changed. Please sign in again.',
      );
    }
    // A device match alone is not a backend sign-in. Force Firebase to validate
    // its existing session; revoked/expired credentials never enter the app.
    final token = await current.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const BiometricFailure(
        'Your session expired. Sign in with your password.',
      );
    }
    await current.reload();
    final verified = auth?.currentUser;
    if (epoch != _authEpoch ||
        verified == null ||
        verified.uid != current.uid) {
      throw const BiometricFailure(
        'Your account changed. Sign in with your password.',
      );
    }
    await activateUser(verified, fromCredentials: false);
  }

  Future<void> activateUser(
    User authenticated, {
    bool fromCredentials = true,
  }) async {
    if (!authenticated.emailVerified && authenticated.phoneNumber == null) {
      throw StateError(
        'Verify your email address before opening your account.',
      );
    }
    final box = await Hive.openBox('account_${authenticated.uid}_reports');
    if (Hive.isBoxOpen('local_audits')) {
      await transferGuestReports(
        Hive.box('local_audits'),
        box,
        prefix: 'legacy',
      );
    }
    await transferGuestReports(guestReports, box);
    await rememberSuccessfulEmail(authenticated.email);
    user = authenticated;
    credentialAuthenticated = fromCredentials;
    reports = box;
    await preferences?.put('sessionMode', 'account');
    entered = true;
    notifyListeners();
  }

  /// Stable keys make a retry after an interrupted transfer safe.
  static Future<void> transferGuestReports(
    Box source,
    Box target, {
    String prefix = 'guest',
  }) async {
    final entries = <String, dynamic>{};
    for (final key in source.keys.toList()) {
      final value = source.get(key);
      final timestamp = value is Map ? value['timestamp'] : null;
      entries['${prefix}_${timestamp ?? 'report'}_$key'] = value;
    }
    await target.putAll(entries);
    await target.flush();
    await source.clear();
  }

  Future<void> signOut() async {
    _authEpoch++;
    final wasEnabled = biometricEnabled;
    // Record logout first so a process interruption cannot restore this session.
    await preferences?.put('sessionMode', 'signedOut');
    await preferences?.put('biometricEnabled', false);
    user = null;
    credentialAuthenticated = false;
    reports = guestReports;
    entered = false;
    notifyListeners();
    try {
      if (wasEnabled) await biometrics.disable();
    } finally {
      await auth?.signOut();
    }
  }
}
