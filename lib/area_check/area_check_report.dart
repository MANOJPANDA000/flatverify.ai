import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'area_check_model.dart';

Future<Uint8List> buildAreaCheckPdf(AreaCheck check) async {
  final document = pw.Document();
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/PlusJakartaSans.ttf'),
  );
  pw.Widget line(String name, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Text('$name: $value'),
  );
  // The bundled font keeps report creation available offline.
  String ascii(String text) => text
      .replaceAll('×', 'x')
      .replaceAll('−', '-')
      .replaceAll('—', ' - ')
      .replaceAll('·', '/');
  document.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: font, bold: font),
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(
          'Flatverify.ai',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Understand Your Property'),
        pw.Header(level: 0, text: 'Property Area Verification Report'),
        line('Local report ID', check.id),
        line('Saved at', check.updated),
        line(
          'Property',
          '${check.displayTitle} / ${check.flat} / ${check.configuration}',
        ),
        line('Method', check.method),
        line('Information quality', check.quality),
        line('Display unit', check.metricDisplay ? 'sq m' : 'sq ft'),
        pw.TableHelper.fromTextArray(
          headers: [
            'Space / source',
            'Category',
            'Dimensions / quantity',
            'Area',
          ],
          data: check.spaces
              .map(
                (s) => [
                  '${s.name}\n${s.source}\n${s.notes}',
                  s.category.label,
                  ascii(s.dimensions),
                  check.areaLabel(s.area),
                ],
              )
              .toList(),
          cellStyle: const pw.TextStyle(fontSize: 8),
        ),
        pw.Header(level: 1, text: 'Area breakdown'),
        for (final category in SpaceCategory.values) ...[
          line(category.label, check.areaLabel(check.categoryTotal(category))),
          pw.Container(
            height: 6,
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: check.spaces.fold(0.0, (sum, s) => sum + s.area) > 0
                  ? 400 *
                        check.categoryTotal(category) /
                        check.spaces.fold(0.0, (sum, s) => sum + s.area)
                  : 0,
              color: PdfColors.blue,
            ),
          ),
        ],
        line('Net Usable Indoor Area', check.areaLabel(check.usable)),
        line('Internal-wall method', check.walls.name),
        line('Assumption', ascii(check.wallAssumption)),
        line('Included internal walls', check.areaLabel(check.internalWalls)),
        if (check.carpet != null)
          line('Estimated RERA Carpet Area', check.areaLabel(check.carpet!)),
        line('Total Measured Floor Area', check.areaLabel(check.measuredFloor)),
        pw.Text(
          'Total floor area includes indoor rooms, circulation, balcony, utility and terrace. Walls and excluded areas are separate. Estimated carpet = indoor + circulation + internal partition footprints. Exterior walls and exclusive outdoor areas are excluded.',
        ),
        if (check.advertisedCarpet != null)
          line(
            'Advertised Carpet Area',
            check.areaLabel(check.advertisedCarpet!),
          ),
        if (check.advertisedBuiltUp != null)
          line(
            'Advertised Built-up Area',
            check.areaLabel(check.advertisedBuiltUp!),
          ),
        if (check.advertisedSaleable != null)
          line(
            'Advertised Super Built-up Area',
            check.areaLabel(check.advertisedSaleable!),
          ),
        if (check.difference != null)
          line(
            'Advertised minus estimated carpet',
            '${check.areaLabel(check.difference!)} (${check.differencePercent!.toStringAsFixed(2)}%)',
          ),
        line('Comparison', ascii(check.comparisonStatus)),
        line(
          'Review thresholds (not legal standards)',
          '${check.closeThreshold}% closely aligned; ${check.reviewThreshold}% small difference',
        ),
        if (check.loading(check.advertisedCarpet) != null)
          line(
            'Loading on advertised Carpet Area',
            '${check.loading(check.advertisedCarpet)!.toStringAsFixed(2)}%',
          ),
        if (check.loading(check.advertisedBuiltUp) != null)
          line(
            'Loading on advertised Built-up Area',
            '${check.loading(check.advertisedBuiltUp)!.toStringAsFixed(2)}%',
          ),
        if (check.efficiency != null)
          line(
            '${check.carpet != null ? 'Estimated ' : ''}Carpet Efficiency',
            '${check.efficiency!.toStringAsFixed(2)}%',
          ),
        pw.Text(
          'Loading = (advertised saleable / stated base - 1) x 100. Efficiency = carpet / advertised saleable x 100. Difference % = (advertised - estimated) / advertised x 100. 1 sq m = 10.7639 sq ft.',
        ),
        line('User notes', check.notes.isEmpty ? 'None' : check.notes),
        pw.SizedBox(height: 16),
        pw.Text(reportDisclaimer, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
  return document.save();
}

Future<void> exportAreaCheck(AreaCheck check) async {
  await Printing.sharePdf(
    bytes: await buildAreaCheckPdf(check),
    filename: 'Flatverify-${check.id}.pdf',
  );
}
