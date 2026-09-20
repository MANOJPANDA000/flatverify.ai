import React from 'react';
import {
  Layers,
  Ruler,
  Info,
  Maximize2,
  Minimize2,
  Sparkles,
  HelpCircle,
  Building,
  Check,
} from 'lucide-react';
import { AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

export interface WallThicknessVisualizerProps {
  usableAreaSqFt: number;
  internalWallPercent: number;
  onInternalWallPercentChange?: (newVal: number) => void;
  displayUnit: AreaDisplayUnit;
  compact?: boolean;
  className?: string;
}

interface WallBenchmark {
  label: string;
  sublabel: string;
  percent: number;
  description: string;
}

const WALL_BENCHMARKS: WallBenchmark[] = [
  {
    label: 'Drywall / Gypsum',
    sublabel: '3"–4" studs',
    percent: 6.0,
    description: 'Minimal loss, common in modern commercial & premium modular flats',
  },
  {
    label: 'Standard Brick',
    sublabel: '4.5" single leaf',
    percent: 10.0,
    description: 'Standard residential partition in Indian apartments (IS 2212)',
  },
  {
    label: 'RCC / Heavy Brick',
    sublabel: '9" masonry / shear',
    percent: 16.0,
    description: 'High-rise shear walls, seismic zones & older load-bearing blocks',
  },
];

export const WallThicknessVisualizer: React.FC<WallThicknessVisualizerProps> = ({
  usableAreaSqFt,
  internalWallPercent,
  onInternalWallPercentChange,
  displayUnit,
  compact = false,
  className = '',
}) => {
  // Area calculations
  const internalWallAreaSqFt = usableAreaSqFt * (internalWallPercent / 100);
  const totalFloorPlateSqFt = usableAreaSqFt + internalWallAreaSqFt;

  // Percentage distribution within the physical floor plate
  const usableRatio = totalFloorPlateSqFt > 0 ? (usableAreaSqFt / totalFloorPlateSqFt) * 100 : 90;
  const wallRatio = totalFloorPlateSqFt > 0 ? (internalWallAreaSqFt / totalFloorPlateSqFt) * 100 : 10;

  // Metric equivalents
  const usableAreaSqM = DimensionParser.squareFeetToSquareMeters(usableAreaSqFt);
  const internalWallAreaSqM = DimensionParser.squareFeetToSquareMeters(internalWallAreaSqFt);

  // Tangible room equivalent
  const getTangibleEquivalent = (sqFt: number): string => {
    if (sqFt < 25) return 'a large built-in wardrobe (~4ft × 6ft)';
    if (sqFt < 45) return 'a standard powder room / compact toilet (~7ft × 5ft)';
    if (sqFt < 70) return 'a full-sized master bathroom or utility balcony (~8ft × 6ft)';
    if (sqFt < 100) return 'a private study room or kitchen (~10ft × 8ft)';
    return 'an entire extra guest bedroom (~12ft × 10ft)';
  };

  // Border thickness scale for the visual room representation (8px to 22px)
  const clampedPercent = Math.min(Math.max(internalWallPercent, 5), 20);
  const visualWallThicknessPx = Math.round(8 + ((clampedPercent - 5) / 15) * 14);

  return (
    <div
      id="wall-thickness-visualizer"
      className={`bg-white rounded-2xl border border-[#E2E8F0] shadow-xs overflow-hidden ${className}`}
    >
      {/* Card Header */}
      <div className="p-4 bg-gradient-to-r from-slate-50 to-blue-50/40 border-b border-[#E2E8F0] flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-blue-600/10 border border-blue-600/20 flex items-center justify-center text-blue-700 shrink-0">
            <Layers className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-xs font-black text-[#0F172A] uppercase tracking-wide">
              Wall Thickness Impact Indicator
            </h4>
            <p className="text-[11px] text-[#64748B]">
              How internal partition walls affect usable floor efficiency
            </p>
          </div>
        </div>

        <span className="px-2.5 py-1 rounded-full text-[11px] font-black bg-blue-600 text-white shadow-2xs">
          {internalWallPercent.toFixed(1)}% Wall
        </span>
      </div>

      <div className="p-4 space-y-4">
        {/* Dynamic Architectural Floor Plate Graphic */}
        <div className="bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl p-4 flex flex-col items-center justify-center">
          <div className="text-[11px] font-bold text-[#64748B] mb-2 text-center flex items-center gap-1.5">
            <Maximize2 className="w-3.5 h-3.5 text-blue-600" />
            <span>Interactive Floor Plate Cross-Section</span>
          </div>

          {/* Graphic Container */}
          <div className="relative w-full max-w-[280px] aspect-4/3 flex items-center justify-center">
            {/* Outer Wall Boundary (Brick/Masonry Textured Border) */}
            <div
              style={{
                padding: `${visualWallThicknessPx}px`,
                transition: 'padding 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
              }}
              className="w-full h-full rounded-2xl bg-amber-200/80 border-2 border-amber-600/40 shadow-xs flex items-center justify-center relative overflow-hidden group"
            >
              {/* Subtle architectural brick hatch pattern overlay */}
              <div
                className="absolute inset-0 opacity-25 pointer-events-none"
                style={{
                  backgroundImage: `repeating-linear-gradient(45deg, #78350F 0, #78350F 1px, transparent 0, transparent 8px)`,
                }}
              />

              {/* Inner Walkable Room Plate */}
              <div className="w-full h-full rounded-xl bg-blue-600 text-white flex flex-col items-center justify-center p-3 text-center shadow-inner relative z-10 transition-all">
                <span className="text-[10px] font-extrabold uppercase tracking-wider text-blue-200">
                  Net Usable Carpet Floor
                </span>
                <span className="text-base font-black text-white leading-tight">
                  {DimensionParser.formatArea(usableAreaSqFt, displayUnit)}
                </span>
                <span className="text-[10px] font-bold text-blue-200 mt-0.5">
                  {usableRatio.toFixed(1)}% of Enclosed Plate
                </span>
              </div>
            </div>

            {/* Dimension Callout Badges */}
            <div className="absolute -bottom-2.5 right-2 bg-amber-800 text-amber-50 text-[9px] font-black px-2 py-0.5 rounded-md shadow-xs border border-amber-700 z-20">
              Wall: {internalWallPercent.toFixed(1)}% (+{DimensionParser.format(internalWallAreaSqFt, 1)} sq ft)
            </div>
          </div>

          <div className="mt-3 text-center">
            <p className="text-[11px] text-[#475569]">
              <span className="font-extrabold text-[#0F172A]">
                {DimensionParser.format(internalWallAreaSqFt, 1)} sq ft
              </span>{' '}
              ({DimensionParser.format(internalWallAreaSqM, 2)} sq m) is consumed by internal walls —{' '}
              <span className="font-bold text-amber-700">
                equivalent to {getTangibleEquivalent(internalWallAreaSqFt)}
              </span>.
            </p>
          </div>
        </div>

        {/* Proportional Split Bar (Usable Carpet vs Wall Structure) */}
        <div className="space-y-1.5">
          <div className="flex items-center justify-between text-xs font-bold">
            <span className="text-blue-700 flex items-center gap-1">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-600 inline-block" />
              <span>Net Walkable Living Floor</span>
            </span>
            <span className="text-amber-700 flex items-center gap-1">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-500 inline-block" />
              <span>Wall Brickwork / Dead Space</span>
            </span>
          </div>

          {/* Visual Bar */}
          <div className="h-4 w-full rounded-xl bg-slate-100 overflow-hidden flex border border-[#CBD5E1]">
            <div
              style={{ width: `${usableRatio}%` }}
              className="h-full bg-blue-600 text-[10px] font-black text-white flex items-center justify-center transition-all"
              title={`Net Usable: ${usableRatio.toFixed(1)}%`}
            >
              {usableRatio >= 20 && <span>{usableRatio.toFixed(1)}% Usable</span>}
            </div>
            <div
              style={{ width: `${wallRatio}%` }}
              className="h-full bg-amber-500 text-[10px] font-black text-white flex items-center justify-center transition-all"
              title={`Wall Encroachment: ${wallRatio.toFixed(1)}%`}
            >
              {wallRatio >= 10 && <span>{wallRatio.toFixed(1)}% Wall</span>}
            </div>
          </div>

          {/* Numeric values */}
          <div className="flex items-center justify-between text-[11px] text-[#64748B]">
            <span>
              {DimensionParser.formatArea(usableAreaSqFt, displayUnit)} paint-to-paint
            </span>
            <span>
              +{DimensionParser.formatArea(internalWallAreaSqFt, displayUnit)} under walls
            </span>
          </div>
        </div>

        {/* Architectural Material Benchmark Comparison Buttons */}
        {onInternalWallPercentChange && (
          <div>
            <label className="block text-[11px] font-bold text-[#475569] uppercase tracking-wider mb-1.5 flex items-center justify-between">
              <span>Compare Wall Material Standards:</span>
              <span className="text-[10px] font-normal text-blue-600 lowercase">
                click to test impact
              </span>
            </label>

            <div className="grid grid-cols-3 gap-2">
              {WALL_BENCHMARKS.map(bm => {
                const isSelected = Math.abs(internalWallPercent - bm.percent) < 0.6;
                return (
                  <button
                    key={bm.label}
                    type="button"
                    onClick={() => onInternalWallPercentChange(bm.percent)}
                    className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer flex flex-col justify-between ${
                      isSelected
                        ? 'bg-blue-50 border-blue-500 ring-2 ring-blue-500/20 shadow-2xs'
                        : 'bg-[#F8FAFC] border-[#E2E8F0] hover:bg-[#F1F5F9] hover:border-[#CBD5E1]'
                    }`}
                  >
                    <div className="flex items-center justify-between w-full mb-1">
                      <span className="text-[11px] font-black text-[#0F172A] leading-tight">
                        {bm.label}
                      </span>
                      {isSelected && (
                        <Check className="w-3 h-3 text-blue-600 shrink-0" />
                      )}
                    </div>
                    <span className="text-[10px] font-semibold text-[#64748B] block">
                      {bm.sublabel}
                    </span>
                    <span className="text-xs font-black text-blue-700 mt-1 block">
                      {bm.percent}% wall
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* Statutory Legal Insight Note */}
        <div className="p-3 bg-blue-50/70 border border-blue-200/80 rounded-xl text-[11px] text-[#334155] space-y-1">
          <div className="flex items-center gap-1.5 font-bold text-blue-900">
            <Info className="w-3.5 h-3.5 text-blue-700 shrink-0" />
            <span>RERA Section 2(k) Carpet Area Mandate:</span>
          </div>
          <p className="text-[#475569] leading-relaxed">
            By statutory definition, RERA Carpet Area includes the area covered by internal
            partition walls. This visual indicator isolates the{' '}
            <strong className="text-[#0F172A]">clear net usable floor</strong> (paint-to-paint)
            from the brickwork so you know exactly how much physical room you can occupy.
          </p>
        </div>
      </div>
    </div>
  );
};
