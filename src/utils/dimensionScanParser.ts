import { ParsedRoomMeasurement, PlanTextLine } from '../types';
import { DimensionParser } from './dimensionParser';

export class DimensionScanParser {
  // Common room keywords in architectural drawings
  static readonly ROOM_KEYWORDS = [
    'living room',
    'living/dining',
    'living',
    'dining room',
    'dining',
    'drawing room',
    'drawing',
    'master bed room',
    'master bedroom',
    'master bed',
    'bed room',
    'bedroom',
    'bed',
    'kitchen',
    'utility',
    'dry yard',
    'balcony',
    'terrace',
    'toilet',
    'attached toilet',
    'bath',
    'attached bath',
    'bathroom',
    'powder room',
    'foyer',
    'entry',
    'study room',
    'study',
    'pooja',
    'puja',
    'mandir',
    'store',
    'dress',
    'wardrobe',
    'passage',
    'corridor',
  ];

  static normalizeText(text: string): string {
    return text
      .replace(/[\u2018\u2019\u201A\u201B`]/g, "'")
      .replace(/[\u201C\u201D\u201E\u201F]/g, '"')
      .replace(/[xX×*]/g, ' x ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  static toMeters(dimension: string): number {
    return DimensionParser.parseDimensionToMeters(dimension);
  }

  /**
   * Parses free-form text from OCR into room measurements
   */
  static parseRooms(rawText: string): ParsedRoomMeasurement[] {
    const results: ParsedRoomMeasurement[] = [];
    const normalized = this.normalizeText(rawText);
    const lines = rawText.split(/\r?\n/).map(l => l.trim()).filter(Boolean);

    // Pattern 1: Feet-Inches pair like 10' 6" x 12' 0" or 10'-6" x 12'-0" or 10'6" x 12'4"
    const feetPattern = /(\d{1,2})['′\-]\s*(\d{1,2})?(?:["″])?\s*[xX×*]\s*(\d{1,2})['′\-]\s*(\d{1,2})?(?:["″])?/gi;

    // Pattern 2: Metric dimension pair like 3.20 x 4.15 or 3200 x 4150 or 3.2m x 4.1m or 3200mm x 4150mm
    const metricPattern = /(\d+(?:\.\d+)?)\s*(?:mm|cm|m)?\s*[xX×*]\s*(\d+(?:\.\d+)?)\s*(?:mm|cm|m)?/gi;

    // First scan line by line to associate room names with measurement lines
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const normLine = this.normalizeText(line);

      // Check if line contains a dimension pair
      const feetMatches = [...normLine.matchAll(/(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?)\s*[xX×*]\s*(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?)/gi)];
      const metricMatches = [...normLine.matchAll(/(\d+(?:\.\d+)?\s*(?:mm|cm|m)?)\s*[xX×*]\s*(\d+(?:\.\d+)?\s*(?:mm|cm|m)?)/gi)];

      if (feetMatches.length > 0) {
        for (const match of feetMatches) {
          const lenStr = match[1].trim();
          const widStr = match[2].trim();
          const roomName = this.findNearestRoomName(lines, i) || `Room ${results.length + 1}`;
          results.push({
            name: roomName,
            length: lenStr,
            width: widStr,
          });
        }
      } else if (metricMatches.length > 0) {
        for (const match of metricMatches) {
          const lenStr = match[1].trim();
          const widStr = match[2].trim();
          // Filter out tiny or unreasonable numbers unless mm/m
          const n1 = parseFloat(lenStr);
          const n2 = parseFloat(widStr);
          if ((n1 >= 1.0 && n1 <= 100) || n1 >= 1000) {
            const roomName = this.findNearestRoomName(lines, i) || `Room ${results.length + 1}`;
            results.push({
              name: roomName,
              length: lenStr,
              width: widStr,
            });
          }
        }
      }
    }

    // Fallback: If line-by-line found nothing, scan the full normalized text
    if (results.length === 0) {
      const allMatches = [...normalized.matchAll(/(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?)\s*x\s*(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?)/gi)];
      for (const match of allMatches) {
        results.push({
          name: `Room ${results.length + 1}`,
          length: match[1].trim(),
          width: match[2].trim(),
        });
      }
    }

    return results;
  }

  /**
   * Parses structured OCR bounding boxes to associate text labels with spatial coordinates
   */
  static parseLayout(lines: PlanTextLine[]): ParsedRoomMeasurement[] {
    if (!lines || lines.length === 0) return [];

    const measurements: Array<{
      length: string;
      width: string;
      x: number;
      y: number;
    }> = [];

    const labels: Array<{
      name: string;
      x: number;
      y: number;
    }> = [];

    for (const line of lines) {
      const norm = this.normalizeText(line.text);

      // Check for dimension pair in this line
      const match = norm.match(/(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?|\d+(?:\.\d+)?\s*(?:mm|cm|m)?)\s*x\s*(\d{1,2}\s*['′\-]\s*\d{0,2}\s*["″]?|\d+(?:\.\d+)?\s*(?:mm|cm|m)?)/i);
      if (match) {
        measurements.push({
          length: match[1].trim(),
          width: match[2].trim(),
          x: line.x,
          y: line.y,
        });
        continue;
      }

      // Check if it matches a known room label
      const lower = norm.toLowerCase();
      for (const kw of this.ROOM_KEYWORDS) {
        if (lower.includes(kw)) {
          // Capitalize first letter of each word
          const formatted = kw
            .split(' ')
            .map(w => w.charAt(0).toUpperCase() + w.slice(1))
            .join(' ');
          labels.push({
            name: formatted,
            x: line.x,
            y: line.y,
          });
          break;
        }
      }
    }

    // Match each measurement with closest label (usually label is right above dimension)
    const usedLabels = new Set<number>();
    const results: ParsedRoomMeasurement[] = [];

    for (let i = 0; i < measurements.length; i++) {
      const meas = measurements[i];
      let bestLabelIdx = -1;
      let minDistance = Infinity;

      for (let j = 0; j < labels.length; j++) {
        if (usedLabels.has(j)) continue;
        const label = labels[j];
        // Labels are usually above or near the measurement in floor plans
        const dx = meas.x - label.x;
        const dy = meas.y - label.y;
        // Weight vertical proximity (label is above: dy > 0) favorably
        const distance = Math.hypot(dx, dy * 0.8);

        if (distance < minDistance) {
          minDistance = distance;
          bestLabelIdx = j;
        }
      }

      let name = `Room ${i + 1}`;
      if (bestLabelIdx !== -1 && minDistance < 400) {
        name = labels[bestLabelIdx].name;
        usedLabels.add(bestLabelIdx);
      }

      results.push({
        name,
        length: meas.length,
        width: meas.width,
        labelX: meas.x,
        labelY: meas.y,
      });
    }

    return results.length > 0 ? results : this.parseRooms(lines.map(l => l.text).join('\n'));
  }

  private static findNearestRoomName(lines: string[], targetIdx: number): string | null {
    // Look 1-2 lines before or on the current line
    for (let offset of [0, -1, -2, 1]) {
      const idx = targetIdx + offset;
      if (idx >= 0 && idx < lines.length) {
        const text = lines[idx].toLowerCase();
        for (const kw of this.ROOM_KEYWORDS) {
          if (text.includes(kw)) {
            return kw
              .split(' ')
              .map(w => w.charAt(0).toUpperCase() + w.slice(1))
              .join(' ');
          }
        }
      }
    }
    return null;
  }
}
