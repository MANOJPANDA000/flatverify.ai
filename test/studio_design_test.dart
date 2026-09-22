import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/app_theme.dart';
import 'package:my_first_app/account/session_controller.dart';
import 'package:my_first_app/studio_ui.dart';
import 'report_units_test.dart' show report;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final session = SessionController.instance;
  const ocrChannel = MethodChannel('google_mlkit_text_recognizer');

  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    final materialFont = File(
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts/materialicons-regular.otf',
    );
    if (materialFont.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(materialFont.readAsBytesSync())),
          ))
          .load();
    }
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('studio_design_');
    Hive.init(directory.path);
    session.user = null;
    session.auth = null;
    await session.initialize();
    await StudioSettings.instance.select(StudioAreaUnit.imperial);
    await session.enterGuest();
    await session.reports.add({
      ...report(),
      'auditName': 'Garden Apartment',
      'project': 'Garden Court',
      'timestamp': '2026-09-20T10:00:00',
    });
    await session.reports.add({
      ...report(type: 'scan'),
      'auditName': 'Terrace Apartment',
      'project': 'Terrace Gardens',
      'timestamp': '2026-09-21T10:00:00',
    });
  });
  tearDown(() async {
    session.entered = false;
    session.preferences = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
      'Studio navigation preserves measurements and lays out at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        if (width == 320) {
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        }
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          ocrChannel,
          (_) async => null,
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            ocrChannel,
            null,
          );
        });
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: buildAppTheme(),
              home: const MainNavigationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'dashboard at $width');
        await capture(tester, boundary, width, 'dashboard');

        Future<void> select(int index) async {
          if (width < 1000) {
            final nav = tester.widget<NavigationBar>(
              find.byType(NavigationBar),
            );
            nav.onDestinationSelected!(index);
          } else {
            await tester.tap(
              find.byTooltip(
                [
                  'Dashboard',
                  'Calculator',
                  'Scan Blueprint',
                  'Saved Audits',
                  'Settings',
                ][index],
              ),
            );
          }
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'tab $index at $width',
          );
        }

        await select(1);
        await tester.ensureVisible(find.text('Meter / CM'));
        await tester.tap(find.text('Meter / CM'));
        await tester.pumpAndSettle();
        final meters = find.widgetWithText(TextField, 'Meter');
        await tester.ensureVisible(meters.first);
        await tester.enterText(meters.first, '4');
        await tester.ensureVisible(meters.last);
        await tester.enterText(meters.last, '3');
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await capture(tester, boundary, width, 'calculator');
        await select(2);
        expect(find.text('Add your floor plan'), findsOneWidget);
        await capture(tester, boundary, width, 'scanner');
        await select(3);
        await capture(tester, boundary, width, 'audits');
        await select(4);
        await capture(tester, boundary, width, 'settings');
        await tester.runAsync(
          () => StudioSettings.instance.select(StudioAreaUnit.metric),
        );
        await tester.pumpAndSettle();
        await select(1);
        final restored = tester
            .widget<RoomCard>(find.byType(RoomCard).first)
            .room;
        expect(restored.lengthMeters, 4);
        expect(restored.widthMeters, 3);
        expect(find.text('12.0 m²'), findsOneWidget);
        await tester.runAsync(
          () => StudioSettings.instance.select(StudioAreaUnit.dual),
        );
        await tester.pumpAndSettle();
        expect(find.text('129.2 sq ft / 12.0 m²'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('Saved audit search, filters and comparison use stored reports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: SavedAuditsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('audit-search')),
      'does not exist',
    );
    await tester.pumpAndSettle();
    expect(find.text('No Audits Found'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('audit-search')), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(ChoiceChip, 'Manual Calculations'),
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Manual Calculations'));
    await tester.pumpAndSettle();
    expect(find.text('Garden Apartment'), findsOneWidget);
    expect(find.text('Terrace Apartment'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'All Audits'));
    await tester.pumpAndSettle();
    for (final name in ['Garden Apartment', 'Terrace Apartment']) {
      final checkbox = find.byWidgetPredicate(
        (w) => w is Checkbox && w.semanticLabel == 'Compare $name',
      );
      await tester.scrollUntilVisible(
        checkbox,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Compare Audits (2/2)'));
    await tester.tap(find.text('Compare Audits (2/2)'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Garden Apartment'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terrace Apartment'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  double width,
  String screen,
) async {
  if (width == 320) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = Directory('build/design-review');
    await output.create(recursive: true);
    await File(
      '${output.path}/flutter-${width.toInt()}-$screen.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
