part of 'main.dart';

/// Areas stay in square feet and room lengths stay in metres in saved data.
/// Switching units only derives display strings from those original values.
class AreaUnitControl extends StatelessWidget {
  final AreaDisplayUnit value;
  final ValueChanged<AreaDisplayUnit> onChanged;
  const AreaUnitControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Display measurement units',
    child: SegmentedButton<AreaDisplayUnit>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: AreaDisplayUnit.metric,
          label: Text('m²'),
          tooltip: 'Metres and square metres',
        ),
        ButtonSegment(
          value: AreaDisplayUnit.imperial,
          label: Text('sq ft'),
          tooltip: 'Feet and square feet',
        ),
      ],
      selected: {value},
      onSelectionChanged: (units) => onChanged(units.first),
    ),
  );
}
