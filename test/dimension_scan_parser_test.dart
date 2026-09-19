import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/dimension_scan_parser.dart';

void main() {
  test(
    'room labels are associated with the following size without reusing names',
    () {
      final rooms = DimensionScanParser.parseRooms(
        'Bedroom 02\n4.35M X 3.35M\nKitchen 10ft x 8ft\n12ft x 10ft',
      );
      expect(rooms.map((room) => room.name).toList(), [
        'Bedroom 02',
        'Kitchen',
        null,
      ]);
    },
  );
  final cases = <String, List<double>>{
    '12 ft x 10 ft': [3.6576, 3.048],
    '12 x 10 feet': [3.6576, 3.048],
    '12 feet by 10 feet': [3.6576, 3.048],
    '12.5ft x 10ft': [3.81, 3.048],
    '''10'-6" X 12'-0"''': [3.2004, 3.6576],
    '10′6″ × 12′0″': [3.2004, 3.6576],
    '10 ft 6 in x 12 ft': [3.2004, 3.6576],
    '120 inches x 96 inches': [3.048, 2.4384],
    '120" x 96"': [3.048, 2.4384],
    '120 x 96 in': [3.048, 2.4384],
    '10 ft 6 1/2 in x 12 ft': [3.2131, 3.6576],
    '120½ inches x 96 inches': [3.0607, 2.4384],
    '4.35M X 3.35M': [4.35, 3.35],
    '3.35 x 2 metres': [3.35, 2],
    '335 cm x 200 cm': [3.35, 2],
    '3350mm x 2000mm': [3.35, 2],
    '3,35m × 2,00m': [3.35, 2],
    '3m x 120in': [3, 3.048],
    '12 x 10': [3.6576, 3.048],
    '3.35M\nX\n2.00M': [3.35, 2],
  };
  for (final entry in cases.entries) {
    test('parses ${entry.key}', () {
      final values = DimensionScanParser.parsePairs(entry.key);
      expect(values, hasLength(2));
      expect(
        DimensionScanParser.toMeters(values[0]),
        closeTo(entry.value[0], 0.00001),
      );
      expect(
        DimensionScanParser.toMeters(values[1]),
        closeTo(entry.value[1], 0.00001),
      );
    });
  }
  test('mixed units and plain pairs retain drawing order', () {
    final values = DimensionScanParser.parsePairs(
      'Kitchen 120in x 96in\nBedroom 4.35M X 3.35M\n'
      'Living 12ft x 10ft\nOther 8 x 6',
    );
    expect(values, hasLength(8));
    final meters = values.map(DimensionScanParser.toMeters).toList();
    expect(meters[0], closeTo(3.048, 0.00001));
    expect(meters[2], 4.35);
    expect(meters[4], closeTo(3.6576, 0.00001));
    expect(meters[6], closeTo(2.4384, 0.00001));
  });
  test('invalid measurements are excluded', () {
    expect(DimensionScanParser.parsePairs('0m x 2m'), isEmpty);
    expect(DimensionScanParser.parsePairs('10 1/0 in x 12 in'), isEmpty);
    expect(DimensionScanParser.parsePairs('Bedroom 2, floor 4'), isEmpty);
  });
}
