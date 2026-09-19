part of 'main.dart';

class ScanRoomDetailsCard extends StatelessWidget {
  final AreaDisplayUnit? displayUnit;
  final RoomData room;
  final VoidCallback onEdit, onConfirm, onDelete;
  const ScanRoomDetailsCard({
    super.key,
    this.displayUnit,
    required this.room,
    required this.onEdit,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasMeasurements = room.hasMeasurements;
    final confirmed = room.isUserVerified && hasMeasurements;
    final status = confirmed
        ? 'Confirmed'
        : hasMeasurements
        ? 'Review'
        : 'Needs measurement';
    final color = confirmed
        ? const Color(0xFF16805D)
        : hasMeasurements
        ? const Color(0xFFAC720A)
        : AppColors.secondaryText;
    final name = room.name.toLowerCase();
    final icon = name.contains('bed')
        ? Icons.bed_outlined
        : name.contains('bath') || name.contains('toilet')
        ? Icons.bathtub_outlined
        : name.contains('balcon')
        ? Icons.balcony_outlined
        : Icons.weekend_outlined;
    String dimension(double meters) =>
        (displayUnit?.dimensionUnit ?? room.unit) == DimensionUnit.meterCm
        ? '${DimensionParser.format(meters)} m'
        : DimensionParser.formatFeetInches(meters);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        if (hasMeasurements) ...[
                          Text(
                            (displayUnit ?? AreaDisplayUnit.imperial)
                                .formatArea(
                                  DimensionParser.squareMetersToSquareFeet(
                                    room.lengthMeters * room.widthMeters,
                                  ),
                                ),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          Text(
                            '(${dimension(room.lengthMeters)} × ${dimension(room.widthMeters)})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ] else
                          const Text(
                            'Add length and width',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Room options',
                    icon: const Icon(
                      Icons.more_vert,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    onSelected: (action) =>
                        action == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit room')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove room'),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasMeasurements && !confirmed) ...[
                const SizedBox(height: 7),
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('Confirm room'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
