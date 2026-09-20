import 'package:flutter/material.dart';
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
