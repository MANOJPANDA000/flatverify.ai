import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/account/session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  testWidgets('guest opens calculator, saved checks and Learn without login', (
    tester,
  ) async {
    await Hive.openBox('flatverify_area_checks_v1', bytes: Uint8List(0));
    final session = SessionController.instance;
    session.guestReports = await Hive.openBox(
      'guest_session_reports',
      bytes: Uint8List(0),
    );
    session.reports = session.guestReports;
    session.preferences = await Hive.openBox(
      'account_preferences',
      bytes: Uint8List(0),
    );
    session.entered = false;
    session.auth = null;
    session.user = null;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await Hive.close();
      session.preferences = null;
      session.entered = false;
    });
    await tester.pumpWidget(const FAreaApp());
    await tester.pumpAndSettle();
    expect(find.text('Continue as Guest'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();
    expect(find.text('Start Area Check'), findsOneWidget);
    await tester.ensureVisible(find.text('Start Area Check'));
    await tester.tap(find.text('Start Area Check'));
    await tester.pumpAndSettle();
    expect(find.text('Property name (optional)'), findsOneWidget);
    for (final index in [2, 3, 4, 0]) {
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(index);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
