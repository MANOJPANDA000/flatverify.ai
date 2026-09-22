import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('undo restores a deleted room to its original input mode', (
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
        home: OcrScannerScreen(initialMode: VerifyInputMode.manual),
      ),
    );
    final dynamic state = tester.state(find.byType(OcrScannerScreen));
    final room = state.scanRooms.first;
    room.lengthMeters = 4.0;
    room.widthMeters = 3.0;
    tester.widget<RoomCard>(find.byType(RoomCard).first).onChanged();
    await tester.pumpAndSettle();
    expect(find.text('Calculated area'), findsOneWidget);
    expect(
      state.usableArea,
      closeTo(DimensionParser.squareMetersToSquareFeet(12), .001),
    );
    tester.widget<RoomCard>(find.byType(RoomCard).first).onDelete();
    await tester.pumpAndSettle();
    expect(state.scanRooms, isEmpty);
    expect(state.hasCalculatedRooms, isFalse);
    await tester.tap(find.text('Scan Floor Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(state.scanRooms, isEmpty);
    await tester.tap(find.text('Enter Manually'));
    await tester.pumpAndSettle();
    expect(state.scanRooms, [room]);
    expect(
      state.usableArea,
      closeTo(DimensionParser.squareMetersToSquareFeet(12), .001),
    );
    await tester.tap(find.text('View results'));
    await tester.pumpAndSettle();
    expect(find.text('Area Audit Summary').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
