import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('room details show area, dimensions and confirmation below', (
    tester,
  ) async {
    final room = RoomData(
      name: 'Bedroom 1',
      lengthMeters: 4.35,
      widthMeters: 3.35,
      unit: DimensionUnit.meterCm,
    );
    var edited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ScanRoomDetailsCard(
              room: room,
              onEdit: () => edited = true,
              onDelete: () {},
              onConfirm: () => setState(() => room.isUserVerified = true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Bedroom 1'), findsOneWidget);
    expect(find.text('(4.35 m × 3.35 m)'), findsOneWidget);
    expect(
      find.text(
        '${DimensionParser.format(DimensionParser.squareMetersToSquareFeet(4.35 * 3.35))} sq ft',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Confirm room')).dy,
      greaterThan(tester.getTopLeft(find.text('(4.35 m × 3.35 m)')).dy),
    );
    await tester.tap(find.text('Bedroom 1'));
    expect(edited, isTrue);
    await tester.tap(find.text('Confirm room'));
    await tester.pump();
    expect(find.text('Confirmed'), findsOneWidget);
    expect(room.isUserVerified, isTrue);
  });

  testWidgets('editor validates and saves mixed-unit measurements and name', (
    tester,
  ) async {
    RoomData? result;
    final room = RoomData(
      name: 'Room 1',
      lengthMeters: 4.35,
      widthMeters: 3.35,
      unit: DimensionUnit.meterCm,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<RoomData>(
                  context: context,
                  builder: (_) => ScannedRoomEditor(room: room),
                );
              },
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Bedroom 1');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Save & Confirm'));
    await tester.pump();
    expect(
      find.text('Enter a positive measurement with units'),
      findsOneWidget,
    );
    expect(result, isNull);
    await tester.enterText(find.byType(TextFormField).at(1), '12 ft');
    await tester.enterText(find.byType(TextFormField).at(2), '120 in');
    await tester.tap(find.text('Save & Confirm'));
    await tester.pumpAndSettle();
    expect(result!.name, 'Bedroom 1');
    expect(result!.lengthMeters, closeTo(3.6576, 0.00001));
    expect(result!.widthMeters, closeTo(3.048, 0.00001));
    expect(room.name, 'Room 1');
  });
}
