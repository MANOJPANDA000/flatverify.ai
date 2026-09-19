import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/dimension_scan_parser.dart';

void main() {
  test('actual plan OCR retains all 12 spaces and separates merged toilets', () {
    // OCR text and bounding boxes captured on the Android device. Deliberately
    // retain misread text to exercise the failure rather than corrected input.
    final lines = [
      PlanTextLine('Balcony', 107, 2579, 172, 71),
      PlanTextLine('1Mx453N', 99, 2661, 186, 50),
      PlanTextLine('Bedroom 02', 409, 1247, 344, 82),
      PlanTextLine('4.35M X 3.35M', 409, 1331, 427, 70),
      PlanTextLine('A.Toilet', 677, 1920, 217, 75),
      PlanTextLine('3.35M X 1.5M', 628, 2001, 399, 81),
      PlanTextLine('Master Bedroom', 572, 2699, 443, 87),
      PlanTextLine('3.35M x 4.53M', 583, 2782, 415, 88),
      PlanTextLine('C.Toilet', 1717, 1187, 194, 84),
      PlanTextLine('A.Toilet', 1239, 1191, 276, 87),
      PlanTextLine('1.6M X 2.225M1.63M X 2.25M', 1226, 1265, 775, 68),
      PlanTextLine('Dining Area', 1456, 1995, 336, 79),
      PlanTextLine('3.35M X 4.7M', 1466, 2082, 404, 80),
      PlanTextLine('Kitchen', 1480, 2772, 219, 71),
      PlanTextLine('3.35M X 2.00', 1423, 2854, 422, 96),
      PlanTextLine('w3', 1682, 3056, 110, 70),
      PlanTextLine('Uuny', 1472, 3153, 177, 84),
      PlanTextLine('(W36M X 1.00M', 1391, 3235, 506, 99),
      PlanTextLine('Bedroom 01', 2313, 1347, 337, 79),
      PlanTextLine('3.35M X 3.65M', 2273, 1427, 470, 79),
      PlanTextLine('Puia room', 2321, 1926, 289, 85),
      PlanTextLine('3.35M X 1.5M', 2310, 2007, 422, 81),
      PlanTextLine('Living Area', 2231, 2845, 341, 88),
      PlanTextLine('3.35M X 4,23N', 2213, 2944, 467, 92),
    ];
    final rooms = DimensionScanParser.parseLayout(lines);
    expect(rooms, hasLength(12));
    expect(
      rooms.where((room) => room.name?.contains('Toilet') ?? false),
      hasLength(3),
    );
    expect(rooms.where((room) => room.length.isEmpty), hasLength(2));
    final attached = rooms.firstWhere((room) => room.length == '1.6m');
    expect(attached.name, 'A.Toilet');
    expect(attached.width, '2.225m');
    final common = rooms.firstWhere((room) => room.name == 'C.Toilet');
    expect(common.length, '1.63m');
    expect(common.width, '2.25m');
    final balcony = rooms.firstWhere((room) => room.name == 'Balcony');
    expect(balcony.length, isEmpty);
    final living = rooms.firstWhere((room) => room.name == 'Living Area');
    expect(DimensionScanParser.toMeters(living.width), 4.23);
    expect(rooms.any((room) => room.name == 'Puja room'), isTrue);
  });
}
