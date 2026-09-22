const squareFeetPerSquareMeter = 10.7639;
const reportDisclaimer =
    'This report is based on measurements and information entered or confirmed by the user. Estimated values depend on the assumptions shown in this report. Flatverify.ai does not certify title, approvals, construction quality or legal compliance. For legally binding or professional verification, consult an appropriately qualified professional.';

enum SpaceCategory {
  indoor('Net usable indoor area'),
  circulation('Passage and circulation'),
  balcony('Exclusive balcony/verandah'),
  utility('Dry balcony or utility'),
  terrace('Exclusive terrace'),
  internalWall('Internal-wall footprint'),
  externalWall('External-wall footprint'),
  excluded('Other or excluded area');

  const SpaceCategory(this.label);
  final String label;
}

enum MeasureUnit {
  feetInches('Feet and inches'),
  feet('Decimal feet'),
  meters('Metres'),
  centimeters('Centimetres'),
  squareFeet('Direct area (sq ft)'),
  squareMeters('Direct area (sq m)');

  const MeasureUnit(this.label);
  final String label;
  bool get isArea => this == squareFeet || this == squareMeters;
}

enum WallMethod { skip, estimate, measured }

class AreaSpace {
  AreaSpace({
    required this.id,
    required this.name,
    this.category = SpaceCategory.indoor,
    this.unit = MeasureUnit.feetInches,
    this.length = 0,
    this.width = 0,
    this.lengthInches = 0,
    this.widthInches = 0,
    this.quantity = 1,
    this.notes = '',
    this.source = 'User-entered',
    this.photo,
  });
  String id, name, notes, source;
  String? photo;
  SpaceCategory category;
  MeasureUnit unit;
  double length, width, lengthInches, widthInches;
  int quantity;
  String? get error {
    if (name.trim().isEmpty) return 'Enter a space name.';
    if (![
      length,
      width,
      lengthInches,
      widthInches,
    ].every((v) => v.isFinite && v >= 0)) {
      return 'Use finite, non-negative measurements.';
    }
    if (quantity < 1) return 'Quantity must be at least 1.';
    if (unit == MeasureUnit.feetInches &&
        (lengthInches >= 12 || widthInches >= 12)) {
      return 'Inches must be below 12. For 10 ft 13 in, enter 11 ft 1 in.';
    }
    if (!area.isFinite || area <= 0) {
      return 'Enter positive dimensions or a positive direct area.';
    }
    return null;
  }

  double get area {
    if (unit == MeasureUnit.squareFeet) return length * quantity;
    if (unit == MeasureUnit.squareMeters) {
      return length * squareFeetPerSquareMeter * quantity;
    }
    if (unit == MeasureUnit.feetInches) {
      return (length + lengthInches / 12) *
          (width + widthInches / 12) *
          quantity;
    }
    if (unit == MeasureUnit.feet) return length * width * quantity;
    final scale = unit == MeasureUnit.centimeters ? 10000 : 1;
    return length * width / scale * squareFeetPerSquareMeter * quantity;
  }

  String get dimensions => unit.isArea
      ? '$length ${unit == MeasureUnit.squareFeet ? 'sq ft' : 'sq m'} × $quantity'
      : unit == MeasureUnit.feetInches
      ? '$length ft $lengthInches in × $width ft $widthInches in × $quantity'
      : '$length × $width (${unit.label}) × $quantity';
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'unit': unit.name,
    'length': length,
    'width': width,
    'lengthInches': lengthInches,
    'widthInches': widthInches,
    'quantity': quantity,
    'notes': notes,
    'source': source,
    'photo': photo,
  };
  factory AreaSpace.fromJson(Map data) => AreaSpace(
    id: data['id'] as String,
    name: data['name'] as String,
    category: SpaceCategory.values.byName(data['category'] as String),
    unit: MeasureUnit.values.byName(data['unit'] as String),
    length: (data['length'] as num).toDouble(),
    width: (data['width'] as num).toDouble(),
    lengthInches: (data['lengthInches'] as num).toDouble(),
    widthInches: (data['widthInches'] as num).toDouble(),
    quantity: data['quantity'] as int,
    notes: data['notes'] as String,
    source: data['source'] as String,
    photo: data['photo'] as String?,
  );
}

class AreaCheck {
  AreaCheck({required this.id});
  String id;
  String title = '', flat = '', configuration = '2 BHK', notes = '';
  String method = 'Manual entry';
  String updated = DateTime.now().toIso8601String();
  MeasureUnit unit = MeasureUnit.feetInches;
  bool metricDisplay = false;
  WallMethod walls = WallMethod.skip;
  double? wallPercent, advertisedCarpet, advertisedBuiltUp, advertisedSaleable;
  double closeThreshold = 2, reviewThreshold = 5;
  List<AreaSpace> spaces = [];
  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled property' : title.trim();
  double categoryTotal(SpaceCategory category) => spaces
      .where((s) => s.category == category && s.error == null)
      .fold(0.0, (sum, s) => sum + s.area);
  double get usable =>
      categoryTotal(SpaceCategory.indoor) +
      categoryTotal(SpaceCategory.circulation);
  double get internalWalls => switch (walls) {
    WallMethod.skip => 0,
    WallMethod.estimate => usable * (wallPercent ?? 0) / 100,
    WallMethod.measured => categoryTotal(SpaceCategory.internalWall),
  };
  double? get carpet =>
      walls == WallMethod.skip ||
          (walls == WallMethod.estimate && wallPercent == null) ||
          (walls == WallMethod.measured && internalWalls <= 0)
      ? null
      : usable + internalWalls;
  double get measuredFloor =>
      usable +
      categoryTotal(SpaceCategory.balcony) +
      categoryTotal(SpaceCategory.utility) +
      categoryTotal(SpaceCategory.terrace);
  String get wallAssumption => switch (walls) {
    WallMethod.skip =>
      'Internal walls not included. Room areas alone are not RERA Carpet Area.',
    WallMethod.estimate =>
      '${wallPercent ?? 0}% of net usable indoor area. Estimated internal-wall area—not physically measured.',
    WallMethod.measured =>
      'User-entered internal partition footprints. Avoid counting the same shared wall twice.',
  };
  String get quality => walls == WallMethod.estimate && carpet != null
      ? 'Detailed Estimate'
      : walls == WallMethod.measured && carpet != null
      ? 'Detailed Measurement'
      : method == 'Site measurement'
      ? 'Site-Checked Input'
      : spaces.any(
          (s) => [
            SpaceCategory.circulation,
            SpaceCategory.balcony,
            SpaceCategory.utility,
          ].contains(s.category),
        )
      ? 'Improved Calculation'
      : 'Basic Calculation';
  double? get difference =>
      advertisedCarpet != null && advertisedCarpet! > 0 && carpet != null
      ? advertisedCarpet! - carpet!
      : null;
  double? get differencePercent =>
      difference == null ? null : difference! / advertisedCarpet! * 100;
  String get comparisonStatus => differencePercent == null
      ? 'Insufficient information for comparison'
      : differencePercent!.abs() <= closeThreshold
      ? 'Closely aligned'
      : differencePercent!.abs() <= reviewThreshold
      ? 'Small difference—review measurements'
      : 'Significant difference—further checking recommended';
  double? loading(double? base) =>
      base != null &&
          base > 0 &&
          advertisedSaleable != null &&
          advertisedSaleable! > 0
      ? (advertisedSaleable! / base - 1) * 100
      : null;
  double? get efficiency =>
      advertisedSaleable != null &&
          advertisedSaleable! > 0 &&
          (carpet ?? advertisedCarpet) != null
      ? (carpet ?? advertisedCarpet)! / advertisedSaleable! * 100
      : null;
  String areaLabel(double value) =>
      '${(metricDisplay ? value / squareFeetPerSquareMeter : value).toStringAsFixed(2)} ${metricDisplay ? 'sq m' : 'sq ft'}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'flat': flat,
    'configuration': configuration,
    'notes': notes,
    'method': method,
    'updated': updated,
    'unit': unit.name,
    'metricDisplay': metricDisplay,
    'walls': walls.name,
    'wallPercent': wallPercent,
    'advertisedCarpet': advertisedCarpet,
    'advertisedBuiltUp': advertisedBuiltUp,
    'advertisedSaleable': advertisedSaleable,
    'closeThreshold': closeThreshold,
    'reviewThreshold': reviewThreshold,
    'spaces': spaces.map((s) => s.toJson()).toList(),
  };
  factory AreaCheck.fromJson(Map data) {
    final check = AreaCheck(id: data['id'] as String);
    check.title = data['title'] as String;
    check.flat = data['flat'] as String;
    check.configuration = data['configuration'] as String;
    check.notes = data['notes'] as String;
    check.method = data['method'] as String;
    check.updated = data['updated'] as String;
    check.unit = MeasureUnit.values.byName(data['unit'] as String);
    check.metricDisplay = data['metricDisplay'] as bool;
    check.walls = WallMethod.values.byName(data['walls'] as String);
    check.wallPercent = (data['wallPercent'] as num?)?.toDouble();
    check.advertisedCarpet = (data['advertisedCarpet'] as num?)?.toDouble();
    check.advertisedBuiltUp = (data['advertisedBuiltUp'] as num?)?.toDouble();
    check.advertisedSaleable = (data['advertisedSaleable'] as num?)?.toDouble();
    check.closeThreshold = (data['closeThreshold'] as num).toDouble();
    check.reviewThreshold = (data['reviewThreshold'] as num).toDouble();
    check.spaces = (data['spaces'] as List)
        .map((s) => AreaSpace.fromJson(s as Map))
        .toList();
    return check;
  }
}
