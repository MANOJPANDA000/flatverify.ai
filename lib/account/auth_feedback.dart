import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showAuthFeedback(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    if (error.code == 'configuration-not-found' ||
        (error.message?.contains('CONFIGURATION_NOT_FOUND') ?? false)) {
      return 'Account registration is not ready yet. Firebase Authentication '
          'must be set up for this app. Please try again after setup.';
    }
    return switch (error.code) {
      'invalid-verification-code' =>
        'That code is incorrect. Please try again.',
      'session-expired' => 'This code has expired. Request a new code.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'email-already-in-use' =>
        'An account already uses this email. Sign in instead.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'operation-not-allowed' =>
        'Email/password sign-in is not enabled for this app yet.',
      'invalid-email' => 'Enter a valid email address.',
      'wrong-password' =>
        'The password you entered is incorrect. Please try again.',
      'requires-recent-login' =>
        'Please sign in again before changing your password.',
      'invalid-credential' || 'user-not-found' =>
        'The email or password is incorrect. Try again or reset your password.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'invalid-api-key' || 'app-not-authorized' =>
        'This app could not connect to its sign-in service. Contact support.',
      _ =>
        'Sign-in could not be completed. Please try again. '
            'Support code: ${error.code}',
    };
  }
  return 'Unable to complete this request. Please try again.';
}
