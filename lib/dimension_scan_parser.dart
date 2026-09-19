class ScannedRoomMeasurement {
  final String? name;
  final String length;
  final String width;

  const ScannedRoomMeasurement(this.name, this.length, this.width);
}

class PlanTextLine {
  final String text;
  final double left, top, width, height;
  const PlanTextLine(this.text, this.left, this.top, this.width, this.height);
  double get centerX => left + width / 2;
}

/// Parses room-size pairs while retaining their units and order in OCR text.
class DimensionScanParser {
  static const _number = r'(?:\d+[ \t]+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)';
  static const _unit = r'''(?:mm\b|cm\b|m\b|ft\b|in\b|'|")''';
  static final _dimension =
      '$_number(?:\\s*(?:ft\\b|\x27)(?:[ \\t]*-?[ \\t]*$_number(?:[ \\t]*(?:in\\b|\x22))?)?|\\s*$_unit)?';
  static final _pair = RegExp(
    '(?<![\\w./])($_dimension)\\s*(?:[x×✕]|by\\b)\\s*($_dimension)(?![\\w./])',
    caseSensitive: false,
  );

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[′’‘]'), "'")
        .replaceAll(RegExp('[″“”]'), '"')
        .replaceAll(RegExp('[–−]'), '-')
        .replaceAll('½', ' 1/2')
        .replaceAll('¼', ' 1/4')
        .replaceAll('¾', ' 3/4')
        .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
        .replaceAll(RegExp(r'\bmillimet(?:er|re)s?\b'), 'mm')
        .replaceAll(RegExp(r'\bcentimet(?:er|re)s?\b'), 'cm')
        .replaceAll(RegExp(r'\bmet(?:er|re)s?\b'), 'm')
        .replaceAll(RegExp(r'\b(?:feet|foot)\b'), 'ft')
        .replaceAll(RegExp(r'\binch(?:es)?\b'), 'in');
  }

  static String? _measurementUnit(String value) {
    if (RegExp(r"ft\b|'").hasMatch(value)) return 'ft';
    final match = RegExp(r'''(mm|cm|m|in|ft|"|')\s*$''').firstMatch(value);
    return match?[1] == '"' ? 'in' : match?[1];
  }

  /// Unlabelled pairs retain the app's feet default; explicit units take priority.
  static List<String> parsePairs(String text, {String defaultUnit = 'ft'}) {
    return parseRooms(
      text,
      defaultUnit: defaultUnit,
    ).expand((room) => [room.length, room.width]).toList();
  }

  static List<ScannedRoomMeasurement> parseRooms(
    String text, {
    String defaultUnit = 'ft',
  }) {
    final rooms = <ScannedRoomMeasurement>[];
    final normalized = _normalize(text)
        // OCR can join adjacent sizes: 2.225M1.63M or 1Mx2M.
        .replaceAllMapped(
          RegExp(r'(mm|cm|m|ft|in)(?=\d|x\d)'),
          (m) => '${m[1]} ',
        );
    int previousEnd = 0;
    final roomLabel = RegExp(
      r'\b(?:(?:master|guest|kids|children|a\.|c\.|attached|common)\s+)?'
      r'(?:bed\s*room|living(?:\s+(?:room|area))?|dining(?:\s+(?:room|area))?|'
      r'kitchen|toilet|bathroom|bath|balcony|utility|puja(?:\s+room)?|pooja(?:\s+room)?|'
      r'study|store(?:\s+room)?|terrace|passage|foyer|lounge|room)\b(?:[ \t]*[0-9]+)?',
    );
    for (final match in _pair.allMatches(normalized)) {
      String length = match[1]!.trim();
      String width = match[2]!.trim();
      final lengthUnit = _measurementUnit(length);
      final widthUnit = _measurementUnit(width);
      if (lengthUnit == null) length = '$length ${widthUnit ?? defaultUnit}';
      if (widthUnit == null) width = '$width ${lengthUnit ?? defaultUnit}';
      if (toMeters(length) > 0 && toMeters(width) > 0) {
        final preceding = normalized.substring(previousEnd, match.start).trim();
        final lines = preceding.split('\n');
        final nearby = lines
            .skip(lines.length > 2 ? lines.length - 2 : 0)
            .join(' ');
        final labels = roomLabel.allMatches(nearby).toList();
        final label = labels.isEmpty ? null : labels.last[0];
        final name = label
            ?.split(RegExp(r'\s+'))
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        rooms.add(ScannedRoomMeasurement(name, length, width));
      }
      previousEnd = match.end;
    }
    return rooms;
  }

  /// Match measurements to nearby labels, rather than OCR's column order.
  /// Unreadable size lines remain visible as rooms needing manual measurements.
  static List<ScannedRoomMeasurement> parseLayout(List<PlanTextLine> lines) {
    final output = <ScannedRoomMeasurement>[];
    final usedLabels = <PlanTextLine>{};
    final sizeLines =
        lines
            .where(
              (line) =>
                  RegExp(
                    r'\d.*[x×✕].*\d',
                    caseSensitive: false,
                  ).hasMatch(line.text) ||
                  parseRooms(line.text).isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => a.top == b.top
                ? a.left.compareTo(b.left)
                : a.top.compareTo(b.top),
          );
    final labels = lines
        .where(
          (line) =>
              !sizeLines.contains(line) &&
              RegExp(r'[a-z]{3}', caseSensitive: false).hasMatch(line.text) &&
              !RegExp(
                r'\d',
              ).hasMatch(line.text.replaceAll(RegExp(r'\b\d{1,2}\b'), '')),
        )
        .toList();
    for (final line in sizeLines) {
      String text = line.text;
      // A decimal metric size ending in N is a common OCR confusion for M.
      // Do not infer missing decimal points, e.g. "453N" remains unreadable.
      if (RegExp(r'\d\s*m', caseSensitive: false).hasMatch(text)) {
        text = text.replaceAllMapped(
          RegExp(r'(\d+[.,]\d+)\s*N\b', caseSensitive: false),
          (m) => '${m[1]}M',
        );
      }
      final parsed = parseRooms(text);
      final count = parsed.isEmpty ? 1 : parsed.length;
      for (int index = 0; index < count; index++) {
        final center = line.left + line.width * (index + 0.5) / count;
        final nearby =
            labels.where((label) {
              final dy = line.top - (label.top + label.height);
              return !usedLabels.contains(label) &&
                  dy >= -line.height * 0.6 &&
                  dy < line.height * 2.5 &&
                  (label.centerX - center).abs() < line.width / count * 0.75;
            }).toList()..sort((a, b) {
              double score(PlanTextLine label) =>
                  (label.centerX - center).abs() +
                  (line.top - label.top - label.height).abs() * 2;
              return score(a).compareTo(score(b));
            });
        final label = nearby.isEmpty ? null : nearby.first;
        if (label != null) usedLabels.add(label);
        final rawName = label?.text.trim();
        final name = rawName?.replaceAll(
          RegExp(r'\bpuia\b', caseSensitive: false),
          'Puja',
        );
        output.add(
          ScannedRoomMeasurement(
            name,
            parsed.isEmpty ? '' : parsed[index].length,
            parsed.isEmpty ? '' : parsed[index].width,
          ),
        );
      }
    }
    return output;
  }

  static double _numeric(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    double total = 0;
    for (final part in parts) {
      if (part.contains('/')) {
        final fraction = part.split('/');
        final denominator = double.parse(fraction[1]);
        if (denominator == 0) return double.nan;
        total += double.parse(fraction[0]) / denominator;
      } else {
        total += double.parse(part);
      }
    }
    return total;
  }

  static double toMeters(String text) {
    final value = _normalize(text).trim();
    final feet = RegExp(
      '^($_number)\\s*(?:ft|\x27)(?:\\s*-?\\s*($_number)\\s*(?:in|\x22)?)?\\s*\$',
    ).firstMatch(value);
    double meters;
    if (feet != null) {
      meters =
          _numeric(feet[1]!) * 0.3048 +
          (feet[2] == null ? 0 : _numeric(feet[2]!) * 0.0254);
    } else {
      final single = RegExp(
        '^($_number)\\s*(mm|cm|m|in|\x22)\$',
      ).firstMatch(value);
      if (single == null) return 0;
      final factor = switch (single[2]) {
        'mm' => 0.001,
        'cm' => 0.01,
        'm' => 1.0,
        _ => 0.0254,
      };
      meters = _numeric(single[1]!) * factor;
    }
    return meters.isFinite && meters > 0 ? meters : 0;
  }
}
