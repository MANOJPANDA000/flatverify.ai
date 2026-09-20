import os
import zipfile

base_dir = "flutter_rera_calculator"

files = {
    "pubspec.yaml": """name: flutter_rera_calculator
description: "Mobile-First RERA Carpet Area & Statutory Audit App in Flutter"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
""",

    "README.md": """# Mobile-First RERA Carpet & Built-up Area Audit App (Flutter)

A 100% mobile-optimized Flutter application designed specifically for Android and iOS devices. Complies strictly with **Section 2(k) of the Real Estate (Regulation & Development) Act, 2016**.

## 📱 Mobile Architecture
- **Bottom Navigation Bar**: 4 dedicated mobile tabs:
  1. 🧮 **Calculator**: Room-by-room area builder, 1-tap BHK presets, live Carpet & Built-up area metrics, thumb-friendly FAB.
  2. 📊 **Efficiency**: Visual carpet efficiency gauge, space breakdown charts, wall & common loading sliders.
  3. 📜 **RERA Rules**: Mobile-friendly 4-part statutory law guide (Section 2(k), Balcony laws, Utility outer wall rulings, Buyer safeguards).
  4. 🏆 **Certificate**: Official RERA Area Audit Certificate and printable compliance summary.
- **Mobile Touch Controls**:
  - Add / Edit rooms via bottom sheets with numeric keypads (`keyboardType: TextInputType.numberWithOptions(decimal: true)`).
  - Quick-preset chips for room names ("Living", "Master Bed", "Kitchen", "Utility", "Balcony").
  - Segmented toggle chips for Utility location (Inside Outer Wall vs Outside Dry Balcony).
  - Unit toggle pill in the app bar (`sq ft` / `sq m`).

## 🚀 Quick Start
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on your Android / iOS phone or emulator
flutter run
```
""",

    "lib/models/rera_room_model.dart": """/// RERA Space classification relative to the flat's outer perimeter walls
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
""",

    "lib/data/bhk_presets.dart": """import '../models/rera_room_model.dart';

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
""",

    "lib/services/rera_calculator_service.dart": """import '../models/rera_room_model.dart';

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
  double get efficiencyRatioPercent =>
      superBuiltUpAreaSqFt > 0 ? (reraCarpetAreaSqFt / superBuiltUpAreaSqFt) * 100 : 0;

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
    required List<RoomData> rooms,
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

  static String formatArea(double sqFt, AreaDisplayUnit unit) {
    if (unit == AreaDisplayUnit.sqMeters) {
      final sqM = sqFt / 10.7639104;
      return '${sqM.toStringAsFixed(1)} sq m';
    }
    return '${sqFt.toStringAsFixed(1)} sq ft';
  }
}
""",

    "lib/widgets/carpet_efficiency_gauge.dart": """import 'package:flutter/material.dart';

class CarpetEfficiencyGauge extends StatelessWidget {
  final double efficiencyPercent;
  final double carpetSqFt;
  final double superBuiltUpSqFt;

  const CarpetEfficiencyGauge({
    super.key,
    required this.efficiencyPercent,
    required this.carpetSqFt,
    required this.superBuiltUpSqFt,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String rating;
    String comment;

    if (efficiencyPercent >= 75) {
      color = const Color(0xFF16A34A);
      rating = 'Exceptional';
      comment = 'High carpet efficiency with minimal common loading loss.';
    } else if (efficiencyPercent >= 68) {
      color = const Color(0xFF2563EB);
      rating = 'Good Standard';
      comment = 'Optimal balance between personal flat space and common amenities.';
    } else if (efficiencyPercent >= 62) {
      color = const Color(0xFFD97706);
      rating = 'Moderate';
      comment = 'Significant area consumed by building amenities & circulation.';
    } else {
      color = const Color(0xFFDC2626);
      rating = 'Heavy Loading';
      comment = 'High loading ratio (>35%). Verify common amenity disclosures.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Carpet Efficiency Ratio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rating (${efficiencyPercent.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (efficiencyPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
""",

    "lib/widgets/wall_thickness_slider.dart": """import 'package:flutter/material.dart';

class WallThicknessSliderCard extends StatelessWidget {
  final double internalWallPercent;
  final double externalWallPercent;
  final double loadingPercent;
  final ValueChanged<double> onInternalChange;
  final ValueChanged<double> onExternalChange;
  final ValueChanged<double> onLoadingChange;

  const WallThicknessSliderCard({
    super.key,
    required this.internalWallPercent,
    required this.externalWallPercent,
    required this.loadingPercent,
    required this.onInternalChange,
    required this.onExternalChange,
    required this.onLoadingChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Wall & Loading Factors',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RERA Norms',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Internal Partition Wall Slider
          _sliderRow(
            title: 'Internal Partition Walls',
            description: 'Included in Carpet Area per Sec 2(k)',
            value: internalWallPercent,
            min: 2.0,
            max: 6.0,
            unit: '%',
            onChanged: onInternalChange,
          ),
          const SizedBox(height: 10),

          // External Boundary Wall Slider
          _sliderRow(
            title: 'External Perimeter Walls',
            description: 'Built-up only; excluded from Carpet',
            value: externalWallPercent,
            min: 4.0,
            max: 10.0,
            unit: '%',
            onChanged: onExternalChange,
          ),
          const SizedBox(height: 10),

          // Common Loading Slider
          _sliderRow(
            title: 'Common Loading',
            description: 'Lobbies, stairwells, lifts & amenities',
            value: loadingPercent,
            min: 15.0,
            max: 40.0,
            unit: '%',
            onChanged: onLoadingChange,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String title,
    required String description,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: const Color(0xFF2563EB),
          inactiveColor: const Color(0xFFE2E8F0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
""",

    "lib/widgets/aggregate_carpet_breakdown.dart": """import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class AggregateCarpetBreakdownCard extends StatelessWidget {
  final List<RoomData> rooms;
  final AreaDisplayUnit displayUnit;

  const AggregateCarpetBreakdownCard({
    super.key,
    required this.rooms,
    required this.displayUnit,
  });

  @override
  Widget build(BuildContext context) {
    double livingBedSqFt = 0;
    double toiletsSqFt = 0;
    double utilityInsideSqFt = 0;
    double utilityOutsideSqFt = 0;
    double balconiesSqFt = 0;

    for (final r in rooms) {
      final lower = r.name.toLowerCase();
      final sqFt = r.areaSqFt;

      if (r.spaceType == RoomSpaceType.balcony) {
        balconiesSqFt += sqFt;
      } else if (r.spaceType == RoomSpaceType.utilityOutside) {
        utilityOutsideSqFt += sqFt;
      } else if (r.spaceType == RoomSpaceType.utilityInside) {
        utilityInsideSqFt += sqFt;
      } else if (lower.contains('toilet') || lower.contains('bath') || lower.contains('powder') || lower.contains('wc')) {
        toiletsSqFt += sqFt;
      } else {
        livingBedSqFt += sqFt;
      }
    }

    final totalSqFt = livingBedSqFt + toiletsSqFt + utilityInsideSqFt + utilityOutsideSqFt + balconiesSqFt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Space Categorization Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _itemRow('Habitable Living & Bedrooms', livingBedSqFt, totalSqFt, const Color(0xFF2563EB)),
          _itemRow('Toilets & Bathrooms', toiletsSqFt, totalSqFt, const Color(0xFF0284C7)),
          _itemRow('Enclosed Utility (Inside Wall)', utilityInsideSqFt, totalSqFt, const Color(0xFF059669)),
          _itemRow('Exclusive Balconies', balconiesSqFt, totalSqFt, const Color(0xFFD97706)),
          _itemRow('Dry Balconies (Outside Wall)', utilityOutsideSqFt, totalSqFt, const Color(0xFFEA580C)),
        ],
      ),
    );
  }

  Widget _itemRow(String title, double sqFt, double totalSqFt, Color color) {
    final pct = totalSqFt > 0 ? (sqFt / totalSqFt) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${ReraAuditCalculation.formatArea(sqFt, displayUnit)} (${pct.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
""",

    "lib/widgets/rera_result_card.dart": """import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class ReraResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double valueSqFt;
  final IconData icon;
  final AreaDisplayUnit displayUnit;
  final bool isHighlighted;
  final String? badge;
  final Color? accentColor;
  final String? tooltipText;
  final VoidCallback? onInfoTap;

  const ReraResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.valueSqFt,
    required this.icon,
    this.displayUnit = AreaDisplayUnit.sqFt,
    this.isHighlighted = false,
    this.badge,
    this.accentColor,
    this.tooltipText,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ??
        (isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF475569));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: effectiveColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: effectiveColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ReraAuditCalculation.formatArea(valueSqFt, displayUnit),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
""",

    "lib/widgets/rera_room_card.dart": """import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class ReraRoomCard extends StatelessWidget {
  final RoomData room;
  final AreaDisplayUnit displayUnit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<RoomSpaceType> onSpaceTypeChanged;

  const ReraRoomCard({
    super.key,
    required this.room,
    required this.displayUnit,
    required this.onEdit,
    required this.onDelete,
    required this.onSpaceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lowerName = room.name.toLowerCase();
    final isUtility = lowerName.contains('utility') ||
        lowerName.contains('wash') ||
        lowerName.contains('dry') ||
        lowerName.contains('yard');

    final isBalcony = !isUtility &&
        (lowerName.contains('balcony') ||
            lowerName.contains('balc') ||
            lowerName.contains('verandah') ||
            lowerName.contains('deck') ||
            lowerName.contains('terrace'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildClassificationBadge(),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${room.length} × ${room.width} ${room.unit == DimensionUnit.feet ? 'ft' : 'm'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ReraAuditCalculation.formatArea(room.areaSqFt, displayUnit),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (isUtility) ...[
            const SizedBox(height: 8),
            _buildUtilityPositionSelector(),
          ] else if (isBalcony) ...[
            const SizedBox(height: 6),
            _buildBalconyNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildClassificationBadge() {
    switch (room.spaceType) {
      case RoomSpaceType.utilityInside:
        return _badge('In Carpet ✓', const Color(0xFF059669));
      case RoomSpaceType.utilityOutside:
        return _badge('Built-up Only', Colors.amber.shade800);
      case RoomSpaceType.balcony:
        return _badge('Balcony (Built-up)', Colors.amber.shade800);
      case RoomSpaceType.livingEnclosed:
        return _badge('Carpet Area', const Color(0xFF2563EB));
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUtilityPositionSelector() {
    final isInside = room.spaceType == RoomSpaceType.utilityInside;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wall Placement:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0369A1),
                ),
              ),
              Row(
                children: [
                  _choiceButton(
                    label: 'Inside (Carpet)',
                    selected: isInside,
                    onTap: () => onSpaceTypeChanged(RoomSpaceType.utilityInside),
                  ),
                  const SizedBox(width: 4),
                  _choiceButton(
                    label: 'Outside (Dry Balcony)',
                    selected: !isInside,
                    onTap: () => onSpaceTypeChanged(RoomSpaceType.utilityOutside),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            isInside
                ? '✓ Counted in RERA Carpet Area'
                : '✓ Excluded from Carpet, in Built-up only',
            style: TextStyle(
              fontSize: 9.5,
              color: isInside ? const Color(0xFF047857) : const Color(0xFFB45309),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBalconyNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Excluded from Carpet per Sec 2(k); included in Built-up Area.',
        style: TextStyle(fontSize: 9.5, color: Color(0xFF92400E)),
      ),
    );
  }
}
""",

    "lib/dialogs/rera_definitions_sheet.dart": """import 'package:flutter/material.dart';

class ReraDefinitionsSheet extends StatefulWidget {
  final int initialTabIndex;

  const ReraDefinitionsSheet({super.key, this.initialTabIndex = 0});

  static void show(BuildContext context, {int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReraDefinitionsSheet(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<ReraDefinitionsSheet> createState() => _ReraDefinitionsSheetState();
}

class _ReraDefinitionsSheetState extends State<ReraDefinitionsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'RERA Area Rules (Sec 2(k))',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            indicatorColor: const Color(0xFF2563EB),
            tabs: const [
              Tab(text: 'Carpet vs Built-up'),
              Tab(text: 'Balconies'),
              Tab(text: 'Utility Inside/Out'),
              Tab(text: 'Buyer Safeguards'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComparisonTab(),
                _buildBalconyTab(),
                _buildUtilityTab(),
                _buildSafeguardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Text(
            '“Carpet area means the net usable floor area of an apartment, excluding the area covered by external walls, areas under service shafts, exclusive balcony or verandah, but includes area covered by internal partition walls.”\\n— RERA Act 2016, Sec 2(k)',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E3A8A),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _categoryBox(
          title: 'RERA Carpet Area',
          subtitle: 'Mandatory pricing baseline under law',
          color: const Color(0xFF059669),
          inclusions: [
            'All interior bedrooms, living room, study',
            'Kitchen, bathrooms, toilets, washrooms',
            'Utility area INSIDE continuous external wall',
            'Internal partition walls between rooms',
          ],
          exclusions: [
            'Balconies, verandahs, and open terraces',
            'External facade / boundary walls',
            'Dry balconies outside external perimeter wall',
            'Common shafts, lift wells, and lobbies',
          ],
        ),
        const SizedBox(height: 12),
        _categoryBox(
          title: 'Built-Up Area (Plinth Area)',
          subtitle: 'Total physical structure footprint',
          color: const Color(0xFF2563EB),
          inclusions: [
            'Everything included in RERA Carpet Area',
            'External perimeter walls (100% or 50% shared)',
            'All exclusive balconies and attached verandahs',
            'Dry balconies & outdoor service projections',
          ],
          exclusions: [
            'Common staircase landings, lift lobbies',
            'Clubhouse, security room, shared amenities',
          ],
        ),
      ],
    );
  }

  Widget _categoryBox({
    required String title,
    required String subtitle,
    required Color color,
    required List<String> inclusions,
    required List<String> exclusions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'INCLUDED:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
            ),
          ),
          ...inclusions.map((item) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓ ',
                        style: TextStyle(
                            color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          const Text(
            'STRICTLY EXCLUDED:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.redAccent,
            ),
          ),
          ...exclusions.map((item) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✗ ',
                        style: TextStyle(
                            color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBalconyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard(
          title: 'The Balcony Ruling',
          content:
              'Under RERA Section 2(k), exclusive balconies and verandahs are EXCLUDED from Carpet Area. Builders cannot sell or price an apartment quoting a single combined area figure without explicitly stating the separate Carpet Area and Balcony Area.',
          icon: Icons.balcony_outlined,
          color: const Color(0xFFD97706),
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Enclosing or Glazing a Balcony',
          content:
              'Even if a balcony is covered with sliding glass windows or fully enclosed by the builder, statutory RERA appellate rulings state that it remains classified as an Exclusive Balcony and cannot be added into the RERA Carpet Area.',
          icon: Icons.window_outlined,
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildUtilityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard(
          title: 'Utility Inside Outer Wall',
          content:
              'When the utility or washing area sits INSIDE the main external perimeter wall of the apartment, it is legally part of the net usable floor area and IS COUNTED in RERA Carpet Area.',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Dry Balcony Outside Outer Wall',
          content:
              'When the washing yard or utility space projects OUTSIDE the flat\'s continuous external perimeter wall, it is classified as a Dry Balcony. It is EXCLUDED from Carpet Area and included in Built-up Area only.',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildSafeguardsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoCard(
          title: 'Mandatory Disclosure (Section 4)',
          content:
              'Promoters must register the project on the state RERA portal with verified architectural sanction drawings and explicitly state the RERA Carpet Area of every apartment type.',
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Refund for Area Discrepancy (Section 14)',
          content:
              'If the actual carpet area upon possession is less than the agreement, the promoter must refund the excess amount with interest within 45 days.',
          icon: Icons.currency_rupee_rounded,
          color: const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
""",

    "lib/dialogs/pdf_audit_preview_dialog.dart": """import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class PdfAuditPreviewDialog extends StatelessWidget {
  final List<RoomData> rooms;
  final ReraAuditCalculation audit;
  final AreaDisplayUnit displayUnit;
  final String propertyTitle;

  const PdfAuditPreviewDialog({
    super.key,
    required this.rooms,
    required this.audit,
    required this.displayUnit,
    this.propertyTitle = 'Residential Apartment Audit',
  });

  static void show(
    BuildContext context, {
    required List<RoomData> rooms,
    required ReraAuditCalculation audit,
    required AreaDisplayUnit displayUnit,
    String propertyTitle = 'Residential Apartment Audit',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: PdfAuditPreviewDialog(
          rooms: rooms,
          audit: audit,
          displayUnit: displayUnit,
          propertyTitle: propertyTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Statutory Audit Certificate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RERA Compliance Certificate • Act Section 2(k)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _summaryRow('RERA Carpet Area', ReraAuditCalculation.formatArea(audit.reraCarpetAreaSqFt, displayUnit), isBold: true, color: const Color(0xFF2563EB)),
                    _summaryRow('Exclusive Balconies', ReraAuditCalculation.formatArea(audit.balconySqFt, displayUnit)),
                    _summaryRow('Dry Balconies (Outside)', ReraAuditCalculation.formatArea(audit.utilityOutsideSqFt, displayUnit)),
                    _summaryRow('Built-Up (Plinth) Area', ReraAuditCalculation.formatArea(audit.builtUpAreaSqFt, displayUnit), isBold: true),
                    _summaryRow('Super Built-Up Area', ReraAuditCalculation.formatArea(audit.superBuiltUpAreaSqFt, displayUnit), isBold: true, color: const Color(0xFF7C3AED)),
                    _summaryRow('Carpet Efficiency Ratio', '${audit.efficiencyRatioPercent.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Room Space Schedule',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              ...rooms.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${r.length}×${r.width} (${ReraAuditCalculation.formatArea(r.areaSqFt, displayUnit)})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
""",

    "lib/screens/mobile_main_screen.dart": """import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';
import '../data/bhk_presets.dart';
import '../widgets/rera_result_card.dart';
import '../widgets/rera_room_card.dart';
import '../widgets/carpet_efficiency_gauge.dart';
import '../widgets/wall_thickness_slider.dart';
import '../widgets/aggregate_carpet_breakdown.dart';
import '../dialogs/rera_definitions_sheet.dart';
import '../dialogs/pdf_audit_preview_dialog.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentTabIndex = 0;
  AreaDisplayUnit _displayUnit = AreaDisplayUnit.sqFt;
  String _propertyTitle = 'Modern 2BHK Apartment';
  double _internalWallPercent = 3.5;
  double _externalWallPercent = 6.5;
  double _loadingPercent = 25.0;
  String _selectedPresetId = '2bhk_standard';

  late List<RoomData> _rooms;

  @override
  void initState() {
    super.initState();
    _rooms = BhkPresetData.getPresets().first.rooms;
  }

  ReraAuditCalculation get _audit => ReraAuditCalculation.compute(
        rooms: _rooms,
        internalWallPercent: _internalWallPercent,
        externalWallPercent: _externalWallPercent,
        loadingPercent: _loadingPercent,
      );

  @override
  Widget build(BuildContext context) {
    final audit = _audit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RERA Area Audit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Section 2(k) Compliance',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Unit switch button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _displayUnit = _displayUnit == AreaDisplayUnit.sqFt
                      ? AreaDisplayUnit.sqMeters
                      : AreaDisplayUnit.sqFt;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _displayUnit == AreaDisplayUnit.sqFt
                          ? Icons.square_foot_rounded
                          : Icons.straighten_rounded,
                      size: 14,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayUnit == AreaDisplayUnit.sqFt ? 'sq ft' : 'sq m',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
            onPressed: () => ReraDefinitionsSheet.show(context),
            tooltip: 'RERA Rules',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildCalculatorTab(audit),
          _buildAnalysisTab(audit),
          _buildRulesTab(),
          _buildCertificateTab(audit),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        backgroundColor: Colors.white,
        elevation: 2,
        height: 62,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: Color(0xFF2563EB)),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF2563EB)),
            label: 'Efficiency',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel, color: Color(0xFF2563EB)),
            label: 'RERA Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified, color: Color(0xFF2563EB)),
            label: 'Certificate',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddRoomBottomSheet,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Room',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            )
          : null,
    );
  }

  // --- TAB 1: CALCULATOR ---
  Widget _buildCalculatorTab(ReraAuditCalculation audit) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      children: [
        // BHK Presets (Horizontal Scroll)
        _buildBhkPresetChips(),
        const SizedBox(height: 12),

        // Live Area Hero Summary Card
        _buildHeroSummaryCard(audit),
        const SizedBox(height: 14),

        // Result Metrics Grid
        ReraResultCard(
          title: 'Built-Up (Plinth) Area',
          subtitle: 'Carpet + External Walls + Balconies',
          valueSqFt: audit.builtUpAreaSqFt,
          icon: Icons.home_work_outlined,
          displayUnit: _displayUnit,
          accentColor: const Color(0xFF475569),
        ),
        ReraResultCard(
          title: 'Super Built-Up Area',
          subtitle: 'Built-up + ${_loadingPercent.toStringAsFixed(0)}% Common Loading',
          valueSqFt: audit.superBuiltUpAreaSqFt,
          icon: Icons.layers_outlined,
          displayUnit: _displayUnit,
          accentColor: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 10),

        // Rooms Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rooms & Spaces (${_rooms.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Net: ${ReraAuditCalculation.formatArea(audit.internalUsableSqFt, _displayUnit)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List of Room Cards
        ..._rooms.asMap().entries.map((entry) {
          final idx = entry.key;
          final room = entry.value;
          return ReraRoomCard(
            room: room,
            displayUnit: _displayUnit,
            onEdit: () => _showEditRoomBottomSheet(idx),
            onDelete: () {
              if (_rooms.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('At least 1 room is required.')),
                );
                return;
              }
              setState(() => _rooms.removeAt(idx));
            },
            onSpaceTypeChanged: (newType) {
              setState(() {
                _rooms[idx] = room.copyWith(spaceType: newType);
              });
            },
          );
        }),
      ],
    );
  }

  // --- TAB 2: EFFICIENCY & ANALYSIS ---
  Widget _buildAnalysisTab(ReraAuditCalculation audit) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        CarpetEfficiencyGauge(
          efficiencyPercent: audit.efficiencyRatioPercent,
          carpetSqFt: audit.reraCarpetAreaSqFt,
          superBuiltUpSqFt: audit.superBuiltUpAreaSqFt,
        ),
        const SizedBox(height: 14),
        AggregateCarpetBreakdownCard(
          rooms: _rooms,
          displayUnit: _displayUnit,
        ),
        const SizedBox(height: 14),
        WallThicknessSliderCard(
          internalWallPercent: _internalWallPercent,
          externalWallPercent: _externalWallPercent,
          loadingPercent: _loadingPercent,
          onInternalChange: (val) => setState(() => _internalWallPercent = val),
          onExternalChange: (val) => setState(() => _externalWallPercent = val),
          onLoadingChange: (val) => setState(() => _loadingPercent = val),
        ),
      ],
    );
  }

  // --- TAB 3: RERA RULES GUIDE ---
  Widget _buildRulesTab() {
    return const ReraDefinitionsSheet(initialTabIndex: 0);
  }

  // --- TAB 4: AUDIT CERTIFICATE ---
  Widget _buildCertificateTab(ReraAuditCalculation audit) {
    return PdfAuditPreviewDialog(
      rooms: _rooms,
      audit: audit,
      displayUnit: _displayUnit,
      propertyTitle: _propertyTitle,
    );
  }

  // --- WIDGETS ---
  Widget _buildBhkPresetChips() {
    final presets = BhkPresetData.getPresets();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final isSelected = preset.id == _selectedPresetId;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                preset.shortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPresetId = preset.id;
                    _propertyTitle = preset.title;
                    _rooms = preset.rooms.map((r) => r.copyWith()).toList();
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSummaryCard(ReraAuditCalculation audit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'RERA CARPET AREA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sec 2(k) Standard',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ReraAuditCalculation.formatArea(audit.reraCarpetAreaSqFt, _displayUnit),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Formula: Net Usable Floor Area + Internal Partition Walls',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroSubStat('Exclusive Balconies', audit.balconySqFt),
              _heroSubStat('Dry Balcony (Outside)', audit.utilityOutsideSqFt),
              _heroSubStat('Internal Walls', audit.internalWallAreaSqFt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSubStat(String label, double sqFt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          ReraAuditCalculation.formatArea(sqFt, _displayUnit),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  // --- ADD / EDIT BOTTOM SHEET ---
  void _showAddRoomBottomSheet() {
    _showRoomFormBottomSheet(
      title: 'Add New Room / Space',
      initialName: 'Bedroom',
      initialLength: 12.0,
      initialWidth: 10.0,
      initialSpaceType: RoomSpaceType.livingEnclosed,
      onSave: (name, length, width, spaceType) {
        setState(() {
          _rooms.add(RoomData(
            id: 'room_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            length: length,
            width: width,
            spaceType: spaceType,
          ));
        });
      },
    );
  }

  void _showEditRoomBottomSheet(int index) {
    final room = _rooms[index];
    _showRoomFormBottomSheet(
      title: 'Edit ${room.name}',
      initialName: room.name,
      initialLength: room.length,
      initialWidth: room.width,
      initialSpaceType: room.spaceType,
      onSave: (name, length, width, spaceType) {
        setState(() {
          _rooms[index] = room.copyWith(
            name: name,
            length: length,
            width: width,
            spaceType: spaceType,
          );
        });
      },
    );
  }

  void _showRoomFormBottomSheet({
    required String title,
    required String initialName,
    required double initialLength,
    required double initialWidth,
    required RoomSpaceType initialSpaceType,
    required Function(String name, double length, double width, RoomSpaceType spaceType) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final lengthCtrl = TextEditingController(text: initialLength.toString());
    final widthCtrl = TextEditingController(text: initialWidth.toString());
    RoomSpaceType selectedType = initialSpaceType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Living', 'Master Bed', 'Bed 2', 'Kitchen', 'Utility', 'Balcony', 'Toilet'].map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            nameCtrl.text = p;
                            selectedType = RoomData.inferRoomSpaceType(p);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Room / Space Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) {
                  setModalState(() {
                    selectedType = RoomData.inferRoomSpaceType(val);
                  });
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Length (ft)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Width (ft)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'RERA Space Classification:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _spaceTypeChip('Living / Bed / Bath (In Carpet)', RoomSpaceType.livingEnclosed, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Utility Inside Wall (In Carpet)', RoomSpaceType.utilityInside, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Dry Balcony (Built-up Only)', RoomSpaceType.utilityOutside, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Balcony / Terrace (Built-up)', RoomSpaceType.balcony, selectedType, (t) => setModalState(() => selectedType = t)),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final l = double.tryParse(lengthCtrl.text) ?? 10.0;
                    final w = double.tryParse(widthCtrl.text) ?? 10.0;
                    onSave(nameCtrl.text.trim().isEmpty ? 'Room' : nameCtrl.text.trim(), l, w, selectedType);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Space', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spaceTypeChip(String label, RoomSpaceType type, RoomSpaceType selectedType, ValueChanged<RoomSpaceType> onSelected) {
    final isSelected = type == selectedType;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (_) => onSelected(type),
    );
  }
}
""",

    "lib/screens/rera_calculator_screen.dart": """import 'package:flutter/material.dart';
import 'mobile_main_screen.dart';

/// Legacy alias routing directly into the mobile main screen
class ReraCalculatorScreen extends StatelessWidget {
  const ReraCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobileMainScreen();
  }
}
""",

    "lib/main.dart": """import 'package:flutter/material.dart';
import 'screens/mobile_main_screen.dart';

void main() {
  runApp(const ReraCalculatorApp());
}

class ReraCalculatorApp extends StatelessWidget {
  const ReraCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RERA Area Audit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
        ),
      ),
      home: const MobileMainScreen(),
    );
  }
}
""",
}

out_zip = "public/flutter_rera_calculator.zip"
os.makedirs(os.path.dirname(out_zip), exist_ok=True)

with zipfile.ZipFile(out_zip, "w", zipfile.ZIP_DEFLATED) as zf:
    for file_path, content in files.items():
        arcname = os.path.join(base_dir, file_path)
        zf.writestr(arcname, content)

print(f"Successfully generated mobile-first zip at {out_zip} with {len(files)} files.")
