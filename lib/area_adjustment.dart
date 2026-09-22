part of 'main.dart';

enum AreaValueMode { calculated, fixed }

class AreaAdjustment {
  AreaAdjustment({required this.percent});
  double percent;
  AreaValueMode mode = AreaValueMode.calculated;
  double fixedSquareFeet = 0;
  AreaDisplayUnit inputUnit = AreaDisplayUnit.imperial;
  bool inputValid = true;

  double areaFor(double baseSquareFeet) => mode == AreaValueMode.fixed
      ? fixedSquareFeet
      : baseSquareFeet * percent / 100;
  bool get isValid => mode == AreaValueMode.calculated
      ? inputValid && percent >= 0 && percent <= 1000
      : inputValid && fixedSquareFeet > 0 && fixedSquareFeet <= 1000000;
  String get sourceLabel => mode == AreaValueMode.fixed
      ? 'Fixed builder value (${AreaDisplayUnit.imperial.formatArea(fixedSquareFeet)})'
      : '${percent.toStringAsFixed(1)}% calculated assumption';
  void reset(double defaultPercent) {
    percent = defaultPercent;
    mode = AreaValueMode.calculated;
    fixedSquareFeet = 0;
    inputUnit = AreaDisplayUnit.imperial;
    inputValid = true;
  }

  Map<String, dynamic> serialize(String key) => {
    '${key}Mode': mode.name,
    '${key}FixedSquareFeet': fixedSquareFeet,
    '${key}InputUnit': inputUnit.name,
  };
}

class AreaAdjustmentInput extends StatefulWidget {
  const AreaAdjustmentInput({
    super.key,
    required this.label,
    required this.adjustment,
    required this.helper,
    required this.onChanged,
  });
  final String label;
  final AreaAdjustment adjustment;
  final String helper;
  final VoidCallback onChanged;
  @override
  State<AreaAdjustmentInput> createState() => _AreaAdjustmentInputState();
}

class _AreaAdjustmentInputState extends State<AreaAdjustmentInput> {
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _sync();
  }

  void _sync() {
    final a = widget.adjustment;
    final value = a.mode == AreaValueMode.calculated
        ? a.percent
        : (a.inputUnit == AreaDisplayUnit.metric
              ? a.fixedSquareFeet / DimensionParser.squareMeterToSquareFeet
              : a.fixedSquareFeet);
    controller.text = value == 0 ? '' : DimensionParser.format(value);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void changed(String text) {
    final parsed = double.tryParse(text.trim());
    final a = widget.adjustment;
    a.inputValid = parsed != null && parsed >= 0;
    if (parsed != null) {
      if (a.mode == AreaValueMode.calculated) {
        a.percent = parsed;
      } else {
        a.fixedSquareFeet = a.inputUnit == AreaDisplayUnit.metric
            ? parsed * DimensionParser.squareMeterToSquareFeet
            : parsed;
      }
    }
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.adjustment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AreaValueMode>(
              segments: const [
                ButtonSegment(
                  value: AreaValueMode.calculated,
                  label: Text('Calculated'),
                ),
                ButtonSegment(
                  value: AreaValueMode.fixed,
                  label: Text('Fixed value'),
                ),
              ],
              selected: {a.mode},
              onSelectionChanged: (value) {
                setState(() {
                  a.mode = value.first;
                  a.inputValid =
                      a.mode == AreaValueMode.calculated ||
                      a.fixedSquareFeet > 0;
                  _sync();
                });
                widget.onChanged();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: changed,
                    decoration: InputDecoration(
                      labelText: a.mode == AreaValueMode.calculated
                          ? 'Percentage'
                          : 'Builder-provided area',
                      suffixText: a.mode == AreaValueMode.calculated
                          ? '%'
                          : a.inputUnit.label,
                      errorText: a.isValid
                          ? null
                          : 'Enter a valid positive value',
                    ),
                  ),
                ),
                if (a.mode == AreaValueMode.fixed) ...[
                  const SizedBox(width: 8),
                  DropdownButton<AreaDisplayUnit>(
                    value: a.inputUnit,
                    items: AreaDisplayUnit.values
                        .map(
                          (u) =>
                              DropdownMenuItem(value: u, child: Text(u.label)),
                        )
                        .toList(),
                    onChanged: (u) {
                      if (u == null) return;
                      setState(() {
                        a.inputUnit = u;
                        _sync();
                      });
                      widget.onChanged();
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.helper,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
            if (a.mode == AreaValueMode.fixed && a.fixedSquareFeet > 0)
              Text(
                'Equivalent: ${a.inputUnit == AreaDisplayUnit.metric ? AreaDisplayUnit.imperial.formatArea(a.fixedSquareFeet) : AreaDisplayUnit.metric.formatArea(a.fixedSquareFeet)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
