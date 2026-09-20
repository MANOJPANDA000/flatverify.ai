import React, { useState } from 'react';
import {
  HelpCircle,
  CheckCircle2,
  AlertTriangle,
  Building2,
  ChevronDown,
  ChevronUp,
  Info,
  Layers,
  ArrowRight,
} from 'lucide-react';
import { AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

interface ReraBalconyUtilityGuideProps {
  displayUnit: AreaDisplayUnit;
  internalLivingSqFt: number;
  utilityInsideSqFt: number;
  utilityOutsideSqFt: number;
  balconySqFt: number;
  internalWallAreaSqFt: number;
  externalWallAreaSqFt: number;
  builtUpAreaSqFt: number;
  onOpenModal?: (tab?: 'comparison' | 'balcony' | 'utility' | 'checklist') => void;
}

export const ReraBalconyUtilityGuide: React.FC<ReraBalconyUtilityGuideProps> = ({
  displayUnit,
  internalLivingSqFt,
  utilityInsideSqFt,
  utilityOutsideSqFt,
  balconySqFt,
  internalWallAreaSqFt,
  externalWallAreaSqFt,
  builtUpAreaSqFt,
  onOpenModal,
}) => {
  const [isExpanded, setIsExpanded] = useState(true);

  const totalExclusiveOutdoorSqFt = balconySqFt + utilityOutsideSqFt;
  const netInternalFloorSqFt = internalLivingSqFt + utilityInsideSqFt;

  return (
    <div className="bg-white rounded-3xl border border-[#E2E8F0] shadow-xs overflow-hidden">
      {/* Header with toggle */}
      <div
        onClick={() => setIsExpanded(!isExpanded)}
        className="p-5 flex items-center justify-between cursor-pointer bg-linear-to-r from-blue-50/50 via-white to-slate-50 border-b border-[#F1F5F9] hover:bg-slate-50/80 transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-blue-600 text-white flex items-center justify-center shrink-0 shadow-xs">
            <Building2 className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-sm sm:text-base text-[#0F172A]">
                RERA Rule: Balcony & Utility Area Classification
              </h3>
              <span className="px-2 py-0.5 text-[10px] font-black uppercase tracking-wider bg-blue-100 text-blue-800 rounded-full">
                Sec 2(k) Compliance
              </span>
            </div>
            <p className="text-xs text-[#64748B] mt-0.5">
              Definitive statutory rule for Balconies and Utility areas inside vs outside outer walls
            </p>
          </div>
        </div>

        <button
          type="button"
          className="p-2 text-[#64748B] hover:text-[#0F172A] rounded-xl hover:bg-white"
        >
          {isExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
        </button>
      </div>

      {isExpanded && (
        <div className="p-5 space-y-5">
          {/* Direct Answers to Key Questions */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Card 1: Utility Area Inside Outer Wall */}
            <div className="p-4 rounded-2xl bg-emerald-50/70 border border-emerald-200/90 flex flex-col justify-between">
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-extrabold text-emerald-900 uppercase tracking-wide">
                    Question 1: Utility Inside Outer Wall
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-black rounded bg-emerald-600 text-white shadow-2xs">
                    Carpet Area ✓
                  </span>
                </div>
                <h4 className="font-black text-sm text-emerald-950">
                  Where does Utility Area come if it is INSIDE outer wall?
                </h4>
                <p className="text-xs text-emerald-900 leading-relaxed font-medium">
                  <strong>It comes under CARPET AREA</strong> (and automatically in Built-up Area).
                  Under RERA Section 2(k), any enclosed wash alcove or utility room within the
                  external boundary walls constitutes net usable internal floor space, exactly like
                  a kitchen or bathroom.
                </p>
              </div>

              <div className="mt-3 pt-2.5 border-t border-emerald-200 flex items-center justify-between text-xs">
                <span className="text-emerald-800 font-semibold">Your Enclosed Utility:</span>
                <span className="font-extrabold text-emerald-950">
                  {DimensionParser.formatArea(utilityInsideSqFt, displayUnit)}
                </span>
              </div>
            </div>

            {/* Card 2: Balcony & Dry Balcony Outside Outer Wall */}
            <div className="p-4 rounded-2xl bg-amber-50/70 border border-amber-200/90 flex flex-col justify-between">
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-extrabold text-amber-900 uppercase tracking-wide">
                    Question 2: Balcony & Outdoor Utility
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-black rounded bg-amber-600 text-white shadow-2xs">
                    Built-up Area Only
                  </span>
                </div>
                <h4 className="font-black text-sm text-amber-950">
                  Where do Balconies and Outdoor Utility Balconies come?
                </h4>
                <p className="text-xs text-amber-900 leading-relaxed font-medium">
                  <strong>They come under BUILT-UP AREA</strong> and are{' '}
                  <strong>EXCLUDED from RERA Carpet Area</strong>. RERA Section 2(k) strictly excludes
                  exclusive balcony and open terrace areas from statutory carpet area. They are
                  disclosed as a separate schedule and added to Built-up (Plinth) Area.
                </p>
              </div>

              <div className="mt-3 pt-2.5 border-t border-amber-200 flex items-center justify-between text-xs">
                <span className="text-amber-800 font-semibold">Your Balcony & Dry Balcony:</span>
                <span className="font-extrabold text-amber-950">
                  {DimensionParser.formatArea(totalExclusiveOutdoorSqFt, displayUnit)}
                </span>
              </div>
            </div>
          </div>

          {/* Live Distribution Ledger */}
          <div className="p-4 bg-[#F8FAFC] rounded-2xl border border-[#E2E8F0] space-y-3">
            <div className="flex items-center justify-between text-xs">
              <span className="font-extrabold text-[#0F172A] uppercase tracking-wide">
                Current Audit Area Routing Ledger
              </span>
              <span className="text-[11px] text-[#64748B]">Zero-discrepancy breakdown</span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
              <div className="bg-white p-3 rounded-xl border border-slate-200 space-y-1">
                <span className="text-[10px] font-bold text-slate-500 uppercase block">
                  Living / Bed / Bath
                </span>
                <div className="font-black text-sm text-slate-900">
                  {DimensionParser.formatArea(internalLivingSqFt, displayUnit)}
                </div>
                <span className="text-[10px] font-semibold text-emerald-700 block">
                  → RERA Carpet
                </span>
              </div>

              <div className="bg-white p-3 rounded-xl border border-emerald-200 space-y-1">
                <span className="text-[10px] font-bold text-emerald-700 uppercase block">
                  Utility (Inside Wall)
                </span>
                <div className="font-black text-sm text-emerald-950">
                  {DimensionParser.formatArea(utilityInsideSqFt, displayUnit)}
                </div>
                <span className="text-[10px] font-bold text-emerald-700 block">
                  → RERA Carpet
                </span>
              </div>

              <div className="bg-white p-3 rounded-xl border border-amber-200 space-y-1">
                <span className="text-[10px] font-bold text-amber-700 uppercase block">
                  Balconies / Verandahs
                </span>
                <div className="font-black text-sm text-amber-950">
                  {DimensionParser.formatArea(balconySqFt, displayUnit)}
                </div>
                <span className="text-[10px] font-bold text-amber-700 block">
                  → Built-up Only
                </span>
              </div>

              <div className="bg-white p-3 rounded-xl border border-amber-200 space-y-1">
                <span className="text-[10px] font-bold text-amber-700 uppercase block">
                  Dry Balcony (Outside)
                </span>
                <div className="font-black text-sm text-amber-950">
                  {DimensionParser.formatArea(utilityOutsideSqFt, displayUnit)}
                </div>
                <span className="text-[10px] font-bold text-amber-700 block">
                  → Built-up Only
                </span>
              </div>
            </div>

            {/* Arithmetic Flow Line */}
            <div className="p-3 bg-white rounded-xl border border-blue-200 text-xs text-blue-950 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-bold text-blue-900">How Built-up Area is compiled:</span>
                <span className="text-[#64748B]">
                  [Internal Rooms + Enclosed Utility] ({DimensionParser.formatArea(netInternalFloorSqFt, displayUnit)})
                  {' + '}
                  Walls ({DimensionParser.formatArea(internalWallAreaSqFt + externalWallAreaSqFt, displayUnit)})
                  {' + '}
                  Balconies & Outdoor Utility ({DimensionParser.formatArea(totalExclusiveOutdoorSqFt, displayUnit)})
                </span>
              </div>
              <div className="font-black text-sm text-blue-900 shrink-0">
                = {DimensionParser.formatArea(builtUpAreaSqFt, displayUnit)}
              </div>
            </div>

            {onOpenModal && (
              <div className="pt-1 flex items-center justify-end">
                <button
                  type="button"
                  onClick={() => onOpenModal('comparison')}
                  className="text-xs font-bold text-blue-700 hover:text-blue-900 hover:underline flex items-center gap-1.5 cursor-pointer py-1"
                >
                  <span>Open Full RERA Area Definitions & Buyer Safeguards Guide</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
