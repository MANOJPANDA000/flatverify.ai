import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  for (final mode in VerifyInputMode.values) {
    testWidgets('$mode allows one incomplete manual room at a time', (
      tester,
    ) async {
      const channel = MethodChannel('google_mlkit_text_recognizer');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: OcrScannerScreen(initialMode: mode)),
      );
      final dynamic state = tester.state(find.byType(OcrScannerScreen));
      expect(state.hasCalculatedRooms, isFalse);
      expect(find.text('0.00 sq ft calculated carpet area'), findsNothing);
      final add = find.widgetWithText(TextButton, 'Add room');
      Future<void> tapAdd() async {
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        await tester.tap(add);
        await tester.pump();
      }

      if (mode == VerifyInputMode.photo) await tapAdd();
      expect(state.scanRooms.length, 1);
      await tapAdd();
      expect(state.scanRooms.length, 1);
      state.scanRooms.first.lengthMeters = 3.0;
      await tapAdd();
      expect(state.scanRooms.length, 1);
      state.scanRooms.first.widthMeters = 4.0;
      await tapAdd();
      expect(state.scanRooms.length, 2);
      expect(state.hasCalculatedRooms, isTrue);
      state.selectDisplayUnit(AreaDisplayUnit.metric);
      await tester.pump();
      expect(find.text('12.00 m²'), findsWidgets);
      state.selectDisplayUnit(AreaDisplayUnit.imperial);
      await tester.pump();
      expect(find.text('12.00 m²'), findsNothing);
      expect(find.text('129.17 sq ft'), findsWidgets);
      await tapAdd();
      expect(state.scanRooms.length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
