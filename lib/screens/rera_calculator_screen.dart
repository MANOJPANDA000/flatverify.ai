import 'package:flutter/material.dart';
import 'mobile_main_screen.dart';

class ReraCalculatorScreen extends StatefulWidget {
  const ReraCalculatorScreen({super.key});

  @override
  State<ReraCalculatorScreen> createState() => _ReraCalculatorScreenState();
}

class _ReraCalculatorScreenState extends State<ReraCalculatorScreen> {
  final _propertyController = TextEditingController();
  final _flatController = TextEditingController();
  final _builderController = TextEditingController();

  final _carpetController = TextEditingController();
  final _builtUpController = TextEditingController();
  final _superBuiltUpController = TextEditingController();

  String _configuration = '2 BHK';

  @override
  void dispose() {
    _propertyController.dispose();
    _flatController.dispose();
    _builderController.dispose();
    _carpetController.dispose();
    _builtUpController.dispose();
    _superBuiltUpController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  void _openMeasurementCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MobileMainScreen()),
    );
  }

  Widget _stepHeader({
    required int number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _workflowStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 19,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area Verification',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Understand what area you are getting',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text(
              'Verify your property area',
              style: TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Compare the builder-stated area with your measurements and understand how carpet, built-up and super built-up areas are calculated.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            // Workflow
            _sectionCard(
              child: Row(
                children: [
                  _workflowStep(
                    icon: Icons.home_outlined,
                    title: 'Property',
                    subtitle: '',
                    active: true,
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: Color(0xFFCBD5E1),
                  ),
                  _workflowStep(
                    icon: Icons.description_outlined,
                    title: 'Builder Area',
                    subtitle: '',
                    active: false,
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: Color(0xFFCBD5E1),
                  ),
                  _workflowStep(
                    icon: Icons.straighten,
                    title: 'Measure',
                    subtitle: '',
                    active: false,
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 17,
                    color: Color(0xFFCBD5E1),
                  ),
                  _workflowStep(
                    icon: Icons.compare_arrows,
                    title: 'Compare',
                    subtitle: '',
                    active: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Property
            _stepHeader(
              number: 1,
              title: 'Property details',
              subtitle: 'Identify the property you are verifying.',
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: _propertyController,
                    decoration: _inputDecoration(
                      'Project / Property name',
                      icon: Icons.apartment_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: TextField(
                          controller: _flatController,
                          decoration: _inputDecoration(
                            'Flat / Unit No.',
                            icon: Icons.tag,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _configuration,
                          decoration: _inputDecoration('Configuration'),
                          items: const [
                            DropdownMenuItem(
                              value: '1 BHK',
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('1 BHK'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: '2 BHK',
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('2 BHK'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: '3 BHK',
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('3 BHK'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: '4 BHK',
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('4 BHK'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _configuration = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _builderController,
                    decoration: _inputDecoration(
                      'Builder / Developer',
                      icon: Icons.business_outlined,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Builder area
            _stepHeader(
              number: 2,
              title: 'Builder-stated area',
              subtitle:
                  'Enter the figures shown in the builder brochure, agreement or area statement.',
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: _carpetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Carpet area (sq ft)',
                      icon: Icons.square_foot,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _builtUpController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Built-up area (sq ft)',
                      icon: Icons.home_work_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _superBuiltUpController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      'Super built-up area (sq ft)',
                      icon: Icons.domain,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Measurement
            _stepHeader(
              number: 3,
              title: 'Your measurement',
              subtitle:
                  'Use Flatverify measurement tools to calculate the area independently.',
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can measure rooms manually or use the existing floor-plan scanning and OCR workflow.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openMeasurementCalculator,
                      icon: const Icon(Icons.straighten),
                      label: const Text('Open Measurement Calculator'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Compare preview
            _stepHeader(
              number: 4,
              title: 'Compare',
              subtitle:
                  'After measurement, Flatverify will show builder vs calculated values and identify differences requiring review.',
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                children: [
                  _comparisonRow(
                    'Carpet Area',
                    _carpetController.text.isEmpty
                        ? '—'
                        : '${_carpetController.text} sq ft',
                    'Calculated after measurement',
                  ),
                  const Divider(height: 24),
                  _comparisonRow(
                    'Built-up Area',
                    _builtUpController.text.isEmpty
                        ? '—'
                        : '${_builtUpController.text} sq ft',
                    'Calculated after measurement',
                  ),
                  const Divider(height: 24),
                  _comparisonRow(
                    'Super Built-up',
                    _superBuiltUpController.text.isEmpty
                        ? '—'
                        : '${_superBuiltUpController.text} sq ft',
                    'Calculated after measurement',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Report
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_outlined, color: Color(0xFF2563EB)),
                      SizedBox(width: 9),
                      Text(
                        'Verification Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The final report will record the measurements, calculation assumptions, builder figures and differences requiring review.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'Flatverify provides measurement and calculation support. Differences should be reviewed against the builder documents and applicable regulations.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(
    String label,
    String builderValue,
    String flatverifyValue,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              builderValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              flatverifyValue,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }
}
