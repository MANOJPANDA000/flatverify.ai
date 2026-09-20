/// RERA Space classification relative to the flat's outer perimeter walls
enum RoomSpaceType {
  /// Enclosed interior living space (Living, Bed, Kitchen, Bath, Pooja, Study)
  livingEnclosed,

  /// Utility / washing space INSIDE the continuous external perimeter wall
  utilityInside,

  /// Dry balcony / wash yard cantilevered OUTSIDE the external perimeter wall
  utilityOutside,

  /// Attached balcony, verandah, sit-out, deck, or open terrace
  balcony,
}

enum DimensionUnit {
  meters,
  feet,
}

enum AreaDisplayUnit {
  sqFt,
  sqMeters,
}

class RoomData {
  final String id;
  String name;
  double length;
  double width;
  DimensionUnit unit;
  RoomSpaceType spaceType;
  bool isUserVerified;

  RoomData({
    required this.id,
    required this.name,
    required this.length,
    required this.width,
    this.unit = DimensionUnit.feet,
    RoomSpaceType? spaceType,
    this.isUserVerified = false,
  }) : spaceType = spaceType ?? inferRoomSpaceType(name);

  double get lengthMeters =>
      unit == DimensionUnit.meters ? length : length * 0.3048;

  double get widthMeters =>
      unit == DimensionUnit.meters ? width : width * 0.3048;

  double get areaSqMeters => lengthMeters * widthMeters;

  double get areaSqFt => areaSqMeters * 10.7639104;

  RoomData copyWith({
    String? name,
    double? length,
    double? width,
    DimensionUnit? unit,
    RoomSpaceType? spaceType,
    bool? isUserVerified,
  }) {
    return RoomData(
      id: id,
      name: name ?? this.name,
      length: length ?? this.length,
      width: width ?? this.width,
      unit: unit ?? this.unit,
      spaceType: spaceType ?? this.spaceType,
      isUserVerified: isUserVerified ?? this.isUserVerified,
    );
  }

  static RoomSpaceType inferRoomSpaceType(String name) {
    final lower = name.toLowerCase().trim();

    if (lower.contains('dry') ||
        lower.contains('dry balcony') ||
        lower.contains('service balcony') ||
        lower.contains('wash yard') ||
        lower.contains('yard')) {
      return RoomSpaceType.utilityOutside;
    }

    if (lower.contains('utility') ||
        lower.contains('wash') ||
        lower.contains('scullery') ||
        lower.contains('laundry')) {
      return RoomSpaceType.utilityInside;
    }

    if (lower.contains('balcony') ||
        lower.contains('balc') ||
        lower.contains('verandah') ||
        lower.contains('veranda') ||
        lower.contains('sitout') ||
        lower.contains('deck') ||
        lower.contains('terrace') ||
        lower.contains('foyer open')) {
      return RoomSpaceType.balcony;
    }

    return RoomSpaceType.livingEnclosed;
  }
}
