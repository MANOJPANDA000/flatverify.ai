import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/app_theme.dart';
import 'package:my_first_app/area_check/area_check_app.dart';
import 'package:my_first_app/area_check/area_check_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  for (final width in [320.0, 390.0, 1100.0]) {
    testWidgets('redesigned screens fit $width with working navigation', (
      tester,
    ) async {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await Hive.close();
      });
      final box = await Hive.openBox(
        'flatverify_area_checks_v1',
        bytes: Uint8List(0),
      );
      final check = AreaCheck(id: 'design')
        ..title = 'Maple Heights'
        ..flat = 'B-204'
        ..spaces = [
          AreaSpace(
            id: 'living',
            name: 'Living & dining',
            unit: MeasureUnit.feet,
            length: 18,
            width: 12,
          ),
          AreaSpace(
            id: 'bedroom',
            name: 'Main bedroom',
            unit: MeasureUnit.feet,
            length: 12,
            width: 11,
          ),
          AreaSpace(
            id: 'balcony',
            name: 'Balcony',
            unit: MeasureUnit.feet,
            length: 8,
            width: 4,
            category: SpaceCategory.balcony,
          ),
        ]
        ..walls = WallMethod.estimate
        ..wallPercent = 5
        ..advertisedCarpet = 380
        ..advertisedSaleable = 500;
      await box.put('draft', check.toJson());
      await box.put('check_design', check.toJson());
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      if (width == 320) {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      }
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: AreaCheckApp(
              floorPlanBuilder: (_) => const Scaffold(body: Text('Scanner')),
              legacySavedBuilder: (_) => const Scaffold(body: Text('Reports')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Home at $width');
      Future<void> capture(String name) async {
        if (width == 320) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/ui-refresh');
          await dir.create(recursive: true);
          await File(
            '${dir.path}/${width.toInt()}-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('home');
      Future<void> navigate(int index) async {
        if (width < 900) {
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .onDestinationSelected!(index);
        } else {
          await tester.tap(
            find
                .widgetWithText(
                  ListTile,
                  ['Home', 'Calculator', 'Floor Plan', 'Saved', 'Learn'][index],
                )
                .first,
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Tab $index at $width');
      }

      for (final index in [1, 2, 3, 4]) {
        await navigate(index);
        await capture(
          ['home', 'calculator', 'floor-plan', 'saved', 'learn'][index],
        );
      }
      await tester.enterText(find.byType(TextField), 'wall');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Internal and external walls'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Internal and external walls'), findsOneWidget);
      await navigate(1);
      for (int step = 1; step <= 3; step++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Step $step at $width');
        await capture('step-$step');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await Hive.close();
    });
  }
}
