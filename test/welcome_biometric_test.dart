import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_first_app/account/biometric_login_service.dart';
import 'package:my_first_app/account/session_controller.dart';
import 'package:my_first_app/account/access_screen.dart';
import 'package:my_first_app/app_theme.dart';
import 'auth_fakes.dart';

class TestDevice implements BiometricDevice {
  List<BiometricType> types = [BiometricType.fingerprint];
  bool result = true;
  Object? error;
  int prompts = 0;
  @override
  Future<List<BiometricType>> available() async => types;
  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    if (error != null) throw error!;
    return result;
  }
}

class TestVault implements BiometricVault {
  String? uid;
  @override
  Future<String?> read() async => uid;
  @override
  Future<void> write(String value) async {
    uid = value;
  }

  @override
  Future<void> clear() async {
    uid = null;
  }
}

class RefreshUser extends TestUser {
  bool refreshed = false;
  Object? refreshError;
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    refreshed = forceRefresh;
    if (refreshError != null) throw refreshError!;
    return 'test-only-token';
  }
}

class RecoveryAuth extends TestAuth {
  RecoveryAuth(super.user);
  int resets = 0;
  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resets++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestDevice device;
  late TestVault vault;
  late SessionController session;
  late RefreshUser user;
  late RecoveryAuth auth;
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  setUp(() async {
    device = TestDevice();
    vault = TestVault();
    session = SessionController(
      biometrics: BiometricLoginService(device: device, vault: vault),
    );
    session.preferences = await Hive.openBox(
      'account_preferences',
      bytes: Uint8List(0),
    );
    session.guestReports = await Hive.openBox(
      'guest_session_reports',
      bytes: Uint8List(0),
    );
    session.reports = session.guestReports;
    user = RefreshUser();
    auth = RecoveryAuth(user);
    session.auth = auth;
    await Hive.openBox('account_test-user_reports', bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
    session.dispose();
  });
  test(
    'biometric login requires opt-in, binding, hardware and backend refresh',
    () async {
      expect(await session.biometricButtonLabel(), isNull);
      await expectLater(
        session.enableBiometrics(),
        throwsA(isA<BiometricFailure>()),
      );
      await session.activateUser(user);
      await session.enableBiometrics();
      expect(vault.uid, user.uid);
      expect(session.biometricEnabled, isTrue);
      expect(await session.biometricButtonLabel(), 'Use Fingerprint');
      session.user = null;
      session.entered = false;
      await session.restoreUser(user);
      expect(session.entered, isFalse);
      await session.signInWithBiometrics();
      expect(session.entered, isTrue);
      expect(user.refreshed, isTrue);
      expect(session.credentialAuthenticated, isFalse);
      expect(
        session.preferences!.values.any((v) => v == 'test-only-token'),
        isFalse,
      );
    },
  );
  test(
    'unavailable, wrong account, cancellation, lockout and revoked session stay locked',
    () async {
      await session.activateUser(user);
      await session.enableBiometrics();
      session.entered = false;
      session.user = null;
      device.types = [];
      expect(await session.biometricButtonLabel(), isNull);
      await expectLater(
        session.signInWithBiometrics(),
        throwsA(isA<BiometricFailure>()),
      );
      device.types = [BiometricType.face];
      expect(await session.biometricButtonLabel(), 'Use Biometrics');
      vault.uid = 'different-user';
      await expectLater(
        session.signInWithBiometrics(),
        throwsA(isA<BiometricFailure>()),
      );
      vault.uid = user.uid;
      device.result = false;
      await expectLater(
        session.signInWithBiometrics(),
        throwsA(isA<BiometricFailure>()),
      );
      expect(session.entered, isFalse);
      for (final code in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout,
      ]) {
        device.error = LocalAuthException(code: code);
        await expectLater(
          session.signInWithBiometrics(),
          throwsA(isA<BiometricFailure>()),
        );
        expect(session.entered, isFalse);
      }
      device.error = null;
      device.result = true;
      user.refreshError = FirebaseAuthException(code: 'user-token-expired');
      await expectLater(
        session.signInWithBiometrics(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(session.entered, isFalse);
    },
  );
  test('logout clears auth and enrollment while retaining reports', () async {
    await session.activateUser(user);
    await session.enableBiometrics();
    await session.reports.put('saved', {'title': 'Preserved account report'});
    await session.guestReports.put('guest', {
      'title': 'Preserved guest report',
    });
    await session.signOut();
    expect(auth.currentUser, isNull);
    expect(vault.uid, isNull);
    expect(session.user, isNull);
    expect(session.entered, isFalse);
    expect(session.preferences!.get('sessionMode'), 'signedOut');
    expect(session.biometricEnabled, isFalse);
    expect(Hive.box('account_test-user_reports').containsKey('saved'), isTrue);
    expect(session.guestReports.containsKey('guest'), isTrue);
    await session.restoreUser(user);
    expect(session.entered, isFalse);
  });
  test('remember disabled requires password on subsequent launch', () async {
    await session.preferences!.put('sessionMode', 'account');
    await session.setRememberSession(false);
    await session.restoreUser(user);
    expect(auth.currentUser, isNull);
    expect(session.entered, isFalse);
  });
  Future<void> pumpAccess(WidgetTester tester, {bool register = false}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AccessScreen(
          controller: session,
          register: register,
          termsUrl: 'https://example.test/terms',
          privacyUrl: 'https://example.test/privacy',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    final finder = find.widgetWithText(FilledButton, text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'single-page login validates both fields and preserves password fallback',
    (tester) async {
      await pumpAccess(tester);
      await tapButton(tester, 'Sign In');
      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'not-an-email',
      );
      await tapButton(tester, 'Sign In');
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'person@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      auth.signInError = FirebaseAuthException(code: 'invalid-credential');
      await tapButton(tester, 'Sign In');
      expect(session.entered, isFalse);
      expect(
        find.textContaining('The email or password is incorrect'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'successful credentials enter existing session and remember selection',
    (tester) async {
      await pumpAccess(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'person@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tapButton(tester, 'Sign In');
      expect(session.entered, isTrue);
      expect(session.user, user);
      expect(auth.signInCalls, 1);
      expect(session.preferences!.get('sessionMode'), 'account');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'registration validates confirmation and consent before backend call',
    (tester) async {
      await pumpAccess(tester, register: true);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'Test Person',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'),
        'person@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'different',
      );
      await tapButton(tester, 'Create Account');
      expect(find.text('Passwords must match.'), findsOneWidget);
      expect(auth.signInCalls, 0);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'password123',
      );
      await tapButton(tester, 'Create Account');
      expect(
        find.text('Accept the Terms and Privacy Policy to continue.'),
        findsOneWidget,
      );
      expect(auth.signInCalls, 0);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tapButton(tester, 'Create Account');
      expect(auth.signInCalls, 1);
      expect(session.entered, isTrue);
      expect(user.displayName, 'Test Person');
    },
  );
  testWidgets('network errors and password recovery remain truthful', (
    tester,
  ) async {
    await pumpAccess(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    auth.signInError = FirebaseAuthException(code: 'network-request-failed');
    await tapButton(tester, 'Sign In');
    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
    expect(session.entered, isFalse);
    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(auth.resets, 1);
    expect(
      find.textContaining('If this address has an account'),
      findsOneWidget,
    );
  });
  testWidgets(
    'returning user sees real biometric option and cancellation keeps login screen',
    (tester) async {
      await session.activateUser(user);
      await session.enableBiometrics();
      session.entered = false;
      session.user = null;
      await pumpAccess(tester);
      expect(find.text('Use Fingerprint'), findsOneWidget);
      device.result = false;
      await tester.ensureVisible(find.text('Use Fingerprint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Fingerprint'));
      await tester.pumpAndSettle();
      expect(session.entered, isFalse);
      expect(
        find.textContaining('Biometric authentication was not completed'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    },
  );
}
