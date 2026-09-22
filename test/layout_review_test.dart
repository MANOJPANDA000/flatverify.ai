import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/account/account_screens.dart';
import 'package:my_first_app/account/access_screen.dart';
import 'package:my_first_app/account/profile_widgets.dart';
import 'package:my_first_app/account/session_controller.dart';
import 'package:my_first_app/app_theme.dart';
import 'package:my_first_app/main.dart';
import 'auth_fakes.dart';
import 'report_units_test.dart' show report;

void main() {
  setUpAll(() async {
    await (FontLoader('PlusJakartaSans')
          ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf')))
        .load();
    // Use the SDK fonts for review images when available; no bundled test assets.
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (file.existsSync()) {
        await (FontLoader(entry.key)..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  late Directory directory;
  final session = SessionController.instance;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('layout_review_');
    Hive.init(directory.path);
    await session.initialize();
    session.user = TestUser();
    session.auth = TestAuth(session.user);
  });
  tearDown(() async {
    session.user = null;
    session.auth = null;
    session.preferences = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('screen layouts at width $width and larger text', (
      tester,
    ) async {
      final originalErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        originalErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalErrorHandler);
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      const channel = MethodChannel('google_mlkit_text_recognizer');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });
      final screens = <String, Widget>{
        'welcome': const WelcomeScreen(),
        'access': const AccessScreen(),
        'registration': const AccessScreen(register: true),
        'sign-in': const SignInScreen(),
        'home': const HomeScreen(),
        'verify': const OcrScannerScreen(),
        'manual': const OcrScannerScreen(initialMode: VerifyInputMode.manual),
        'calculator': const StandaloneCalculatorPage(),
        'room-edit': ScannedRoomEditor(
          room: RoomData(name: 'Bedroom 1', lengthMeters: 4, widthMeters: 3),
        ),
        'saved': const SavedAuditsScreen(),
        'report': SavedAuditReportScreen(data: report()),
        'scan-report': SavedAuditReportScreen(data: report(type: 'scan')),
        'room-details': DetailedAreaReportScreen(data: report()),
        'account': const AccountScreen(),
        'password': const ChangePasswordScreen(),
        'support': const HelpScreen(),
      };
      for (final entry in screens.entries) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: RepaintBoundary(
                    key: boundary,
                    child: Scaffold(body: entry.value),
                  ),
                ),
              ),
            ),
          ),
        );
        if (entry.key == 'home' || entry.key == 'welcome') {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/branding/floor_plan_hero.png'),
              boundary.currentContext!,
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        if (entry.key == 'verify') {
          expect(find.byType(ProfileAvatar), findsNothing);
        }
        if (entry.key == 'home') {
          expect(find.byType(ProfileAvatar), findsOneWidget);
        }
        if (width == 320 &&
            [
              'welcome',
              'access',
              'registration',
              'home',
              'account',
              'report',
            ].contains(entry.key)) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '.dart_tool/ui-review-${entry.key}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }
}
