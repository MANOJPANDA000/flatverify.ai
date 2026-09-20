import '../models/rera_room_model.dart';

class BhkPreset {
  final String id;
  final String title;
  final String shortLabel;
  final String description;
  final List<RoomData> rooms;

  const BhkPreset({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.rooms,
  });
}

class BhkPresetData {
  static List<BhkPreset> getPresets() {
    return [
      BhkPreset(
        id: '2bhk_standard',
        title: '2 BHK Standard (Modern)',
        shortLabel: '2 BHK',
        description: 'Living, 2 Bedrooms, Kitchen, Utility (Inside), Balcony, 2 Toilets',
        rooms: [
          RoomData(id: 'r1', name: 'Living / Dining', length: 16.0, width: 12.0),
          RoomData(id: 'r2', name: 'Master Bedroom', length: 12.0, width: 14.0),
          RoomData(id: 'r3', name: 'Bedroom 2', length: 11.0, width: 12.0),
          RoomData(id: 'r4', name: 'Kitchen', length: 8.5, width: 10.0),
          RoomData(id: 'r5', name: 'Utility / Wash Area', length: 6.0, width: 4.5, spaceType: RoomSpaceType.utilityInside),
          RoomData(id: 'r6', name: 'Living Balcony', length: 12.0, width: 4.5, spaceType: RoomSpaceType.balcony),
          RoomData(id: 'r7', name: 'Master Toilet', length: 5.0, width: 8.0),
          RoomData(id: 'r8', name: 'Common Toilet', length: 5.0, width: 7.5),
        ],
      ),
      BhkPreset(
        id: '3bhk_premium',
        title: '3 BHK Premium Residence',
        shortLabel: '3 BHK',
        description: 'Living, 3 Bedrooms, Kitchen, Dry Balcony, 2 Balconies, 3 Toilets',
        rooms: [
          RoomData(id: 'r10', name: 'Living Room', length: 18.0, width: 14.0),
          RoomData(id: 'r11', name: 'Dining Area', length: 12.0, width: 10.0),
          RoomData(id: 'r12', name: 'Master Bedroom', length: 14.0, width: 15.0),
          RoomData(id: 'r13', name: 'Bedroom 2', length: 12.0, width: 13.0),
          RoomData(id: 'r14', name: 'Bedroom 3 (Guest)', length: 11.0, width: 12.0),
          RoomData(id: 'r15', name: 'Kitchen', length: 10.0, width: 11.0),
          RoomData(id: 'r16', name: 'Dry Balcony (Wash Yard)', length: 7.0, width: 5.0, spaceType: RoomSpaceType.utilityOutside),
          RoomData(id: 'r17', name: 'Deck Balcony', length: 14.0, width: 5.5, spaceType: RoomSpaceType.balcony),
          RoomData(id: 'r18', name: 'Master Balcony', length: 10.0, width: 4.5, spaceType: RoomSpaceType.balcony),
          RoomData(id: 'r19', name: 'Master Toilet', length: 5.5, width: 9.0),
          RoomData(id: 'r20', name: 'Toilet 2', length: 5.0, width: 8.0),
          RoomData(id: 'r21', name: 'Powder Room', length: 4.5, width: 5.0),
        ],
      ),
      BhkPreset(
        id: '1bhk_compact',
        title: '1 BHK Compact Flat',
        shortLabel: '1 BHK',
        description: 'Living, 1 Bedroom, Kitchen with Enclosed Utility, Balcony, Toilet',
        rooms: [
          RoomData(id: 'r30', name: 'Living / Dining', length: 14.0, width: 10.5),
          RoomData(id: 'r31', name: 'Bedroom', length: 11.0, width: 10.0),
          RoomData(id: 'r32', name: 'Kitchen', length: 8.0, width: 7.5),
          RoomData(id: 'r33', name: 'Enclosed Utility', length: 5.0, width: 4.0, spaceType: RoomSpaceType.utilityInside),
          RoomData(id: 'r34', name: 'Balcony', length: 10.0, width: 4.0, spaceType: RoomSpaceType.balcony),
          RoomData(id: 'r35', name: 'Bathroom / Toilet', length: 5.0, width: 7.0),
        ],
      ),
      BhkPreset(
        id: '4bhk_luxury',
        title: '4 BHK Luxury Penthouse',
        shortLabel: '4 BHK',
        description: 'Double Living, 4 Bedrooms, Wet/Dry Kitchen, Terrace, 4 Toilets',
        rooms: [
          RoomData(id: 'r40', name: 'Formal Living', length: 22.0, width: 16.0),
          RoomData(id: 'r41', name: 'Family Lounge', length: 15.0, width: 14.0),
          RoomData(id: 'r42', name: 'Master Suite', length: 16.0, width: 18.0),
          RoomData(id: 'r43', name: 'Bedroom 2', length: 14.0, width: 15.0),
          RoomData(id: 'r44', name: 'Bedroom 3', length: 13.0, width: 14.0),
          RoomData(id: 'r45', name: 'Bedroom 4 / Study', length: 12.0, width: 12.0),
          RoomData(id: 'r46', name: 'Main Kitchen', length: 12.0, width: 14.0),
          RoomData(id: 'r47', name: 'Utility & Scullery', length: 8.0, width: 6.0, spaceType: RoomSpaceType.utilityInside),
          RoomData(id: 'r48', name: 'Outdoor Service Yard', length: 8.0, width: 5.0, spaceType: RoomSpaceType.utilityOutside),
          RoomData(id: 'r49', name: 'Sky Terrace Balcony', length: 20.0, width: 8.0, spaceType: RoomSpaceType.balcony),
          RoomData(id: 'r50', name: 'Master Bath', length: 8.0, width: 12.0),
          RoomData(id: 'r51', name: 'Toilet 2', length: 6.0, width: 9.0),
          RoomData(id: 'r52', name: 'Toilet 3', length: 5.5, width: 8.5),
          RoomData(id: 'r53', name: 'Powder Room', length: 5.0, width: 5.5),
        ],
      ),
    ];
  }
}
