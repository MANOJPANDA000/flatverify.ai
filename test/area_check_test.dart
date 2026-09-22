import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_app/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/area_check/area_check_model.dart';
import 'package:my_first_app/area_check/area_check_app.dart';
import 'package:my_first_app/area_check/area_check_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  test('guest check survives closing and reopening disk storage', () async {
    final directory = await Directory.systemTemp.createTemp('area_check_disk_');
    Hive.init(directory.path);
    try {
      final saved = AreaCheck(id: 'persistent')..title = 'My flat';
      final box = await Hive.openBox('persistence_test');
      await box.put('draft', saved.toJson());
      await box.close();
      final restored = await Hive.openBox('persistence_test');
      expect(AreaCheck.fromJson(restored.get('draft') as Map).title, 'My flat');
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
  test(
    'PDF builds offline with bundled font and all eight categories',
    () async {
      final check = AreaCheck(id: 'pdf')
        ..spaces = [
          for (final category in SpaceCategory.values)
            AreaSpace(
              id: category.name,
              name: category.label,
              category: category,
              unit: MeasureUnit.squareFeet,
              length: 100,
            ),
        ]
        ..walls = WallMethod.estimate
        ..wallPercent = 5
        ..advertisedCarpet = 220
        ..advertisedBuiltUp = 300
        ..advertisedSaleable = 400;
      final bytes = await buildAreaCheckPdf(check);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );
  AreaSpace room(String name, double area, SpaceCategory category) => AreaSpace(
    id: name,
    name: name,
    unit: MeasureUnit.squareFeet,
    length: area,
    category: category,
  );
  test(
    'categories, optional walls, comparisons and loading use separate bases',
    () {
      final c = AreaCheck(id: 'test')
        ..spaces = [
          room('Living', 800, SpaceCategory.indoor),
          room('Passage', 100, SpaceCategory.circulation),
          room('Balcony', 50, SpaceCategory.balcony),
          room('Utility', 20, SpaceCategory.utility),
          room('Terrace', 30, SpaceCategory.terrace),
          room('Partition', 45, SpaceCategory.internalWall),
          room('Exterior', 80, SpaceCategory.externalWall),
          room('Shaft', 10, SpaceCategory.excluded),
        ];
      expect(c.usable, 900);
      expect(c.measuredFloor, 1000);
      expect(c.carpet, isNull);
      c.walls = WallMethod.estimate;
      expect(c.carpet, isNull);
      c.wallPercent = 5;
      expect(c.carpet, 945);
      c.walls = WallMethod.measured;
      expect(c.carpet, 945);
      c.advertisedCarpet = 1000;
      c.advertisedBuiltUp = 1200;
      c.advertisedSaleable = 1500;
      expect(c.difference, 55);
      expect(c.differencePercent, 5.5);
      expect(c.loading(c.advertisedCarpet), 50);
      expect(c.loading(c.advertisedBuiltUp), 25);
      expect(c.efficiency, 63);
      for (var i = 0; i < 10; i++) {
        c.metricDisplay = !c.metricDisplay;
        c.areaLabel(c.usable);
      }
      expect(c.usable, 900);
      expect(AreaCheck.fromJson(c.toJson()).toJson(), c.toJson());
    },
  );
  test('mixed units, quantities, inches validation and zero dimensions', () {
    final s = AreaSpace(
      id: 'room',
      name: 'Room',
      length: 10,
      lengthInches: 6,
      width: 8,
      quantity: 2,
    );
    expect(s.area, 168);
    expect(s.error, isNull);
    s.lengthInches = 13;
    expect(s.error, contains('below 12'));
    s.unit = MeasureUnit.centimeters;
    s.length = 300;
    s.width = 200;
    s.quantity = 1;
    expect(s.area, closeTo(64.5834, 0.00001));
    s.width = 0;
    expect(s.error, isNotNull);
    s.length = double.nan;
    expect(s.error, isNotNull);
  });
  test('missing and zero comparison values do not divide by zero', () {
    final c = AreaCheck(id: 'empty')
      ..advertisedCarpet = 0
      ..advertisedSaleable = 0;
    expect(c.difference, isNull);
    expect(c.efficiency, isNull);
    expect(c.loading(0), isNull);
  });
  group('mobile guest flow', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('flatverify_test_');
      Hive.init(directory.path);
      await Hive.openBox('flatverify_area_checks_v1', bytes: Uint8List(0));
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    testWidgets('360px flow adds a room, skips walls, saves and restores', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app() => MaterialApp(
        theme: buildAppTheme(),
        home: AreaCheckApp(
          floorPlanBuilder: (_) => const SizedBox(),
          legacySavedBuilder: (_) => const SizedBox(),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Start Area Check'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Start Area Check'));
      await tester.tap(find.text('Start Area Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add a space or segment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a space or segment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Space name'),
        'Living room',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Length (feet)'),
        '12',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Width (feet)'),
        '10',
      );
      await tester.tap(find.text('Save space'));
      await tester.pumpAndSettle();
      expect(find.text('120.00 sq ft'), findsWidgets);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Skip wall calculation'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Estimated RERA Carpet Area'), findsNothing);
      await tester.tap(find.text('Save Area Check'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pumpAndSettle();
      final box = Hive.box('flatverify_area_checks_v1');
      expect(
        box.keys.where((k) => k.toString().startsWith('check_')).length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start Area Check'));
      await tester.tap(find.text('Start Area Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Living room'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
