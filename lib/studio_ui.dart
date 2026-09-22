import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'branding.dart';

enum StudioAreaUnit { imperial, metric, dual }

/// Display preferences only; stored measurements always retain their units.
class StudioSettings extends ChangeNotifier {
  static final instance = StudioSettings();
  StudioAreaUnit _unit = StudioAreaUnit.imperial;
  StudioAreaUnit get unit => _unit;
  bool get metric => _unit == StudioAreaUnit.metric;
  void restore() {
    if (!Hive.isBoxOpen('account_preferences')) return;
    final saved = Hive.box('account_preferences').get('studioAreaUnit');
    _unit = StudioAreaUnit.values.firstWhere(
      (value) => value.name == saved,
      orElse: () => StudioAreaUnit.imperial,
    );
  }

  Future<void> select(StudioAreaUnit value) async {
    _unit = value;
    notifyListeners();
    if (Hive.isBoxOpen('account_preferences')) {
      await Hive.box('account_preferences').put('studioAreaUnit', value.name);
    }
  }

  String area(double squareFeet) {
    final feet = '${squareFeet.toStringAsFixed(1)} sq ft';
    final meters = '${(squareFeet / 10.7639104).toStringAsFixed(1)} m²';
    return switch (_unit) {
      StudioAreaUnit.imperial => feet,
      StudioAreaUnit.metric => meters,
      StudioAreaUnit.dual => '$feet / $meters',
    };
  }
}

class StudioShellScope extends InheritedWidget {
  const StudioShellScope({super.key, required super.child});
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioShellScope>() != null;
  @override
  bool updateShouldNotify(StudioShellScope oldWidget) => false;
}

class StudioUnitControl extends StatelessWidget {
  const StudioUnitControl({super.key, this.onChanged});
  final ValueChanged<StudioAreaUnit>? onChanged;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StudioSettings.instance,
    builder: (context, _) => Wrap(
      spacing: 6,
      runSpacing: 4,
      children: StudioAreaUnit.values
          .map(
            (unit) => ChoiceChip(
              label: Text(switch (unit) {
                StudioAreaUnit.imperial => 'Sq. Ft.',
                StudioAreaUnit.metric => 'Sq. Meters',
                StudioAreaUnit.dual => 'Both (Dual)',
              }),
              selected: StudioSettings.instance.unit == unit,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: StudioSettings.instance.unit == unit
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: AppColors.border),
              onSelected: (_) {
                StudioSettings.instance.select(unit);
                onChanged?.call(unit);
              },
            ),
          )
          .toList(),
    ),
  );
}

class StudioHeading extends StatelessWidget {
  const StudioHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
  });
  final String title, subtitle;
  final Widget? actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
            height: 1.5,
          ),
        ),
        if (actions != null) ...[const SizedBox(height: 16), actions!],
      ],
    ),
  );
}

class StudioPanel extends StatelessWidget {
  const StudioPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.dark.withValues(alpha: .025),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class StudioColumns extends StatelessWidget {
  const StudioColumns({super.key, required this.main, required this.aside});
  final Widget main, aside;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 850) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, const SizedBox(height: 24), aside],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: main),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: aside),
        ],
      );
    },
  );
}

class StudioStat extends StatelessWidget {
  const StudioStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.primary,
  });
  final IconData icon;
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => StudioPanel(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
