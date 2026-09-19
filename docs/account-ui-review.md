# Account and interface update

## Implementation map

The existing Flutter routes, Firebase Authentication session controller, Hive
report boxes, OCR parser and PDF exporter are retained. No new package is needed.
Existing uncommitted changes were preserved; formatting was applied to Dart files.

| Request | Implementation |
| --- | --- |
| Consistent UI | `lib/app_theme.dart` centralizes typography, spacing, buttons, cards, dialogs and focus styling. `lib/branding.dart` improves status-color contrast. App content is capped at 960 logical pixels on wide displays. The app remains light-themed; no dark theme previously existed. |
| Remember email | `lib/account/session_controller.dart` stores only the last verified, successfully authenticated email and a remember-email preference in the existing app-local Hive storage. Failed attempts do not change it. Disabling the preference deletes the remembered email. |
| Password convenience | `lib/account/account_screens.dart` supplies username/email and current/new-password autofill hints in an AutofillGroup. Passwords stay masked by default, can be revealed deliberately, and are never persisted by the app. Successful authentication completes the OS autofill context; abandoning the form cancels it. |
| Incorrect credentials | `lib/account/auth_feedback.dart` maps reliable Firebase codes to safe messages. A wrong-password response is specific; generic invalid-credential responses remain generic. The email remains, the password clears and regains focus, and one snackbar is shown. Network, disabled-account, setup and rate-limit failures remain distinct. |
| Home avatar | `lib/account/profile_widgets.dart`, `lib/home_dashboard.dart` and `lib/verification_widgets.dart` render the Firebase photo URL in a circle, with initials/icon fallback during loading or failure. Only HTTPS photo URLs are rendered. The Home avatar opens Account; Verify has no avatar. |
| Report units | `lib/report_units.dart` shares Verify's unit control with report summary and room-detail screens in `lib/main.dart`. Saved room lengths remain metres; totals remain square feet. Each display conversion uses those base values and the existing rounding rules. No converted values are written back. |
| Account screen | Profile summary, registered email, editable full name, existing photo removal, remember-email preference, password change, support/privacy and sign-out. Name/photo mutations use Firebase APIs and update the session only on success. |
| Verification email | The verification screen remains available if email sending fails after account creation. Sending starts a 60-second local cooldown; a rate-limit response starts a five-minute cooldown and explains that Firebase may require longer. No automated email retries are made. |

## Backend boundaries

- Firebase Authentication supports profile names, photo URL references and password
  changes. Password changes reauthenticate using the current password before
  calling `updatePassword`. Authentication methods are documented in
  [Firebase's Flutter user-management guide](https://firebase.google.com/docs/auth/flutter/manage-users).
- **Photo upload/change is disabled and explained in the UI.** There is no image
  upload backend, storage bucket, authorization policy or deletion endpoint in
  this project. Firebase's photo URL field does not upload image bytes. No fake
  upload, progress or success state is shown.
- To enable uploads, first provide authenticated storage with per-user access
  rules, content validation for supported image formats, a file-size limit,
  HTTPS download URLs and deletion/cleanup support. Preview, progress and retry
  can then use that real endpoint. No paid storage service was enabled.
- Existing remote profile photos can be removed from the Firebase profile; this
  clears the reference, not the externally hosted file.
- Reports remain device-local and account-scoped. Cloud backup is not added.
- Report unit selections are screen state, like Verify's current draft setting;
  they are not a new persistent account preference. Reopening defaults to square
  feet, and the converter remains available. Room detail initially inherits the
  parent report selection. PDF preview, download, share and print inherit the
  selected report unit; other existing export entry points default to square feet.
- A resend countdown cannot override Firebase throttling or guarantee delivery.
  Check Inbox and Spam for the previous link and wait if requests remain limited.
  See [Firebase Authentication limits](https://firebase.google.com/docs/auth/limits).

## Validation and limits

Automated tests cover remembered-email storage and opt-out, successful and failed
authentication through test Firebase implementations, masked/autofill fields,
focus/error feedback, verification throttling, valid and broken avatar images,
profile update/removal success and failures, password validation and reauthentication,
report length/area conversion, repeated toggles and reopening.

Layout tests cover Welcome, Sign In, Home, Verify, manual entry, standalone
calculator, room editor, Saved, both report types, room detail, Account, Change
Password and Support at 320, 768 and 1440 logical pixels with 130% text scaling.
They also assert the Home-only avatar rule. Rendered Home, Account and report
images are written to `.dart_tool/ui-review-*.png` for visual review.

Live email delivery, a real password change and OS password-manager prompts need
device checks with the owner's account. Test doubles cannot prove those external
services work. No account was force-verified, no live password was changed and
no credentials were collected. Native desktop/web functionality is not certified
by desktop-width widget tests: this project still uses mobile OCR and native IO.

The Android release configuration currently uses the existing debug signing key.
A successful release-mode build is not a store-ready signed release. Signing and
store-target configuration were not changed as part of this update.

## Manual acceptance steps

1. Run `flutter run --dart-define-from-file=config/firebase.json` on the connected
   Android device when ready to install the workspace build.
2. On an installation with no remembered email, open Sign In: the field is empty.
   Enter your own email and password using the OS password manager if available.
   Check that the password starts masked and both the show/hide and keyboard
   Continue/Done actions work.
3. Sign in successfully with a verified account. Sign out and open Sign In again:
   the email is prefilled and editable. Turn off **Remember my email**, sign in
   and sign out again: the field must be empty. A failed attempt with a different
   email must not replace the remembered successful email.
4. Try an incorrect password once. Confirm the safe error message, unchanged
   email, cleared password and password focus. With networking disabled, check
   the network error. Re-enable networking afterwards. Do not repeatedly request
   verification emails; check Inbox and Spam and use the delivered link.
5. Open Home and tap the circular avatar to open Account. Check initials when no
   photo exists. A test account with a valid HTTPS `photoURL` should show the
   photo; an unavailable URL should show the fallback. Verify must have no avatar.
6. Edit the name and save. Return Home and confirm updated initials when there is
   no photo. Where a photo exists, use Remove and confirm the fallback. Upload /
   change photo remains disabled with a setup explanation.
7. Open Change password. Check empty, short, mismatched and incorrect-current-
   password cases. To test a real successful change, deliberately enter your
   current password and a matching new password; then sign out and sign in with
   the new password. The app does not save either password.
8. Save a room of 4 m × 2.5 m. In Saved, open the report: it must switch between
   **10.00 m²** and **107.64 sq ft**. Open room details: metric lengths are **4.00 m**
   and **2.50 m**, imperial lengths are displayed in feet/inches. Toggle repeatedly,
   reopen, and confirm the original measurements are unchanged. Repeat for a
   scanned report. Preview/download its PDF and check existing export behavior.
9. Increase device text size, rotate the device and test tablet/desktop window
   widths. Check scrolling, keyboard focus, button labels and the horizontal room
   table. Exercise camera/gallery, room confirmation, manual/scan draft isolation,
   report saving, guest entry, sign-out and reopening the app.

No commit, push or deployment is part of this change.
