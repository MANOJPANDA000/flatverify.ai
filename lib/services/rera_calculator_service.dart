import '../models/rera_room_model.dart';

class ReraAuditCalculation {
  final double internalLivingSqFt;
  final double utilityInsideSqFt;
  final double utilityOutsideSqFt;
  final double balconySqFt;

  final double internalWallPercent;
  final double externalWallPercent;
  final double loadingPercent;

  final double internalWallAreaSqFt;
  final double externalWallAreaSqFt;
  final double loadingAreaSqFt;

  final double internalUsableSqFt;
  final double reraCarpetAreaSqFt;
  final double totalExclusiveOutdoorSqFt;
  final double builtUpAreaSqFt;
  final double superBuiltUpAreaSqFt;

  /// Carpet-to-Super-Built-Up Efficiency Ratio (%)
  double get efficiencyRatioPercent => superBuiltUpAreaSqFt > 0
      ? (reraCarpetAreaSqFt / superBuiltUpAreaSqFt) * 100
      : 0;

  ReraAuditCalculation({
    required this.internalLivingSqFt,
    required this.utilityInsideSqFt,
    required this.utilityOutsideSqFt,
    required this.balconySqFt,
    required this.internalWallPercent,
    required this.externalWallPercent,
    required this.loadingPercent,
    required this.internalWallAreaSqFt,
    required this.externalWallAreaSqFt,
    required this.loadingAreaSqFt,
    required this.internalUsableSqFt,
    required this.reraCarpetAreaSqFt,
    required this.totalExclusiveOutdoorSqFt,
    required this.builtUpAreaSqFt,
    required this.superBuiltUpAreaSqFt,
  });

  static ReraAuditCalculation compute({
    required List<ReraRoomData> rooms,
    double internalWallPercent = 3.5,
    double externalWallPercent = 6.5,
    double loadingPercent = 25.0,
  }) {
    double living = 0;
    double utilIn = 0;
    double utilOut = 0;
    double balc = 0;

    for (final r in rooms) {
      final sqFt = r.areaSqFt;
      switch (r.spaceType) {
        case RoomSpaceType.livingEnclosed:
          living += sqFt;
          break;
        case RoomSpaceType.utilityInside:
          utilIn += sqFt;
          break;
        case RoomSpaceType.utilityOutside:
          utilOut += sqFt;
          break;
        case RoomSpaceType.balcony:
          balc += sqFt;
          break;
      }
    }

    final internalUsable = living + utilIn;
    final exclusiveOutdoor = balc + utilOut;

    final internalWallArea = internalUsable * (internalWallPercent / 100.0);
    final externalWallArea = internalUsable * (externalWallPercent / 100.0);

    final carpetArea = internalUsable + internalWallArea;
    final builtUpArea = carpetArea + externalWallArea + exclusiveOutdoor;
    final loadingArea = builtUpArea * (loadingPercent / 100.0);
    final superBuiltUp = builtUpArea + loadingArea;

    return ReraAuditCalculation(
      internalLivingSqFt: living,
      utilityInsideSqFt: utilIn,
      utilityOutsideSqFt: utilOut,
      balconySqFt: balc,
      internalWallPercent: internalWallPercent,
      externalWallPercent: externalWallPercent,
      loadingPercent: loadingPercent,
      internalWallAreaSqFt: internalWallArea,
      externalWallAreaSqFt: externalWallArea,
      loadingAreaSqFt: loadingArea,
      internalUsableSqFt: internalUsable,
      reraCarpetAreaSqFt: carpetArea,
      totalExclusiveOutdoorSqFt: exclusiveOutdoor,
      builtUpAreaSqFt: builtUpArea,
      superBuiltUpAreaSqFt: superBuiltUp,
    );
  }

  static String formatArea(double sqFt, ReraAreaDisplayUnit unit) {
    if (unit == ReraAreaDisplayUnit.sqMeters) {
      final sqM = sqFt / 10.7639104;
      return '${sqM.toStringAsFixed(1)} sq m';
    }
    return '${sqFt.toStringAsFixed(1)} sq ft';
  }
}
