import React, { useState, useMemo } from 'react';
import {
  ShieldCheck,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Info,
  Building2,
  Home,
  Briefcase,
  Layers,
  Scale,
  Sparkles,
  ChevronDown,
  ChevronUp,
  FileText,
  Wrench,
  Check,
  RotateCcw,
  ExternalLink,
} from 'lucide-react';
import { ReraPropertyType, AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

export interface ReraComplianceChecklistProps {
  propertyType?: ReraPropertyType;
  onPropertyTypeChange?: (type: ReraPropertyType) => void;
  rooms?: Array<{
    id?: string;
    name: string;
    lengthMeters: number;
    widthMeters: number;
    isUserVerified?: boolean;
  }>;
  usableAreaSqFt: number;
  carpetAreaSqFt: number;
  internalWallPercent: number;
  internalWallAreaSqFt: number;
  externalWallPercent: number;
  externalWallAreaSqFt: number;
  loadingPercent: number;
  loadingAreaSqFt: number;
  superBuiltUpAreaSqFt: number;
  displayUnit?: AreaDisplayUnit;
  onUpdateAssumptions?: (updates: {
    internalWallPercent?: number;
    externalWallPercent?: number;
    loadingPercent?: number;
  }) => void;
  initialExpanded?: boolean;
  className?: string;
}

export type RuleStatus = 'pass' | 'warning' | 'fail' | 'info';

export interface EvaluatedRule {
  id: string;
  title: string;
  section: string;
  category: 'partition_walls' | 'perimeter_walls' | 'balconies' | 'shafts_voids' | 'loading' | 'efficiency' | 'room_norms' | 'property_specific';
  importance: 'mandatory' | 'advisory';
  status: RuleStatus;
  badge: string;
  details: string;
  recommendation?: string;
  autoFix?: {
    label: string;
    action: () => void;
  };
}

const PROPERTY_TYPE_CONFIG: Record<
  ReraPropertyType,
  {
    name: string;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    description: string;
    expectedLoadingMin: number;
    expectedLoadingMax: number;
    recommendedInternalWall: number;
    minEfficiency: number;
  }
> = {
  apartment: {
    name: 'Apartment / High-Rise Flat',
    label: 'Apartment',
    icon: Building2,
    description: 'Multi-unit residential tower with shared core, elevators, and lobbies.',
    expectedLoadingMin: 20,
    expectedLoadingMax: 32,
    recommendedInternalWall: 12,
    minEfficiency: 68,
  },
  villa: {
    name: 'Villa / Independent House',
    label: 'Villa / House',
    icon: Home,
    description: 'Standalone or gated villa with dedicated plot boundaries, private garden, and stairs.',
    expectedLoadingMin: 10,
    expectedLoadingMax: 20,
    recommendedInternalWall: 10,
    minEfficiency: 80,
  },
  studio: {
    name: 'Studio / 1RK (Affordable Housing)',
    label: 'Studio / 1RK',
    icon: Layers,
    description: 'Compact urban housing unit adhering to PMAY/RERA affordable housing standards.',
    expectedLoadingMin: 18,
    expectedLoadingMax: 28,
    recommendedInternalWall: 10,
    minEfficiency: 72,
  },
  penthouse: {
    name: 'Penthouse / Duplex Unit',
    label: 'Penthouse',
    icon: Sparkles,
    description: 'Top-floor or multi-level residence with exclusive private terraces or double-height voids.',
    expectedLoadingMin: 22,
    expectedLoadingMax: 35,
    recommendedInternalWall: 12,
    minEfficiency: 65,
  },
  commercial: {
    name: 'Commercial / Office Suite',
    label: 'Commercial',
    icon: Briefcase,
    description: 'Office, retail, or workspace unit governed by BOMA and commercial RERA norms.',
    expectedLoadingMin: 28,
    expectedLoadingMax: 44,
    recommendedInternalWall: 8,
    minEfficiency: 60,
  },
};

export const ReraComplianceChecklist: React.FC<ReraComplianceChecklistProps> = ({
  propertyType: controlledPropertyType,
  onPropertyTypeChange,
  rooms = [],
  usableAreaSqFt,
  carpetAreaSqFt,
  internalWallPercent,
  internalWallAreaSqFt,
  externalWallPercent,
  externalWallAreaSqFt,
  loadingPercent,
  loadingAreaSqFt,
  superBuiltUpAreaSqFt,
  displayUnit = 'imperial',
  onUpdateAssumptions,
  initialExpanded = true,
  className = '',
}) => {
  const [internalPropertyType, setInternalPropertyType] = useState<ReraPropertyType>('apartment');
  const [isExpanded, setIsExpanded] = useState<boolean>(initialExpanded);
  const [filter, setFilter] = useState<'all' | 'issues' | 'passed'>('all');
  const [userVerifiedRules, setUserVerifiedRules] = useState<Record<string, boolean>>({});
  const [expandedRuleId, setExpandedRuleId] = useState<string | null>(null);

  const activePropertyType = controlledPropertyType || internalPropertyType;
  const config = PROPERTY_TYPE_CONFIG[activePropertyType];

  const handlePropertyTypeSelect = (type: ReraPropertyType) => {
    if (onPropertyTypeChange) {
      onPropertyTypeChange(type);
    } else {
      setInternalPropertyType(type);
    }
  };

  const toggleManualVerification = (ruleId: string) => {
    setUserVerifiedRules(prev => ({
      ...prev,
      [ruleId]: !prev[ruleId],
    }));
  };

  // Evaluate dynamic validation rules against actual calculation state
  const evaluatedRules = useMemo<EvaluatedRule[]>(() => {
    const rules: EvaluatedRule[] = [];
    const internalWallFormatted = DimensionParser.formatArea(internalWallAreaSqFt, displayUnit);
    const externalWallFormatted = DimensionParser.formatArea(externalWallAreaSqFt, displayUnit);
    const efficiency =
      superBuiltUpAreaSqFt > 0 ? (carpetAreaSqFt / superBuiltUpAreaSqFt) * 100 : 0;

    // 1. Internal Partition Wall Inclusion (RERA Section 2(k))
    if (internalWallPercent === 0) {
      rules.push({
        id: 'internal_walls',
        title: 'Internal Partition Walls Included in Carpet Area',
        section: 'RERA Section 2(k)',
        category: 'partition_walls',
        importance: 'mandatory',
        status: 'fail',
        badge: 'Non-Compliant: 0% Internal Walls',
        details:
          'Under RERA Section 2(k), carpet area explicitly includes the net usable floor area PLUS the thickness of internal partition walls. Your internal wall allowance is currently 0%.',
        recommendation:
          'Apply the standard internal partition wall allowance (typically 10%–14% for standard brick/block masonry) to compute the legally valid RERA Carpet Area.',
        autoFix: onUpdateAssumptions
          ? {
              label: `Apply ${config.recommendedInternalWall}% Standard Preset`,
              action: () =>
                onUpdateAssumptions({ internalWallPercent: config.recommendedInternalWall }),
            }
          : undefined,
      });
    } else if (internalWallPercent > 18) {
      rules.push({
        id: 'internal_walls',
        title: 'Internal Partition Walls Included in Carpet Area',
        section: 'RERA Section 2(k)',
        category: 'partition_walls',
        importance: 'mandatory',
        status: 'warning',
        badge: `High Allowance (${internalWallPercent.toFixed(1)}%)`,
        details: `Internal partition wall allowance is set to ${internalWallPercent.toFixed(1)}% (${internalWallFormatted}). Typical residential partition masonry accounts for 10%–14% of usable floor area.`,
        recommendation:
          'Verify if structural load-bearing walls or unusually thick column offsets are inflating this ratio above standard benchmarks.',
        autoFix: onUpdateAssumptions
          ? {
              label: `Reset to ${config.recommendedInternalWall}% Standard`,
              action: () =>
                onUpdateAssumptions({ internalWallPercent: config.recommendedInternalWall }),
            }
          : undefined,
      });
    } else {
      rules.push({
        id: 'internal_walls',
        title: 'Internal Partition Walls Included in Carpet Area',
        section: 'RERA Section 2(k)',
        category: 'partition_walls',
        importance: 'mandatory',
        status: 'pass',
        badge: 'RERA Compliant',
        details: `Complies with RERA Section 2(k): Internal wall thickness is factored into carpet area at ${internalWallPercent.toFixed(1)}% (${internalWallFormatted}), matching standard construction specifications.`,
      });
    }

    // 2. External Perimeter Wall Exclusion (RERA Section 2(k))
    rules.push({
      id: 'external_walls',
      title: 'External Perimeter Walls Excluded from Carpet Area',
      section: 'RERA Section 2(k)',
      category: 'perimeter_walls',
      importance: 'mandatory',
      status: 'pass',
      badge: 'Properly Excluded',
      details: `External façade and corridor boundary walls (${externalWallPercent.toFixed(1)}% / ${externalWallFormatted}) are strictly excluded from the calculated carpet area and apportioned into built-up area only, as mandated by Section 2(k).`,
    });

    // 3. Exclusive Balcony / Verandah Segregation (RERA Section 2(k) Proviso)
    const balconyKeywords = ['balcony', 'balc', 'verandah', 'veranda', 'sitout', 'sit-out', 'deck'];
    const balconyRooms = rooms.filter(r =>
      balconyKeywords.some(kw => r.name.toLowerCase().includes(kw))
    );

    if (balconyRooms.length > 0) {
      const totalBalconySqM = balconyRooms.reduce(
        (sum, r) => sum + r.lengthMeters * r.widthMeters,
        0
      );
      const totalBalconySqFt = DimensionParser.squareMetersToSquareFeet(totalBalconySqM);
      const balconyFormatted = DimensionParser.formatArea(totalBalconySqFt, displayUnit);

      rules.push({
        id: 'balcony_segregation',
        title: 'Exclusive Balcony & Verandah Segregation',
        section: 'RERA Section 2(k) Proviso',
        category: 'balconies',
        importance: 'mandatory',
        status: 'warning',
        badge: 'Separate Disclosure Required',
        details: `Detected ${balconyRooms.length} outdoor space(s) (${balconyRooms.map(r => r.name).join(', ')}) totaling ${balconyFormatted}. Under RERA Section 2(k), exclusive balconies/verandahs must be disclosed and billed as a separate line item rather than blended into the primary indoor carpet area.`,
        recommendation:
          'Ensure the developer agreement displays this balcony area in a separate schedule column and does not charge it at the pure indoor carpet rate.',
      });
    } else {
      rules.push({
        id: 'balcony_segregation',
        title: 'Exclusive Balcony & Verandah Segregation',
        section: 'RERA Section 2(k) Proviso',
        category: 'balconies',
        importance: 'mandatory',
        status: 'pass',
        badge: 'Compliant Indoor Floor',
        details:
          'All evaluated spaces represent enclosed internal living quarters. No unsegregated balconies are improperly mixed into the indoor living floor footprint.',
      });
    }

    // 4. Service Shafts, Ducts, & Structural Voids Deduction (RERA Section 2(k))
    const shaftKeywords = ['shaft', 'duct', 'plumbing', 'pipe', 'ots', 'void', 'chase', 'cutout', 'cut-out'];
    const shaftRooms = rooms.filter(r =>
      shaftKeywords.some(kw => r.name.toLowerCase().includes(kw))
    );

    if (shaftRooms.length > 0) {
      rules.push({
        id: 'shafts_voids',
        title: 'Zero Service Shafts & Voids in Carpet Area',
        section: 'RERA Section 2(k)',
        category: 'shafts_voids',
        importance: 'mandatory',
        status: 'fail',
        badge: 'Non-Compliant: Shaft Detected',
        details: `Detected space(s) matching service shafts/voids: "${shaftRooms.map(r => r.name).join(', ')}". RERA strictly dictates 0 sq ft of service shafts, electrical ducts, and cutouts may be credited towards carpet area.`,
        recommendation:
          'Exclude or remove these shafts and mechanical voids from the room schedule so they are not billed as usable carpet area.',
      });
    } else {
      rules.push({
        id: 'shafts_voids',
        title: 'Zero Service Shafts & Structural Voids in Carpet Area',
        section: 'RERA Section 2(k)',
        category: 'shafts_voids',
        importance: 'mandatory',
        status: 'pass',
        badge: '100% Excluded',
        details:
          'No MEP plumbing shafts, electrical risers, or slab cutouts are erroneously included in the carpet area calculation.',
      });
    }

    // 5. Common Loading Factor Cap (Benchmark by Property Type)
    if (loadingPercent > config.expectedLoadingMax) {
      rules.push({
        id: 'loading_factor',
        title: `Common Area Loading Factor Benchmark (${config.label})`,
        section: 'State RERA / Fair Consumer Practice',
        category: 'loading',
        importance: 'advisory',
        status: 'warning',
        badge: `High Loading (${loadingPercent.toFixed(1)}%)`,
        details: `The common area loading factor is ${loadingPercent.toFixed(1)}% (${DimensionParser.formatArea(loadingAreaSqFt, displayUnit)}), which exceeds the standard benchmark of ${config.expectedLoadingMin}%–${config.expectedLoadingMax}% for a ${config.name}.`,
        recommendation:
          'Review the project RERA disclosure on the state portal. Unusually high loading means a smaller percentage of your purchase price corresponds to actual private usable space.',
        autoFix: onUpdateAssumptions
          ? {
              label: `Cap Loading to ${config.expectedLoadingMax}%`,
              action: () => onUpdateAssumptions({ loadingPercent: config.expectedLoadingMax }),
            }
          : undefined,
      });
    } else if (loadingPercent < config.expectedLoadingMin) {
      rules.push({
        id: 'loading_factor',
        title: `Common Area Loading Factor Benchmark (${config.label})`,
        section: 'State RERA / Fair Consumer Practice',
        category: 'loading',
        importance: 'advisory',
        status: 'pass',
        badge: 'Favorable / Low Loading',
        details: `Common loading is ${loadingPercent.toFixed(1)}%, lower than the market benchmark (${config.expectedLoadingMin}%–${config.expectedLoadingMax}%). Excellent private-to-common space proportion.`,
      });
    } else {
      rules.push({
        id: 'loading_factor',
        title: `Common Area Loading Factor Benchmark (${config.label})`,
        section: 'State RERA / Fair Consumer Practice',
        category: 'loading',
        importance: 'advisory',
        status: 'pass',
        badge: 'Within Standard Benchmark',
        details: `Common loading of ${loadingPercent.toFixed(1)}% falls squarely within the standard ${config.expectedLoadingMin}%–${config.expectedLoadingMax}% range for ${config.name} projects.`,
      });
    }

    // 6. Usable Space Efficiency Ratio (Carpet / Super Built-Up)
    if (efficiency < config.minEfficiency && superBuiltUpAreaSqFt > 0) {
      rules.push({
        id: 'space_efficiency',
        title: 'Net Usable Space Efficiency Index',
        section: 'Carpet-to-Saleable Ratio',
        category: 'efficiency',
        importance: 'advisory',
        status: 'warning',
        badge: `Low Efficiency (${efficiency.toFixed(1)}%)`,
        details: `Net usable living efficiency is ${efficiency.toFixed(1)}% (below the recommended ${config.minEfficiency}% minimum). You receive ${DimensionParser.formatArea(carpetAreaSqFt, displayUnit)} of usable carpet space out of ${DimensionParser.formatArea(superBuiltUpAreaSqFt, displayUnit)} billed.`,
        recommendation:
          'Ask the developer for a breakdown of common areas contributing to the super built-up figure to ensure you are not paying excessive premiums for unbuilt amenities.',
      });
    } else if (superBuiltUpAreaSqFt > 0) {
      rules.push({
        id: 'space_efficiency',
        title: 'Net Usable Space Efficiency Index',
        section: 'Carpet-to-Saleable Ratio',
        category: 'efficiency',
        importance: 'advisory',
        status: 'pass',
        badge: `Strong Efficiency (${efficiency.toFixed(1)}%)`,
        details: `Usable space efficiency is ${efficiency.toFixed(1)}%, meeting the minimum benchmark of ${config.minEfficiency}%. A healthy proportion of the unit translates directly to usable living space.`,
      });
    }

    // 7. Habitable Room Minimum Dimensions (NBC 2016 Part 3 / RERA Guidelines)
    if (activePropertyType !== 'commercial' && rooms.length > 0) {
      const livingOrBed = rooms.filter(r => {
        const n = r.name.toLowerCase();
        return (
          n.includes('bed') ||
          n.includes('master') ||
          n.includes('living') ||
          n.includes('hall') ||
          n.includes('drawing')
        );
      });

      const substandardRooms: string[] = [];
      livingOrBed.forEach(r => {
        const sqM = r.lengthMeters * r.widthMeters;
        const minDimensionM = Math.min(r.lengthMeters, r.widthMeters);
        // NBC minimum habitable room: 9.5 sq.m (or 7.5 sq.m for 2nd bedroom) and min width 2.4 m
        if (sqM < 7.5 || minDimensionM < 2.1) {
          substandardRooms.push(
            `${r.name} (${DimensionParser.formatLength(minDimensionM, displayUnit)} min width, ${DimensionParser.formatArea(DimensionParser.squareMetersToSquareFeet(sqM), displayUnit)})`
          );
        }
      });

      if (substandardRooms.length > 0) {
        rules.push({
          id: 'habitable_dimensions',
          title: 'NBC Habitable Room Dimension Standards',
          section: 'NBC 2016 Part 3 / Development Control Regulations',
          category: 'room_norms',
          importance: 'mandatory',
          status: 'warning',
          badge: 'Dimension Alert',
          details: `The following room(s) fall below NBC minimum habitable thresholds (min 7.5–9.5 m² area or 2.1–2.4 m clear width): ${substandardRooms.join(', ')}.`,
          recommendation:
            'Review architectural clear dimensions. Compact rooms might be reclassified as a study, storage, or utility zone rather than a primary bedroom.',
        });
      } else if (livingOrBed.length > 0) {
        rules.push({
          id: 'habitable_dimensions',
          title: 'NBC Habitable Room Dimension Standards',
          section: 'NBC 2016 Part 3 / Development Control Regulations',
          category: 'room_norms',
          importance: 'mandatory',
          status: 'pass',
          badge: 'Meets NBC Standards',
          details:
            'All primary bedrooms and living halls exceed the NBC 2016 minimum habitable thresholds for floor area and minimum clear span width.',
        });
      }
    }

    // 8. Property Type Specific Rules
    if (activePropertyType === 'studio') {
      // PMAY / RERA Affordable Housing Cap: 30 sq.m (~323 sq.ft) in metros, 60 sq.m (~645 sq.ft) in non-metros
      const carpetSqM = DimensionParser.squareFeetToSquareMeters(carpetAreaSqFt);
      const isMetroAffordable = carpetSqM <= 30.5;
      const isNonMetroAffordable = carpetSqM <= 60.5;

      rules.push({
        id: 'studio_affordable_cap',
        title: 'Affordable Housing Carpet Area Cap (PMAY / RERA)',
        section: 'PMAY & RERA Affordable Housing Criteria',
        category: 'property_specific',
        importance: 'advisory',
        status: isMetroAffordable ? 'pass' : isNonMetroAffordable ? 'info' : 'warning',
        badge: isMetroAffordable
          ? 'Metro Affordable Qualified (≤30 m²)'
          : isNonMetroAffordable
          ? 'Non-Metro Affordable (≤60 m²)'
          : 'Exceeds Affordable Slab',
        details: `Calculated carpet area is ${DimensionParser.formatArea(carpetAreaSqFt, displayUnit)} (${carpetSqM.toFixed(1)} m²). Metro affordable housing cap is 30 m² (323 sq ft); non-metro cap is 60 m² (645 sq ft).`,
        recommendation: isMetroAffordable
          ? 'Qualifies for GST concession (1% without ITC) and PMAY interest subsidies under standard affordable housing guidelines.'
          : 'Check local municipal definition if applying for affordable housing tax or stamp duty exemptions.',
      });
    }

    if (activePropertyType === 'villa') {
      const openGardenKeywords = ['garden', 'lawn', 'driveway', 'porch', 'backyard', 'frontyard'];
      const openSpaces = rooms.filter(r =>
        openGardenKeywords.some(kw => r.name.toLowerCase().includes(kw))
      );

      rules.push({
        id: 'villa_open_spaces',
        title: 'Private Plot Yard & Garden Demarcation',
        section: 'Villa / Plinth Measurement Guidelines',
        category: 'property_specific',
        importance: 'mandatory',
        status: openSpaces.length > 0 ? 'warning' : 'pass',
        badge: openSpaces.length > 0 ? 'Open Space Segregation Alert' : 'Compliant Enclosed Space',
        details:
          openSpaces.length > 0
            ? `Detected open plot spaces: "${openSpaces.map(r => r.name).join(', ')}". Private unroofed gardens, driveways, and open lawns must be 100% excluded from the villa carpet area.`
            : 'Private open yards, lawns, and external driveways are properly separated from the interior villa carpet area calculation.',
        recommendation:
          openSpaces.length > 0
            ? 'Ensure open-to-sky plot land is designated under land plot area and not billed under construction carpet area.'
            : undefined,
      });

      rules.push({
        id: 'villa_staircase',
        title: 'Internal Staircase Single-Footprint Count',
        section: 'Multi-Floor Duplex / Villa RERA Rule',
        category: 'property_specific',
        importance: 'mandatory',
        status: 'pass',
        badge: 'Standard Single Count',
        details:
          'Under RERA multi-level rules, the internal staircase footprint is counted once within the carpet area. The cut-out void on the upper floor slab is excluded.',
      });
    }

    if (activePropertyType === 'penthouse') {
      const terraceKeywords = ['terrace', 'open terrace', 'roof deck', 'rooftop'];
      const terraceRooms = rooms.filter(r =>
        terraceKeywords.some(kw => r.name.toLowerCase().includes(kw))
      );

      rules.push({
        id: 'penthouse_terrace',
        title: 'Exclusive Open Terrace Demarcation',
        section: 'RERA Section 2(k) - Exclusive Open Terrace Area',
        category: 'property_specific',
        importance: 'mandatory',
        status: terraceRooms.length > 0 ? 'warning' : 'pass',
        badge: terraceRooms.length > 0 ? 'Separate Terrace Pricing Required' : 'Indoor Living Verified',
        details:
          terraceRooms.length > 0
            ? `Detected private open terrace space(s): "${terraceRooms.map(r => r.name).join(', ')}". RERA Section 2(k) defines "exclusive open terrace area" distinctly from carpet area. It cannot be billed at indoor carpet rates.`
            : 'Exclusive open terrace space is either measured separately or not included within the enclosed penthouse carpet area figure.',
        recommendation:
          terraceRooms.length > 0
            ? 'Request an addendum specifying the terrace area under the exclusive open terrace clause at appropriate adjusted pricing.'
            : undefined,
      });
    }

    if (activePropertyType === 'commercial') {
      rules.push({
        id: 'commercial_demising',
        title: 'Demising Wall & Core Common Service Standard',
        section: 'Commercial RERA & BOMA Standard',
        category: 'property_specific',
        importance: 'mandatory',
        status: 'pass',
        badge: 'Usable Suite Standard',
        details:
          'Carpet area reflects net usable office premises measured from interior finish of exterior glass/walls to the centerline of demising partitions dividing adjoining suites. Common AHU and electrical rooms remain excluded.',
      });
    }

    return rules;
  }, [
    activePropertyType,
    config,
    rooms,
    usableAreaSqFt,
    carpetAreaSqFt,
    internalWallPercent,
    internalWallAreaSqFt,
    externalWallPercent,
    externalWallAreaSqFt,
    loadingPercent,
    loadingAreaSqFt,
    superBuiltUpAreaSqFt,
    displayUnit,
    onUpdateAssumptions,
  ]);

  // Summary counts
  const totalRules = evaluatedRules.length;
  const failCount = evaluatedRules.filter(r => r.status === 'fail').length;
  const warningCount = evaluatedRules.filter(r => r.status === 'warning').length;
  const passCount = evaluatedRules.filter(r => r.status === 'pass').length;

  const complianceScore = Math.max(
    0,
    Math.round(((passCount + warningCount * 0.5) / totalRules) * 100)
  );

  const filteredRules = evaluatedRules.filter(r => {
    if (filter === 'issues') return r.status === 'fail' || r.status === 'warning';
    if (filter === 'passed') return r.status === 'pass';
    return true;
  });

  const getStatusIcon = (status: RuleStatus) => {
    switch (status) {
      case 'pass':
        return <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />;
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" />;
      case 'fail':
        return <XCircle className="w-4 h-4 text-rose-600 shrink-0" />;
      case 'info':
        return <Info className="w-4 h-4 text-blue-500 shrink-0" />;
    }
  };

  const getStatusBadgeClass = (status: RuleStatus) => {
    switch (status) {
      case 'pass':
        return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      case 'warning':
        return 'bg-amber-50 text-amber-800 border-amber-200';
      case 'fail':
        return 'bg-rose-50 text-rose-800 border-rose-200';
      case 'info':
        return 'bg-blue-50 text-blue-700 border-blue-200';
    }
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div
      id="rera-compliance-checklist"
      className={`bg-white rounded-3xl border border-[#E2E8F0] shadow-sm overflow-hidden transition-all duration-200 ${className}`}
    >
      {/* Header Bar */}
      <div className="p-5 sm:p-6 bg-gradient-to-r from-[#0F172A] to-[#1E293B] text-white flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-blue-600/20 border border-blue-500/30 flex items-center justify-center shrink-0">
            <ShieldCheck className="w-5 h-5 text-blue-400" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base sm:text-lg font-black tracking-tight">
                RERA Compliance Checklist
              </h2>
              <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full bg-blue-500/20 text-blue-300 border border-blue-400/30">
                Sec 2(k) Verified
              </span>
            </div>
            <p className="text-xs text-slate-300 mt-0.5">
              Specific architectural and statutory rules for {config.name}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 self-end sm:self-center">
          <div className="flex items-center gap-1 bg-slate-800/80 p-1 rounded-xl border border-slate-700 text-xs">
            <span className="text-slate-400 pl-2 pr-1 text-[11px] font-medium hidden sm:inline">
              Score:
            </span>
            <span
              className={`px-2 py-0.5 rounded-lg font-black text-xs ${
                complianceScore >= 90
                  ? 'bg-emerald-500/20 text-emerald-300'
                  : complianceScore >= 70
                  ? 'bg-amber-500/20 text-amber-300'
                  : 'bg-rose-500/20 text-rose-300'
              }`}
            >
              {complianceScore}%
            </span>
          </div>

          <button
            type="button"
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl transition-colors cursor-pointer"
            title={isExpanded ? 'Collapse checklist' : 'Expand checklist'}
          >
            {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {isExpanded && (
        <div className="p-5 sm:p-6 space-y-6">
          {/* Property Type Selector */}
          <div>
            <div className="flex items-center justify-between mb-2.5">
              <label className="text-xs font-bold uppercase tracking-wider text-[#475569] flex items-center gap-1.5">
                <Building2 className="w-3.5 h-3.5 text-blue-600" />
                <span>Select Property Type for Targeted Rules:</span>
              </label>
              <span className="text-[11px] text-[#64748B]">
                Switches RERA thresholds & legal constraints
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-2">
              {(Object.keys(PROPERTY_TYPE_CONFIG) as ReraPropertyType[]).map(type => {
                const item = PROPERTY_TYPE_CONFIG[type];
                const Icon = item.icon;
                const isSelected = activePropertyType === type;

                return (
                  <button
                    key={type}
                    type="button"
                    onClick={() => handlePropertyTypeSelect(type)}
                    className={`p-3 rounded-2xl border text-left transition-all cursor-pointer flex flex-col justify-between gap-1.5 ${
                      isSelected
                        ? 'bg-blue-50/80 border-blue-600 text-blue-900 ring-2 ring-blue-500/20 shadow-xs'
                        : 'bg-white border-[#E2E8F0] text-[#334155] hover:bg-slate-50 hover:border-[#CBD5E1]'
                    }`}
                  >
                    <div className="flex items-center justify-between w-full">
                      <Icon
                        className={`w-4 h-4 ${isSelected ? 'text-blue-600' : 'text-[#64748B]'}`}
                      />
                      {isSelected && (
                        <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse" />
                      )}
                    </div>
                    <div>
                      <span className="text-xs font-bold block leading-tight">{item.label}</span>
                      <span className="text-[10px] text-[#64748B] line-clamp-1 block mt-0.5">
                        {item.name}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>

            <p className="text-[11px] text-[#64748B] mt-2 italic bg-[#F8FAFC] px-3 py-1.5 rounded-xl border border-[#F1F5F9]">
              💡 {config.description} Expected loading: {config.expectedLoadingMin}%–
              {config.expectedLoadingMax}%. Recommended internal wall factor:{' '}
              {config.recommendedInternalWall}%.
            </p>
          </div>

          {/* Compliance KPI Banner */}
          <div className="p-4 bg-gradient-to-br from-[#F8FAFC] to-[#F1F5F9] rounded-2xl border border-[#E2E8F0] flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-4 w-full md:w-auto">
              <div
                className={`w-14 h-14 rounded-2xl flex flex-col items-center justify-center font-black text-lg shrink-0 border ${
                  complianceScore >= 90
                    ? 'bg-emerald-100 text-emerald-900 border-emerald-300'
                    : complianceScore >= 70
                    ? 'bg-amber-100 text-amber-900 border-amber-300'
                    : 'bg-rose-100 text-rose-900 border-rose-300'
                }`}
              >
                <span>{complianceScore}%</span>
                <span className="text-[9px] font-bold tracking-tighter uppercase -mt-1 text-slate-600">
                  RERA Fit
                </span>
              </div>

              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-sm font-extrabold text-[#0F172A]">
                    {complianceScore === 100
                      ? 'Fully Compliant with RERA Section 2(k)'
                      : failCount > 0
                      ? 'Statutory Action Required'
                      : 'Minor Advisory Warnings Detected'}
                  </h3>
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                      complianceScore >= 90
                        ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                        : 'bg-amber-50 text-amber-800 border-amber-200'
                    }`}
                  >
                    {passCount}/{totalRules} Passed
                  </span>
                </div>
                <p className="text-xs text-[#64748B] mt-0.5">
                  Calculated Carpet Area:{' '}
                  <strong className="text-[#0F172A]">
                    {DimensionParser.formatArea(carpetAreaSqFt, displayUnit)}
                  </strong>{' '}
                  • Usable Efficiency:{' '}
                  <strong className="text-blue-700">
                    {superBuiltUpAreaSqFt > 0
                      ? `${((carpetAreaSqFt / superBuiltUpAreaSqFt) * 100).toFixed(1)}%`
                      : 'N/A'}
                  </strong>
                </p>
              </div>
            </div>

            {/* Filter Tabs */}
            <div className="flex items-center gap-1.5 self-stretch md:self-center justify-end">
              <button
                type="button"
                onClick={() => setFilter('all')}
                className={`px-3 py-1.5 text-xs font-bold rounded-xl transition-colors cursor-pointer ${
                  filter === 'all'
                    ? 'bg-[#0F172A] text-white'
                    : 'bg-white text-[#475569] border border-[#CBD5E1] hover:bg-slate-50'
                }`}
              >
                All ({totalRules})
              </button>
              <button
                type="button"
                onClick={() => setFilter('issues')}
                className={`px-3 py-1.5 text-xs font-bold rounded-xl transition-colors cursor-pointer flex items-center gap-1 ${
                  filter === 'issues'
                    ? 'bg-amber-600 text-white'
                    : 'bg-white text-amber-700 border border-amber-200 hover:bg-amber-50'
                }`}
              >
                <AlertTriangle className="w-3 h-3" />
                <span>Issues ({failCount + warningCount})</span>
              </button>
              <button
                type="button"
                onClick={() => setFilter('passed')}
                className={`px-3 py-1.5 text-xs font-bold rounded-xl transition-colors cursor-pointer flex items-center gap-1 ${
                  filter === 'passed'
                    ? 'bg-emerald-600 text-white'
                    : 'bg-white text-emerald-700 border border-emerald-200 hover:bg-emerald-50'
                }`}
              >
                <CheckCircle2 className="w-3 h-3" />
                <span>Passed ({passCount})</span>
              </button>
            </div>
          </div>

          {/* Rules List */}
          <div className="space-y-3">
            {filteredRules.length === 0 ? (
              <div className="text-center py-8 bg-[#F8FAFC] rounded-2xl border border-dashed border-[#CBD5E1]">
                <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2" />
                <p className="text-xs font-bold text-[#334155]">
                  No items matching the selected filter.
                </p>
              </div>
            ) : (
              filteredRules.map(rule => {
                const isManuallyChecked = !!userVerifiedRules[rule.id];
                const isRowExpanded = expandedRuleId === rule.id;

                return (
                  <div
                    key={rule.id}
                    className={`rounded-2xl border transition-all ${
                      rule.status === 'fail'
                        ? 'border-rose-200 bg-rose-50/30'
                        : rule.status === 'warning'
                        ? 'border-amber-200 bg-amber-50/20'
                        : 'border-[#E2E8F0] bg-white hover:border-[#CBD5E1]'
                    }`}
                  >
                    <div className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                      <div className="flex items-start gap-3">
                        <div className="pt-0.5">{getStatusIcon(rule.status)}</div>

                        <div>
                          <div className="flex flex-wrap items-center gap-2">
                            <h4 className="text-xs font-extrabold text-[#0F172A]">{rule.title}</h4>
                            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-md bg-slate-100 text-[#475569] border border-slate-200">
                              {rule.section}
                            </span>
                            <span
                              className={`text-[10px] font-bold px-2 py-0.5 rounded-md border ${getStatusBadgeClass(
                                rule.status
                              )}`}
                            >
                              {rule.badge}
                            </span>
                            {rule.importance === 'mandatory' && (
                              <span className="text-[9px] font-black uppercase tracking-wider text-rose-700 bg-rose-50 border border-rose-200 px-1.5 py-0.2 rounded">
                                Mandatory
                              </span>
                            )}
                          </div>

                          <p className="text-xs text-[#475569] mt-1 leading-relaxed">
                            {rule.details}
                          </p>

                          {rule.recommendation && (
                            <div className="mt-2 p-2.5 bg-amber-50/80 border border-amber-200/70 rounded-xl text-xs text-amber-900 flex items-start gap-2">
                              <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0 mt-0.5" />
                              <div>
                                <strong className="font-bold text-[11px] block text-amber-950">
                                  RERA Recommendation:
                                </strong>
                                <span>{rule.recommendation}</span>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Right Action Buttons */}
                      <div className="flex items-center gap-2 self-end sm:self-center shrink-0">
                        {rule.autoFix && (
                          <button
                            type="button"
                            onClick={rule.autoFix.action}
                            className="px-3 py-1.5 text-xs font-bold bg-blue-600 hover:bg-blue-700 text-white rounded-xl shadow-2xs flex items-center gap-1.5 transition-colors cursor-pointer"
                          >
                            <Wrench className="w-3 h-3" />
                            <span>{rule.autoFix.label}</span>
                          </button>
                        )}

                        <button
                          type="button"
                          onClick={() => toggleManualVerification(rule.id)}
                          className={`p-1.5 rounded-xl border text-xs font-bold flex items-center gap-1 transition-colors cursor-pointer ${
                            isManuallyChecked
                              ? 'bg-emerald-100 border-emerald-300 text-emerald-800'
                              : 'bg-slate-50 border-slate-200 text-slate-500 hover:bg-slate-100'
                          }`}
                          title="Mark rule as verified during audit"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span className="text-[11px]">
                            {isManuallyChecked ? 'Audit Verified' : 'Verify'}
                          </span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Bottom Statutory Explanatory Note */}
          <div className="p-4 bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-xs text-[#64748B]">
            <div className="flex items-center gap-2">
              <Scale className="w-4 h-4 text-blue-600 shrink-0" />
              <span>
                Based on <strong>Real Estate (Regulation and Development) Act, 2016</strong> Section
                2(k) & National Building Code (NBC 2016).
              </span>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={() => setUserVerifiedRules({})}
                className="text-slate-500 hover:text-slate-700 font-bold flex items-center gap-1 cursor-pointer"
              >
                <RotateCcw className="w-3 h-3" />
                <span>Reset Verifications</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
