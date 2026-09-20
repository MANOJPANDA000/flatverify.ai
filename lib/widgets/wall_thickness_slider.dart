import 'package:flutter/material.dart';

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
