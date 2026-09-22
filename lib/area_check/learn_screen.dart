import 'package:flutter/material.dart';
import 'area_check_model.dart';
import 'check_ui.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String search = '';
  static const topics = <String, String>{
    'Net usable area':
        'Add indoor floor spaces and passages. Measure between finished wall faces. Keep each space separate so you can check your arithmetic.',
    'Estimated RERA Carpet Area':
        'This calculator adds usable indoor area and internal partition footprints. It excludes external walls, service shafts, common areas, exclusive balconies and exclusive open terraces. The result is a user-input estimate, not an official measurement.',
    'Built-up and saleable area':
        'Built-up commonly adds wall footprints and some exclusive areas. Super built-up or saleable area may also allocate common areas. Ask what is included before comparing claims; definitions and inclusions matter.',
    'Internal and external walls':
        'Internal partitions divide rooms within your flat. External walls enclose the flat. Measure wall length × thickness and count shared internal partitions once.',
    'Loading and carpet efficiency':
        'Loading on carpet = (saleable / carpet − 1) × 100. Loading on built-up uses built-up as the base. Carpet efficiency = carpet / saleable × 100. Example: 800 sq ft carpet and 1,000 sq ft saleable gives 25% loading on carpet and 80% efficiency.',
    'How to measure a room':
        'Measure length and width between finished inside faces. Record recesses and obstructions separately. A 12 ft × 10 ft room has 120 sq ft of floor area. Do not include wall thickness in room dimensions.',
    'Feet, inches and metric':
        '12 inches = 1 foot. 10 ft 6 in = 10.5 ft, not 10.6 ft. Enter 10 ft 13 in as 11 ft 1 in. 1 sq m = 10.7639 sq ft.',
    'Irregular rooms':
        'Split an L-shaped room into rectangles that do not overlap. Add each as a separate named segment. For example: Kitchen segment 1 (10 × 8 ft) + segment 2 (4 × 3 ft) = 92 sq ft.',
    'Common mistakes':
        'Avoid overlapping room segments, counting a shared wall twice, treating sample dimensions as measurements, or comparing room-only area directly with saleable area. Confirm every OCR dimension against the original plan.',
    'Privacy and local storage':
        'Area checks and site photographs stay on this device. No account is required. Export important reports; clearing data or uninstalling can remove them. The floor-plan scanner has its own review and report workflow.',
  };
  @override
  Widget build(BuildContext context) {
    final entries = topics.entries
        .where(
          (entry) => '${entry.key} ${entry.value}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const Text(
          'A little knowledge.\nA better home decision.',
          style: TextStyle(
            fontSize: 27,
            height: 1.2,
            letterSpacing: -.9,
            fontWeight: FontWeight.w800,
            color: CheckPalette.ink,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Property terms, without the complicated language.',
          style: TextStyle(
            fontSize: 13,
            color: CheckPalette.muted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        CheckSurface(
          color: const Color(0xFFEDF5F3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CheckBadge(
                'GOOD TO KNOW',
                icon: Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 18),
              const Text(
                'Not every square foot\nis the same.',
                style: TextStyle(
                  fontSize: 23,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF175C54),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Usable area is where you live. Wall footprints and shared spaces tell a different part of the story.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF4B756F),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  CheckBadge('Rooms', icon: Icons.chair_outlined),
                  CheckBadge('Walls', icon: Icons.view_column_outlined),
                  CheckBadge('Common areas', icon: Icons.apartment_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Search areas, walls, measurements…',
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Find a topic',
          ),
        ),
        const SizedBox(height: 22),
        CheckSectionTitle(
          'The homebuyer’s handbook',
          caption: '${entries.length} straightforward explanations',
        ),
        if (entries.isEmpty)
          const CheckEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching topics',
            subtitle: 'Try “carpet”, “walls” or “measure”.',
          ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: CheckPalette.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: ValueKey(entry.key),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CheckIcon(topicIcon(entry.key), size: 38),
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.75,
                        color: CheckPalette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData topicIcon(String title) => title.contains('wall')
      ? Icons.view_column_outlined
      : title.contains('measure') || title.contains('inches')
      ? Icons.straighten_rounded
      : title.contains('Privacy')
      ? Icons.lock_outline
      : title.contains('Loading')
      ? Icons.pie_chart_outline_rounded
      : Icons.menu_book_outlined;
}

class QuickConverter extends StatefulWidget {
  const QuickConverter({super.key});
  @override
  State<QuickConverter> createState() => _QuickConverterState();
}

class _QuickConverterState extends State<QuickConverter> {
  double? value;
  bool fromMetric = false;
  @override
  Widget build(BuildContext context) => CheckSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CheckIcon(
              Icons.swap_horiz_rounded,
              color: CheckPalette.teal,
              size: 38,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quick area converter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                fromMetric
                    ? 'Square metres → square feet'
                    : 'Square feet → square metres',
                style: const TextStyle(fontSize: 12, color: CheckPalette.muted),
              ),
            ),
            IconButton(
              tooltip: 'Swap conversion direction',
              onPressed: () => setState(() => fromMetric = !fromMetric),
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: CheckPalette.blue,
              ),
            ),
          ],
        ),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: fromMetric ? 'Area (sq m)' : 'Area (sq ft)',
          ),
          onChanged: (v) => setState(() => value = double.tryParse(v)),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value != null && value!.isFinite && value! >= 0
                ? '${(fromMetric ? value! * squareFeetPerSquareMeter : value! / squareFeetPerSquareMeter).toStringAsFixed(2)} ${fromMetric ? 'sq ft' : 'sq m'}'
                : 'Your converted area appears here',
            style: TextStyle(
              fontSize: value == null ? 12 : 22,
              fontWeight: FontWeight.w700,
              color: CheckPalette.teal,
            ),
          ),
        ),
      ],
    ),
  );
}
