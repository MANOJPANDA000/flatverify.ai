export interface SampleFloorPlan {
  id: string;
  title: string;
  subtitle: string;
  thumbnailSvg: string;
  ocrText: string;
  suggestedDimensions: string[];
  rooms: Array<{
    name: string;
    length: string;
    width: string;
  }>;
}

// Sample 1: Modern 2BHK Apartment (1050 sq ft Super Built-up)
const svgFloorPlan1 = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600" fill="%23FFFFFF">
  <style>
    .wall { stroke: %231E293B; stroke-width: 6; fill: %23F1F5F9; }
    .label { font-family: sans-serif; font-size: 16px; font-weight: bold; fill: %230F172A; text-anchor: middle; }
    .dim { font-family: monospace; font-size: 14px; font-weight: bold; fill: %232563EB; text-anchor: middle; }
    .door { stroke: %2394A3B8; stroke-dasharray: 4 4; fill: none; }
  </style>
  <rect width="800" height="600" fill="%23FFFFFF"/>
  <rect x="50" y="50" width="700" height="500" fill="%23FAFAFC" stroke="%23334155" stroke-width="8"/>
  <!-- Living & Dining -->
  <rect x="50" y="50" width="400" height="300" class="wall"/>
  <text x="250" y="180" class="label">LIVING / DINING</text>
  <text x="250" y="210" class="dim">16' 0" x 12' 0"</text>
  <!-- Master Bedroom -->
  <rect x="450" y="50" width="300" height="260" class="wall"/>
  <text x="600" y="160" class="label">MASTER BEDROOM</text>
  <text x="600" y="190" class="dim">12' 0" x 14' 0"</text>
  <!-- Bedroom 2 -->
  <rect x="450" y="310" width="300" height="240" class="wall"/>
  <text x="600" y="410" class="label">BEDROOM 2</text>
  <text x="600" y="440" class="dim">11' 0" x 12' 0"</text>
  <!-- Kitchen -->
  <rect x="50" y="350" width="220" height="200" class="wall"/>
  <text x="160" y="430" class="label">KITCHEN</text>
  <text x="160" y="460" class="dim">8' 6" x 10' 0"</text>
  <!-- Master Toilet -->
  <rect x="270" y="350" width="180" height="100" class="wall"/>
  <text x="360" y="395" class="label">TOILET 1</text>
  <text x="360" y="420" class="dim">5' 0" x 8' 0"</text>
  <!-- Common Toilet -->
  <rect x="270" y="450" width="180" height="100" class="wall"/>
  <text x="360" y="495" class="label">COMMON TOILET</text>
  <text x="360" y="520" class="dim">5' 0" x 7' 6"</text>
</svg>`;

// Sample 2: Premium 3BHK Residence (1750 sq ft Super Built-up)
const svgFloorPlan2 = `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600" fill="%23FFFFFF">
  <style>
    .wall { stroke: %231E293B; stroke-width: 6; fill: %23F8FAFC; }
    .label { font-family: sans-serif; font-size: 15px; font-weight: bold; fill: %230F172A; text-anchor: middle; }
    .dim { font-family: monospace; font-size: 14px; font-weight: bold; fill: %231D4ED8; text-anchor: middle; }
  </style>
  <rect width="800" height="600" fill="%23FFFFFF"/>
  <rect x="40" y="40" width="720" height="520" fill="%23F8FAFC" stroke="%231E293B" stroke-width="8"/>
  <!-- Living -->
  <rect x="40" y="40" width="360" height="240" class="wall"/>
  <text x="220" y="140" class="label">LIVING ROOM</text>
  <text x="220" y="170" class="dim">18' 0" x 13' 6"</text>
  <!-- Dining -->
  <rect x="400" y="40" width="200" height="240" class="wall"/>
  <text x="500" y="140" class="label">DINING</text>
  <text x="500" y="170" class="dim">10' 6" x 12' 0"</text>
  <!-- Kitchen -->
  <rect x="600" y="40" width="160" height="240" class="wall"/>
  <text x="680" y="140" class="label">KITCHEN</text>
  <text x="680" y="170" class="dim">9' 0" x 11' 6"</text>
  <!-- Master Bed -->
  <rect x="40" y="280" width="260" height="280" class="wall"/>
  <text x="170" y="400" class="label">MASTER BEDROOM</text>
  <text x="170" y="430" class="dim">14' 0" x 15' 0"</text>
  <!-- Bedroom 2 -->
  <rect x="300" y="280" width="240" height="280" class="wall"/>
  <text x="420" y="400" class="label">BEDROOM 2</text>
  <text x="420" y="430" class="dim">12' 0" x 13' 0"</text>
  <!-- Bedroom 3 -->
  <rect x="540" y="280" width="220" height="280" class="wall"/>
  <text x="650" y="400" class="label">BEDROOM 3</text>
  <text x="650" y="430" class="dim">11' 0" x 12' 6"</text>
</svg>`;

export const SAMPLE_FLOOR_PLANS: SampleFloorPlan[] = [
  {
    id: 'sample_2bhk',
    title: 'Standard 2BHK Plan',
    subtitle: 'Living, 2 Beds, Kitchen, 2 Baths (~1050 sq ft)',
    thumbnailSvg: svgFloorPlan1,
    ocrText: `TYPICAL 2BHK FLOOR PLAN
LIVING / DINING : 16' 0" x 12' 0"
MASTER BEDROOM : 12' 0" x 14' 0"
BEDROOM 2 : 11' 0" x 12' 0"
KITCHEN : 8' 6" x 10' 0"
TOILET 1 : 5' 0" x 8' 0"
COMMON TOILET : 5' 0" x 7' 6"
BALCONY : 10' 0" x 4' 6"`,
    suggestedDimensions: [
      `16' 0"`, `12' 0"`,
      `12' 0"`, `14' 0"`,
      `11' 0"`, `12' 0"`,
      `8' 6"`, `10' 0"`,
      `5' 0"`, `8' 0"`,
      `5' 0"`, `7' 6"`,
      `10' 0"`, `4' 6"`,
    ],
    rooms: [
      { name: 'Living / Dining', length: `16' 0"`, width: `12' 0"` },
      { name: 'Master Bedroom', length: `12' 0"`, width: `14' 0"` },
      { name: 'Bedroom 2', length: `11' 0"`, width: `12' 0"` },
      { name: 'Kitchen', length: `8' 6"`, width: `10' 0"` },
      { name: 'Master Bathroom', length: `5' 0"`, width: `8' 0"` },
      { name: 'Common Bathroom', length: `5' 0"`, width: `7' 6"` },
      { name: 'Living Balcony', length: `10' 0"`, width: `4' 6"` },
    ],
  },
  {
    id: 'sample_3bhk',
    title: 'Premium 3BHK Residence',
    subtitle: 'Large Living, Dining, 3 Beds, Kitchen (~1750 sq ft)',
    thumbnailSvg: svgFloorPlan2,
    ocrText: `PREMIUM 3BHK LAYOUT
LIVING ROOM : 18' 0" x 13' 6"
DINING : 10' 6" x 12' 0"
KITCHEN : 9' 0" x 11' 6"
MASTER BEDROOM : 14' 0" x 15' 0"
BEDROOM 2 : 12' 0" x 13' 0"
BEDROOM 3 : 11' 0" x 12' 6"
MASTER TOILET : 6' 0" x 9' 0"
COMMON TOILET : 5' 6" x 8' 0"`,
    suggestedDimensions: [
      `18' 0"`, `13' 6"`,
      `10' 6"`, `12' 0"`,
      `9' 0"`, `11' 6"`,
      `14' 0"`, `15' 0"`,
      `12' 0"`, `13' 0"`,
      `11' 0"`, `12' 6"`,
      `6' 0"`, `9' 0"`,
      `5' 6"`, `8' 0"`,
    ],
    rooms: [
      { name: 'Living Room', length: `18' 0"`, width: `13' 6"` },
      { name: 'Dining Room', length: `10' 6"`, width: `12' 0"` },
      { name: 'Kitchen', length: `9' 0"`, width: `11' 6"` },
      { name: 'Master Bedroom', length: `14' 0"`, width: `15' 0"` },
      { name: 'Bedroom 2', length: `12' 0"`, width: `13' 0"` },
      { name: 'Bedroom 3', length: `11' 0"`, width: `12' 6"` },
      { name: 'Master Bathroom', length: `6' 0"`, width: `9' 0"` },
      { name: 'Common Bathroom', length: `5' 6"`, width: `8' 0"` },
    ],
  },
];
