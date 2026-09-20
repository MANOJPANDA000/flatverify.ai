import 'package:flutter/material.dart';
import '../models/rera_room_model.dart';
import '../services/rera_calculator_service.dart';
import '../data/bhk_presets.dart';
import '../widgets/rera_result_card.dart';
import '../widgets/rera_room_card.dart';
import '../widgets/carpet_efficiency_gauge.dart';
import '../widgets/wall_thickness_slider.dart';
import '../widgets/aggregate_carpet_breakdown.dart';
import '../dialogs/rera_definitions_sheet.dart';
import '../dialogs/pdf_audit_preview_dialog.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentTabIndex = 0;
  AreaDisplayUnit _displayUnit = AreaDisplayUnit.sqFt;
  String _propertyTitle = 'Modern 2BHK Apartment';
  double _internalWallPercent = 3.5;
  double _externalWallPercent = 6.5;
  double _loadingPercent = 25.0;
  String _selectedPresetId = '2bhk_standard';

  late List<RoomData> _rooms;

  @override
  void initState() {
    super.initState();
    _rooms = BhkPresetData.getPresets().first.rooms;
  }

  ReraAuditCalculation get _audit => ReraAuditCalculation.compute(
        rooms: _rooms,
        internalWallPercent: _internalWallPercent,
        externalWallPercent: _externalWallPercent,
        loadingPercent: _loadingPercent,
      );

  @override
  Widget build(BuildContext context) {
    final audit = _audit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RERA Area Audit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Section 2(k) Compliance',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Unit switch button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _displayUnit = _displayUnit == AreaDisplayUnit.sqFt
                      ? AreaDisplayUnit.sqMeters
                      : AreaDisplayUnit.sqFt;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _displayUnit == AreaDisplayUnit.sqFt
                          ? Icons.square_foot_rounded
                          : Icons.straighten_rounded,
                      size: 14,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayUnit == AreaDisplayUnit.sqFt ? 'sq ft' : 'sq m',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B), size: 20),
            onPressed: () => ReraDefinitionsSheet.show(context),
            tooltip: 'RERA Rules',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildCalculatorTab(audit),
          _buildAnalysisTab(audit),
          _buildRulesTab(),
          _buildCertificateTab(audit),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        backgroundColor: Colors.white,
        elevation: 2,
        height: 62,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: Color(0xFF2563EB)),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Color(0xFF2563EB)),
            label: 'Efficiency',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel, color: Color(0xFF2563EB)),
            label: 'RERA Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified, color: Color(0xFF2563EB)),
            label: 'Certificate',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddRoomBottomSheet,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Room',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            )
          : null,
    );
  }

  // --- TAB 1: CALCULATOR ---
  Widget _buildCalculatorTab(ReraAuditCalculation audit) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      children: [
        // BHK Presets (Horizontal Scroll)
        _buildBhkPresetChips(),
        const SizedBox(height: 12),

        // Live Area Hero Summary Card
        _buildHeroSummaryCard(audit),
        const SizedBox(height: 14),

        // Result Metrics Grid
        ReraResultCard(
          title: 'Built-Up (Plinth) Area',
          subtitle: 'Carpet + External Walls + Balconies',
          valueSqFt: audit.builtUpAreaSqFt,
          icon: Icons.home_work_outlined,
          displayUnit: _displayUnit,
          accentColor: const Color(0xFF475569),
        ),
        ReraResultCard(
          title: 'Super Built-Up Area',
          subtitle: 'Built-up + ${_loadingPercent.toStringAsFixed(0)}% Common Loading',
          valueSqFt: audit.superBuiltUpAreaSqFt,
          icon: Icons.layers_outlined,
          displayUnit: _displayUnit,
          accentColor: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 10),

        // Rooms Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rooms & Spaces (${_rooms.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Net: ${ReraAuditCalculation.formatArea(audit.internalUsableSqFt, _displayUnit)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List of Room Cards
        ..._rooms.asMap().entries.map((entry) {
          final idx = entry.key;
          final room = entry.value;
          return ReraRoomCard(
            room: room,
            displayUnit: _displayUnit,
            onEdit: () => _showEditRoomBottomSheet(idx),
            onDelete: () {
              if (_rooms.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('At least 1 room is required.')),
                );
                return;
              }
              setState(() => _rooms.removeAt(idx));
            },
            onSpaceTypeChanged: (newType) {
              setState(() {
                _rooms[idx] = room.copyWith(spaceType: newType);
              });
            },
          );
        }),
      ],
    );
  }

  // --- TAB 2: EFFICIENCY & ANALYSIS ---
  Widget _buildAnalysisTab(ReraAuditCalculation audit) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        CarpetEfficiencyGauge(
          efficiencyPercent: audit.efficiencyRatioPercent,
          carpetSqFt: audit.reraCarpetAreaSqFt,
          superBuiltUpSqFt: audit.superBuiltUpAreaSqFt,
        ),
        const SizedBox(height: 14),
        AggregateCarpetBreakdownCard(
          rooms: _rooms,
          displayUnit: _displayUnit,
        ),
        const SizedBox(height: 14),
        WallThicknessSliderCard(
          internalWallPercent: _internalWallPercent,
          externalWallPercent: _externalWallPercent,
          loadingPercent: _loadingPercent,
          onInternalChange: (val) => setState(() => _internalWallPercent = val),
          onExternalChange: (val) => setState(() => _externalWallPercent = val),
          onLoadingChange: (val) => setState(() => _loadingPercent = val),
        ),
      ],
    );
  }

  // --- TAB 3: RERA RULES GUIDE ---
  Widget _buildRulesTab() {
    return const ReraDefinitionsSheet(initialTabIndex: 0);
  }

  // --- TAB 4: AUDIT CERTIFICATE ---
  Widget _buildCertificateTab(ReraAuditCalculation audit) {
    return PdfAuditPreviewDialog(
      rooms: _rooms,
      audit: audit,
      displayUnit: _displayUnit,
      propertyTitle: _propertyTitle,
    );
  }

  // --- WIDGETS ---
  Widget _buildBhkPresetChips() {
    final presets = BhkPresetData.getPresets();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final isSelected = preset.id == _selectedPresetId;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                preset.shortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPresetId = preset.id;
                    _propertyTitle = preset.title;
                    _rooms = preset.rooms.map((r) => r.copyWith()).toList();
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSummaryCard(ReraAuditCalculation audit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'RERA CARPET AREA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Sec 2(k) Standard',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ReraAuditCalculation.formatArea(audit.reraCarpetAreaSqFt, _displayUnit),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Formula: Net Usable Floor Area + Internal Partition Walls',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroSubStat('Exclusive Balconies', audit.balconySqFt),
              _heroSubStat('Dry Balcony (Outside)', audit.utilityOutsideSqFt),
              _heroSubStat('Internal Walls', audit.internalWallAreaSqFt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroSubStat(String label, double sqFt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          ReraAuditCalculation.formatArea(sqFt, _displayUnit),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  // --- ADD / EDIT BOTTOM SHEET ---
  void _showAddRoomBottomSheet() {
    _showRoomFormBottomSheet(
      title: 'Add New Room / Space',
      initialName: 'Bedroom',
      initialLength: 12.0,
      initialWidth: 10.0,
      initialSpaceType: RoomSpaceType.livingEnclosed,
      onSave: (name, length, width, spaceType) {
        setState(() {
          _rooms.add(RoomData(
            id: 'room_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            length: length,
            width: width,
            spaceType: spaceType,
          ));
        });
      },
    );
  }

  void _showEditRoomBottomSheet(int index) {
    final room = _rooms[index];
    _showRoomFormBottomSheet(
      title: 'Edit ${room.name}',
      initialName: room.name,
      initialLength: room.length,
      initialWidth: room.width,
      initialSpaceType: room.spaceType,
      onSave: (name, length, width, spaceType) {
        setState(() {
          _rooms[index] = room.copyWith(
            name: name,
            length: length,
            width: width,
            spaceType: spaceType,
          );
        });
      },
    );
  }

  void _showRoomFormBottomSheet({
    required String title,
    required String initialName,
    required double initialLength,
    required double initialWidth,
    required RoomSpaceType initialSpaceType,
    required Function(String name, double length, double width, RoomSpaceType spaceType) onSave,
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final lengthCtrl = TextEditingController(text: initialLength.toString());
    final widthCtrl = TextEditingController(text: initialWidth.toString());
    RoomSpaceType selectedType = initialSpaceType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Living', 'Master Bed', 'Bed 2', 'Kitchen', 'Utility', 'Balcony', 'Toilet'].map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            nameCtrl.text = p;
                            selectedType = RoomData.inferRoomSpaceType(p);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Room / Space Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) {
                  setModalState(() {
                    selectedType = RoomData.inferRoomSpaceType(val);
                  });
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lengthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Length (ft)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Width (ft)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'RERA Space Classification:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _spaceTypeChip('Living / Bed / Bath (In Carpet)', RoomSpaceType.livingEnclosed, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Utility Inside Wall (In Carpet)', RoomSpaceType.utilityInside, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Dry Balcony (Built-up Only)', RoomSpaceType.utilityOutside, selectedType, (t) => setModalState(() => selectedType = t)),
                  _spaceTypeChip('Balcony / Terrace (Built-up)', RoomSpaceType.balcony, selectedType, (t) => setModalState(() => selectedType = t)),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final l = double.tryParse(lengthCtrl.text) ?? 10.0;
                    final w = double.tryParse(widthCtrl.text) ?? 10.0;
                    onSave(nameCtrl.text.trim().isEmpty ? 'Room' : nameCtrl.text.trim(), l, w, selectedType);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Space', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spaceTypeChip(String label, RoomSpaceType type, RoomSpaceType selectedType, ValueChanged<RoomSpaceType> onSelected) {
    final isSelected = type == selectedType;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      onSelected: (_) => onSelected(type),
    );
  }
}
