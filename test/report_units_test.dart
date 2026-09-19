import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/app_theme.dart';

Map<String, dynamic> report({String type = 'calculator'}) => {
  'type': type,
  'auditName': 'Test apartment',
  'carpetArea': DimensionParser.squareMetersToSquareFeet(10),
  'builtUpArea': DimensionParser.squareMetersToSquareFeet(12),
  'internalWallArea': DimensionParser.squareMetersToSquareFeet(1),
  'externalWallArea': DimensionParser.squareMetersToSquareFeet(1),
  'loadingArea': DimensionParser.squareMetersToSquareFeet(3),
  'superBuiltUpArea': DimensionParser.squareMetersToSquareFeet(15),
  'rooms': [
    {'name': 'Bedroom 1', 'lengthMeters': 4.0, 'widthMeters': 2.5},
  ],
};

void main() {
  for (final unit in AreaDisplayUnit.values) {
    testWidgets('PDF export uses $unit for lengths and areas', (tester) async {
      const channel = MethodChannel('net.nfet.printing');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'printingInfo' ? <String, dynamic>{} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AuditPdfPreviewScreen(data: report(), displayUnit: unit),
        ),
      );
      await tester.pump();
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      final bytes = await preview.build(PdfPageFormat.a4);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      final source = latin1.decode(bytes);
      final content = StringBuffer();
      for (final match in RegExp(r'stream\r?\n').allMatches(source)) {
        final end = source.indexOf('endstream', match.end);
        if (end < 0) continue;
        try {
          content.write(
            latin1.decode(zlib.decode(bytes.sublist(match.end, end))),
          );
        } catch (_) {
          /* Non-compressed streams are not page text. */
        }
      }
      final words = RegExp(r'\[\((.*?)\)\]TJ')
          .allMatches(content.toString())
          .map((match) => match.group(1)!)
          .join(' ');
      expect(
        words,
        contains(unit == AreaDisplayUnit.metric ? '10.00 m' : '107.64 sq ft'),
      );
      if (unit == AreaDisplayUnit.metric) {
        expect(words, contains('4.00 m'));
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
  test('length and area use dimensionally correct conversions', () {
    expect(
      DimensionParser.squareMetersToSquareFeet(1),
      closeTo(10.7639, .0001),
    );
    expect(AreaDisplayUnit.metric.formatLength(1), '1.00 m');
    expect(
      AreaDisplayUnit.imperial.formatLength(.3048),
      DimensionParser.formatFeetInches(.3048),
    );
    expect(
      AreaDisplayUnit.metric.formatArea(
        DimensionParser.squareMetersToSquareFeet(1),
      ),
      '1.00 m²',
    );
  });

  for (final type in ['calculator', 'scan']) {
    testWidgets(
      '$type report converts repeatedly without changing original values',
      (tester) async {
        final data = report(type: type);
        final original = jsonEncode(data);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: SavedAuditReportScreen(data: data),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.ensureVisible(find.text('m²'));
          await tester.tap(find.text('m²'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('10.00 m²'));
          expect(find.text('10.00 m²'), findsOneWidget);
          await tester.ensureVisible(find.text('sq ft'));
          await tester.tap(find.text('sq ft'));
          await tester.pumpAndSettle();
          expect(find.text('107.64 sq ft'), findsOneWidget);
        }
        expect(jsonEncode(data), original);
        await tester.tap(find.text('m²'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('View Detailed Area Report'));
        await tester.tap(find.text('View Detailed Area Report'));
        await tester.pumpAndSettle();
        expect(find.text('4.00 m'), findsOneWidget);
        expect(find.text('2.50 m'), findsOneWidget);
        expect(find.text('10.00 m²'), findsOneWidget);
        await tester.tap(find.text('sq ft'));
        await tester.pumpAndSettle();
        expect(find.text(DimensionParser.formatFeetInches(4)), findsOneWidget);
        expect(find.text('107.64 sq ft'), findsOneWidget);
        expect(jsonEncode(data), original);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(home: SavedAuditReportScreen(data: data)),
        );
        expect(
          tester
              .widget<SegmentedButton<AreaDisplayUnit>>(
                find.byType(SegmentedButton<AreaDisplayUnit>),
              )
              .selected,
          {AreaDisplayUnit.imperial},
        );
      },
    );
  }
}
