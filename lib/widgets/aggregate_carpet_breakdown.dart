import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class AggregateCarpetBreakdownCard extends StatelessWidget {
  final List<ReraRoomData> rooms;
  final ReraAreaDisplayUnit displayUnit;

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
      } else if (lower.contains('toilet') ||
          lower.contains('bath') ||
          lower.contains('powder') ||
          lower.contains('wc')) {
        toiletsSqFt += sqFt;
      } else {
        livingBedSqFt += sqFt;
      }
    }

    final totalSqFt =
        livingBedSqFt +
        toiletsSqFt +
        utilityInsideSqFt +
        utilityOutsideSqFt +
        balconiesSqFt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          _itemRow(
            'Habitable Living & Bedrooms',
            livingBedSqFt,
            totalSqFt,
            const Color(0xFF2563EB),
          ),
          _itemRow(
            'Toilets & Bathrooms',
            toiletsSqFt,
            totalSqFt,
            const Color(0xFF0284C7),
          ),
          _itemRow(
            'Enclosed Utility (Inside Wall)',
            utilityInsideSqFt,
            totalSqFt,
            const Color(0xFF059669),
          ),
          _itemRow(
            'Exclusive Balconies',
            balconiesSqFt,
            totalSqFt,
            const Color(0xFFD97706),
          ),
          _itemRow(
            'Dry Balconies (Outside Wall)',
            utilityOutsideSqFt,
            totalSqFt,
            const Color(0xFFEA580C),
          ),
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${ReraAuditCalculation.formatArea(sqFt, displayUnit)} (${pct.toStringAsFixed(1)}%)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
