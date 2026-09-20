export type DimensionUnit = 'feetInches' | 'meterCm' | 'decimalFeet';

export type AreaDisplayUnit = 'imperial' | 'metric' | 'hybrid';

export type VerifyInputMode = 'photo' | 'manual';

export type ReraPropertyType = 'apartment' | 'villa' | 'commercial' | 'studio' | 'penthouse';

export type RoomSpaceType =
  | 'internal' // Standard internal room enclosed within outer wall (Carpet + Built-up)
  | 'balcony' // Balcony, verandah, sitout, terrace (Excluded from RERA carpet, Included in Built-up)
  | 'utility_inside' // Utility / wash area INSIDE outer wall (Included in RERA carpet + Built-up)
  | 'utility_outside'; // Utility / dry balcony OUTSIDE outer wall (Excluded from RERA carpet, Included in Built-up)

export function inferRoomSpaceType(roomName: string): RoomSpaceType {
  const name = (roomName || '').toLowerCase().trim();
  if (
    name.includes('balcony') ||
    name.includes('balc') ||
    name.includes('verandah') ||
    name.includes('veranda') ||
    name.includes('sitout') ||
    name.includes('deck') ||
    name.includes('terrace')
  ) {
    if (name.includes('dry balcony') || name.includes('utility')) {
      // If user typed "dry balcony", default to outside unless specified
      return 'utility_outside';
    }
    return 'balcony';
  }
  if (name.includes('dry balcony') || name.includes('dry yard') || name.includes('service yard')) {
    return 'utility_outside';
  }
  if (name.includes('utility') || name.includes('wash')) {
    // Default utility inside outer wall (standard enclosed wash alcove)
    return 'utility_inside';
  }
  return 'internal';
}

export interface RoomData {
  id: string;
  name: string;
  lengthMeters: number;
  widthMeters: number;
  unit: DimensionUnit;
  isAutoExtracted: boolean;
  isUserVerified: boolean;
  sourcePhotoId?: string;
  sourcePairId?: string;
  spaceType?: RoomSpaceType;
}

export interface ScanPhotoData {
  id: string;
  imageUrl: string;
  originalPath?: string;
  ocrText: string;
  dimensions: string[];
  pairIds: string[];
  roomNames: (string | null)[];
}

export interface SavedRoomRecord {
  name: string;
  lengthMeters: number;
  widthMeters: number;
  unit: string;
  source?: string;
  sourcePhotoId?: string;
  sourcePairId?: string;
  isUserVerified: boolean;
  spaceType?: RoomSpaceType;
}

export interface PropertyAudit {
  id: string;
  type: 'scan' | 'calculator';
  auditName: string;
  builder?: string;
  project?: string;
  tower?: string;
  flat?: string;
  floor?: string;
  configuration?: string;
  propertyType?: ReraPropertyType;
  notes?: string;
  timestamp: string;
  rawText?: string;
  parsedDimensions?: Record<string, string>;
  imagePaths?: string[];
  imageUrls?: string[];
  scanPhotos?: Array<{
    id: string;
    ocrText: string;
    dimensions: string[];
    imageUrl?: string;
  }>;
  dismissedOcrPairIds?: string[];
  rooms: SavedRoomRecord[];
  usableArea: number; // in sq ft
  carpetArea: number; // in sq ft
  internalWallPercent: number;
  internalWallArea: number;
  builtUpArea: number;
  externalWallPercent: number;
  externalWallArea: number;
  loadingPercent: number;
  loadingArea: number;
  superBuiltUpArea: number;
  balconyArea?: number;
  utilityInsideArea?: number;
  utilityOutsideArea?: number;
}

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  isGuest: boolean;
  createdAt: string;
}

export interface PlanTextLine {
  text: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ParsedRoomMeasurement {
  name: string;
  length: string;
  width: string;
  labelX?: number;
  labelY?: number;
}
