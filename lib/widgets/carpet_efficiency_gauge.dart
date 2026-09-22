import 'package:flutter/material.dart';

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
      comment =
          'Optimal balance between personal flat space and common amenities.';
    } else if (efficiencyPercent >= 62) {
      color = const Color(0xFFD97706);
      rating = 'Moderate';
      comment =
          'Significant area consumed by building amenities & circulation.';
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
            color: Colors.black.withValues(alpha: 0.02),
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
