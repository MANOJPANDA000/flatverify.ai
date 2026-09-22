# Welcome, account access and biometrics

The welcome page now leads to single-page email/password sign-in, account
registration or persistent guest access. The calculator, scanner, saved reports
and existing navigation remain available behind the session gateway. The Account
action provides account settings and optional biometric enrollment.

## Files

- `lib/account/access_screen.dart`: responsive login/registration, validation,
  password visibility, reset and verification email flows, policy consent and
  biometric enrollment settings.
- `lib/account/account_screens.dart`: welcome page, gateway and account integration.
- `lib/account/session_controller.dart`: guest/account restoration, Remember Me,
  biometric session gating and logout without deleting saved reports.
- `lib/account/biometric_login_service.dart`: native biometric authentication and
  secure opt-in storage, with injectable adapters for tests.
- `lib/main.dart` and `lib/area_check/area_check_app.dart`: gateway and Account route.
- Android manifest, activity and themes: biometric permission, FragmentActivity,
  AppCompat themes and disabled Android backup.
- iOS Info.plist, Runner.entitlements and project settings: Face ID usage text
  and Keychain access group.

## Authentication model

Firebase performs real email/password authentication; there is no simulated
production success path. Passwords and biometric data are never stored by the
app. Firebase's native SDK manages its persisted credentials. Secure storage
contains only the UID binding for an explicitly enrolled biometric account;
it does not contain a duplicate bearer token or password.

Enrollment requires a successful password login and explicit consent. On later
launches an enrolled account stays behind the gateway. A successful native
biometric prompt is followed by a forced Firebase token refresh and user reload
before access is granted. Unavailable sensors, cancellation, lockout and expired
sessions retain the password fallback. This is an application access gate, not
biometric encryption of the local report database.

Remember Me controls account restoration. Guest access persists across restarts.
Logout clears the biometric enrollment and Firebase session while preserving
saved local reports. Guest calculations are stored on this device and can be lost
when app data is cleared or the app is removed. Cloud synchronization is absent.

## Configuration required

1. Follow [Firebase setup](authentication-setup.md) and enable Email/Password in
   Firebase Console. Use a separate registered Firebase app configuration for
   each platform.
2. Copy `config/firebase.example.json` to the ignored `config/firebase.json` and
   supply the four Firebase values. Add `TERMS_URL` and `PRIVACY_URL` with the
   owner's published HTTPS policy pages. Registration explains the missing
   configuration until those URLs are supplied.
3. Run `flutter run --dart-define-from-file=config/firebase.json`.
4. Register and verify a real email, sign in with a password, then enable
   **Enable Biometric Login** in Account on a device with enrolled biometrics.

No Firebase project, policy publication, storage service or cloud deployment is
created by this UI implementation. A build without configuration supports guest
access and explains why account authentication is unavailable.

## Verification

`test/welcome_biometric_test.dart` exercises validation, real-service boundaries
using test adapters, enrollment/unlock, cancellation, lockout, revoked sessions,
Remember Me, password reset and preservation of reports on logout. Existing
account, guest-navigation and storage tests cover the gateway integration.

Validation on 2026-09-22: static analysis was clean. The full suite passed 82
tests and found two old preference-map expectations; both were corrected and
the complete 11-test account file passed on rerun. All three responsive layout
checks passed, including the new access and registration screens. A separate
320-pixel run with the bundled font also passed and generated review images in
`.dart_tool/ui-review-*.png`.
The Android ARM64 debug APK built successfully and was installed with `adb
install -r` on the connected RMX2030, preserving app data. This build uses the
unconfigured guest fallback; real Firebase and enrolled-biometric flows remain
subject to the device checks below.

Before release, verify native prompts on Android and iOS with enrolled and
unenrolled sensors, cancellation and lockout. Test real Firebase registration,
verification, reset, session refresh, restart and logout with the owner's project.
An iOS signing/build and physical Face ID check require macOS/Xcode and an iPhone.

Platform references: [local_auth](https://pub.dev/packages/local_auth),
[Android integration](https://pub.dev/packages/local_auth_android),
[secure storage](https://pub.dev/packages/flutter_secure_storage), and
[Firebase session persistence](https://firebase.google.com/docs/auth/flutter/start).
