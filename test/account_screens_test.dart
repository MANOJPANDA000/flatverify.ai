import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/account/account_screens.dart';

void main() {
  testWidgets(
    'Firebase setup failures explain the setup problem without exposing details',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      final dynamic state = tester.state(find.byType(SignInScreen));
      final String message = state.errorText(
        FirebaseAuthException(
          code: 'internal-error',
          message:
              'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
        ),
      );
      expect(message, contains('Firebase Authentication must be set up'));
      expect(message, isNot(contains('password is incorrect')));
      expect(
        state.errorText(FirebaseAuthException(code: 'operation-not-allowed')),
        contains('not enabled'),
      );
      final String unknown = state.errorText(
        FirebaseAuthException(
          code: 'internal-error',
          message: 'Sensitive server details',
        ),
      );
      expect(unknown, contains('Support code: internal-error'));
      expect(unknown, isNot(contains('Sensitive server details')));
    },
  );
  testWidgets('default credentials use email and reject a phone number', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    expect(find.widgetWithText(TextField, 'Email address'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Country code'), findsNothing);
  });
  testWidgets('welcome explains persistent local guest reports', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(
      find.textContaining('Guest calculations are stored only'),
      findsOneWidget,
    );
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets(
    'email advances to password and missing configuration never fakes sign-in',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
      await tester.enterText(
        find.byType(TextField).first,
        'person@example.com',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'not-stored-password',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sign-in is not available yet'),
        findsOneWidget,
      );
    },
  );
}
