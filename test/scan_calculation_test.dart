import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets(
    'photo units default automatically and conversion preserves confirmed measurements',
    (tester) async {
      const channel = MethodChannel('google_mlkit_text_recognizer');
      String text = 'Bedroom 1\n4.35m x 3.35m';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'vision#startTextRecognizer'
            ? {'text': text, 'blocks': []}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: OcrScannerScreen(initialMode: VerifyInputMode.photo),
        ),
      );
      final dynamic state = tester.state(find.byType(OcrScannerScreen));
      await state.processImage(File('metric.png'));
      expect(state.displayUnit, AreaDisplayUnit.metric);
      expect(state.hasCalculatedRooms, isFalse);
      final RoomData room = state.scanRooms.first;
      room.isUserVerified = true;
      final double area = state.usableArea;
      state.selectDisplayUnit(AreaDisplayUnit.imperial);
      expect(room.lengthMeters, 4.35);
      expect(room.isUserVerified, isTrue);
      expect(state.usableArea, area);
      await state.processImage(File('metric-second.png'));
      expect(state.displayUnit, AreaDisplayUnit.imperial);
      text = '12ft x 10ft';
      await state.processImage(File('feet.png'));
      expect(state.displayUnit, AreaDisplayUnit.imperial);
      expect(state.usableArea, area);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('OCR photos contribute only after each room is confirmed', (
    tester,
  ) async {
    const channel = MethodChannel('google_mlkit_text_recognizer');
    String recognizedText = '12 x 10';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'vision#startTextRecognizer'
          ? {'text': recognizedText, 'blocks': []}
          : null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: OcrScannerScreen(initialMode: VerifyInputMode.photo),
      ),
    );
    // Exercise the shared processing path used by camera and gallery.
    // Native OCR is mocked, so no actual image file is required.
    final dynamic state = tester.state(find.byType(OcrScannerScreen));
    await state.processImage(File('first-plan.png'));
    expect(state.parsedDimensions.length, 2);
    expect(state.scanRooms.length, 1);
    expect(state.scanRooms.first.isUserVerified, isFalse);
    expect(state.usableArea, 0);
    expect(state.hasCalculatedRooms, isFalse);
    state.scanRooms.first.isUserVerified = true;
    expect(state.usableArea, closeTo(120, 0.01));
    expect(state.builtUpArea, closeTo(134.4, 0.01));
    expect(state.superBuiltUpArea, closeTo(174.72, 0.01));

    recognizedText = '''8'-0" X 10'-0"''';
    await state.processImage(File('second-plan.png'));
    expect(state.parsedDimensions.length, 4);
    expect(state.scanRooms.length, 2);
    expect(state.usableArea, closeTo(120, 0.01));
    state.scanRooms[1].isUserVerified = true;
    expect(state.usableArea, closeTo(200, 0.01));

    recognizedText = 'Bedroom 02\n4.35M X 3.35M\nDining Area\n3.35M X 4.7M';
    await state.processImage(File('metric-plan.png'));
    expect(state.scanRooms.length, 4);
    expect(state.scanRooms[2].lengthMeters, 4.35);
    expect(state.scanRooms[2].widthMeters, 3.35);
    expect(state.scanRooms[2].unit, DimensionUnit.meterCm);
    expect(state.usableArea, closeTo(200, 0.01));
    state.scanRooms[2].isUserVerified = true;
    state.scanRooms[3].isUserVerified = true;
    expect(
      state.usableArea,
      closeTo(200 + DimensionParser.squareMetersToSquareFeet(30.3175), 0.01),
    );

    recognizedText = '3.35 × 2.00 m\n335cm X 200cm\n3350mm x 2000mm';
    await state.processImage(File('metric-units-plan.png'));
    expect(state.scanRooms.length, 7);
    expect(state.scanRooms.last.lengthMeters, 3.35);
    expect(state.scanRooms.last.widthMeters, 2);
    for (final RoomData room in state.scanRooms) {
      room.isUserVerified = true;
    }

    recognizedText = 'No dimensions visible';
    await state.processImage(File('unreadable-plan.png'));
    expect(state.scanRooms.length, 7);
    expect(
      state.usableArea,
      closeTo(200 + DimensionParser.squareMetersToSquareFeet(50.4175), 0.01),
    );

    // Dispose before rendering mocked image paths.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
