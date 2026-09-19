import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/account/account_screens.dart';
import 'package:my_first_app/account/auth_feedback.dart';
import 'package:my_first_app/account/profile_widgets.dart';
import 'package:my_first_app/account/session_controller.dart';
import 'auth_fakes.dart';
import 'image_http_fake.dart';

void main() {
  final session = SessionController.instance;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account_improvements_');
    Hive.init(directory.path);
    session.user = null;
    session.auth = null;
    session.entered = false;
    await session.initialize();
  });
  tearDown(() async {
    session.user = null;
    session.auth = null;
    session.preferences = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('valid HTTPS profile photo renders a decoded image in a circle', (
    tester,
  ) async {
    final bytes = File('assets/branding/app_icon.png').readAsBytesSync();
    debugNetworkImageHttpClientProvider = () => ImageHttpClient(bytes);
    addTearDown(() => debugNetworkImageHttpClientProvider = null);
    final user = TestUser(photoURL: 'https://profile.example/avatar.png');
    await tester.pumpWidget(MaterialApp(home: ProfileAvatar(user: user)));
    await tester.runAsync(
      () => precacheImage(
        NetworkImage(user.photoURL!),
        tester.element(find.byType(ProfileAvatar)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ClipOval), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    expect(find.text('SP'), findsNothing);
    debugNetworkImageHttpClientProvider = null;
  });

  testWidgets(
    'successful sign-in remembers email without storing credentials',
    (tester) async {
      session.auth = TestAuth(TestUser());
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      final dynamic state = tester.state(find.byType(SignInScreen));
      state.identifier.text = 'person@example.com';
      await state.submit();
      await tester.pump();
      state.password.text = 'test-only-password';
      await tester.runAsync(() async {
        await state.submit();
      });
      await tester.pumpAndSettle();
      expect(session.lastEmail, 'person@example.com');
      expect(session.preferences!.toMap(), {'lastEmail': 'person@example.com'});
      expect(state.password.text, isEmpty);
      expect(session.isGuest, isFalse);
    },
  );

  testWidgets('account supports profile edits and clearly disables upload', (
    tester,
  ) async {
    final user = TestUser(photoURL: 'https://example.invalid/unavailable.png');
    session.user = user;
    session.auth = TestAuth(user);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AccountScreen())),
    );
    final upload = find.widgetWithText(OutlinedButton, 'Upload / change photo');
    expect(tester.widget<OutlinedButton>(upload).onPressed, isNull);
    await tester.ensureVisible(find.widgetWithText(TextField, 'Full name'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Full name'),
      'Updated Person',
    );
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(user.displayName, 'Updated Person');
    expect(find.text('Profile updated.'), findsOneWidget);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remove profile photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove profile photo'));
    await tester.pumpAndSettle();
    expect(user.photoURL, isNull);
    expect(find.text('Remove profile photo'), findsNothing);
  });

  test(
    'remember only verified successful email; shared-device opt-out survives logout',
    () async {
      expect(session.lastEmail, isEmpty);
      final pending = TestUser(emailVerified: false);
      await expectLater(session.activateUser(pending), throwsStateError);
      expect(session.lastEmail, isEmpty);
      final user = TestUser();
      session.auth = TestAuth(user);
      await session.activateUser(user);
      expect(session.lastEmail, user.email);
      await session.signOut();
      expect(session.lastEmail, user.email);
      await session.setRememberEmail(false);
      await session.activateUser(user);
      expect(session.lastEmail, isEmpty);
      expect(session.preferences!.containsKey('lastEmail'), isFalse);
      expect(session.preferences!.keys.toSet(), {'rememberEmail'});
    },
  );

  testWidgets(
    'first email empty; returning email editable; registration stays empty',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => session.rememberSuccessfulEmail('returning@example.com'),
      );
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'returning@example.com',
      );
      await tester.enterText(find.byType(TextField).first, '');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        const MaterialApp(home: SignInScreen(register: true)),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'incorrect password retains email, clears password, focuses and reports once',
    (tester) async {
      final auth = TestAuth(TestUser())
        ..signInError = FirebaseAuthException(code: 'wrong-password');
      session.auth = auth;
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      await tester.enterText(
        find.byType(TextField).first,
        'person@example.com',
      );
      final dynamic state = tester.state(find.byType(SignInScreen));
      await state.submit();
      await tester.pump();
      final field = find.widgetWithText(TextField, 'Password');
      expect(tester.widget<TextField>(field).obscureText, isTrue);
      expect(
        tester.widget<TextField>(field).autofillHints,
        contains(AutofillHints.password),
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Email address'))
            .autofillHints,
        contains(AutofillHints.username),
      );
      await tester.enterText(field, 'test-password-only');
      await state.submit();
      await tester.pump();
      expect(auth.signInCalls, 1);
      expect(state.identifier.text, 'person@example.com');
      expect(state.password.text, isEmpty);
      expect(state.passwordFocus.hasFocus, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(session.lastEmail, isEmpty);
      expect(
        authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        contains('email or password'),
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        contains('internet'),
      );
      expect(
        authErrorMessage(
          FirebaseAuthException(code: 'internal-error', message: 'private'),
        ),
        isNot(contains('private')),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'registration send failure retains verification screen and blocks duplicate sends',
    (tester) async {
      final user = TestUser(emailVerified: false)
        ..sendError = FirebaseAuthException(code: 'too-many-requests');
      session.auth = TestAuth(user);
      await tester.pumpWidget(
        const MaterialApp(home: SignInScreen(register: true)),
      );
      final dynamic state = tester.state(find.byType(SignInScreen));
      state.name.text = 'Sample Person';
      state.identifier.text = 'person@example.com';
      await state.submit();
      await tester.pump();
      state.password.text = 'test-password-only';
      await state.submit();
      await tester.pump();
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.textContaining('temporarily limited'), findsOneWidget);
      expect(state.emailResendSeconds, 300);
      await state.emailAction();
      expect(user.sends, 1);
      await tester.pump(const Duration(seconds: 300));
      user.sendError = null;
      await state.emailAction();
      await tester.pump();
      expect(user.sends, 2);
      expect(find.textContaining('Verification email sent.'), findsOneWidget);
      await state.emailAction();
      expect(user.sends, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'name and photo update success and failure; password requires reauthentication',
    () async {
      final user = TestUser(photoURL: 'https://example.com/photo.png');
      session.user = user;
      session.auth = TestAuth(user);
      await session.updateName(' New Name ');
      expect(user.displayName, 'New Name');
      user.profileError = FirebaseAuthException(code: 'network-request-failed');
      await expectLater(
        session.updateName('Other'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(user.displayName, 'New Name');
      await expectLater(
        session.removePhoto(),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(user.photoURL, isNotNull);
      user.profileError = null;
      await session.removePhoto();
      expect(user.photoURL, isNull);
      user.reauthError = FirebaseAuthException(code: 'wrong-password');
      await expectLater(
        session.changePassword('incorrect', 'new-test-password'),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(user.calls, ['reauthenticate']);
      user.calls.clear();
      user.reauthError = null;
      await session.changePassword(
        'current-test-password',
        'new-test-password',
      );
      expect(user.calls, ['reauthenticate', 'updatePassword']);
      user.passwordError = FirebaseAuthException(
        code: 'network-request-failed',
      );
      await expectLater(
        session.changePassword('current-test-password', 'new-test-password'),
        throwsA(isA<FirebaseAuthException>()),
      );
    },
  );

  testWidgets('avatar initials, unsafe URL and broken image fallback', (
    tester,
  ) async {
    final user = TestUser();
    await tester.pumpWidget(MaterialApp(home: ProfileAvatar(user: user)));
    expect(find.text('SP'), findsOneWidget);
    user.photoURL = 'file:///private';
    await tester.pumpWidget(MaterialApp(home: ProfileAvatar(user: user)));
    expect(find.byType(Image), findsNothing);
    user.photoURL = 'https://example.invalid/missing.png';
    await tester.pumpWidget(MaterialApp(home: ProfileAvatar(user: user)));
    await tester.pumpAndSettle();
    expect(find.text('SP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'password form validates matching values and masks each field independently',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'current-test-only');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'different');
      await tester.tap(find.text('Update password'));
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      final inputs = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(inputs.map((field) => field.obscureText), [false, true, true]);
    },
  );
}
