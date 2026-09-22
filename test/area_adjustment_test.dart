import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  test('calculated and fixed area modes preserve the original formula', () {
    final adjustment = AreaAdjustment(percent: 12);
    expect(adjustment.areaFor(1000), 120);
    adjustment
      ..mode = AreaValueMode.fixed
      ..fixedSquareFeet = 87.5;
    expect(adjustment.areaFor(1000), 87.5);
    adjustment.mode = AreaValueMode.calculated;
    expect(adjustment.areaFor(1000), 120);
  });

  test('fixed values serialize canonically without conversion drift', () {
    final adjustment = AreaAdjustment(percent: 30)
      ..mode = AreaValueMode.fixed
      ..fixedSquareFeet = 10.7639
      ..inputUnit = AreaDisplayUnit.metric;
    for (var i = 0; i < 100; i++) {
      adjustment.inputUnit = adjustment.inputUnit == AreaDisplayUnit.metric
          ? AreaDisplayUnit.imperial
          : AreaDisplayUnit.metric;
    }
    expect(adjustment.fixedSquareFeet, 10.7639);
    expect(adjustment.serialize('loading'), {
      'loadingMode': 'fixed',
      'loadingFixedSquareFeet': 10.7639,
      'loadingInputUnit': 'metric',
    });
  });

  test('fixed values reject empty, zero and extreme values', () {
    final adjustment = AreaAdjustment(percent: 12)..mode = AreaValueMode.fixed;
    expect(adjustment.isValid, isFalse);
    adjustment.fixedSquareFeet = 1;
    expect(adjustment.isValid, isTrue);
    adjustment.fixedSquareFeet = 1000001;
    expect(adjustment.isValid, isFalse);
    adjustment.inputValid = false;
    expect(adjustment.isValid, isFalse);
  });
}
