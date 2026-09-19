# Authentication setup

Guest mode works without a Firebase project. The app never simulates a successful
OTP or password login. Real sign-in requires the app owner's Firebase project.

Account preferences, password changes, verification-email throttling and the
photo-upload dependency are described in [the account/UI review](account-ui-review.md).
The verification email contains a link, not an OTP. If sending is rate-limited,
check Inbox and Spam for an earlier message and wait before requesting another.
The app's resend countdown cannot remove Firebase's server-side restriction.

## This computer is configured

The matching `com.example.my_first_app` client from the downloaded
`google-services.json` has been imported into `config/firebase.json`.
This file is excluded from Git. No paid SMS is enabled by this setup.

In VS Code, select **Run and Debug > Flatverify — Email sign-in**, connect your
Android phone, then press **F5**. This launch option supplies the configuration
automatically. From PowerShell, use:

```powershell
flutter run --dart-define-from-file=config/firebase.json
```

Firebase Console must also have **Authentication > Sign-in method >
Email/Password** enabled. Then use **Get Started** in the app with your own
email and a new password, open the verification email, and return to the app
to select **I have verified my email**. End-to-end sign-in must be checked on
the device after this console step; importing the file alone does not enable
the provider.

## Start with free email/password registration

Email/password registration is already implemented in the app. For initial
testing, use the no-cost Spark plan and leave Phone authentication disabled.
You do not need SMS, Blaze billing, or signing fingerprints for email/password.
The app now shows email/password by default. Phone sign-in is hidden unless
built explicitly with `--dart-define=ENABLE_PHONE_AUTH=true` after paid SMS
has been configured. No billing is enabled by the app.

1. Open [Firebase Console](https://console.firebase.google.com/). Create or open
   your Flatverify project and keep it on Spark. Google Analytics is optional.
2. Add an Android app using package name `com.example.my_first_app`.
   A nickname such as Flatverify is optional. Skip the SHA fingerprint for now.
3. Download the Android app's `google-services.json`. This is app configuration,
   not a service-account private key. The app already has the Firebase SDKs.
4. Open Authentication, click Get started if shown, then go to Sign-in method.
   Enable **Email/Password** and save. Leave **Email link (passwordless sign-in)**
   and **Phone** disabled for this setup.
5. Copy `config/firebase.example.json` to `config/firebase.json`. Fill its four
   values using the mapping table in the phone setup section below. All four
   values must be strings. This local configuration file is ignored by Git.
6. Connect your phone and run:

   ```powershell
   flutter run --dart-define-from-file=config/firebase.json
   ```

   Use this define file on future runs and builds too; a plain `flutter run`
   without configuration builds the guest-only fallback.
7. In the app, choose **Get Started**. Enter your name and actual email address,
   then choose a password of at least 8 characters.
8. Open the verification email (check spam too), follow its link, return to the
   app and tap **I have verified my email**.
9. Save a report, fully close and reopen the app, and check **Saved**. You can
   also sign out and sign back in with the same email/password. Reports persist
   on this installation; cloud backup is not enabled.

Do not share your account password or email verification link in chat.
See [Firebase email/password setup](https://firebase.google.com/docs/auth/flutter/password-auth).

The app initializes Firebase through explicit `FirebaseOptions`. It does not
need to read a hardcoded project configuration from the source. Other platforms
need their own Firebase app registration and matching app ID.

## Optional later: test with your actual mobile number (SMS billing required)

1. Open [Firebase Console](https://console.firebase.google.com/) and create or
   select your project. Add an Android app with package `com.example.my_first_app`.
2. In Project settings > Your apps > Android > SHA certificate fingerprints,
   add these fingerprints for this computer's current debug build:

   ```text
   SHA-1: 22:DC:0C:E0:91:4C:9C:B6:98:DF:32:8D:68:AF:FE:D2:41:EB:08:EB
   SHA-256: FE:FE:AA:4E:B5:E3:CE:74:1E:C1:39:DF:CA:0C:AE:7D:C4:A2:DE:7A:33:F2:13:C0:33:D7:AB:7F:E8:8A:82:D8
   ```

   Other computers and production signing keys need their own fingerprints.
3. Under Authentication > Sign-in method, enable Phone (and Email/Password
   if you want to test email registration). In Authentication > Settings > SMS
   region policy, allow India for a +91 number, or your number's country.
4. Enable the Blaze billing plan to send real SMS. SMS usage can incur charges;
   review Firebase's pricing before enabling billing. Configured fictional test
   numbers use a fixed test code and do not send a real SMS.
5. Download the Android app's `google-services.json` from Project settings.
   Copy `config/firebase.example.json` to `config/firebase.json` and map:

   | App configuration key | Value in google-services.json |
   | --- | --- |
   | `FIREBASE_API_KEY` | matching Android client's `api_key[0].current_key` |
   | `FIREBASE_APP_ID` | matching client's `client_info.mobilesdk_app_id` |
   | `FIREBASE_PROJECT_ID` | `project_info.project_id` |
   | `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` (as a string) |

6. Connect your phone and run from the project folder:

   ```powershell
   flutter run --dart-define-from-file=config/firebase.json
   ```

7. Tap **Get Started**, enter your name and mobile number, check the country
   code, and tap **Continue**. Complete any browser verification and enter the
   SMS code in the app. Do not share your OTP in chat.
8. Save a report, fully close the app, and reopen it. Your registered account
   should remain signed in and the report should appear under **Saved**.
   Signing out and signing back into the same account should restore access.
   Reports are device-local; reinstalling or clearing app data removes them.

See [Android phone sign-in setup](https://firebase.google.com/docs/auth/android/phone-auth)
and [SMS billing and limits](https://firebase.google.com/docs/auth/limits).

## Reports and sessions

- Guest reports use a separate Hive box, cleared only at process startup.
  Opening the camera, gallery, switching tabs or backgrounding does not clear it.
- Each verified account uses a box scoped to its Firebase UID. Firebase persists
  its authentication session; the app restores verified users on the next launch.
- Signing in transfers current guest reports. Previous unowned `local_audits`
  are preserved until the first verified account imports them. The source is
  cleared only after the destination is flushed successfully.
- Account reports are local to this installation. Cloud backup, cross-device
  sync, account linking and account deletion are not implemented in this change.
- Downloaded PDFs remain outside session storage.

Before public release, publish the owner's support contact, privacy policy and
terms, and complete real-device authentication tests (including invalid/expired
OTP, resend, email verification, password reset, logout and restored sessions).

Official references:
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/phone-auth
- https://firebase.google.com/docs/auth/flutter/password-auth
