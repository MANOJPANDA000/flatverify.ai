# Flatverify.ai

Flutter application for property area calculations, floor-plan dimension review,
saved local reports and PDF export, with guest access and optional Firebase
email/password authentication and biometric unlocking.

This branch contains the current Flutter application. The older React/Vite
reference and standalone Flutter generator have been removed. The repository's
`main` branch contains a separate native Android implementation.

## Run

```sh
flutter pub get
flutter run
```

An unconfigured build supports guest access. For real account authentication,
follow [authentication setup](docs/authentication-setup.md) and
[welcome and biometric login setup](docs/welcome-login.md), then run:

```sh
flutter run --dart-define-from-file=config/firebase.json
```

## Project files

- `lib/`: current Flutter app, account screens and calculators.
- `assets/`: application artwork and bundled fonts.
- `test/`: regression, layout and calculation tests.
- `tool/`: launcher icon generation utility.
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Flutter platform projects;
  feature availability varies by platform.
- `docs/`: implementation and setup notes.

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug
```

See [area check implementation](docs/area-check-mvp.md) for the current calculator
workflow. Saved reports are local to this installation; cloud sync is not enabled.
