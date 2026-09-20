import { AreaDisplayUnit, DimensionUnit } from '../types';

export class DimensionParser {
  static readonly METERS_TO_FEET = 3.280839895013123;
  static readonly METERS_TO_INCHES = 39.37007874015748;
  static readonly SQ_METERS_TO_SQ_FEET = 10.763910416709722;

  static feetInchesToMeters(feet: number, inches: number): number {
    const totalInches = feet * 12 + inches;
    return totalInches * 0.0254;
  }

  static meterCmToMeters(meters: number, cm: number): number {
    return meters + cm / 100.0;
  }

  static metersToFeet(meters: number): number {
    return meters * this.METERS_TO_FEET;
  }

  static metersToInches(meters: number): number {
    return meters * this.METERS_TO_INCHES;
  }

  static squareMetersToSquareFeet(squareMeters: number): number {
    return squareMeters * this.SQ_METERS_TO_SQ_FEET;
  }

  static squareFeetToSquareMeters(squareFeet: number): number {
    return squareFeet / this.SQ_METERS_TO_SQ_FEET;
  }

  static format(value: number, decimals: number = 2): string {
    return Number(value.toFixed(decimals)).toLocaleString('en-US', {
      minimumFractionDigits: 0,
      maximumFractionDigits: decimals,
    });
  }

  static formatFeetInches(meters: number): string {
    if (meters <= 0) return '0\' 0"';
    const totalInches = Math.round(meters * this.METERS_TO_INCHES);
    const feet = Math.floor(totalInches / 12);
    const inches = totalInches % 12;
    return `${feet}' ${inches}"`;
  }

  static formatMeterCm(meters: number): string {
    if (meters <= 0) return '0.00 m';
    return `${meters.toFixed(2)} m`;
  }

  static formatLength(meters: number, unit: AreaDisplayUnit = 'imperial'): string {
    if (meters <= 0) return '-';
    if (unit === 'metric') {
      return this.formatMeterCm(meters);
    }
    return this.formatFeetInches(meters);
  }

  static formatArea(squareFeet: number, unit: AreaDisplayUnit = 'imperial'): string {
    if (squareFeet <= 0 || isNaN(squareFeet)) return '0 sq ft';

    const sqMeters = this.squareFeetToSquareMeters(squareFeet);

    switch (unit) {
      case 'imperial':
        return `${this.format(squareFeet, 2)} sq ft`;
      case 'metric':
        return `${this.format(sqMeters, 2)} sq m`;
      case 'hybrid':
        return `${this.format(squareFeet, 2)} sq ft (${this.format(sqMeters, 2)} sq m)`;
    }
  }

  static getUnitLabel(unit: AreaDisplayUnit): string {
    switch (unit) {
      case 'imperial':
        return 'sq ft';
      case 'metric':
        return 'sq m';
      case 'hybrid':
        return 'sq ft / sq m';
    }
  }

  /**
   * Parses common dimension string formats into meters:
   * e.g. "12' 6\"", "12-6", "12.5 ft", "3.8 m", "3800 mm", "380 cm"
   */
  static parseDimensionToMeters(input: string): number {
    if (!input) return 0;
    const clean = input
      .trim()
      .replace(/[’‘`]/g, "'")
      .replace(/[“”]/g, '"')
      .toLowerCase();

    // Feet and inches: 10' 6", 10'6", 10'-6", 10-6, 10' - 6", 10 ft 6 in
    const feetInchesMatch = clean.match(/^(\d+(?:\.\d+)?)\s*(?:'|ft|feet)?\s*[-–—]?\s*(\d+(?:\.\d+)?)\s*(?:"|in|inch|inches)?$/);
    if (feetInchesMatch && (clean.includes("'") || clean.includes("ft") || clean.includes("-") || clean.includes("–") || clean.includes('"') || clean.includes("in") || clean.includes(" "))) {
      const feet = parseFloat(feetInchesMatch[1]);
      const inches = parseFloat(feetInchesMatch[2] || '0');
      return this.feetInchesToMeters(feet, inches);
    }

    // Feet only: 10' or 10 ft
    const feetOnlyMatch = clean.match(/^(\d+(?:\.\d+)?)\s*(?:'|ft|feet)$/);
    if (feetOnlyMatch) {
      const feet = parseFloat(feetOnlyMatch[1]);
      return feet * 0.3048;
    }

    // Inches only: 120" or 120 in
    const inchesOnlyMatch = clean.match(/^(\d+(?:\.\d+)?)\s*(?:"|in|inch|inches)$/);
    if (inchesOnlyMatch) {
      const inches = parseFloat(inchesOnlyMatch[1]);
      return inches * 0.0254;
    }

    // Millimeters: 3500 mm or 3500mm
    const mmMatch = clean.match(/^(\d+(?:\.\d+)?)\s*mm$/);
    if (mmMatch) {
      return parseFloat(mmMatch[1]) / 1000.0;
    }

    // Centimeters: 350 cm or 350cm
    const cmMatch = clean.match(/^(\d+(?:\.\d+)?)\s*cm$/);
    if (cmMatch) {
      return parseFloat(cmMatch[1]) / 100.0;
    }

    // Meters: 3.5 m or 3.5m or 3.5 meter
    const mMatch = clean.match(/^(\d+(?:\.\d+)?)\s*(?:m|meter|meters|metre|metres)$/);
    if (mMatch) {
      return parseFloat(mMatch[1]);
    }

    // Decimal number without unit
    const num = parseFloat(clean);
    if (!isNaN(num) && num > 0) {
      // Heuristic: if >= 500 it's probably millimeters (e.g. 3200)
      if (num >= 500) {
        return num / 1000.0;
      }
      // If between 20 and 500 it's probably centimeters (e.g. 350)
      if (num >= 50 && num < 500) {
        return num / 100.0;
      }
      // If <= 10 and has decimals, could be meters e.g. 3.25
      if (clean.includes('.') && num <= 15) {
        return num; // meters
      }
      // Otherwise default to feet (e.g. 10 or 12.5)
      return num * 0.3048;
    }

    return 0;
  }
}
