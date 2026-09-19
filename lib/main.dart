import 'dart:io';
import 'branding.dart';
import 'app_theme.dart';
export 'branding.dart';
import 'account/session_controller.dart';
import 'account/account_screens.dart';
import 'account/profile_widgets.dart';

import 'dimension_scan_parser.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'home_dashboard.dart';
part 'scan_room_card.dart';
part 'verification_widgets.dart';
part 'report_units.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox(
    'local_audits',
  ); // Preserve existing reports during migration.
  await SessionController.instance.initialize();

  runApp(const FAreaApp());
}

// ============================================================
// APP
// ============================================================

class FAreaApp extends StatelessWidget {
  const FAreaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flatverify.ai',
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      builder: (context, child) => ColoredBox(
        color: AppColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: SessionGateway(appBuilder: (_) => const MainNavigationScreen()),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int selectedIndex = 0;
  final _scannerKey = GlobalKey<_OcrScannerScreenState>();

  void openVerification(VerifyInputMode mode) {
    _scannerKey.currentState?._selectInputMode(mode);
    setState(() => selectedIndex = 1);
  }

  late final List<Widget> pages = [
    const HomeScreen(),
    OcrScannerScreen(key: _scannerKey),
    const SavedAuditsScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightBlue,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Verify',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: SessionController.instance.isGuest ? 'Reports' : 'Saved',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

enum DimensionUnit { feetInches, meterCm, decimalFeet }

// ============================================================
// ROOM DATA
// ============================================================

enum AreaDisplayUnit { metric, imperial }

extension AreaDisplayFormat on AreaDisplayUnit {
  String get label => this == AreaDisplayUnit.metric ? 'm²' : 'sq ft';
  String formatLength(double meters) => this == AreaDisplayUnit.metric
      ? '${DimensionParser.format(meters)} m'
      : DimensionParser.formatFeetInches(meters);
  String formatArea(double squareFeet) =>
      '${DimensionParser.format(this == AreaDisplayUnit.metric ? squareFeet / DimensionParser.squareMeterToSquareFeet : squareFeet)} $label';
  DimensionUnit get dimensionUnit => this == AreaDisplayUnit.metric
      ? DimensionUnit.meterCm
      : DimensionUnit.feetInches;
}

class RoomData {
  bool get hasMeasurements =>
      lengthMeters.isFinite &&
      widthMeters.isFinite &&
      lengthMeters > 0 &&
      widthMeters > 0;
  bool get contributesToTotal =>
      hasMeasurements && (!isAutoExtracted || isUserVerified);
  String name;
  double lengthMeters;
  double widthMeters;
  DimensionUnit unit;
  bool isAutoExtracted;
  String? sourcePhotoId;
  String? sourcePairId;
  bool isUserVerified;

  RoomData({
    this.name = '',
    this.lengthMeters = 0.0,
    this.widthMeters = 0.0,
    this.unit = DimensionUnit.feetInches,
    this.isAutoExtracted = false,
    this.sourcePhotoId,
    this.sourcePairId,
    this.isUserVerified = false,
  });
}

class ScannedRoomEditor extends StatefulWidget {
  final RoomData room;
  final AreaDisplayUnit? displayUnit;
  const ScannedRoomEditor({super.key, required this.room, this.displayUnit});

  @override
  State<ScannedRoomEditor> createState() => _ScannedRoomEditorState();
}

class _ScannedRoomEditorState extends State<ScannedRoomEditor> {
  DimensionUnit get editingUnit =>
      widget.displayUnit?.dimensionUnit ?? widget.room.unit;
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController length;
  late final TextEditingController width;
  late final String originalLength;
  late final String originalWidth;

  @override
  void initState() {
    super.initState();
    String dimension(double meters) => !meters.isFinite || meters <= 0
        ? ''
        : editingUnit == DimensionUnit.meterCm
        ? '$meters m'
        : DimensionParser.formatFeetInches(meters);
    name = TextEditingController(text: widget.room.name);
    length = TextEditingController(text: dimension(widget.room.lengthMeters));
    width = TextEditingController(text: dimension(widget.room.widthMeters));
    originalLength = length.text;
    originalWidth = width.text;
  }

  @override
  void dispose() {
    name.dispose();
    length.dispose();
    width.dispose();
    super.dispose();
  }

  double _meters(String value) {
    final trimmed = value.trim();
    if (double.tryParse(trimmed) != null) {
      return DimensionScanParser.toMeters(
        '$trimmed ${editingUnit == DimensionUnit.meterCm ? 'm' : 'ft'}',
      );
    }
    return DimensionScanParser.toMeters(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit room details'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Room name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a room name'
                    : null,
              ),
              const SizedBox(height: 12),
              for (final entry in {
                'Length': length,
                'Width': width,
              }.entries) ...[
                TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key),
                  validator: (value) => _meters(value ?? '') <= 0
                      ? 'Enter a positive measurement with units'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Use m, cm, mm, ft or in (for example 4.35 m or 10 ft 6 in). '
                'Without a unit, values use ${editingUnit == DimensionUnit.meterCm ? 'metres' : 'feet'}.',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              RoomData(
                name: name.text.trim(),
                lengthMeters: length.text == originalLength
                    ? widget.room.lengthMeters
                    : _meters(length.text),
                widthMeters: width.text == originalWidth
                    ? widget.room.widthMeters
                    : _meters(width.text),
              ),
            );
          },
          child: const Text('Save & Confirm'),
        ),
      ],
    );
  }
}

class _ScanPhotoData {
  final String id;
  final File imageFile;
  final String originalPath;
  String ocrText = '';
  final List<String> dimensions;
  final List<String> pairIds;
  final List<String?> roomNames = [];

  _ScanPhotoData({
    required this.id,
    required this.imageFile,
    required this.originalPath,
    List<String>? dimensions,
    List<String>? pairIds,
  }) : dimensions = dimensions ?? [],
       pairIds = pairIds ?? [];
}

class _PdfScanEvidence {
  final Uint8List bytes;
  final String ocrText;

  const _PdfScanEvidence(this.bytes, this.ocrText);
}

// ============================================================
// ROOM NAME OPTIONS
// ============================================================

const Map<String, List<String>> roomCategories = {
  'Bedrooms & Toilets': [
    'Master Bedroom',
    'Master Bedroom Toilet',
    'Bedroom 1',
    'Bedroom 1 Toilet',
    'Bedroom 2',
    'Bedroom 2 Toilet',
    'Guest Bedroom',
    'Guest Bedroom Toilet',
    'Kids Bedroom',
    'Kids Bedroom Toilet',
  ],
  'Living & Common Areas': [
    'Living Room',
    'Dining Area',
    'Puja Room',
    'Study Room',
    'Passage / Lobby',
    'Family Lounge',
  ],
  'Kitchen & Utility': [
    'Kitchen',
    'Utility Area',
    'Store Room',
    'Servant Room',
    'Servant Toilet',
  ],
  'Balconies': [
    'Balcony - Master Bedroom',
    'Balcony - Bedroom 1',
    'Balcony - Bedroom 2',
    'Balcony - Guest Bedroom',
    'Balcony - Kids Bedroom',
    'Balcony - Living Room',
    'Terrace',
    'Verandah',
  ],
};

const String customRoomOption = 'Other / Custom';

// ============================================================
// DIMENSION CONVERTER
// ============================================================

class DimensionParser {
  static const double feetToMeter = 0.3048;
  static const double inchToMeter = 0.0254;
  static const double cmToMeter = 0.01;
  static const double squareMeterToSquareFeet = 10.7639104167;

  static double feetInchesToMeters(double feet, double inches) {
    return (feet * feetToMeter) + (inches * inchToMeter);
  }

  static double meterCmToMeters(double meters, double centimeters) {
    return meters + (centimeters * cmToMeter);
  }

  static double decimalFeetToMeters(double feet) {
    return feet * feetToMeter;
  }

  static double squareMetersToSquareFeet(double squareMeters) {
    return squareMeters * squareMeterToSquareFeet;
  }

  static double metersToFeet(double meters) {
    return meters / feetToMeter;
  }

  static double metersToInches(double meters) {
    return meters / inchToMeter;
  }

  static String format(double value) {
    return value.toStringAsFixed(2);
  }

  static String formatFeetInches(double meters) {
    if (meters <= 0) return '--';

    double totalInches = metersToInches(meters);
    int feet = totalInches ~/ 12;
    double inches = totalInches - (feet * 12);

    if (inches >= 11.95) {
      feet++;
      inches = 0;
    }

    return "$feet' ${inches.toStringAsFixed(1)}\"";
  }

  static String formatMeterCm(double meters) {
    if (meters <= 0) return '--';

    final int wholeMeters = meters.floor();
    final double centimeters = (meters - wholeMeters) * 100;

    if (centimeters >= 99.95) {
      return '${wholeMeters + 1} m 0 cm';
    }

    return '$wholeMeters m ${centimeters.toStringAsFixed(1)} cm';
  }
}

// ============================================================
// SHARED AUDIT DETAILS DIALOG
// ============================================================

Future<Map<String, String>?> showAuditDetailsDialog(
  BuildContext context, {
  required String suggestedName,
}) async {
  final builderController = TextEditingController();
  final projectController = TextEditingController();
  final towerController = TextEditingController();
  final flatController = TextEditingController();
  final floorController = TextEditingController();

  final auditNameController = TextEditingController(text: suggestedName);

  final notesController = TextEditingController();

  String configuration = '2 BHK';

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.save_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Save Property Audit',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.sizeOf(dialogContext).width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Property details',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: builderController,
                      decoration: const InputDecoration(
                        labelText: 'Builder / Developer *',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: projectController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: towerController,
                            decoration: const InputDecoration(
                              labelText: 'Tower / Block',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: flatController,
                            decoration: const InputDecoration(
                              labelText: 'Flat / Unit',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: floorController,
                            decoration: const InputDecoration(
                              labelText: 'Floor',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: configuration,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Configuration',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '1 BHK',
                                child: Text('1 BHK'),
                              ),
                              DropdownMenuItem(
                                value: '2 BHK',
                                child: Text('2 BHK'),
                              ),
                              DropdownMenuItem(
                                value: '3 BHK',
                                child: Text('3 BHK'),
                              ),
                              DropdownMenuItem(
                                value: '4 BHK',
                                child: Text('4 BHK'),
                              ),
                              DropdownMenuItem(
                                value: '5 BHK',
                                child: Text('5 BHK'),
                              ),
                              DropdownMenuItem(
                                value: 'Other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  configuration = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: auditNameController,
                      decoration: const InputDecoration(
                        labelText: 'Audit Name',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Example: Builder quoted 60% loading',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Required fields',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (builderController.text.trim().isEmpty ||
                      projectController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter Builder and Project Name.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, {
                    'builder': builderController.text.trim(),
                    'project': projectController.text.trim(),
                    'tower': towerController.text.trim(),
                    'flat': flatController.text.trim(),
                    'floor': floorController.text.trim(),
                    'configuration': configuration,
                    'auditName': auditNameController.text.trim(),
                    'notes': notesController.text.trim(),
                  });
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Audit'),
              ),
            ],
          );
        },
      );
    },
  );

  // Keep form controllers alive until the closing route animation finishes.
  await Future<void>.delayed(const Duration(milliseconds: 350));

  builderController.dispose();
  projectController.dispose();
  towerController.dispose();
  flatController.dispose();
  floorController.dispose();
  auditNameController.dispose();
  notesController.dispose();

  return result;
}

// ============================================================
// AREA CALCULATOR
// ============================================================

class AreaCalculatorScreen extends StatelessWidget {
  const AreaCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StandaloneCalculatorPage();
  }
}

class StandaloneCalculatorPage extends StatefulWidget {
  const StandaloneCalculatorPage({super.key});

  @override
  State<StandaloneCalculatorPage> createState() =>
      _StandaloneCalculatorPageState();
}

class _StandaloneCalculatorPageState extends State<StandaloneCalculatorPage> {
  final List<RoomData> rooms = [RoomData(name: 'Living Room')];

  double internalWallPercent = 12.0;
  double externalWallPercent = 0.0;
  double loadingPercent = 30.0;

  double get usableArea {
    double totalSquareMeters = 0.0;

    for (final room in rooms) {
      if (room.lengthMeters > 0 && room.widthMeters > 0) {
        totalSquareMeters += room.lengthMeters * room.widthMeters;
      }
    }

    return DimensionParser.squareMetersToSquareFeet(totalSquareMeters);
  }

  double get internalWallArea {
    return usableArea * internalWallPercent / 100.0;
  }

  double get builtUpArea {
    return usableArea + internalWallArea;
  }

  double get externalWallArea {
    return usableArea * externalWallPercent / 100.0;
  }

  double get loadingArea {
    return builtUpArea * loadingPercent / 100.0;
  }

  double get superBuiltUpArea {
    return builtUpArea + externalWallArea + loadingArea;
  }

  void addRoom() {
    if (rooms.any((room) => !room.hasMeasurements)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the current room length and width before adding another room.',
          ),
        ),
      );
      return;
    }
    setState(() {
      rooms.insert(0, RoomData(name: 'Other / Custom'));
    });
  }

  void removeRoom(int index) {
    if (rooms.length == 1) return;

    setState(() {
      rooms.removeAt(index);
    });
  }

  Future<void> saveCalculatorAudit() async {
    final details = await showAuditDetailsDialog(
      context,
      suggestedName: '${rooms.length} Areas - Flatverify.ai Calculation',
    );

    if (details == null) return;

    final Box box = SessionController.instance.reports;

    final List<Map<String, dynamic>> roomList = rooms.map((room) {
      return {
        'name': room.name,
        'lengthMeters': room.lengthMeters,
        'widthMeters': room.widthMeters,
        'unit': room.unit.name,
      };
    }).toList();

    await box.add({
      'type': 'calculator',
      'auditName': details['auditName'],
      'builder': details['builder'],
      'project': details['project'],
      'tower': details['tower'],
      'flat': details['flat'],
      'floor': details['floor'],
      'configuration': details['configuration'],
      'notes': details['notes'],
      'timestamp': DateTime.now().toIso8601String(),
      'rooms': roomList,
      'usableArea': usableArea,
      'carpetArea': usableArea,
      'internalWallPercent': internalWallPercent,
      'internalWallArea': internalWallArea,
      'builtUpArea': builtUpArea,
      'externalWallPercent': externalWallPercent,
      'externalWallArea': externalWallArea,
      'loadingPercent': loadingPercent,
      'loadingArea': loadingArea,
      'superBuiltUpArea': superBuiltUpArea,
    });

    if (!mounted) return;

    setState(() {
      rooms
        ..clear()
        ..add(RoomData(name: 'Living Room'));
      internalWallPercent = 12.0;
      externalWallPercent = 0.0;
      loadingPercent = 30.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Area audit saved successfully. Ready for a new property.',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Area Calculator',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalculatorHeader(
              displayUnit: AreaDisplayUnit.imperial,
              usableArea: usableArea,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Rooms / Spaces',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: addRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Add room'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ...List.generate(
              rooms.length,
              (index) => RoomCard(
                key: ValueKey(rooms[index]),
                room: rooms[index],
                roomNumber: index + 1,
                onDelete: () => removeRoom(index),
                onChanged: () {
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 18),

            const _SectionTitle(
              title: 'Wall assumptions',
              subtitle:
                  'Adjust these values according to your property or drawing.',
            ),

            const SizedBox(height: 12),

            _PercentageInput(
              label: 'Internal wall',
              value: internalWallPercent,
              onChanged: (value) {
                setState(() {
                  internalWallPercent = value;
                });
              },
            ),

            const SizedBox(height: 10),

            _PercentageInput(
              label: 'External wall / other',
              value: externalWallPercent,
              onChanged: (value) {
                setState(() {
                  externalWallPercent = value;
                });
              },
            ),

            const SizedBox(height: 10),

            _PercentageInput(
              label: 'Loading / common area',
              value: loadingPercent,
              onChanged: (value) {
                setState(() {
                  loadingPercent = value;
                });
              },
            ),

            const SizedBox(height: 22),

            const _SectionTitle(
              title: 'Area calculation',
              subtitle: 'External wall is kept separate from built-up area.',
            ),

            const SizedBox(height: 12),

            _ResultCard(
              title: 'Calculated Carpet Area',
              value: usableArea,
              icon: Icons.square_foot,
              subtitle: 'Total area of entered rooms / spaces',
            ),

            _ResultCard(
              title: 'Internal Wall Area',
              value: internalWallArea,
              icon: Icons.home_work_outlined,
              subtitle: '${internalWallPercent.toStringAsFixed(1)}% assumption',
            ),

            _ResultCard(
              title: 'Built-up Area',
              value: builtUpArea,
              icon: Icons.home_outlined,
              subtitle: 'Carpet area + internal wall area',
              highlighted: true,
            ),

            _ResultCard(
              title: 'External Wall / Other Area',
              value: externalWallArea,
              icon: Icons.domain,
              subtitle:
                  '${externalWallPercent.toStringAsFixed(1)}% shown separately',
            ),

            _ResultCard(
              title: 'Loading / Common Area',
              value: loadingArea,
              icon: Icons.add_chart,
              subtitle:
                  '${loadingPercent.toStringAsFixed(1)}% of built-up area',
            ),

            _ResultCard(
              title: 'Super Built-up / Saleable Area',
              value: superBuiltUpArea,
              icon: Icons.apartment,
              subtitle: 'Built-up + external/other + loading',
              highlighted: true,
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4D47A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These calculations are estimates based on the assumptions you enter. Actual construction and legal area definitions may vary by project and applicable regulations.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF6B5A20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveCalculatorAudit,
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Save Area Audit',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CALCULATOR HEADER
// ============================================================

class _CalculatorHeader extends StatelessWidget {
  final double? usableArea;
  final AreaDisplayUnit? displayUnit;

  const _CalculatorHeader({required this.usableArea, this.displayUnit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172B65), Color(0xFF2457D6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.calculate, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property Area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usableArea == null
                      ? ''
                      : displayUnit != null
                      ? '${displayUnit!.formatArea(usableArea!)}\nCalculated carpet area'
                      : '${DimensionParser.format(usableArea! / DimensionParser.squareMeterToSquareFeet)} m²  •  '
                            '${DimensionParser.format(usableArea!)} sq ft\nCalculated carpet area',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12.5,
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

// ============================================================
// ROOM CARD
// ============================================================

class RoomCard extends StatefulWidget {
  final AreaDisplayUnit? displayUnit;
  final RoomData room;
  final int roomNumber;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final bool requiresConfirmation;
  final bool isConfirmed;
  final VoidCallback? onConfirm;

  const RoomCard({
    super.key,
    this.displayUnit,
    required this.room,
    required this.roomNumber,
    required this.onDelete,
    required this.onChanged,
    this.requiresConfirmation = false,
    this.isConfirmed = true,
    this.onConfirm,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  late final TextEditingController nameController;

  late final TextEditingController customNameController;

  late final TextEditingController lengthPrimaryController;

  late final TextEditingController lengthSecondaryController;

  late final TextEditingController widthPrimaryController;

  late final TextEditingController widthSecondaryController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.room.name);

    customNameController = TextEditingController();

    lengthPrimaryController = TextEditingController();

    lengthSecondaryController = TextEditingController();

    widthPrimaryController = TextEditingController();

    widthSecondaryController = TextEditingController();

    _loadValuesIntoFields();
  }

  @override
  void dispose() {
    nameController.dispose();
    customNameController.dispose();
    lengthPrimaryController.dispose();
    lengthSecondaryController.dispose();
    widthPrimaryController.dispose();
    widthSecondaryController.dispose();
    super.dispose();
  }

  bool get isCustomRoom {
    return !roomOptionExists(widget.room.name);
  }

  bool roomOptionExists(String name) {
    for (final category in roomCategories.values) {
      if (category.contains(name)) {
        return true;
      }
    }
    return false;
  }

  List<String> get dropdownValues {
    return [
      ...roomCategories.values.expand((items) => items),
      customRoomOption,
    ];
  }

  void _loadValuesIntoFields() {
    final double length = widget.room.lengthMeters;

    final double width = widget.room.widthMeters;

    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        _setFeetInches(length, width);
        break;

      case DimensionUnit.meterCm:
        _setMeterCm(length, width);
        break;

      case DimensionUnit.decimalFeet:
        _setDecimalFeet(length, width);
        break;
    }

    if (isCustomRoom) {
      customNameController.text = widget.room.name;
    }
  }

  void _setFeetInches(double length, double width) {
    final double lengthTotalInches = DimensionParser.metersToInches(length);

    final int lengthFeet = lengthTotalInches ~/ 12;

    final double lengthInches = lengthTotalInches - (lengthFeet * 12);

    final double widthTotalInches = DimensionParser.metersToInches(width);

    final int widthFeet = widthTotalInches ~/ 12;

    final double widthInches = widthTotalInches - (widthFeet * 12);

    lengthPrimaryController.text = length > 0 ? lengthFeet.toString() : '';

    lengthSecondaryController.text = length > 0
        ? _cleanNumber(lengthInches)
        : '';

    widthPrimaryController.text = width > 0 ? widthFeet.toString() : '';

    widthSecondaryController.text = width > 0 ? _cleanNumber(widthInches) : '';
  }

  void _setMeterCm(double length, double width) {
    final int lengthMeters = length.floor();

    final double lengthCm = (length - lengthMeters) * 100;

    final int widthMeters = width.floor();

    final double widthCm = (width - widthMeters) * 100;

    lengthPrimaryController.text = length > 0 ? lengthMeters.toString() : '';

    lengthSecondaryController.text = length > 0 ? _cleanNumber(lengthCm) : '';

    widthPrimaryController.text = width > 0 ? widthMeters.toString() : '';

    widthSecondaryController.text = width > 0 ? _cleanNumber(widthCm) : '';
  }

  void _setDecimalFeet(double length, double width) {
    lengthPrimaryController.text = length > 0
        ? _cleanNumber(DimensionParser.metersToFeet(length))
        : '';

    widthPrimaryController.text = width > 0
        ? _cleanNumber(DimensionParser.metersToFeet(width))
        : '';

    lengthSecondaryController.clear();
    widthSecondaryController.clear();
  }

  String _cleanNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  void _changeUnit(DimensionUnit unit) {
    setState(() {
      widget.room.unit = unit;
      _loadValuesIntoFields();
    });

    widget.onChanged();
  }

  void _updateLength() {
    final double primary = double.tryParse(lengthPrimaryController.text) ?? 0.0;

    final double secondary =
        double.tryParse(lengthSecondaryController.text) ?? 0.0;

    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        widget.room.lengthMeters = DimensionParser.feetInchesToMeters(
          primary,
          secondary,
        );
        break;

      case DimensionUnit.meterCm:
        widget.room.lengthMeters = DimensionParser.meterCmToMeters(
          primary,
          secondary,
        );
        break;

      case DimensionUnit.decimalFeet:
        widget.room.lengthMeters = DimensionParser.decimalFeetToMeters(primary);
        break;
    }

    widget.onChanged();
  }

  void _updateWidth() {
    final double primary = double.tryParse(widthPrimaryController.text) ?? 0.0;

    final double secondary =
        double.tryParse(widthSecondaryController.text) ?? 0.0;

    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        widget.room.widthMeters = DimensionParser.feetInchesToMeters(
          primary,
          secondary,
        );
        break;

      case DimensionUnit.meterCm:
        widget.room.widthMeters = DimensionParser.meterCmToMeters(
          primary,
          secondary,
        );
        break;

      case DimensionUnit.decimalFeet:
        widget.room.widthMeters = DimensionParser.decimalFeetToMeters(primary);
        break;
    }

    widget.onChanged();
  }

  String get primaryLabel {
    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        return 'Feet';

      case DimensionUnit.meterCm:
        return 'Meter';

      case DimensionUnit.decimalFeet:
        return 'Decimal feet';
    }
  }

  String get secondaryLabel {
    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        return 'Inches';

      case DimensionUnit.meterCm:
        return 'CM';

      case DimensionUnit.decimalFeet:
        return '';
    }
  }

  double get areaSqFt {
    if (widget.room.lengthMeters <= 0 || widget.room.widthMeters <= 0) {
      return 0.0;
    }

    final double squareMeters =
        widget.room.lengthMeters * widget.room.widthMeters;

    return DimensionParser.squareMetersToSquareFeet(squareMeters);
  }

  String get dimensionPreview {
    if (widget.room.lengthMeters <= 0 || widget.room.widthMeters <= 0) {
      return 'Enter dimensions';
    }

    switch (widget.room.unit) {
      case DimensionUnit.feetInches:
        return '${DimensionParser.formatFeetInches(widget.room.lengthMeters)} × '
            '${DimensionParser.formatFeetInches(widget.room.widthMeters)}';

      case DimensionUnit.meterCm:
        return '${DimensionParser.formatMeterCm(widget.room.lengthMeters)} × '
            '${DimensionParser.formatMeterCm(widget.room.widthMeters)}';

      case DimensionUnit.decimalFeet:
        return '${DimensionParser.format(DimensionParser.metersToFeet(widget.room.lengthMeters))} ft × '
            '${DimensionParser.format(DimensionParser.metersToFeet(widget.room.widthMeters))} ft';
    }
  }

  Widget _dimensionField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        setState(() {});
        onChanged();
      },
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _unitButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        backgroundColor: selected ? Colors.white : Colors.transparent,
        foregroundColor: selected ? AppColors.primary : AppColors.secondaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),
  );
  Widget _roomNameSelector() {
    final String selectedValue = dropdownValues.contains(widget.room.name)
        ? widget.room.name
        : customRoomOption;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Room / Space',
        prefixIcon: Icon(Icons.meeting_room_outlined),
      ),
      items: [
        for (final category in roomCategories.entries) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: '__CATEGORY__${category.key}',
            child: Text(
              category.key,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          ...category.value.map(
            (roomName) => DropdownMenuItem<String>(
              value: roomName,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(roomName),
              ),
            ),
          ),
        ],
        const DropdownMenuItem<String>(
          value: customRoomOption,
          child: Text(
            'Other / Custom',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null || value.startsWith('__CATEGORY__')) {
          return;
        }

        setState(() {
          widget.room.name = value;

          if (value != customRoomOption) {
            nameController.text = value;
          } else {
            nameController.clear();
          }
        });

        widget.onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDecimal = widget.room.unit == DimensionUnit.decimalFeet;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${widget.roomNumber}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Room / Space',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _roomNameSelector(),

          if (isCustomRoom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: customNameController,
              onChanged: (value) {
                widget.room.name = value.trim().isEmpty
                    ? customRoomOption
                    : value.trim();
                widget.onChanged();
              },
              decoration: const InputDecoration(
                labelText: 'Enter custom room / area name',
                hintText: 'Example: Store Balcony',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
          ],

          const SizedBox(height: 16),

          const Text(
            'Dimension unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _unitButton(
                    label: 'Feet / Inches',
                    selected: widget.room.unit == DimensionUnit.feetInches,
                    onTap: () {
                      _changeUnit(DimensionUnit.feetInches);
                    },
                  ),
                ),
                Expanded(
                  child: _unitButton(
                    label: 'Meter / CM',
                    selected: widget.room.unit == DimensionUnit.meterCm,
                    onTap: () {
                      _changeUnit(DimensionUnit.meterCm);
                    },
                  ),
                ),
                Expanded(
                  child: _unitButton(
                    label: 'Decimal Feet',
                    selected: widget.room.unit == DimensionUnit.decimalFeet,
                    onTap: () {
                      _changeUnit(DimensionUnit.decimalFeet);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Length',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _dimensionField(
                  label: primaryLabel,
                  controller: lengthPrimaryController,
                  onChanged: _updateLength,
                ),
              ),
              if (!isDecimal) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _dimensionField(
                    label: secondaryLabel,
                    controller: lengthSecondaryController,
                    onChanged: _updateLength,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          const Text(
            'Width',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _dimensionField(
                  label: primaryLabel,
                  controller: widthPrimaryController,
                  onChanged: _updateWidth,
                ),
              ),
              if (!isDecimal) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _dimensionField(
                    label: secondaryLabel,
                    controller: widthSecondaryController,
                    onChanged: _updateWidth,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dimension',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dimensionPreview,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Room area',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    (widget.displayUnit ?? AreaDisplayUnit.imperial).formatArea(
                      areaSqFt,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.requiresConfirmation) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isConfirmed
                    ? const Color(0xFFEFFAF3)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isConfirmed
                      ? const Color(0xFFB8E6C9)
                      : const Color(0xFFF4D47A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isConfirmed
                        ? Icons.verified_outlined
                        : Icons.auto_awesome_outlined,
                    color: widget.isConfirmed
                        ? AppColors.green
                        : AppColors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.isConfirmed
                          ? 'Confirmed by user • Included in total area'
                          : 'OCR estimate • Confirm to include in total area.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isConfirmed
                            ? AppColors.green
                            : const Color(0xFF6B5A20),
                      ),
                    ),
                  ),
                  if (!widget.isConfirmed)
                    TextButton(
                      onPressed: widget.onConfirm,
                      child: const Text('Confirm'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// PERCENTAGE INPUT
// ============================================================

class _PercentageInput extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PercentageInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PercentageInput> createState() => _PercentageInputState();
}

class _PercentageInputState extends State<_PercentageInput> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _PercentageInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value &&
        controller.text != widget.value.toStringAsFixed(1)) {
      controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          SizedBox(
            width: 85,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              onChanged: (text) {
                final double? parsed = double.tryParse(text);

                if (parsed != null) {
                  widget.onChanged(parsed);
                }
              },
              decoration: const InputDecoration(
                suffixText: '%',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// RESULT CARD
// ============================================================

class _ResultCard extends StatelessWidget {
  final AreaDisplayUnit? displayUnit;
  final String title;
  final double? value;
  final IconData icon;
  final String subtitle;
  final bool highlighted;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
    this.highlighted = false,
    this.displayUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEEF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: highlighted ? const Color(0xFFBFD0FF) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: highlighted ? Colors.white : const Color(0xFFF3F5F9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: highlighted ? AppColors.primary : AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (displayUnit ?? AreaDisplayUnit.metric).formatArea(value!),
                  style: TextStyle(
                    fontSize: highlighted ? 18 : 16,
                    fontWeight: FontWeight.w900,
                    color: highlighted ? AppColors.primary : AppColors.dark,
                  ),
                ),
                if (displayUnit == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${DimensionParser.format(value!)} sq ft',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// HELPER FUNCTION
// ============================================================

double _dynamicDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return 0.0;
}

// ============================================================
// OCR SCANNER
// ============================================================

enum VerifyInputMode { manual, photo }

class OcrScannerScreen extends StatefulWidget {
  final VerifyInputMode? initialMode;

  const OcrScannerScreen({super.key, this.initialMode});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _VerificationDraft {
  AreaDisplayUnit displayUnit = AreaDisplayUnit.imperial;
  bool unitChosenByUser = false;
  final Set<AreaDisplayUnit> detectedUnits = {};
  String extractedText = '';
  Map<String, String> parsedDimensions = {};
  final List<File> selectedImages = [];
  final List<_ScanPhotoData> scanPhotos = [];
  final Set<String> dismissedOcrPairIds = {};
  List<RoomData> rooms = [];
  bool isProcessing = false;
  double internalWallPercent = 12;
  double externalWallPercent = 0;
  double loadingPercent = 30;
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final _resultsKey = GlobalKey();
  final _manualDraft = _VerificationDraft();
  final _photoDraft = _VerificationDraft();
  _VerificationDraft get _draft =>
      selectedMode == VerifyInputMode.manual ? _manualDraft : _photoDraft;
  AreaDisplayUnit get displayUnit => _draft.displayUnit;
  set displayUnit(AreaDisplayUnit value) => _draft.displayUnit = value;
  bool get _unitChosenByUser => _draft.unitChosenByUser;
  set _unitChosenByUser(bool value) => _draft.unitChosenByUser = value;
  Set<AreaDisplayUnit> get _detectedUnits => _draft.detectedUnits;

  void selectDisplayUnit(AreaDisplayUnit unit) {
    setState(() {
      displayUnit = unit;
      _unitChosenByUser = true;
    });
  }

  final ImagePicker picker = ImagePicker();
  final TextRecognizer textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  String get extractedText => _draft.extractedText;
  set extractedText(String value) => _draft.extractedText = value;
  Map<String, String> get parsedDimensions => _draft.parsedDimensions;
  set parsedDimensions(Map<String, String> value) =>
      _draft.parsedDimensions = value;
  List<File> get selectedImages => _draft.selectedImages;
  List<_ScanPhotoData> get scanPhotos => _draft.scanPhotos;
  Set<String> get dismissedOcrPairIds => _draft.dismissedOcrPairIds;
  int _photoSequence = 0;
  List<RoomData> get scanRooms => _draft.rooms;
  set scanRooms(List<RoomData> value) => _draft.rooms = value;
  VerifyInputMode? selectedMode;

  @override
  void initState() {
    super.initState();
    selectedMode = widget.initialMode ?? VerifyInputMode.photo;
    if (selectedMode == VerifyInputMode.manual) {
      scanRooms.add(RoomData(name: 'Living Room'));
    }
  }

  bool get isProcessing => _draft.isProcessing;
  set isProcessing(bool value) => _draft.isProcessing = value;
  double get internalWallPercent => _draft.internalWallPercent;
  set internalWallPercent(double value) => _draft.internalWallPercent = value;
  double get externalWallPercent => _draft.externalWallPercent;
  set externalWallPercent(double value) => _draft.externalWallPercent = value;
  double get loadingPercent => _draft.loadingPercent;
  set loadingPercent(double value) => _draft.loadingPercent = value;

  double get usableArea {
    double totalSquareMeters = 0.0;
    for (final room in scanRooms) {
      if (room.contributesToTotal) {
        totalSquareMeters += room.lengthMeters * room.widthMeters;
      }
    }
    return DimensionParser.squareMetersToSquareFeet(totalSquareMeters);
  }

  double get internalWallArea => usableArea * internalWallPercent / 100.0;
  bool get hasCalculatedRooms =>
      scanRooms.any((room) => room.contributesToTotal);
  double get builtUpArea => usableArea + internalWallArea;
  double get externalWallArea => usableArea * externalWallPercent / 100.0;
  double get loadingArea => builtUpArea * loadingPercent / 100.0;
  double get superBuiltUpArea => builtUpArea + externalWallArea + loadingArea;

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> scanFromGallery() async {
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 90);
    if (images.isEmpty) return;
    for (final image in images) {
      await processImage(File(image.path));
    }
  }

  Future<void> scanFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) return;
    await processImage(File(image.path));
  }

  Future<void> processImage(File image) async {
    final String photoId =
        'photo_${DateTime.now().microsecondsSinceEpoch}_${_photoSequence++}';
    final _ScanPhotoData photo = _ScanPhotoData(
      id: photoId,
      imageFile: image,
      originalPath: image.path,
    );
    setState(() {
      selectedImages.add(image);
      scanPhotos.add(photo);
      isProcessing = true;
    });

    try {
      final InputImage inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      final String text = recognizedText.text;
      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map(
            (line) => PlanTextLine(
              line.text,
              line.boundingBox.left,
              line.boundingBox.top,
              line.boundingBox.width,
              line.boundingBox.height,
            ),
          )
          .toList();
      final measurements = lines.isEmpty
          ? DimensionScanParser.parseRooms(text)
          : DimensionScanParser.parseLayout(lines);

      if (!mounted) return;
      setState(() {
        photo.ocrText = text;
        for (final room in measurements) {
          for (final dimension in [room.length, room.width]) {
            if (dimension.isEmpty) continue;
            _detectedUnits.add(
              RegExp(r'(mm|cm|m)\s*$', caseSensitive: false).hasMatch(dimension)
                  ? AreaDisplayUnit.metric
                  : AreaDisplayUnit.imperial,
            );
          }
        }
        if (!_unitChosenByUser && _detectedUnits.isNotEmpty) {
          displayUnit = _detectedUnits.first;
        }
        photo.dimensions
          ..clear()
          ..addAll(measurements.expand((room) => [room.length, room.width]));
        photo.roomNames
          ..clear()
          ..addAll(measurements.map((room) => room.name));
        _ensurePairIds(photo);
        _appendRoomsForPhoto(photo);
        _refreshCompatibilityFields();
        isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    }
  }

  double _dimensionTextToMeters(String value) =>
      DimensionScanParser.toMeters(value);
  RoomData? _roomFromDimensionPair(
    String lengthText,
    String widthText,
    int pairIndex,
  ) {
    final double length = _dimensionTextToMeters(lengthText);
    final double width = _dimensionTextToMeters(widthText);
    if (length <= 0 || width <= 0) return null;

    return RoomData(
      name: 'Room ${pairIndex + 1}',
      lengthMeters: length,
      widthMeters: width,
      unit:
          RegExp(
            r'(?:mm|cm|metres?|meters?|m)\s*$',
            caseSensitive: false,
          ).hasMatch(lengthText)
          ? DimensionUnit.meterCm
          : DimensionUnit.feetInches,
      isAutoExtracted: true,
    );
  }

  void _ensurePairIds(_ScanPhotoData photo) {
    final int pairCount = photo.dimensions.length ~/ 2;
    while (photo.pairIds.length < pairCount) {
      photo.pairIds.add('${photo.id}_pair_${photo.pairIds.length}');
    }
    if (photo.pairIds.length > pairCount) {
      photo.pairIds.removeRange(pairCount, photo.pairIds.length);
    }
  }

  void _refreshCompatibilityFields() {
    final List<String> textSections = [];
    final Map<String, String> dimensions = {};
    int dimensionNumber = 1;
    for (int photoIndex = 0; photoIndex < scanPhotos.length; photoIndex++) {
      final _ScanPhotoData photo = scanPhotos[photoIndex];
      if (photo.ocrText.trim().isNotEmpty) {
        textSections.add('--- Photo ${photoIndex + 1} ---\n${photo.ocrText}');
      }
      for (final value in photo.dimensions) {
        dimensions['Dimension $dimensionNumber'] = value;
        dimensionNumber++;
      }
    }
    extractedText = textSections.join('\n\n');
    parsedDimensions = dimensions;
  }

  void _appendRoomsForPhoto(_ScanPhotoData photo) {
    _ensurePairIds(photo);
    for (int pairIndex = 0; pairIndex < photo.pairIds.length; pairIndex++) {
      final String pairId = photo.pairIds[pairIndex];
      if (dismissedOcrPairIds.contains(pairId) ||
          scanRooms.any((room) => room.sourcePairId == pairId)) {
        continue;
      }
      final int dimensionIndex = pairIndex * 2;
      final RoomData room =
          _roomFromDimensionPair(
            photo.dimensions[dimensionIndex],
            photo.dimensions[dimensionIndex + 1],
            scanRooms.where((room) => room.sourcePairId != null).length,
          ) ??
          RoomData(name: 'Room ${scanRooms.length + 1}', isAutoExtracted: true);
      {
        if (pairIndex < photo.roomNames.length &&
            photo.roomNames[pairIndex] != null) {
          room.name = photo.roomNames[pairIndex]!;
        }
        room.sourcePhotoId = photo.id;
        room.sourcePairId = pairId;
        scanRooms.add(room);
      }
    }
  }

  void _syncUnverifiedRoomsFromPhotos() {
    final Set<String> activePairIds = {};
    for (final photo in scanPhotos) {
      _ensurePairIds(photo);
      for (int pairIndex = 0; pairIndex < photo.pairIds.length; pairIndex++) {
        final String pairId = photo.pairIds[pairIndex];
        activePairIds.add(pairId);
        final int dimensionIndex = pairIndex * 2;
        final int existingIndex = scanRooms.indexWhere(
          (room) => room.sourcePairId == pairId,
        );
        if (existingIndex >= 0) {
          final RoomData existing = scanRooms[existingIndex];
          if (!existing.isUserVerified) {
            final RoomData? updated = _roomFromDimensionPair(
              photo.dimensions[dimensionIndex],
              photo.dimensions[dimensionIndex + 1],
              pairIndex,
            );
            if (updated == null) {
              scanRooms.removeAt(existingIndex);
            } else {
              existing.lengthMeters = updated.lengthMeters;
              existing.widthMeters = updated.widthMeters;
            }
          }
        } else if (!dismissedOcrPairIds.contains(pairId)) {
          _appendRoomsForPhoto(photo);
        }
      }
    }
    scanRooms.removeWhere(
      (room) =>
          room.sourcePairId != null &&
          !room.isUserVerified &&
          !activePairIds.contains(room.sourcePairId),
    );
  }

  void _addManualRoom() {
    if (scanRooms.any(
      (room) => !room.isAutoExtracted && !room.hasMeasurements,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the current room length and width before adding another room.',
          ),
        ),
      );
      return;
    }
    setState(() => scanRooms.insert(0, RoomData(name: 'Other / Custom')));
  }

  Future<void> _editScannedRoom(RoomData room) async {
    final RoomData? edited = await showDialog<RoomData>(
      context: context,
      builder: (_) => ScannedRoomEditor(room: room, displayUnit: displayUnit),
    );
    if (!mounted || edited == null || !scanRooms.contains(room)) return;
    setState(() {
      room.name = edited.name;
      room.lengthMeters = edited.lengthMeters;
      room.widthMeters = edited.widthMeters;
      room.isUserVerified = true;
    });
  }

  void _removeRoom(int index) {
    final draft = _draft;
    final removed = draft.rooms[index];
    setState(() {
      final RoomData room = scanRooms[index];
      if (room.sourcePairId != null) {
        dismissedOcrPairIds.add(room.sourcePairId!);
      }
      scanRooms.removeAt(index);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (!mounted || draft.rooms.contains(removed)) return;
            setState(() {
              draft.rooms.insert(index.clamp(0, draft.rooms.length), removed);
              if (removed.sourcePairId != null) {
                draft.dismissedOcrPairIds.remove(removed.sourcePairId);
              }
            });
          },
        ),
      ),
    );
  }

  void _confirmRoom(RoomData room) {
    setState(() => room.isUserVerified = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('${room.name} confirmed and added to the total'),
      ),
    );
  }

  Future<void> _openImageReview(int initialIndex) async {
    if (selectedImages.isEmpty) return;
    int currentIndex = initialIndex.clamp(0, selectedImages.length - 1).toInt();
    final PageController controller = PageController(initialPage: currentIndex);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              backgroundColor: Colors.black,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Photo ${currentIndex + 1} of ${selectedImages.length} • pinch to zoom',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller,
                        itemCount: selectedImages.length,
                        onPageChanged: (index) {
                          setDialogState(() => currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 6,
                            child: Center(
                              child: Image.file(
                                selectedImages[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _deletePhoto(int index) async {
    final String photoId = scanPhotos[index].id;
    final int removableRooms = scanRooms
        .where((room) => room.sourcePhotoId == photoId && !room.isUserVerified)
        .length;
    final int preservedRooms = scanRooms
        .where((room) => room.sourcePhotoId == photoId && room.isUserVerified)
        .length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete floor-plan photo?'),
        content: Text(
          'This removes the photo, its OCR text and dimensions, and $removableRooms '
          'unverified OCR room(s). $preservedRooms room(s) you edited will be kept as verified data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete photo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      scanRooms.removeWhere(
        (room) => room.sourcePhotoId == photoId && !room.isUserVerified,
      );
      for (final room in scanRooms.where(
        (room) => room.sourcePhotoId == photoId,
      )) {
        room.sourcePhotoId = null;
        room.sourcePairId = null;
        room.isAutoExtracted = false;
      }
      selectedImages.removeAt(index);
      scanPhotos.removeAt(index);
      _refreshCompatibilityFields();
    });
  }

  Future<void> reviewAndEditScan() async {
    if (scanPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a floor-plan photo first.')),
      );
      return;
    }

    final List<List<String>> editable = scanPhotos
        .map((photo) => List<String>.from(photo.dimensions))
        .toList();
    for (final dimensions in editable) {
      if (dimensions.isEmpty) {
        dimensions.addAll(['', '']);
      } else if (dimensions.length.isOdd) {
        dimensions.add('');
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Review OCR Dimensions',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: AppColors.orange,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dimensions are paired in order as Length × Width. Correct OCR mistakes or enter values missed because the photo was unclear. The room calculation updates after you apply the changes.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(editable.length, (photoIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo ${photoIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(editable[photoIndex].length, (
                              dimensionIndex,
                            ) {
                              final controller = TextEditingController(
                                text: editable[photoIndex][dimensionIndex],
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        onChanged: (value) =>
                                            editable[photoIndex][dimensionIndex] =
                                                value,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Dimension ${dimensionIndex + 1}',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        editable[photoIndex].removeAt(
                                          dimensionIndex,
                                        );
                                        setDialogState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (editable.isNotEmpty) editable.last.add('');
                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add missing dimension'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < scanPhotos.length; i++) {
                        scanPhotos[i].dimensions
                          ..clear()
                          ..addAll(
                            editable[i]
                                .map((value) => value.trim())
                                .where((value) => value.isNotEmpty),
                          );
                        _ensurePairIds(scanPhotos[i]);
                      }
                      _syncUnverifiedRoomsFromPhotos();
                      _refreshCompatibilityFields();
                    });
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Measurements updated and property area recalculated.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Apply & Recalculate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> saveScanAudit() async {
    if (selectedImages.isEmpty &&
        extractedText.trim().isEmpty &&
        parsedDimensions.isEmpty &&
        scanRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan a floor plan or enter dimensions first.'),
        ),
      );
      return;
    }

    final bool isPhotoAudit =
        scanPhotos.isNotEmpty ||
        extractedText.trim().isNotEmpty ||
        parsedDimensions.isNotEmpty;
    final details = await showAuditDetailsDialog(
      context,
      suggestedName: isPhotoAudit
          ? 'Floor Plan Scan - ${selectedImages.length} photo${selectedImages.length == 1 ? '' : 's'}'
          : '${scanRooms.length} Areas - Flatverify.ai Calculation',
    );
    if (details == null) return;

    final List<Map<String, dynamic>> roomList = scanRooms
        .where((room) => room.contributesToTotal)
        .map((room) {
          return {
            'name': room.name,
            'lengthMeters': room.lengthMeters,
            'widthMeters': room.widthMeters,
            'unit': room.unit.name,
            'source': room.isUserVerified
                ? 'verified'
                : (room.isAutoExtracted ? 'ocr' : 'manual'),
            'sourcePhotoId': room.sourcePhotoId,
            'sourcePairId': room.sourcePairId,
            'isUserVerified': room.isUserVerified,
          };
        })
        .toList();

    final List<String> imagePaths = selectedImages
        .map((image) => image.path)
        .toList();
    final List<Uint8List> imageBytes = [];
    final List<Map<String, dynamic>> savedScanPhotos = [];
    for (final photo in scanPhotos) {
      Uint8List? bytes;
      try {
        final Uint8List readBytes = await photo.imageFile.readAsBytes();
        bytes = readBytes;
        imageBytes.add(readBytes);
      } catch (_) {
        // Keep the audit save working even if one image can no longer be read.
      }
      savedScanPhotos.add({
        'id': photo.id,
        'originalPath': photo.originalPath,
        'ocrText': photo.ocrText,
        'dimensions': List<String>.from(photo.dimensions),
        'pairIds': List<String>.from(photo.pairIds),
        'generatedRoomIds': List<String>.from(photo.pairIds),
        if (bytes != null) 'imageBytes': bytes,
      });
    }

    final Box box = SessionController.instance.reports;

    await box.add({
      'type': isPhotoAudit ? 'scan' : 'calculator',
      'auditName': details['auditName'],
      'builder': details['builder'],
      'project': details['project'],
      'tower': details['tower'],
      'flat': details['flat'],
      'floor': details['floor'],
      'configuration': details['configuration'],
      'notes': details['notes'],
      'rawText': extractedText,
      'parsedDimensions': Map<String, String>.from(parsedDimensions),
      'timestamp': DateTime.now().toIso8601String(),
      'imagePath': imagePaths.isNotEmpty ? imagePaths.first : '',
      'imagePaths': imagePaths,
      'imageBytes': imageBytes,
      'scanPhotos': savedScanPhotos,
      'dismissedOcrPairIds': dismissedOcrPairIds.toList(),
      'rooms': roomList,
      'usableArea': usableArea,
      'carpetArea': usableArea,
      'internalWallPercent': internalWallPercent,
      'internalWallArea': internalWallArea,
      'builtUpArea': builtUpArea,
      'externalWallPercent': externalWallPercent,
      'externalWallArea': externalWallArea,
      'loadingPercent': loadingPercent,
      'loadingArea': loadingArea,
      'superBuiltUpArea': superBuiltUpArea,
    });

    if (!mounted) return;
    setState(() {
      selectedImages.clear();
      _detectedUnits.clear();
      _unitChosenByUser = false;
      displayUnit = AreaDisplayUnit.imperial;
      scanPhotos.clear();
      dismissedOcrPairIds.clear();
      extractedText = '';
      parsedDimensions = {};
      scanRooms = [];
      if (selectedMode == VerifyInputMode.manual) {
        scanRooms.add(RoomData(name: 'Living Room'));
      }
      isProcessing = false;
      internalWallPercent = 12.0;
      externalWallPercent = 0.0;
      loadingPercent = 30.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Property audit saved successfully. Ready for a new verification.',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _selectInputMode(VerifyInputMode mode) {
    if (isProcessing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait for the photo scan to finish before switching input methods.',
          ),
        ),
      );
      return;
    }
    setState(() {
      selectedMode = mode;
      if (mode == VerifyInputMode.manual && scanRooms.isEmpty) {
        scanRooms.add(RoomData(name: 'Living Room'));
      }
    });
  }

  Widget _photoStrip() => Column(
    children: [
      ...List.generate(
        selectedImages.length,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => _openImageReview(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImages[index],
                    width: 68,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 68,
                      height: 60,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floor plan ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap photo to review',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () => _deletePhoto(index),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: scanFromCamera,
            icon: const Icon(Icons.add_a_photo_outlined, size: 17),
            label: const Text('Add Camera'),
          ),
          TextButton.icon(
            onPressed: scanFromGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 17),
            label: const Text('Add Gallery'),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
          selectedMode == null || (scanRooms.isEmpty && selectedImages.isEmpty)
          ? null
          : _AreaSummaryBar(
              area: hasCalculatedRooms
                  ? displayUnit.formatArea(usableArea)
                  : null,
              photoMode: selectedMode == VerifyInputMode.photo,
              onResults: () {
                final target = _resultsKey.currentContext;
                if (target != null) {
                  Scrollable.ensureVisible(
                    target,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DraftHeader(),
              const SizedBox(height: 12),
              const Text(
                'Verify your area',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<VerifyInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: VerifyInputMode.photo,
                      label: Text('Scan Floor Plan'),
                    ),
                    ButtonSegment(
                      value: VerifyInputMode.manual,
                      label: Text('Enter Manually'),
                    ),
                  ],
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  selected: {if (selectedMode != null) selectedMode!},
                  onSelectionChanged: (modes) {
                    if (modes.isNotEmpty) _selectInputMode(modes.first);
                  },
                ),
              ),
              _VerificationProgress(
                manual: selectedMode == VerifyInputMode.manual,
                current:
                    selectedMode == null ||
                        (selectedMode == VerifyInputMode.photo &&
                            selectedImages.isEmpty)
                    ? 0
                    : scanRooms.isNotEmpty &&
                          scanRooms.every((room) => room.contributesToTotal)
                    ? 2
                    : 1,
              ),
              if (selectedMode == VerifyInputMode.photo &&
                  selectedImages.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 44,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Add your floor plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose a clear photo with visible room dimensions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ScanButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: scanFromCamera,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScanButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: scanFromGallery,
                      ),
                    ),
                  ],
                ),
              ],
              if (selectedMode != null) ...[
                if (isProcessing) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Reading room measurements…'),
                ],
                if (selectedImages.isNotEmpty) ...[
                  _photoStrip(),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedMode == VerifyInputMode.photo
                            ? 'Review rooms'
                            : 'Rooms / Spaces',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    Text(
                      '${scanRooms.where((room) => room.contributesToTotal).length} of ${scanRooms.length} ${selectedMode == VerifyInputMode.photo ? 'confirmed' : 'complete'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    color: const Color(0xFF16805D),
                    backgroundColor: const Color(0xFFDCE2EB),
                    value: scanRooms.isEmpty
                        ? 0
                        : scanRooms
                                  .where((room) => room.contributesToTotal)
                                  .length /
                              scanRooms.length,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tap a room to edit its measurements.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AreaUnitControl(
                      value: displayUnit,
                      onChanged: selectDisplayUnit,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(scanRooms.length, (index) {
                  final room = scanRooms[index];
                  if (room.sourcePhotoId != null) {
                    return ScanRoomDetailsCard(
                      room: room,
                      displayUnit: displayUnit,
                      onEdit: () => _editScannedRoom(room),
                      onConfirm: () => _confirmRoom(room),
                      onDelete: () => _removeRoom(index),
                    );
                  }
                  return RoomCard(
                    key: ValueKey(room),
                    room: room,
                    displayUnit: displayUnit,
                    roomNumber: index + 1,
                    onDelete: () => _removeRoom(index),
                    requiresConfirmation: room.isAutoExtracted,
                    isConfirmed: room.isUserVerified,
                    onConfirm: () => _confirmRoom(room),
                    onChanged: () => setState(() {
                      if (room.sourcePairId != null) room.isUserVerified = true;
                    }),
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addManualRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Add room'),
                  ),
                ),
                if (scanRooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No rooms yet. Add a photo or enter measurements to begin.',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                const SizedBox(height: 14),

                const _SectionTitle(
                  title: 'Wall assumptions',
                  subtitle:
                      'Adjust these values according to your property or drawing.',
                ),
                const SizedBox(height: 12),
                _PercentageInput(
                  label: 'Internal wall',
                  value: internalWallPercent,
                  onChanged: (value) =>
                      setState(() => internalWallPercent = value),
                ),
                const SizedBox(height: 10),
                _PercentageInput(
                  label: 'External wall / other',
                  value: externalWallPercent,
                  onChanged: (value) =>
                      setState(() => externalWallPercent = value),
                ),
                const SizedBox(height: 10),
                _PercentageInput(
                  label: 'Loading / common area',
                  value: loadingPercent,
                  onChanged: (value) => setState(() => loadingPercent = value),
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  key: _resultsKey,
                  title: 'Area calculation',
                  subtitle:
                      'External wall is kept separate from built-up area.',
                ),
                const SizedBox(height: 12),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'Calculated Carpet Area',
                  value: hasCalculatedRooms ? usableArea : null,
                  icon: Icons.square_foot,
                  subtitle: 'Confirmed scans and completed manual rooms',
                ),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'Internal Wall Area',
                  value: hasCalculatedRooms ? internalWallArea : null,
                  icon: Icons.home_work_outlined,
                  subtitle:
                      '${internalWallPercent.toStringAsFixed(1)}% assumption',
                ),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'Built-up Area',
                  value: hasCalculatedRooms ? builtUpArea : null,
                  icon: Icons.home_outlined,
                  subtitle: 'Carpet area + internal wall area',
                  highlighted: true,
                ),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'External Wall / Other Area',
                  value: hasCalculatedRooms ? externalWallArea : null,
                  icon: Icons.domain,
                  subtitle:
                      '${externalWallPercent.toStringAsFixed(1)}% shown separately',
                ),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'Loading / Common Area',
                  value: hasCalculatedRooms ? loadingArea : null,
                  icon: Icons.add_chart,
                  subtitle:
                      '${loadingPercent.toStringAsFixed(1)}% of built-up area',
                ),
                _ResultCard(
                  displayUnit: displayUnit,
                  title: 'Super Built-up / Saleable Area',
                  value: hasCalculatedRooms ? superBuiltUpArea : null,
                  icon: Icons.apartment,
                  subtitle: 'Built-up + external/other + loading',
                  highlighted: true,
                ),
                const SizedBox(height: 16),
                if (selectedMode == VerifyInputMode.photo ||
                    scanPhotos.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF4D47A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'OCR can be affected by photo angle, blur, shadows and drawing quality. Verify every extracted room and manually correct or add missing values before saving. Area calculations use the same method as the main Area Calculator.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Color(0xFF6B5A20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (extractedText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Extracted OCR text',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Tap to inspect raw text from all photos',
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SelectableText(
                          extractedText,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveScanAudit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Save Area Audit',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanReviewItem extends StatefulWidget {
  final int index;
  final String name;
  final TextEditingController dimensionController;

  final ValueChanged<String> onNameChanged;

  final ValueChanged<String> onDimensionChanged;

  final VoidCallback onDelete;

  const _ScanReviewItem({
    required this.index,
    required this.name,
    required this.dimensionController,
    required this.onNameChanged,
    required this.onDimensionChanged,
    required this.onDelete,
  });

  @override
  State<_ScanReviewItem> createState() => _ScanReviewItemState();
}

class _ScanReviewItemState extends State<_ScanReviewItem> {
  late String selectedName;

  @override
  void initState() {
    super.initState();
    selectedName = widget.name;
  }

  List<String> get allRoomNames => [
    ...roomCategories.values.expand((items) => items),
    customRoomOption,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detected item',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
            ],
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: allRoomNames.contains(selectedName)
                ? selectedName
                : customRoomOption,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Room / Area'),
            items: [
              ...roomCategories.entries.expand(
                (category) => [
                  DropdownMenuItem<String>(
                    value: '__CAT_${category.key}',
                    enabled: false,
                    child: Text(
                      category.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  ...category.value.map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ),
                  ),
                ],
              ),
              const DropdownMenuItem<String>(
                value: customRoomOption,
                child: Text('Other / Custom'),
              ),
            ],
            onChanged: (value) {
              if (value == null || value.startsWith('__CAT_')) {
                return;
              }

              setState(() {
                selectedName = value;
              });

              widget.onNameChanged(value);
            },
          ),

          const SizedBox(height: 10),

          TextField(
            controller: widget.dimensionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: widget.onDimensionChanged,
            decoration: const InputDecoration(
              labelText: 'Dimension',
              hintText: 'Example: 10\' 9"',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCAN BUTTON
// ============================================================

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 27),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SAVED AUDITS
// ============================================================

class SavedAuditsScreen extends StatefulWidget {
  const SavedAuditsScreen({super.key});

  @override
  State<SavedAuditsScreen> createState() => _SavedAuditsScreenState();
}

class _SavedAuditsScreenState extends State<SavedAuditsScreen> {
  final Box box = SessionController.instance.reports;

  Future<void> deleteAudit(int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete audit?'),
          content: const Text(
            'This saved property audit will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await box.deleteAt(index);

    if (mounted) {
      setState(() {});
    }
  }

  void previewAuditPdf(dynamic data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuditPdfPreviewScreen(data: data)),
    );
  }

  void openReport(dynamic data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SavedAuditReportScreen(data: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          SessionController.instance.isGuest
              ? 'Session Reports'
              : 'Saved Audits',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (SessionController.instance.isGuest)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GuestReportNotice(),
            ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.folder_open,
                              color: AppColors.primary,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No saved audits yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Your manual calculations and floor-plan scans will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final dynamic data = box.getAt(index);

                    final String type = data['type']?.toString() ?? 'scan';

                    final bool isCalculator = type == 'calculator';

                    final String auditName =
                        data['auditName']?.toString() ?? 'Saved Property Audit';

                    final String builder = data['builder']?.toString() ?? '';

                    final String project = data['project']?.toString() ?? '';

                    final String flat = data['flat']?.toString() ?? '';

                    final String timestamp =
                        data['timestamp']?.toString() ?? '';

                    DateTime? date;

                    try {
                      date = DateTime.parse(timestamp);
                    } catch (_) {}

                    String areaText = '';

                    if (isCalculator) {
                      final double carpet = _dynamicDouble(data['carpetArea']);

                      final double superBuilt = _dynamicDouble(
                        data['superBuiltUpArea'],
                      );

                      areaText =
                          '${DimensionParser.format(carpet)} sq ft carpet • '
                          '${DimensionParser.format(superBuilt)} sq ft SBA';
                    } else {
                      final dynamic dimensions = data['parsedDimensions'];

                      final int count = dimensions is Map
                          ? dimensions.length
                          : 0;

                      areaText = '$count detected dimensions';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => openReport(data),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isCalculator
                                          ? const Color(0xFFEAF0FF)
                                          : const Color(0xFFEFFAF3),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      isCalculator
                                          ? Icons.calculate_outlined
                                          : Icons.document_scanner_outlined,
                                      color: isCalculator
                                          ? AppColors.primary
                                          : AppColors.green,
                                    ),
                                  ),

                                  const SizedBox(width: 13),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auditName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.dark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isCalculator
                                              ? 'MANUAL CALCULATION'
                                              : 'FLOOR PLAN SCAN',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isCalculator
                                                ? AppColors.primary
                                                : AppColors.green,
                                          ),
                                        ),
                                        if (builder.isNotEmpty ||
                                            project.isNotEmpty)
                                          const SizedBox(height: 5),
                                        if (builder.isNotEmpty ||
                                            project.isNotEmpty)
                                          Text(
                                            [
                                              if (builder.isNotEmpty) builder,
                                              if (project.isNotEmpty) project,
                                            ].join(' • '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        if (flat.isNotEmpty)
                                          Text(
                                            'Flat $flat',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        const SizedBox(height: 5),
                                        Text(
                                          areaText,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          date != null
                                              ? '${date.day}/${date.month}/${date.year}'
                                              : 'Saved audit',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.secondaryText,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Container(height: 1, color: AppColors.border),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => openReport(data),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 18,
                                    ),
                                    label: const Text('Open Report'),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: AppColors.border,
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => previewAuditPdf(data),
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('View PDF'),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: AppColors.border,
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => deleteAudit(index),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SAVED AUDIT REPORT
// ============================================================

class SavedAuditReportScreen extends StatefulWidget {
  final dynamic data;

  const SavedAuditReportScreen({super.key, required this.data});

  @override
  State<SavedAuditReportScreen> createState() => _SavedAuditReportScreenState();
}

class _SavedAuditReportScreenState extends State<SavedAuditReportScreen> {
  dynamic get data => widget.data;
  AreaDisplayUnit displayUnit = AreaDisplayUnit.imperial;

  bool get isCalculator => data['type']?.toString() == 'calculator';

  String get auditName =>
      data['auditName']?.toString() ?? 'Property Area Report';

  double value(String key) {
    return _dynamicDouble(data[key]);
  }

  void previewPdf(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AuditPdfPreviewScreen(data: data, displayUnit: displayUnit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String builder = data['builder']?.toString() ?? '';

    final String project = data['project']?.toString() ?? '';

    final String tower = data['tower']?.toString() ?? '';

    final String flat = data['flat']?.toString() ?? '';

    final String floor = data['floor']?.toString() ?? '';

    final String configuration = data['configuration']?.toString() ?? '';

    final String notes = data['notes']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Property Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => previewPdf(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AreaUnitControl(
                value: displayUnit,
                onChanged: (unit) => setState(() => displayUnit = unit),
              ),
            ),
            const SizedBox(height: 16),
            const BrandHeader(compact: true),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF172B65), Color(0xFF2457D6)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auditName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    isCalculator
                        ? 'Manual Area Calculation'
                        : 'Floor Plan OCR Scan',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if ([
              builder,
              project,
              tower,
              flat,
              floor,
              configuration,
            ].any((value) => value.trim().isNotEmpty)) ...[
              _ReportPropertyCard(
                builder: builder,
                project: project,
                tower: tower,
                flat: flat,
                floor: floor,
                configuration: configuration,
              ),

              const SizedBox(height: 18),
            ],

            if (isCalculator)
              _CalculatorReportOverview(data: data, displayUnit: displayUnit)
            else
              _ScanReportOverview(data: data, displayUnit: displayUnit),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ReportNotesCard(notes: notes),
            ],

            const SizedBox(height: 20),

            if (data['rooms'] is List && (data['rooms'] as List).isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailedAreaReportScreen(
                          data: data,
                          initialUnit: displayUnit,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text(
                    'View Detailed Area Report',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

            if (data['rooms'] is List && (data['rooms'] as List).isNotEmpty)
              const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => previewPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text(
                  'Preview',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const _ReportDisclaimer(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REPORT PROPERTY CARD
// ============================================================

class _ReportPropertyCard extends StatelessWidget {
  final String builder;
  final String project;
  final String tower;
  final String flat;
  final String floor;
  final String configuration;

  const _ReportPropertyCard({
    required this.builder,
    required this.project,
    required this.tower,
    required this.flat,
    required this.floor,
    required this.configuration,
  });

  Widget item(String label, String value, IconData icon) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              item('Builder', builder, Icons.business_outlined),
              item('Project', project, Icons.apartment_outlined),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              item('Tower', tower, Icons.domain_outlined),
              item('Flat', flat, Icons.home_outlined),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              item('Floor', floor, Icons.layers_outlined),
              item('Configuration', configuration, Icons.grid_view_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CALCULATOR REPORT OVERVIEW
// ============================================================

class _CalculatorReportOverview extends StatelessWidget {
  final dynamic data;
  final AreaDisplayUnit displayUnit;

  const _CalculatorReportOverview({
    required this.data,
    this.displayUnit = AreaDisplayUnit.imperial,
  });

  double value(String key) => _dynamicDouble(data[key]);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Area Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'Carpet / Usable Area',
          value: value('carpetArea'),
          icon: Icons.square_foot,
        ),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'Internal Wall Area',
          value: value('internalWallArea'),
          subtitle:
              '${value('internalWallPercent').toStringAsFixed(1)}% assumption',
          icon: Icons.home_work_outlined,
        ),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'Built-up Area',
          value: value('builtUpArea'),
          icon: Icons.home_outlined,
          highlighted: true,
        ),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'External Wall / Other',
          value: value('externalWallArea'),
          subtitle:
              '${value('externalWallPercent').toStringAsFixed(1)}% assumption',
          icon: Icons.domain,
        ),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'Loading / Common Area',
          value: value('loadingArea'),
          subtitle:
              '${value('loadingPercent').toStringAsFixed(1)}% of built-up',
          icon: Icons.add_chart,
        ),

        _ReportMetricCard(
          displayUnit: displayUnit,
          title: 'Super Built-up / Saleable Area',
          value: value('superBuiltUpArea'),
          icon: Icons.apartment,
          highlighted: true,
        ),
      ],
    );
  }
}

// ============================================================
// SCAN REPORT OVERVIEW
// ============================================================

class _ScanReportOverview extends StatelessWidget {
  final dynamic data;
  final AreaDisplayUnit displayUnit;

  const _ScanReportOverview({
    required this.data,
    this.displayUnit = AreaDisplayUnit.imperial,
  });

  double value(String key) => _dynamicDouble(data[key]);

  @override
  Widget build(BuildContext context) {
    final dynamic dimensions = data['parsedDimensions'];

    final int dimCount = dimensions is Map ? dimensions.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB8E6C9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.document_scanner,
                    color: AppColors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Floor Plan OCR Scan',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dimCount dimension(s) extracted',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ScanMetric(
                      displayUnit: displayUnit,
                      label: 'Carpet Area',
                      value: value('carpetArea'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScanMetric(
                      displayUnit: displayUnit,
                      label: 'Built-up Area',
                      value: value('builtUpArea'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ScanMetric(
                      displayUnit: displayUnit,
                      label: 'Loading',
                      value: value('loadingArea'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScanMetric(
                      displayUnit: displayUnit,
                      label: 'Super Built-up',
                      value: value('superBuiltUpArea'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanMetric extends StatelessWidget {
  final AreaDisplayUnit displayUnit;
  final String label;
  final double value;

  const _ScanMetric({
    this.displayUnit = AreaDisplayUnit.imperial,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayUnit.formatArea(value),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.dark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORT NOTES CARD
// ============================================================

class _ReportNotesCard extends StatelessWidget {
  final String notes;

  const _ReportNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORT DISCLAIMER
// ============================================================

class _ReportDisclaimer extends StatelessWidget {
  const _ReportDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4D47A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This report is for informational purposes only. Actual area measurements may vary based on construction, applicable regulations, and professional survey. Always verify with qualified professionals before making decisions.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF6B5A20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REPORT METRIC CARD
// ============================================================

class _ReportMetricCard extends StatelessWidget {
  final AreaDisplayUnit displayUnit;
  final String title;
  final double value;
  final IconData icon;
  final String? subtitle;
  final bool highlighted;
  const _ReportMetricCard({
    this.displayUnit = AreaDisplayUnit.imperial,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: highlighted ? AppColors.lightBlue : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                displayUnit.formatArea(value),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: highlighted ? AppColors.primary : AppColors.dark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
// ============================================================
// DETAILED AREA REPORT SCREEN
// ============================================================

class DetailedAreaReportScreen extends StatefulWidget {
  final dynamic data;
  final AreaDisplayUnit initialUnit;

  const DetailedAreaReportScreen({
    super.key,
    required this.data,
    this.initialUnit = AreaDisplayUnit.imperial,
  });

  @override
  State<DetailedAreaReportScreen> createState() =>
      _DetailedAreaReportScreenState();
}

class _DetailedAreaReportScreenState extends State<DetailedAreaReportScreen> {
  dynamic get data => widget.data;
  late AreaDisplayUnit displayUnit = widget.initialUnit;

  @override
  Widget build(BuildContext context) {
    final rooms = (data['rooms'] as List? ?? []).whereType<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Area Report')),
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AreaUnitControl(
                value: displayUnit,
                onChanged: (unit) => setState(() => displayUnit = unit),
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            Text(
              'Room-wise Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 100,
                  columns: const [
                    DataColumn(label: Text('Room / Space')),
                    DataColumn(label: Text('Length'), numeric: true),
                    DataColumn(label: Text('Width'), numeric: true),
                    DataColumn(label: Text('Area'), numeric: true),
                  ],
                  rows: rooms.map((room) {
                    final length = _dynamicDouble(room['lengthMeters']);
                    final width = _dynamicDouble(room['widthMeters']);
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(room['name']?.toString() ?? 'Room'),
                          ),
                        ),
                        DataCell(Text(displayUnit.formatLength(length))),
                        DataCell(Text(displayUnit.formatLength(width))),
                        DataCell(
                          Text(
                            displayUnit.formatArea(
                              DimensionParser.squareMetersToSquareFeet(
                                length * width,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const Text(
              'Swipe across the table to see all measurements.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            Text('Assumptions', style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: Padding(
                padding: AppLayout.pagePadding,
                child: Column(
                  children: [
                    _AssumptionRow(
                      label: 'Internal Wall',
                      value:
                          '${_dynamicDouble(data['internalWallPercent']).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _AssumptionRow(
                      label: 'External Wall / Other',
                      value:
                          '${_dynamicDouble(data['externalWallPercent']).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _AssumptionRow(
                      label: 'Loading / Common Area',
                      value:
                          '${_dynamicDouble(data['loadingPercent']).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssumptionRow extends StatelessWidget {
  final String label;
  final String value;

  const _AssumptionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// AUDIT PDF PREVIEW SCREEN
// ============================================================

class AuditPdfPreviewScreen extends StatefulWidget {
  final dynamic data;
  final AreaDisplayUnit displayUnit;

  const AuditPdfPreviewScreen({
    super.key,
    required this.data,
    this.displayUnit = AreaDisplayUnit.imperial,
  });

  @override
  State<AuditPdfPreviewScreen> createState() => _AuditPdfPreviewScreenState();
}

class _AuditPdfPreviewScreenState extends State<AuditPdfPreviewScreen> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final Uint8List bytes = await _generatePdf();
      if (!mounted) return;
      final String auditName = (widget.data['auditName']?.toString() ?? 'audit')
          .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
          .trim();
      final String baseName = auditName.isEmpty ? 'audit' : auditName;
      final String fileName = baseName.toLowerCase().endsWith('.pdf')
          ? baseName
          : '$baseName.pdf';
      final Uri? savedFile = await FilePicker.saveFile(
        dialogTitle: 'Save report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (!mounted || savedFile == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _sharePdf() async {
    final Uint8List pdf = await _generatePdf();
    await Printing.sharePdf(
      bytes: pdf,
      filename: '${widget.data['auditName'] ?? 'audit'}.pdf',
    );
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      name: widget.data['auditName']?.toString() ?? 'Flatverify.ai Audit',
      onLayout: (_) => _generatePdf(),
    );
  }

  Widget _viewerAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 7, bottom: 7),
          child: Material(
            color: const Color(0xFF202126),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          widget.data['auditName']?.toString() ?? 'Flatverify.ai Report',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        child: PdfPreview(
          build: (_) => _generatePdf(),
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF202126),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: _viewerAction(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  onTap: _printPdf,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF202126),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: _viewerAction(
                  icon: Icons.download_outlined,
                  label: _isDownloading ? 'Saving...' : 'Download',
                  onTap: _isDownloading ? null : _downloadPdf,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF202126),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: _viewerAction(
                  icon: Icons.ios_share,
                  label: 'Share',
                  onTap: _sharePdf,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final List<_PdfScanEvidence> scanEvidence = await _loadScanEvidenceImages();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (_) => _buildPdfWatermark(),
        ),
        build: (context) => _buildPdfPages(context, scanEvidence),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfWatermark() {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.55,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              'Flatverify.ai',
              style: pw.TextStyle(
                fontSize: 54,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey200,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Understand Your Property',
              style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey200),
            ),
          ],
        ),
      ),
    );
  }

  Uint8List? _coerceImageBytes(dynamic value) {
    Uint8List? bytes;
    if (value is Uint8List) {
      bytes = value;
    } else if (value is ByteData) {
      bytes = value.buffer.asUint8List(
        value.offsetInBytes,
        value.lengthInBytes,
      );
    } else if (value is List<int>) {
      bytes = Uint8List.fromList(value);
    } else if (value is List) {
      final List<int> converted = [];
      for (final item in value) {
        if (item is! num || item < 0 || item > 255) return null;
        converted.add(item.toInt());
      }
      bytes = Uint8List.fromList(converted);
    }
    if (bytes == null || bytes.length < 8) return null;
    final bool isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final bool isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return isJpeg || isPng ? bytes : null;
  }

  Future<Uint8List?> _readImagePath(dynamic pathValue) async {
    final String path = pathValue?.toString() ?? '';
    if (path.trim().isEmpty) return null;
    try {
      return _coerceImageBytes(await File(path).readAsBytes());
    } catch (_) {
      return null;
    }
  }

  Future<List<_PdfScanEvidence>> _loadScanEvidenceImages() async {
    if (widget.data['type']?.toString() != 'scan') return [];
    final List<_PdfScanEvidence> evidence = [];
    final dynamic savedPhotosValue = widget.data['scanPhotos'];
    if (savedPhotosValue is List && savedPhotosValue.isNotEmpty) {
      for (final dynamic item in savedPhotosValue) {
        if (item is! Map) continue;
        Uint8List? bytes = _coerceImageBytes(item['imageBytes']);
        bytes ??= await _readImagePath(item['originalPath']);
        if (bytes != null) {
          evidence.add(
            _PdfScanEvidence(bytes, item['ocrText']?.toString() ?? ''),
          );
        }
      }
      if (evidence.isNotEmpty) return evidence;
    }

    final dynamic bytesValue = widget.data['imageBytes'];
    final List<dynamic> storedBytes = _coerceImageBytes(bytesValue) != null
        ? <dynamic>[bytesValue]
        : (bytesValue is List ? List<dynamic>.from(bytesValue) : []);
    final dynamic pathsValue = widget.data['imagePaths'];
    final List<dynamic> paths = pathsValue is List
        ? List<dynamic>.from(pathsValue)
        : (pathsValue is String && pathsValue.trim().isNotEmpty
              ? <dynamic>[pathsValue]
              : []);
    final int count = storedBytes.length > paths.length
        ? storedBytes.length
        : paths.length;
    for (int i = 0; i < count; i++) {
      Uint8List? bytes = i < storedBytes.length
          ? _coerceImageBytes(storedBytes[i])
          : null;
      bytes ??= i < paths.length ? await _readImagePath(paths[i]) : null;
      if (bytes != null) evidence.add(_PdfScanEvidence(bytes, ''));
    }
    if (evidence.isEmpty) {
      final Uint8List? legacy = await _readImagePath(widget.data['imagePath']);
      if (legacy != null) evidence.add(_PdfScanEvidence(legacy, ''));
    }
    return evidence;
  }

  List<pw.Widget> _buildPdfPages(
    pw.Context context,
    List<_PdfScanEvidence> scanEvidence,
  ) {
    final List<pw.Widget> pages = [];

    // Page 1: Property Info & Area Summary
    pages.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPdfHeader(),
          pw.SizedBox(height: 20),
          _buildPdfPropertyInfo(),
          pw.SizedBox(height: 20),
          _buildPdfAreaSummary(),
          pw.SizedBox(height: 20),
          _buildPdfRoomTable(),
          pw.SizedBox(height: 20),
          _buildPdfCalculationMethod(),
          pw.SizedBox(height: 20),
          _buildPdfAssumptions(),
          pw.SizedBox(height: 20),
          _buildPdfVerificationDisclaimer(),
        ],
      ),
    );

    // Additional pages for floor plan photos (if scan)
    final bool isScan = widget.data['type']?.toString() == 'scan';
    if (isScan) {
      for (int i = 0; i < scanEvidence.length; i++) {
        pages.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Scanned Floor Plan Photos - Photo ${i + 1}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                width: double.infinity,
                height: 650,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Image(
                  pw.MemoryImage(scanEvidence[i].bytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      }
      pages.add(_buildPdfScanInformation(scanEvidence));
    }

    return pages;
  }

  pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromHex('172B65'), PdfColor.fromHex('2457D6')],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Flatverify.ai',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Understand Your Property',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            widget.data['auditName']?.toString() ?? 'Property Area Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfPropertyInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Property Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfInfoRow('Builder', widget.data['builder']?.toString() ?? ''),
          _pdfInfoRow('Project', widget.data['project']?.toString() ?? ''),
          _pdfInfoRow('Tower', widget.data['tower']?.toString() ?? ''),
          _pdfInfoRow('Flat', widget.data['flat']?.toString() ?? ''),
          _pdfInfoRow('Floor', widget.data['floor']?.toString() ?? ''),
          _pdfInfoRow(
            'Configuration',
            widget.data['configuration']?.toString() ?? '',
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    if (value.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfAreaSummary() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Area Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfMetricRow(
            'Carpet / Usable Area',
            _dynamicDouble(widget.data['carpetArea']),
          ),
          _pdfMetricRow(
            'Internal Wall Area',
            _dynamicDouble(widget.data['internalWallArea']),
          ),
          _pdfMetricRow(
            'Built-up Area',
            _dynamicDouble(widget.data['builtUpArea']),
            highlighted: true,
          ),
          _pdfMetricRow(
            'External Wall / Other',
            _dynamicDouble(widget.data['externalWallArea']),
          ),
          _pdfMetricRow(
            'Loading / Common Area',
            _dynamicDouble(widget.data['loadingArea']),
          ),
          _pdfMetricRow(
            'Super Built-up / Saleable Area',
            _dynamicDouble(widget.data['superBuiltUpArea']),
            highlighted: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetricRow(
    String label,
    double value, {
    bool highlighted = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.black,
              fontWeight: highlighted
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            widget.displayUnit.formatArea(value),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: highlighted ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfRoomTable() {
    final List<dynamic> rooms = (widget.data['rooms'] as List<dynamic>?) ?? [];

    if (rooms.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Room-wise Details',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _pdfTableCell('Room / Space', isHeader: true),
                  _pdfTableCell('Length', isHeader: true),
                  _pdfTableCell('Width', isHeader: true),
                  _pdfTableCell(
                    'Area (${widget.displayUnit.label})',
                    isHeader: true,
                    alignRight: true,
                  ),
                ],
              ),
              ...rooms.map((roomData) {
                final String name = roomData['name']?.toString() ?? 'Unknown';
                final double lengthM = _dynamicDouble(roomData['lengthMeters']);
                final double widthM = _dynamicDouble(roomData['widthMeters']);
                final double areaSqFt =
                    DimensionParser.squareMetersToSquareFeet(lengthM * widthM);

                return pw.TableRow(
                  children: [
                    _pdfTableCell(name),
                    _pdfTableCell(widget.displayUnit.formatLength(lengthM)),
                    _pdfTableCell(widget.displayUnit.formatLength(widthM)),
                    _pdfTableCell(
                      widget.displayUnit.formatArea(areaSqFt),
                      alignRight: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCalculationMethod() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Calculation Method',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Carpet / usable area is the sum of the included room areas. '
            'Built-up area = usable area + internal wall area. '
            'Loading area = built-up area x loading percentage. '
            'Super built-up area = built-up area + external wall area + loading area.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfVerificationDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FFFBEB'),
        border: pw.Border.all(color: PdfColor.fromHex('F4D47A')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Verification notice: OCR suggestions can be affected by image quality '
        'and are not guaranteed property measurements. This report records the '
        'entered dimensions and may include unconfirmed OCR estimates. Confirm critical measurements and legal '
        'area definitions with qualified professionals.',
        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('6B5A20')),
      ),
    );
  }

  pw.Widget _buildPdfScanInformation(List<_PdfScanEvidence> evidence) {
    final dynamic dimensionsValue = widget.data['parsedDimensions'];
    final int dimensionCount = dimensionsValue is Map
        ? dimensionsValue.length
        : 0;
    final List<String> photoTexts = evidence
        .map((item) => item.ocrText.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final String legacyText = widget.data['rawText']?.toString().trim() ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OCR / Scan Information',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '${evidence.length} readable floor-plan photo(s); '
          '$dimensionCount extracted dimension value(s).',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        if (photoTexts.isNotEmpty)
          ...List.generate(photoTexts.length, (index) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Photo ${index + 1} OCR text',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    photoTexts[index],
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            );
          })
        else
          pw.Text(
            legacyText.isEmpty ? 'No OCR text was retained.' : legacyText,
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.SizedBox(height: 12),
        _buildPdfVerificationDisclaimer(),
      ],
    );
  }

  pw.Widget _pdfTableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildPdfAssumptions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assumptions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _pdfAssumptionRow(
            'Internal Wall',
            '${_dynamicDouble(widget.data['internalWallPercent']).toStringAsFixed(1)}%',
          ),
          _pdfAssumptionRow(
            'External Wall / Other',
            '${_dynamicDouble(widget.data['externalWallPercent']).toStringAsFixed(1)}%',
          ),
          _pdfAssumptionRow(
            'Loading / Common Area',
            '${_dynamicDouble(widget.data['loadingPercent']).toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Note: External wall area is shown separately and is not included in built-up area. Loading is calculated as a percentage of built-up area.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfAssumptionRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.black),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ],
      ),
    );
  }
}
