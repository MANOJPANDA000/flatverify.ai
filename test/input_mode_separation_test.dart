import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('manual and photo modes preserve separate drafts and totals', (
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
      const MaterialApp(
        home: OcrScannerScreen(initialMode: VerifyInputMode.photo),
      ),
    );
    final dynamic state = tester.state(find.byType(OcrScannerScreen));
    final pending = RoomData(
      name: 'Scanned Bedroom',
      lengthMeters: 4,
      widthMeters: 3,
      isAutoExtracted: true,
    );
    state.scanRooms.add(pending);
    state.selectedImages.add(File('test-plan.jpg'));
    state.extractedText = 'Scanned Bedroom 4m x 3m';
    state.parsedDimensions = <String, String>{
      'Dimension 1': '4m',
      'Dimension 2': '3m',
    };
    state.displayUnit = AreaDisplayUnit.metric;
    state.loadingPercent = 20.0;

    await tester.tap(find.text('Enter Manually'));
    await tester.pumpAndSettle();
    expect(state.selectedImages, isEmpty);
    expect(state.parsedDimensions, isEmpty);
    expect(state.extractedText, isEmpty);
    expect(find.text('Scanned Bedroom'), findsNothing);
    expect(state.scanRooms.length, 1);
    expect(state.usableArea, 0);
    expect(state.displayUnit, AreaDisplayUnit.imperial);
    expect(state.loadingPercent, 30);
    final RoomData manual = state.scanRooms.first;
    manual.lengthMeters = 2;
    manual.widthMeters = 3;
    state.loadingPercent = 15.0;

    await tester.tap(find.text('Scan Floor Plan'));
    // Inspect the retained image before rendering its deliberately mocked path.
    expect(state.selectedImages.length, 1);
    state.selectedImages.clear();
    await tester.pumpAndSettle();
    expect(state.scanRooms, [pending]);
    expect(pending.isUserVerified, isFalse);
    expect(state.usableArea, 0);
    expect(state.displayUnit, AreaDisplayUnit.metric);
    expect(state.loadingPercent, 20);
    expect(state.extractedText, contains('Scanned Bedroom'));

    await tester.tap(find.text('Enter Manually'));
    await tester.pumpAndSettle();
    expect(state.scanRooms, [manual]);
    expect(
      state.usableArea,
      closeTo(DimensionParser.squareMetersToSquareFeet(6), 0.001),
    );
    expect(state.loadingPercent, 15);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
