import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../branding.dart';
import 'area_check_model.dart';
import 'area_check_report.dart';
import 'space_editor.dart';
import 'learn_screen.dart';
import 'check_ui.dart';

class AreaCheckApp extends StatefulWidget {
  const AreaCheckApp({
    super.key,
    required this.floorPlanBuilder,
    required this.legacySavedBuilder,
    this.accountBuilder,
  });
  final WidgetBuilder floorPlanBuilder, legacySavedBuilder;
  final WidgetBuilder? accountBuilder;
  @override
  State<AreaCheckApp> createState() => _AreaCheckAppState();
}

class _AreaCheckAppState extends State<AreaCheckApp> {
  Box? box;
  AreaCheck check = AreaCheck(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
  );
  int tab = 0, step = 0;
  bool loading = true, busy = false;
  String status = 'Saved on this device';
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      box = await Hive.openBox('flatverify_area_checks_v1');
      final draft = box!.get('draft');
      if (draft is Map) check = AreaCheck.fromJson(draft);
    } catch (_) {
      status = 'Could not restore local data. You can still calculate.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> persist() async {
    check.updated = DateTime.now().toIso8601String();
    try {
      if (box == null) throw StateError('Storage unavailable');
      await box!.put('draft', check.toJson());
      if (mounted) setState(() => status = 'Saved on this device');
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              status = 'Could not save. Keep the app open and export a report.',
        );
      }
    }
  }

  void change(VoidCallback action) {
    setState(action);
    persist();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<bool> confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Please confirm'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> saveReport() async {
    if (check.spaces.isEmpty) {
      message('Add at least one space first.');
      return;
    }
    try {
      if (box == null) throw StateError('Storage unavailable');
      check.updated = DateTime.now().toIso8601String();
      await box!.put('check_${check.id}', check.toJson());
      message('Area check saved on this device.');
    } catch (_) {
      message('Could not save this report. Please export a PDF.');
    }
  }

  Future<void> export(AreaCheck item) async {
    setState(() => busy = true);
    try {
      await exportAreaCheck(item);
    } catch (_) {
      message('Could not create the PDF. Please try again.');
    }
    if (mounted) setState(() => busy = false);
  }

  void newCheck({bool site = false}) => change(() {
    check = AreaCheck(id: DateTime.now().microsecondsSinceEpoch.toString())
      ..method = site ? 'Site measurement' : 'Manual entry';
    step = 0;
    tab = 1;
  });
  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            height: 1.2,
            letterSpacing: -.9,
            fontWeight: FontWeight.w800,
            color: CheckPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: CheckPalette.muted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
  Widget card(Widget child) => CheckSurface(child: child);
  Widget metric(String label, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 16,
        runSpacing: 6,
        children: [
          SizedBox(
            width: constraints.maxWidth > 460 ? 250 : constraints.maxWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: CheckPalette.muted),
            ),
          ),
          Text(
            check.areaLabel(value),
            style: const TextStyle(
              fontSize: 21,
              letterSpacing: -.5,
              fontWeight: FontWeight.w800,
              color: CheckPalette.ink,
            ),
          ),
        ],
      ),
    ),
  );
  Widget field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool numeric = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey('${check.id}:$label'),
      initialValue: value,
      style: const TextStyle(fontSize: 16),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onChanged: onChanged,
    ),
  );
  Widget select<T>(
    String label,
    T value,
    List<T> values,
    String Function(T) name,
    ValueChanged<T> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(name(v), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
  void continueStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(form.currentState?.validate() ?? true)) return;
    if (step == 1 && check.spaces.isEmpty) {
      message('Add at least one space.');
      return;
    }
    if (step == 2 &&
        check.walls == WallMethod.measured &&
        check.internalWalls <= 0) {
      message('Add an internal-wall footprint or choose Skip.');
      return;
    }
    if (step < 3) {
      setState(() => step++);
    } else {
      saveReport();
    }
  }

  void showHelp() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('A clearer picture in three steps'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CheckIcon(Icons.straighten),
            title: Text('Enter Measurements'),
            subtitle: Text('Add rooms and layout spaces.'),
          ),
          ListTile(
            leading: CheckIcon(Icons.donut_small_outlined),
            title: Text('Review Your Area'),
            subtitle: Text('See indoor, outdoor and wall areas separately.'),
          ),
          ListTile(
            leading: CheckIcon(Icons.file_download_outlined),
            title: Text('Compare and Save'),
            subtitle: Text('Compare claims and keep a clear report.'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  void selectTab(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => tab = value);
  }

  static const navIcons = [
    Icons.grid_view_rounded,
    Icons.straighten_rounded,
    Icons.layers_outlined,
    Icons.folder_open_rounded,
    Icons.auto_stories_outlined,
  ];
  static const navLabels = [
    'Home',
    'Calculator',
    'Floor Plan',
    'Saved',
    'Learn',
  ];
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: tab == 4
            ? const LearnScreen()
            : ListView(
                key: ValueKey('page-$tab-$step'),
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 20,
                  24,
                  wide ? 32 : 20,
                  28,
                ),
                children: [
                  if (tab == 0)
                    ...home()
                  else if (tab == 1)
                    ...calculator()
                  else if (tab == 2)
                    ...floorPlan()
                  else
                    ...saved(),
                ],
              ),
      ),
    );
    return Scaffold(
      backgroundColor: CheckPalette.canvas,
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: Colors.white,
        titleSpacing: 20,
        shape: const Border(bottom: BorderSide(color: CheckPalette.line)),
        title: const BrandHeader(compact: true),
        actions: [
          if (widget.accountBuilder != null)
            IconButton(
              tooltip: 'Account',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: widget.accountBuilder!),
              ),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: CheckPalette.line),
                backgroundColor: CheckPalette.canvas,
              ),
              onPressed: () =>
                  change(() => check.metricDisplay = !check.metricDisplay),
              child: Row(
                children: [
                  Text(
                    check.metricDisplay ? 'sq m' : 'sq ft',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.swap_horiz, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (wide)
              Container(
                width: 194,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: CheckPalette.line)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    for (int i = 0; i < navLabels.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selected: tab == i,
                            selectedTileColor: const Color(0xFFEFF4FF),
                            selectedColor: CheckPalette.blue,
                            leading: Icon(navIcons[i], size: 21),
                            title: Text(
                              navLabels[i],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => selectTab(i),
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CheckBadge(
                        'Private by default',
                        icon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: CheckPalette.line)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab == 1)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          if (step > 0) ...[
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => setState(() => step--),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: busy ? null : continueStep,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    step == 3 ? 'Save Area Check' : 'Continue',
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    step == 3
                                        ? Icons.bookmark_border_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!wide)
                NavigationBar(
                  height: 70,
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFEAF1FF),
                  selectedIndex: tab,
                  onDestinationSelected: selectTab,
                  destinations: List.generate(
                    5,
                    (i) => NavigationDestination(
                      icon: Icon(navIcons[i]),
                      label: navLabels[i],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> home() => [
    Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR HOME, UNDERSTOOD',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                  color: CheckPalette.muted,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'A little more certainty.',
                style: TextStyle(
                  fontSize: 23,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w800,
                  color: CheckPalette.ink,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CheckPalette.line),
          ),
          child: const Icon(
            Icons.waving_hand_outlined,
            size: 24,
            color: CheckPalette.blue,
          ),
        ),
      ],
    ),
    const SizedBox(height: 22),
    CheckHero(onStart: () => selectTab(1), onHelp: showHelp),
    const CheckSectionTitle(
      'How would you like to begin?',
      caption: 'Choose what works for you.',
    ),
    CheckActionGrid(
      children: [
        CheckActionTile(
          icon: Icons.edit_note_rounded,
          title: 'Enter Measurements Manually',
          subtitle: 'Room by room, at your pace',
          onTap: () => selectTab(1),
        ),
        CheckActionTile(
          icon: Icons.layers_outlined,
          title: 'Upload Floor Plan',
          subtitle: 'Read and review your layout',
          color: const Color(0xFF785CC6),
          onTap: () => selectTab(2),
        ),
        CheckActionTile(
          icon: Icons.straighten_rounded,
          title: 'Site Measurement Mode',
          subtitle: 'Capture details on your visit',
          color: CheckPalette.teal,
          onTap: () async {
            if (check.spaces.isEmpty ||
                await confirm(
                  'Start a new site check? Save the current check first to keep it in Saved.',
                )) {
              newCheck(site: true);
            }
          },
        ),
        CheckActionTile(
          icon: Icons.folder_open_rounded,
          title: 'Saved Area Checks',
          subtitle:
              '${savedChecks.length} ${savedChecks.length == 1 ? 'check' : 'checks'} on this device',
          color: const Color(0xFFAE7521),
          onTap: () => selectTab(3),
        ),
      ],
    ),
    const SizedBox(height: 24),
    if (check.spaces.isNotEmpty) ...[
      const CheckSectionTitle('Pick up where you left off'),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckBadge(
              'IN PROGRESS',
              icon: Icons.edit_outlined,
              color: CheckPalette.blue,
            ),
            const SizedBox(height: 14),
            Text(
              check.displayTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '${check.spaces.length} spaces added · ${check.configuration}',
              style: const TextStyle(color: CheckPalette.muted),
            ),
            metric('Net usable area so far', check.usable),
            OutlinedButton.icon(
              onPressed: () => selectTab(1),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue area check'),
            ),
          ],
        ),
      ),
    ],
    if (savedChecks.isNotEmpty) ...[
      const CheckSectionTitle('Your latest check'),
      savedCard(savedChecks.first, compact: true),
    ],
    const CheckSectionTitle('Small tools. Useful answers.'),
    const QuickConverter(),
    const SizedBox(height: 12),
    action(
      Icons.lightbulb_outline_rounded,
      'A room total is only part of the story.',
      'Learn how usable, carpet and saleable areas differ.',
      () => selectTab(4),
    ),
    const SizedBox(height: 16),
    const Center(
      child: CheckBadge(
        'Free to use · No account needed',
        icon: Icons.lock_outline,
      ),
    ),
    const SizedBox(height: 12),
  ];
  Widget action(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CheckPalette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CheckIcon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: CheckPalette.muted,
              height: 1.5,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    ),
  );
  List<Widget> floorPlan() => [
    heading(
      'Your plan. A clearer picture.',
      'Bring the layout you have. Understand the space you get.',
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckBadge(
            'FLOOR-PLAN ASSISTANCE',
            icon: Icons.layers_outlined,
            color: CheckPalette.blue,
          ),
          const SizedBox(height: 24),
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const CustomPaint(painter: FloorPlanArtwork(light: true)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start with your floor plan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              letterSpacing: -.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload a plan, review the dimensions, and keep the numbers you trust.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CheckPalette.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: widget.floorPlanBuilder),
            ),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Open floor-plan scanner'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: CheckBadge(
              'JPG · PNG · PDF',
              icon: Icons.insert_drive_file_outlined,
              color: CheckPalette.muted,
            ),
          ),
        ],
      ),
    ),
    const CheckSectionTitle('Every dimension deserves a second look'),
    const CheckHint(
      'AI-extracted dimensions may be inaccurate. Confirm every measurement before calculating your area.',
      warning: true,
    ),
    const SizedBox(height: 8),
    action(
      Icons.edit_note_rounded,
      'Prefer to enter the numbers yourself?',
      'Use your confirmed dimensions in the area calculator. Scanner results are kept separately.',
      () => selectTab(1),
    ),
  ];
  List<Widget> calculator() => [
    heading(
      [
        'Let’s get to know your home.',
        'Build your room-by-room picture.',
        'Add context to your numbers.',
        'Your space, clearly explained.',
      ][step],
      [
        'A few details to keep your area check organised.',
        'Add each space once. We’ll handle the totals.',
        'Walls and advertised areas are entirely optional.',
        'Review your measurements, assumptions and area breakdown.',
      ][step],
    ),
    CheckProgress(step: step),
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            size: 15,
            color: CheckPalette.teal,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontSize: 11, color: CheckPalette.muted),
            ),
          ),
          Text(
            '${step + 1} OF 4',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: CheckPalette.muted,
            ),
          ),
        ],
      ),
    ),
    Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: step == 0
            ? details()
            : step == 1
            ? spaces()
            : step == 2
            ? [
                card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: assumptions(),
                  ),
                ),
              ]
            : results(),
      ),
    ),
  ];
  List<Widget> details() => [
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckSectionTitle(
            'The basics',
            caption: 'Make this check easy to find later.',
          ),
          field(
            'Property name (optional)',
            check.title,
            (v) => change(() => check.title = v),
          ),
          field(
            'Flat number (optional)',
            check.flat,
            (v) => change(() => check.flat = v),
          ),
          const SizedBox(height: 6),
          const Text(
            'Home configuration',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Studio', '1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Custom']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: check.configuration == v,
                    onSelected: (_) => change(() => check.configuration = v),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckSectionTitle(
            'How you’ll measure',
            caption: 'Use the units you are comfortable with.',
          ),
          select(
            'Input method',
            check.method,
            ['Manual entry', 'Site measurement'],
            (v) => v,
            (v) => change(() => check.method = v),
          ),
          select(
            'Default measurement unit',
            check.unit,
            MeasureUnit.values,
            (v) => v.label,
            (v) => change(() => check.unit = v),
          ),
          const CheckHint(
            'Each space can use its own unit. Existing measurements keep their original units.',
          ),
          OutlinedButton.icon(
            onPressed: applyPreset,
            icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
            label: const Text('Enter editable layout preset'),
          ),
        ],
      ),
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CheckSectionTitle(
            'Anything to remember?',
            caption: 'Add a note for your future self.',
          ),
          field(
            'Property notes (optional)',
            check.notes,
            (v) => change(() => check.notes = v),
          ),
        ],
      ),
    ),
  ];
  Future<void> applyPreset() async {
    final count = int.tryParse(check.configuration.substring(0, 1)) ?? 1;
    final names = check.configuration == 'Studio'
        ? ['Studio', 'Kitchen', 'Bathroom']
        : [
            'Living room',
            'Kitchen',
            for (int i = 1; i <= count; i++) 'Bedroom $i',
            'Bathroom',
            'Passage',
            'Balcony',
            'Dry utility',
          ];
    for (final name in names) {
      if (!mounted) return;
      final added = await editSpace(
        AreaSpace(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          unit: check.unit,
          source: check.method == 'Site measurement'
              ? 'Physically measured'
              : 'User-entered',
          category: name == 'Passage'
              ? SpaceCategory.circulation
              : name == 'Balcony'
              ? SpaceCategory.balcony
              : name == 'Dry utility'
              ? SpaceCategory.utility
              : SpaceCategory.indoor,
        ),
      );
      if (!added) break;
    }
  }

  List<Widget> spaces() => [
    OutlinedButton.icon(
      onPressed: () => editSpace(),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
      label: const Text('Add a space or segment'),
    ),
    const SizedBox(height: 16),
    if (check.spaces.isEmpty)
      const CheckEmptyState(
        icon: Icons.crop_free_rounded,
        title: 'Every room adds to the picture.',
        subtitle:
            'Start with your living room, then add bedrooms, passages and outdoor spaces.',
      ),
    if (check.spaces.isNotEmpty)
      CheckSectionTitle(
        'Your layout',
        caption: '${check.spaces.length} spaces recorded',
      ),
    for (int i = 0; i < check.spaces.length; i++) spaceCard(check.spaces[i], i),
    const SizedBox(height: 16),
    if (check.spaces.isNotEmpty)
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckBadge(
              'LIVE TOTAL',
              icon: Icons.calculate_outlined,
              color: CheckPalette.blue,
            ),
            metric('Net Usable Indoor Area', check.usable),
          ],
        ),
      ),
    const CheckHint(
      'An L-shaped room? Divide it into rectangles and add each as a named segment. Keep balconies and utilities in their own categories.',
      icon: Icons.tips_and_updates_outlined,
    ),
  ];
  Widget spaceCard(AreaSpace space, int index) => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckIcon(
              space.category == SpaceCategory.internalWall
                  ? Icons.view_column_outlined
                  : space.category == SpaceCategory.balcony ||
                        space.category == SpaceCategory.terrace
                  ? Icons.balcony_outlined
                  : Icons.door_sliding_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    space.category.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CheckPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Space actions',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async {
                if (value == 'duplicate') {
                  final copy = AreaSpace.fromJson(space.toJson())
                    ..id = DateTime.now().microsecondsSinceEpoch.toString()
                    ..name = '${space.name} copy';
                  change(() => check.spaces.insert(index + 1, copy));
                }
                if (value == 'up') {
                  change(() {
                    check.spaces.removeAt(index);
                    check.spaces.insert(index - 1, space);
                  });
                }
                if (value == 'down') {
                  change(() {
                    check.spaces.removeAt(index);
                    check.spaces.insert(index + 1, space);
                  });
                }
                if (value == 'delete' &&
                    await confirm('Delete ${space.name}?')) {
                  change(() => check.spaces.removeAt(index));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate'),
                ),
                if (index > 0)
                  const PopupMenuItem(value: 'up', child: Text('Move up')),
                if (index < check.spaces.length - 1)
                  const PopupMenuItem(value: 'down', child: Text('Move down')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CheckPalette.canvas,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                space.dimensions,
                style: const TextStyle(fontSize: 12, color: CheckPalette.muted),
              ),
              const SizedBox(height: 5),
              Text(
                check.areaLabel(space.area),
                style: const TextStyle(
                  fontSize: 23,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (space.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              space.notes,
              style: const TextStyle(fontSize: 12, color: CheckPalette.muted),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                space.source,
                style: const TextStyle(fontSize: 11, color: CheckPalette.teal),
              ),
            ),
            if (space.photo != null)
              const Tooltip(
                message: 'Site photograph attached',
                child: Icon(
                  Icons.photo_outlined,
                  size: 17,
                  color: CheckPalette.muted,
                ),
              ),
            TextButton.icon(
              onPressed: () => editSpace(space),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Edit'),
            ),
          ],
        ),
      ],
    ),
  );
  Future<bool> editSpace([AreaSpace? original]) async {
    final space = original == null
        ? AreaSpace(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: '',
            unit: check.unit,
            source: check.method == 'Site measurement'
                ? 'Physically measured'
                : 'User-entered',
          )
        : AreaSpace.fromJson(original.toJson());
    final result = await showDialog<AreaSpace>(
      context: context,
      builder: (_) =>
          SpaceEditor(space: space, site: check.method == 'Site measurement'),
    );
    if (result == null || !mounted) return false;
    change(() {
      final index = check.spaces.indexWhere((s) => s.id == result.id);
      if (index < 0) {
        check.spaces.add(result);
      } else {
        check.spaces[index] = result;
      }
    });
    return true;
  }

  List<Widget> assumptions() => [
    select(
      'Internal-wall method',
      check.walls,
      WallMethod.values,
      (v) => switch (v) {
        WallMethod.skip => 'Skip wall calculation',
        WallMethod.estimate => 'Estimated percentage',
        WallMethod.measured => 'Manual wall footprints',
      },
      (v) => change(() => check.walls = v),
    ),
    if (check.walls == WallMethod.estimate)
      field(
        'Internal-wall percentage (required)',
        check.wallPercent?.toString() ?? '',
        (v) => change(() => check.wallPercent = double.tryParse(v)),
        numeric: true,
        validator: (v) {
          final n = double.tryParse(v ?? '');
          return n == null || !n.isFinite || n < 0 || n > 100
              ? 'Enter a percentage between 0 and 100.'
              : null;
        },
      ),
    if (check.walls == WallMethod.measured) ...[
      const Text(
        'Enter length × thickness × quantity for each internal partition. Do not count shared walls twice.',
      ),
      OutlinedButton(
        onPressed: () => editSpace(
          AreaSpace(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: 'Internal wall',
            category: SpaceCategory.internalWall,
            unit: check.unit.isArea ? MeasureUnit.feetInches : check.unit,
            source: 'User-entered wall footprint',
          ),
        ),
        child: const Text('Add internal-wall footprint'),
      ),
    ],
    Text(check.wallAssumption),
    const SizedBox(height: 24),
    const Text(
      'Advertised areas (optional)',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    const Text(
      'Enter advertised values in sq ft. Built-up and saleable values are used for loading, not directly compared with room-only area.',
    ),
    const SizedBox(height: 16),
    advertisedField(
      'Advertised Carpet Area (sq ft)',
      check.advertisedCarpet,
      (v) => check.advertisedCarpet = v,
    ),
    advertisedField(
      'Advertised Built-up Area (sq ft)',
      check.advertisedBuiltUp,
      (v) => check.advertisedBuiltUp = v,
    ),
    advertisedField(
      'Advertised Super Built-up Area (sq ft)',
      check.advertisedSaleable,
      (v) => check.advertisedSaleable = v,
    ),
    ExpansionTile(
      title: const Text('Comparison review thresholds'),
      subtitle: const Text('Personal preferences, not legal standards'),
      children: [
        field(
          'Closely aligned up to (%)',
          '${check.closeThreshold}',
          (v) {
            final n = double.tryParse(v);
            if (n != null) change(() => check.closeThreshold = n);
          },
          numeric: true,
          validator: (v) =>
              double.tryParse(v ?? '') == null ||
                  !check.closeThreshold.isFinite ||
                  check.closeThreshold < 0 ||
                  check.closeThreshold > check.reviewThreshold
              ? 'Enter a valid threshold below the second threshold.'
              : null,
        ),
        field(
          'Small difference up to (%)',
          '${check.reviewThreshold}',
          (v) {
            final n = double.tryParse(v);
            if (n != null) change(() => check.reviewThreshold = n);
          },
          numeric: true,
          validator: (v) =>
              double.tryParse(v ?? '') == null ||
                  !check.reviewThreshold.isFinite ||
                  check.reviewThreshold < check.closeThreshold ||
                  check.reviewThreshold > 100
              ? 'Enter a threshold between the first threshold and 100.'
              : null,
        ),
      ],
    ),
  ];
  Widget advertisedField(
    String label,
    double? value,
    void Function(double?) assign,
  ) => field(
    label,
    value?.toString() ?? '',
    (v) => change(() => assign(double.tryParse(v))),
    numeric: true,
    validator: (v) {
      if (v == null || v.isEmpty) return null;
      final n = double.tryParse(v);
      return n == null || !n.isFinite || n <= 0
          ? 'Enter a positive area or leave blank.'
          : null;
    },
  );
  List<Widget> results() => [
    Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF12294C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckBadge(
            check.quality,
            icon: Icons.fact_check_outlined,
            dark: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Net Usable Indoor Area',
            style: TextStyle(fontSize: 13, color: Color(0xFFBED0E8)),
          ),
          const SizedBox(height: 6),
          Text(
            check.areaLabel(check.usable),
            style: const TextStyle(
              fontSize: 36,
              height: 1.2,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${check.spaces.length} spaces · ${check.configuration} · ${check.method}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB5C8E0)),
          ),
          if (check.carpet != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFF365070)),
            ),
            const Text(
              'Estimated RERA Carpet Area',
              style: TextStyle(color: Color(0xFFBED0E8), fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              check.areaLabel(check.carpet!),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    ),
    const CheckSectionTitle(
      'Where your area goes',
      caption: 'Every category, shown separately.',
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (check.spaces.any((s) => s.area > 0))
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 16,
                child: Row(
                  children: [
                    for (final category in SpaceCategory.values)
                      if (check.categoryTotal(category) > 0)
                        Expanded(
                          flex: (check.categoryTotal(category) * 100)
                              .round()
                              .clamp(1, 1000000000),
                          child: Container(color: categoryColor(category)),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          for (final category in SpaceCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: categoryColor(category),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CheckPalette.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    check.areaLabel(check.categoryTotal(category)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: CheckPalette.line, height: 24),
          metric('Total Measured Floor Area', check.measuredFloor),
          const Text(
            'Indoor + circulation + balcony + utility + terrace. Walls and excluded areas are separate.',
            style: TextStyle(
              fontSize: 11,
              color: CheckPalette.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckSectionTitle(
            'Behind the estimate',
            caption: 'Your inputs and assumptions stay visible.',
          ),
          metric('Internal-wall area', check.internalWalls),
          CheckHint(
            check.wallAssumption,
            warning: check.walls == WallMethod.estimate,
          ),
          const Text(
            'Information quality, not a certification.',
            style: TextStyle(fontSize: 11, color: CheckPalette.muted),
          ),
        ],
      ),
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckSectionTitle('Advertised-area comparison'),
          CheckBadge(
            check.comparisonStatus,
            icon: Icons.compare_arrows_rounded,
            color:
                check.differencePercent != null &&
                    check.differencePercent!.abs() > check.reviewThreshold
                ? const Color(0xFF9C6411)
                : CheckPalette.teal,
          ),
          if (check.advertisedCarpet != null)
            metric('Advertised Carpet Area', check.advertisedCarpet!),
          if (check.difference != null) ...[
            metric('Advertised minus estimated carpet', check.difference!),
            Text(
              'Difference: ${check.differencePercent!.toStringAsFixed(2)}% of advertised carpet',
              style: const TextStyle(fontSize: 12, color: CheckPalette.muted),
            ),
          ],
          if (check.loading(check.advertisedCarpet) != null)
            resultLine(
              'Loading on advertised Carpet Area',
              '${check.loading(check.advertisedCarpet)!.toStringAsFixed(2)}%',
            ),
          if (check.loading(check.advertisedBuiltUp) != null)
            resultLine(
              'Loading on advertised Built-up Area',
              '${check.loading(check.advertisedBuiltUp)!.toStringAsFixed(2)}%',
            ),
          if (check.efficiency != null)
            resultLine(
              '${check.carpet != null ? 'Estimated ' : ''}Carpet Efficiency',
              '${check.efficiency!.toStringAsFixed(2)}%',
            ),
          if (check.advertisedSaleable != null &&
              [
                check.advertisedCarpet,
                check.advertisedBuiltUp,
                check.carpet,
              ].any((v) => v != null && v > check.advertisedSaleable!))
            const CheckHint(
              'Area requiring review: saleable area is smaller than a carpet or built-up value.',
              warning: true,
            ),
          const SizedBox(height: 16),
          const Text(
            'Differences are a reason to review measurements and assumptions. They do not establish misrepresentation.',
            style: TextStyle(
              fontSize: 11,
              color: CheckPalette.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
    if (busy) const LinearProgressIndicator(),
    OutlinedButton.icon(
      onPressed: busy || check.spaces.isEmpty ? null : () => export(check),
      icon: const Icon(Icons.file_download_outlined),
      label: const Text('Download free PDF report'),
    ),
    const SizedBox(height: 16),
    const ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'About this report',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            reportDisclaimer,
            style: TextStyle(
              fontSize: 12,
              color: CheckPalette.muted,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  ];
  Color categoryColor(SpaceCategory category) => const [
    Color(0xFF2563EB),
    Color(0xFF67A1F5),
    Color(0xFF168C80),
    Color(0xFF79C3B3),
    Color(0xFFE8B65E),
    Color(0xFF8D7ACC),
    Color(0xFFA6AEC1),
    Color(0xFFCBD2DF),
  ][category.index];
  Widget resultLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: CheckPalette.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
  List<AreaCheck> get savedChecks {
    if (box == null) return [];
    final items = <AreaCheck>[];
    for (final key in box!.keys.where(
      (k) => k.toString().startsWith('check_'),
    )) {
      try {
        items.add(AreaCheck.fromJson(box!.get(key) as Map));
      } catch (_) {
        /* Preserve unreadable records for recovery. */
      }
    }
    items.sort((a, b) => b.updated.compareTo(a.updated));
    return items;
  }

  void openCheck(AreaCheck item) => change(() {
    check = AreaCheck.fromJson(item.toJson());
    tab = 1;
    step = 3;
  });
  Future<void> storeItem(AreaCheck item) async {
    try {
      await box!.put('check_${item.id}', item.toJson());
      if (mounted) setState(() {});
    } catch (_) {
      message('Could not save. Please try again.');
    }
  }

  Widget savedCard(AreaCheck item, {bool compact = false}) => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckIcon(Icons.home_work_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.configuration} · ${item.updated.split('T').first}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CheckPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              PopupMenuButton<String>(
                tooltip: 'Saved check actions',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) async {
                  if (value == 'rename') rename(item);
                  if (value == 'duplicate') {
                    storeItem(
                      AreaCheck.fromJson(item.toJson())
                        ..id = DateTime.now().microsecondsSinceEpoch.toString()
                        ..title = '${item.displayTitle} copy'
                        ..updated = DateTime.now().toIso8601String(),
                    );
                  }
                  if (value == 'delete' &&
                      await confirm('Delete this saved calculation?')) {
                    try {
                      await box!.delete('check_${item.id}');
                      if (mounted) setState(() {});
                    } catch (_) {
                      message('Could not delete. Please try again.');
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CheckPalette.canvas,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET USABLE AREA',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.1,
                      color: CheckPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.areaLabel(item.usable),
                    style: const TextStyle(
                      fontSize: 23,
                      letterSpacing: -.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (item.carpet != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ESTIMATED CARPET',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        color: CheckPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.areaLabel(item.carpet!),
                      style: const TextStyle(
                        fontSize: 23,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CheckBadge(item.quality, icon: Icons.fact_check_outlined),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => openCheck(item),
                child: Text(compact ? 'Open check' : 'Open / Edit'),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Export PDF',
                onPressed: busy ? null : () => export(item),
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: CheckPalette.blue,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
  List<Widget> saved() => [
    heading(
      'Your property notebook.',
      'All your area checks, ready when you need them.',
    ),
    Row(
      children: [
        Expanded(
          child: Text(
            '${savedChecks.length} SAVED ${savedChecks.length == 1 ? 'CHECK' : 'CHECKS'}',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: CheckPalette.muted,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            if (check.spaces.isEmpty ||
                await confirm(
                  'Start a new check? Save your current draft first if you want to keep it.',
                )) {
              newCheck();
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New area check'),
        ),
      ],
    ),
    const SizedBox(height: 12),
    if (savedChecks.isEmpty)
      const CheckEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Your first check belongs here.',
        subtitle:
            'Save an area check to revisit your measurements, compare homes, or download a report.',
      ),
    for (final item in savedChecks) savedCard(item),
    if (savedChecks.length > 1)
      OutlinedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Compare saved flats'),
            content: SizedBox(
              width: 500,
              child: ListView(
                shrinkWrap: true,
                children: savedChecks
                    .map(
                      (item) => ListTile(
                        title: Text(item.displayTitle),
                        subtitle: Text(
                          'Net usable: ${check.areaLabel(item.usable)}\nEstimated carpet: ${item.carpet == null ? 'Not available' : check.areaLabel(item.carpet!)}\n${item.wallAssumption}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: const Text('Compare saved flats'),
      ),
    const CheckHint(
      'Saved on this device. Export important reports before clearing app data or uninstalling.',
      icon: Icons.lock_outline,
    ),
    TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: widget.legacySavedBuilder),
      ),
      child: const Text('Open previous-version reports'),
    ),
    TextButton(
      onPressed: () async {
        if (await confirm(
          'Clear all area-check data, including this draft and saved area checks? Previous-version reports are managed separately.',
        )) {
          try {
            await box?.clear();
            if (mounted) newCheck();
          } catch (_) {
            message('Could not clear data. Please try again.');
          }
        }
      },
      child: const Text('Clear all local area-check data'),
    ),
  ];
  Future<void> rename(AreaCheck item) async {
    String value = item.title;
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rename area check'),
        content: TextFormField(
          initialValue: value,
          onChanged: (v) => value = v,
          decoration: const InputDecoration(labelText: 'Property title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, value),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null) {
      item.title = name;
      await storeItem(item);
    }
  }
}
