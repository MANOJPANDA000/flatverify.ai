import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class ReraResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double valueSqFt;
  final IconData icon;
  final ReraAreaDisplayUnit displayUnit;
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
    this.displayUnit = ReraAreaDisplayUnit.sqFt,
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

