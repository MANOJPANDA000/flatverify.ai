import 'package:flutter/material.dart';

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
            'â€œCarpet area means the net usable floor area of an apartment, excluding the area covered by external walls, areas under service shafts, exclusive balcony or verandah, but includes area covered by internal partition walls.â€\nâ€” RERA Act 2016, Sec 2(k)',
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
                    const Text('âœ“ ',
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
                    const Text('âœ— ',
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
              'When the washing yard or utility space projects OUTSIDE the flat's continuous external perimeter wall, it is classified as a Dry Balcony. It is EXCLUDED from Carpet Area and included in Built-up Area only.',
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



