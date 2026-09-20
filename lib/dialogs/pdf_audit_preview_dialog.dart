import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';

class PdfAuditPreviewDialog extends StatelessWidget {
  final List<ReraRoomData> rooms;
  final ReraAuditCalculation audit;
  final ReraAreaDisplayUnit displayUnit;
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
    required List<ReraRoomData> rooms,
    required ReraAuditCalculation audit,
    required ReraAreaDisplayUnit displayUnit,
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
                      'RERA Compliance Certificate â€¢ Act Section 2(k)',
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
                          '${r.length}Ã—${r.width} (${ReraAuditCalculation.formatArea(r.areaSqFt, displayUnit)})',
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

