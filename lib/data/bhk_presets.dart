import '../models/rera_room_model.dart';

class BhkPreset {
  final String id;
  final String title;
  final String shortLabel;
  final String description;
  final List<ReraRoomData> rooms;

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
          ReraRoomData(id: 'r1', name: 'Living / Dining', length: 16.0, width: 12.0),
          ReraRoomData(id: 'r2', name: 'Master Bedroom', length: 12.0, width: 14.0),
          ReraRoomData(id: 'r3', name: 'Bedroom 2', length: 11.0, width: 12.0),
          ReraRoomData(id: 'r4', name: 'Kitchen', length: 8.5, width: 10.0),
          ReraRoomData(id: 'r5', name: 'Utility / Wash Area', length: 6.0, width: 4.5, spaceType: RoomSpaceType.utilityInside),
          ReraRoomData(id: 'r6', name: 'Living Balcony', length: 12.0, width: 4.5, spaceType: RoomSpaceType.balcony),
          ReraRoomData(id: 'r7', name: 'Master Toilet', length: 5.0, width: 8.0),
          ReraRoomData(id: 'r8', name: 'Common Toilet', length: 5.0, width: 7.5),
        ],
      ),
      BhkPreset(
        id: '3bhk_premium',
        title: '3 BHK Premium Residence',
        shortLabel: '3 BHK',
        description: 'Living, 3 Bedrooms, Kitchen, Dry Balcony, 2 Balconies, 3 Toilets',
        rooms: [
          ReraRoomData(id: 'r10', name: 'Living Room', length: 18.0, width: 14.0),
          ReraRoomData(id: 'r11', name: 'Dining Area', length: 12.0, width: 10.0),
          ReraRoomData(id: 'r12', name: 'Master Bedroom', length: 14.0, width: 15.0),
          ReraRoomData(id: 'r13', name: 'Bedroom 2', length: 12.0, width: 13.0),
          ReraRoomData(id: 'r14', name: 'Bedroom 3 (Guest)', length: 11.0, width: 12.0),
          ReraRoomData(id: 'r15', name: 'Kitchen', length: 10.0, width: 11.0),
          ReraRoomData(id: 'r16', name: 'Dry Balcony (Wash Yard)', length: 7.0, width: 5.0, spaceType: RoomSpaceType.utilityOutside),
          ReraRoomData(id: 'r17', name: 'Deck Balcony', length: 14.0, width: 5.5, spaceType: RoomSpaceType.balcony),
          ReraRoomData(id: 'r18', name: 'Master Balcony', length: 10.0, width: 4.5, spaceType: RoomSpaceType.balcony),
          ReraRoomData(id: 'r19', name: 'Master Toilet', length: 5.5, width: 9.0),
          ReraRoomData(id: 'r20', name: 'Toilet 2', length: 5.0, width: 8.0),
          ReraRoomData(id: 'r21', name: 'Powder Room', length: 4.5, width: 5.0),
        ],
      ),
      BhkPreset(
        id: '1bhk_compact',
        title: '1 BHK Compact Flat',
        shortLabel: '1 BHK',
        description: 'Living, 1 Bedroom, Kitchen with Enclosed Utility, Balcony, Toilet',
        rooms: [
          ReraRoomData(id: 'r30', name: 'Living / Dining', length: 14.0, width: 10.5),
          ReraRoomData(id: 'r31', name: 'Bedroom', length: 11.0, width: 10.0),
          ReraRoomData(id: 'r32', name: 'Kitchen', length: 8.0, width: 7.5),
          ReraRoomData(id: 'r33', name: 'Enclosed Utility', length: 5.0, width: 4.0, spaceType: RoomSpaceType.utilityInside),
          ReraRoomData(id: 'r34', name: 'Balcony', length: 10.0, width: 4.0, spaceType: RoomSpaceType.balcony),
          ReraRoomData(id: 'r35', name: 'Bathroom / Toilet', length: 5.0, width: 7.0),
        ],
      ),
      BhkPreset(
        id: '4bhk_luxury',
        title: '4 BHK Luxury Penthouse',
        shortLabel: '4 BHK',
        description: 'Double Living, 4 Bedrooms, Wet/Dry Kitchen, Terrace, 4 Toilets',
        rooms: [
          ReraRoomData(id: 'r40', name: 'Formal Living', length: 22.0, width: 16.0),
          ReraRoomData(id: 'r41', name: 'Family Lounge', length: 15.0, width: 14.0),
          ReraRoomData(id: 'r42', name: 'Master Suite', length: 16.0, width: 18.0),
          ReraRoomData(id: 'r43', name: 'Bedroom 2', length: 14.0, width: 15.0),
          ReraRoomData(id: 'r44', name: 'Bedroom 3', length: 13.0, width: 14.0),
          ReraRoomData(id: 'r45', name: 'Bedroom 4 / Study', length: 12.0, width: 12.0),
          ReraRoomData(id: 'r46', name: 'Main Kitchen', length: 12.0, width: 14.0),
          ReraRoomData(id: 'r47', name: 'Utility & Scullery', length: 8.0, width: 6.0, spaceType: RoomSpaceType.utilityInside),
          ReraRoomData(id: 'r48', name: 'Outdoor Service Yard', length: 8.0, width: 5.0, spaceType: RoomSpaceType.utilityOutside),
          ReraRoomData(id: 'r49', name: 'Sky Terrace Balcony', length: 20.0, width: 8.0, spaceType: RoomSpaceType.balcony),
          ReraRoomData(id: 'r50', name: 'Master Bath', length: 8.0, width: 12.0),
          ReraRoomData(id: 'r51', name: 'Toilet 2', length: 6.0, width: 9.0),
          ReraRoomData(id: 'r52', name: 'Toilet 3', length: 5.5, width: 8.5),
          ReraRoomData(id: 'r53', name: 'Powder Room', length: 5.0, width: 5.5),
        ],
      ),
    ];
  }
}

