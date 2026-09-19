import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stores guest reports separately from account-owned reports. Passwords and
/// OTPs are handled only by Firebase and are never written to Hive.
class SessionController extends ChangeNotifier {
  static final instance = SessionController();
  late Box guestReports;
  late Box reports;
  FirebaseAuth? auth;
  User? user;
  bool entered = false;
  String? initializationError;
  Box? preferences;
  bool get rememberEmail =>
      preferences?.get('rememberEmail', defaultValue: true) == true;
  String get lastEmail =>
      rememberEmail ? (preferences?.get('lastEmail') as String? ?? '') : '';

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
    // This runs at process startup, never on pause/resume or camera navigation.
    await guestReports.clear();
    reports = guestReports;
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
        await activateUser(restored);
      }
    } catch (_) {
      initializationError =
          'Sign-in could not connect. You can continue as a guest.';
    }
  }

  void enterGuest() {
    entered = true;
    notifyListeners();
  }

  Future<void> activateUser(User authenticated) async {
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
    reports = box;
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
    await auth?.signOut();
    await guestReports.clear();
    user = null;
    reports = guestReports;
    entered = false;
    notifyListeners();
  }
}
