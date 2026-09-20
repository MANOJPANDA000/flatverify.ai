import React, { useState, useMemo } from 'react';
import {
  X,
  ArrowLeftRight,
  Sliders,
  Layers,
  TrendingUp,
  TrendingDown,
  Minus,
  CheckCircle2,
  Building,
  Scale,
  Percent,
  Ruler,
  Info,
} from 'lucide-react';
import { PropertyAudit, AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

export interface AuditComparisonModalProps {
  isOpen: boolean;
  onClose: () => void;
  audits: PropertyAudit[];
  initialAuditAId?: string;
  initialAuditBId?: string;
  displayUnit: AreaDisplayUnit;
  onUnitChange?: (unit: AreaDisplayUnit) => void;
}

export const AuditComparisonModal: React.FC<AuditComparisonModalProps> = ({
  isOpen,
  onClose,
  audits,
  initialAuditAId,
  initialAuditBId,
  displayUnit,
  onUnitChange,
}) => {
  // Default to provided IDs or first two audits
  const [auditAId, setAuditAId] = useState<string>(() => {
    if (initialAuditAId && audits.some(a => a.id === initialAuditAId)) {
      return initialAuditAId;
    }
    return audits[0]?.id || '';
  });

  const [auditBId, setAuditBId] = useState<string>(() => {
    if (initialAuditBId && audits.some(a => a.id === initialAuditBId)) {
      return initialAuditBId;
    }
    const second = audits.find(a => a.id !== (initialAuditAId || audits[0]?.id));
    return second?.id || audits[1]?.id || audits[0]?.id || '';
  });

  // Sync state if initial props change when opened
  React.useEffect(() => {
    if (initialAuditAId && audits.some(a => a.id === initialAuditAId)) {
      setAuditAId(initialAuditAId);
    }
    if (initialAuditBId && audits.some(a => a.id === initialAuditBId)) {
      setAuditBId(initialAuditBId);
    }
  }, [initialAuditAId, initialAuditBId, audits]);

  const auditA = useMemo(() => audits.find(a => a.id === auditAId) || audits[0], [audits, auditAId]);
  const auditB = useMemo(
    () => audits.find(a => a.id === auditBId) || audits.find(a => a.id !== auditAId) || audits[1] || audits[0],
    [audits, auditBId, auditAId]
  );

  if (!isOpen || !auditA) return null;

  const handleSwap = () => {
    if (auditB) {
      setAuditAId(auditB.id);
      setAuditBId(auditA.id);
    }
  };

  // Calculations for Audit A
  const carpetA = auditA.carpetArea || 0;
  const builtUpA = auditA.builtUpArea || 0;
  const superA = auditA.superBuiltUpArea || 0;
  const intWallPctA = auditA.internalWallPercent || 0;
  const intWallAreaA = auditA.internalWallArea || 0;
  const extWallPctA = auditA.externalWallPercent || 0;
  const extWallAreaA = auditA.externalWallArea || 0;
  const loadingPctA = auditA.loadingPercent || 0;
  const loadingAreaA = auditA.loadingArea || 0;
  const balconyA = auditA.balconyArea || 0;
  const utilityInsideA = auditA.utilityInsideArea || 0;
  const efficiencyA = superA > 0 ? (carpetA / superA) * 100 : 0;
  const totalWallsAreaA = intWallAreaA + extWallAreaA;

  // Calculations for Audit B
  const carpetB = auditB?.carpetArea || 0;
  const builtUpB = auditB?.builtUpArea || 0;
  const superB = auditB?.superBuiltUpArea || 0;
  const intWallPctB = auditB?.internalWallPercent || 0;
  const intWallAreaB = auditB?.internalWallArea || 0;
  const extWallPctB = auditB?.externalWallPercent || 0;
  const extWallAreaB = auditB?.externalWallArea || 0;
  const loadingPctB = auditB?.loadingPercent || 0;
  const loadingAreaB = auditB?.loadingArea || 0;
  const balconyB = auditB?.balconyArea || 0;
  const utilityInsideB = auditB?.utilityInsideArea || 0;
  const efficiencyB = superB > 0 ? (carpetB / superB) * 100 : 0;
  const totalWallsAreaB = intWallAreaB + extWallAreaB;

  // Deltas (Audit B - Audit A, showing how B compares relative to A)
  const diffCarpet = carpetB - carpetA;
  const diffCarpetPct = carpetA > 0 ? ((diffCarpet / carpetA) * 100).toFixed(1) : '0';
  const diffBalcony = balconyB - balconyA;
  const diffUtilityInside = utilityInsideB - utilityInsideA;

  const diffBuiltUp = builtUpB - builtUpA;
  const diffBuiltUpPct = builtUpA > 0 ? ((diffBuiltUp / builtUpA) * 100).toFixed(1) : '0';

  const diffSuper = superB - superA;
  const diffSuperPct = superA > 0 ? ((diffSuper / superA) * 100).toFixed(1) : '0';

  const diffEfficiency = efficiencyB - efficiencyA;
  const diffIntWallPct = intWallPctB - intWallPctA;
  const diffIntWallArea = intWallAreaB - intWallAreaA;
  const diffExtWallPct = extWallPctB - extWallPctA;
  const diffExtWallArea = extWallAreaB - extWallAreaA;
  const diffLoadingPct = loadingPctB - loadingPctA;
  const diffLoadingArea = loadingAreaB - loadingAreaA;
  const diffTotalWallsArea = totalWallsAreaB - totalWallsAreaA;

  // Room matching comparison
  const roomMap = new Map<string, { roomA?: typeof auditA.rooms[0]; roomB?: typeof auditA.rooms[0] }>();

  (auditA.rooms || []).forEach(r => {
    const key = r.name.trim().toLowerCase();
    if (!roomMap.has(key)) roomMap.set(key, {});
    roomMap.get(key)!.roomA = r;
  });

  (auditB?.rooms || []).forEach(r => {
    const key = r.name.trim().toLowerCase();
    if (!roomMap.has(key)) roomMap.set(key, {});
    roomMap.get(key)!.roomB = r;
  });

  const matchedRooms = Array.from(roomMap.entries()).map(([key, data]) => {
    const nameA = data.roomA?.name;
    const nameB = data.roomB?.name;
    const name = nameA || nameB || key;

    const areaA = data.roomA
      ? DimensionParser.squareMetersToSquareFeet(data.roomA.lengthMeters * data.roomA.widthMeters)
      : null;
    const areaB = data.roomB
      ? DimensionParser.squareMetersToSquareFeet(data.roomB.lengthMeters * data.roomB.widthMeters)
      : null;
    const diff = areaA !== null && areaB !== null ? areaB - areaA : null;

    return {
      name,
      roomA: data.roomA,
      roomB: data.roomB,
      areaA,
      areaB,
      diff,
    };
  });

  // Render Delta Pill helper
  const renderDelta = (
    deltaVal: number,
    isPercentage: boolean = false,
    inverseGood: boolean = false // e.g. lower wall percentage or lower loading is good
  ) => {
    if (Math.abs(deltaVal) < 0.01) {
      return (
        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-md">
          <Minus className="w-3 h-3" /> Same
        </span>
      );
    }

    const isPositive = deltaVal > 0;
    const isGood = inverseGood ? !isPositive : isPositive;

    const colorClass = isGood
      ? 'text-emerald-700 bg-emerald-50 border border-emerald-200'
      : 'text-amber-700 bg-amber-50 border border-amber-200';

    const Icon = isPositive ? TrendingUp : TrendingDown;
    const sign = isPositive ? '+' : '';
    const formatted = isPercentage
      ? `${sign}${deltaVal.toFixed(1)}%`
      : `${sign}${DimensionParser.formatArea(deltaVal, displayUnit)}`;

    return (
      <span className={`inline-flex items-center gap-1 text-[11px] font-extrabold px-2 py-0.5 rounded-md ${colorClass}`}>
        <Icon className="w-3 h-3" />
        <span>{formatted}</span>
      </span>
    );
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-5 overflow-y-auto animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        id="audit-comparison-dialog"
        className="bg-white w-full max-w-5xl rounded-3xl shadow-2xl border border-[#E2E8F0] overflow-hidden my-auto max-h-[92vh] flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        {/* Modal Top Header */}
        <div className="p-4 sm:p-5 border-b border-[#E2E8F0] bg-[#F8FAFC] flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-blue-600 text-white flex items-center justify-center shadow-xs">
              <Scale className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base sm:text-lg font-black text-[#0F172A]">
                  Audit Comparison & Area Variance
                </h2>
                <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                  Side-by-Side
                </span>
              </div>
              <p className="text-xs text-[#64748B]">
                Directly cross-reference calculated carpet area, wall impact assumptions, and efficiency
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 self-end sm:self-auto">
            {onUnitChange && (
              <div className="flex items-center gap-1 bg-white border border-[#CBD5E1] p-1 rounded-xl shadow-2xs">
                <span className="text-[10px] font-bold text-[#64748B] pl-1.5 hidden md:inline">Unit:</span>
                <button
                  type="button"
                  onClick={() => onUnitChange('imperial')}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold cursor-pointer transition-all ${
                    displayUnit === 'imperial'
                      ? 'bg-blue-600 text-white'
                      : 'text-[#64748B] hover:text-[#0F172A]'
                  }`}
                >
                  Sq. Ft.
                </button>
                <button
                  type="button"
                  onClick={() => onUnitChange('metric')}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold cursor-pointer transition-all ${
                    displayUnit === 'metric'
                      ? 'bg-blue-600 text-white'
                      : 'text-[#64748B] hover:text-[#0F172A]'
                  }`}
                >
                  Sq. M.
                </button>
                <button
                  type="button"
                  onClick={() => onUnitChange('hybrid')}
                  className={`text-xs px-2.5 py-1 rounded-lg font-bold cursor-pointer transition-all ${
                    displayUnit === 'hybrid'
                      ? 'bg-blue-600 text-white'
                      : 'text-[#64748B] hover:text-[#0F172A]'
                  }`}
                >
                  Dual
                </button>
              </div>
            )}

            <button
              type="button"
              onClick={onClose}
              className="w-9 h-9 flex items-center justify-center rounded-xl bg-white hover:bg-gray-100 text-gray-500 hover:text-gray-800 border border-[#E2E8F0] shadow-2xs transition-colors cursor-pointer"
              title="Close Comparison"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Scrollable Comparison Content */}
        <div className="p-4 sm:p-6 overflow-y-auto space-y-6">
          {/* Plan Selector Header Cards */}
          <div className="grid grid-cols-1 md:grid-cols-11 gap-3 items-center">
            {/* Plan A Selector */}
            <div className="md:col-span-5 bg-blue-50/50 border-2 border-blue-200 rounded-2xl p-3.5 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black uppercase tracking-wider text-blue-800 bg-blue-100 px-2 py-0.5 rounded">
                  Report A (Baseline)
                </span>
                <span className="text-xs font-bold text-[#64748B]">
                  {auditA.type === 'scan' ? 'Blueprint Scan' : 'Manual Audit'}
                </span>
              </div>
              <select
                value={auditAId}
                onChange={e => setAuditAId(e.target.value)}
                className="w-full bg-white border border-blue-300 rounded-xl px-3 py-2 text-xs font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {audits.map(a => (
                  <option key={a.id} value={a.id} disabled={a.id === auditBId}>
                    {a.auditName} ({a.configuration || 'Standard'} • {DimensionParser.formatArea(a.carpetArea, displayUnit)})
                  </option>
                ))}
              </select>
              <div className="text-[11px] text-[#64748B] flex items-center justify-between pt-1">
                <span>{auditA.project || 'Project Plan'}</span>
                <span>{new Date(auditA.timestamp).toLocaleDateString()}</span>
              </div>
            </div>

            {/* Swap Button */}
            <div className="md:col-span-1 flex justify-center">
              <button
                type="button"
                onClick={handleSwap}
                className="w-10 h-10 rounded-full bg-white border border-[#CBD5E1] hover:border-blue-500 text-[#475569] hover:text-blue-700 shadow-sm flex items-center justify-center transition-all cursor-pointer hover:rotate-180 duration-200"
                title="Swap Plan A and Plan B"
              >
                <ArrowLeftRight className="w-4 h-4" />
              </button>
            </div>

            {/* Plan B Selector */}
            <div className="md:col-span-5 bg-purple-50/50 border-2 border-purple-200 rounded-2xl p-3.5 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black uppercase tracking-wider text-purple-800 bg-purple-100 px-2 py-0.5 rounded">
                  Report B (Comparison)
                </span>
                <span className="text-xs font-bold text-[#64748B]">
                  {auditB?.type === 'scan' ? 'Blueprint Scan' : 'Manual Audit'}
                </span>
              </div>
              <select
                value={auditBId}
                onChange={e => setAuditBId(e.target.value)}
                className="w-full bg-white border border-purple-300 rounded-xl px-3 py-2 text-xs font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                {audits.map(a => (
                  <option key={a.id} value={a.id} disabled={a.id === auditAId}>
                    {a.auditName} ({a.configuration || 'Standard'} • {DimensionParser.formatArea(a.carpetArea, displayUnit)})
                  </option>
                ))}
              </select>
              <div className="text-[11px] text-[#64748B] flex items-center justify-between pt-1">
                <span>{auditB?.project || 'Project Plan'}</span>
                <span>{auditB ? new Date(auditB.timestamp).toLocaleDateString() : ''}</span>
              </div>
            </div>
          </div>

          {/* Quick Summary Insight Verdict */}
          <div className="p-4 rounded-2xl bg-gradient-to-r from-blue-50 via-indigo-50 to-purple-50 border border-blue-200/80 shadow-2xs flex items-start gap-3">
            <div className="w-8 h-8 rounded-xl bg-blue-600 text-white flex items-center justify-center shrink-0 mt-0.5">
              <Info className="w-4 h-4" />
            </div>
            <div className="text-xs leading-relaxed text-[#1E293B]">
              <span className="font-bold text-[#0F172A]">Comparative Takeaway: </span>
              {diffCarpet !== 0 ? (
                <>
                  <strong>{diffCarpet > 0 ? auditB.auditName : auditA.auditName}</strong> delivers{' '}
                  <strong className="text-blue-700">
                    {DimensionParser.formatArea(Math.abs(diffCarpet), displayUnit)} (
                    {Math.abs(Number(diffCarpetPct))}%)
                  </strong>{' '}
                  more net usable carpet area.
                  {diffEfficiency !== 0 && (
                    <>
                      {' '}Its space efficiency is{' '}
                      <strong className={diffEfficiency > 0 ? 'text-emerald-700' : 'text-blue-700'}>
                        {Math.abs(diffEfficiency).toFixed(1)}% {diffEfficiency > 0 ? 'higher' : 'lower'}
                      </strong>{' '}
                      relative to super built-up area.
                    </>
                  )}
                </>
              ) : (
                <>Both audits share an identical calculated carpet area of <strong>{DimensionParser.formatArea(carpetA, displayUnit)}</strong>.</>
              )}
            </div>
          </div>

          {/* Core Calculated Area Metrics Grid */}
          <div className="space-y-3">
            <h3 className="font-black text-xs uppercase tracking-wider text-[#334155] flex items-center gap-1.5">
              <Ruler className="w-3.5 h-3.5 text-blue-600" />
              <span>Calculated Area Comparison (RERA Metrics)</span>
            </h3>

            <div className="border border-[#E2E8F0] rounded-2xl overflow-hidden shadow-2xs">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[#475569] font-bold">
                    <th className="py-3 px-4">Metric</th>
                    <th className="py-3 px-4 text-blue-900 bg-blue-50/40">
                      {auditA.auditName} (A)
                    </th>
                    <th className="py-3 px-4 text-purple-900 bg-purple-50/40">
                      {auditB?.auditName || 'Plan B'} (B)
                    </th>
                    <th className="py-3 px-4 text-right">Variance (B vs A)</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  {/* Carpet Area */}
                  <tr className="hover:bg-[#F8FAFC]">
                    <td className="py-3 px-4 font-black text-[#0F172A]">
                      <div>RERA Carpet Area</div>
                      <span className="text-[10px] font-normal text-[#64748B]">Net usable enclosed floor</span>
                    </td>
                    <td className="py-3 px-4 font-black text-blue-700 bg-blue-50/20 text-sm">
                      {DimensionParser.formatArea(carpetA, displayUnit)}
                    </td>
                    <td className="py-3 px-4 font-black text-purple-700 bg-purple-50/20 text-sm">
                      {DimensionParser.formatArea(carpetB, displayUnit)}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {renderDelta(diffCarpet)}
                    </td>
                  </tr>

                  {/* Exclusive Balcony Row */}
                  {(balconyA > 0 || balconyB > 0) && (
                    <tr className="hover:bg-[#F8FAFC]">
                      <td className="py-3 px-4 font-bold text-[#0F172A]">
                        <div className="flex items-center gap-1.5">
                          <span>Exclusive Balcony Area</span>
                          <span className="text-[9px] uppercase font-bold px-1.5 py-0.5 rounded bg-amber-100 text-amber-800">
                            Built-up Only
                          </span>
                        </div>
                        <span className="text-[10px] font-normal text-[#64748B]">
                          Excluded from RERA Carpet (Sec 2(k))
                        </span>
                      </td>
                      <td className="py-3 px-4 font-bold text-amber-900 bg-amber-50/20">
                        {DimensionParser.formatArea(balconyA, displayUnit)}
                      </td>
                      <td className="py-3 px-4 font-bold text-amber-900 bg-amber-50/20">
                        {DimensionParser.formatArea(balconyB, displayUnit)}
                      </td>
                      <td className="py-3 px-4 text-right">
                        {renderDelta(diffBalcony)}
                      </td>
                    </tr>
                  )}

                  {/* Enclosed Utility Inside Outer Wall Row */}
                  {(utilityInsideA > 0 || utilityInsideB > 0) && (
                    <tr className="hover:bg-[#F8FAFC]">
                      <td className="py-3 px-4 font-bold text-[#0F172A]">
                        <div className="flex items-center gap-1.5">
                          <span>Utility Area (Inside Outer Wall)</span>
                          <span className="text-[9px] uppercase font-bold px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-800">
                            In Carpet ✓
                          </span>
                        </div>
                        <span className="text-[10px] font-normal text-[#64748B]">
                          Enclosed within external perimeter walls
                        </span>
                      </td>
                      <td className="py-3 px-4 font-bold text-emerald-900 bg-emerald-50/20">
                        {DimensionParser.formatArea(utilityInsideA, displayUnit)}
                      </td>
                      <td className="py-3 px-4 font-bold text-emerald-900 bg-emerald-50/20">
                        {DimensionParser.formatArea(utilityInsideB, displayUnit)}
                      </td>
                      <td className="py-3 px-4 text-right">
                        {renderDelta(diffUtilityInside)}
                      </td>
                    </tr>
                  )}

                  {/* Built-up Area */}
                  <tr className="hover:bg-[#F8FAFC]">
                    <td className="py-3 px-4 font-bold text-[#0F172A]">
                      <div>Built-up Area</div>
                      <span className="text-[10px] font-normal text-[#64748B]">Carpet + Internal & External Walls</span>
                    </td>
                    <td className="py-3 px-4 font-bold text-[#334155] bg-blue-50/20">
                      {DimensionParser.formatArea(builtUpA, displayUnit)}
                    </td>
                    <td className="py-3 px-4 font-bold text-[#334155] bg-purple-50/20">
                      {DimensionParser.formatArea(builtUpB, displayUnit)}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {renderDelta(diffBuiltUp)}
                    </td>
                  </tr>

                  {/* Super Built-up Area */}
                  <tr className="hover:bg-[#F8FAFC]">
                    <td className="py-3 px-4 font-bold text-[#0F172A]">
                      <div>Super Built-up Area (Saleable)</div>
                      <span className="text-[10px] font-normal text-[#64748B]">Built-up + Proportionate Common Areas</span>
                    </td>
                    <td className="py-3 px-4 font-bold text-[#334155] bg-blue-50/20">
                      {DimensionParser.formatArea(superA, displayUnit)}
                    </td>
                    <td className="py-3 px-4 font-bold text-[#334155] bg-purple-50/20">
                      {DimensionParser.formatArea(superB, displayUnit)}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {renderDelta(diffSuper)}
                    </td>
                  </tr>

                  {/* Space Efficiency */}
                  <tr className="hover:bg-[#F8FAFC]">
                    <td className="py-3 px-4 font-black text-[#0F172A]">
                      <div>Usable Space Efficiency</div>
                      <span className="text-[10px] font-normal text-[#64748B]">Carpet Area ÷ Super Built-up Area</span>
                    </td>
                    <td className="py-3 px-4 font-black text-blue-700 bg-blue-50/20">
                      {efficiencyA > 0 ? `${efficiencyA.toFixed(1)}%` : 'N/A'}
                    </td>
                    <td className="py-3 px-4 font-black text-purple-700 bg-purple-50/20">
                      {efficiencyB > 0 ? `${efficiencyB.toFixed(1)}%` : 'N/A'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {renderDelta(diffEfficiency, true)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Wall Assumptions & Loading Impact Comparison */}
          <div className="space-y-3">
            <h3 className="font-black text-xs uppercase tracking-wider text-[#334155] flex items-center gap-1.5">
              <Sliders className="w-3.5 h-3.5 text-indigo-600" />
              <span>Wall Assumptions & Non-Usable Deductions Side-by-Side</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Internal Walls Card */}
              <div className="p-4 rounded-2xl bg-white border border-[#E2E8F0] shadow-2xs space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black text-[#0F172A]">Internal Walls</span>
                  {renderDelta(diffIntWallPct, true, true)}
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-[#F1F5F9]">
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan A</span>
                    <strong className="text-blue-700">{intWallPctA.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(intWallAreaA, displayUnit)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan B</span>
                    <strong className="text-purple-700">{intWallPctB.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(intWallAreaB, displayUnit)}
                    </span>
                  </div>
                </div>
              </div>

              {/* External Walls Card */}
              <div className="p-4 rounded-2xl bg-white border border-[#E2E8F0] shadow-2xs space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black text-[#0F172A]">External Walls</span>
                  {renderDelta(diffExtWallPct, true, true)}
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-[#F1F5F9]">
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan A</span>
                    <strong className="text-blue-700">{extWallPctA.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(extWallAreaA, displayUnit)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan B</span>
                    <strong className="text-purple-700">{extWallPctB.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(extWallAreaB, displayUnit)}
                    </span>
                  </div>
                </div>
              </div>

              {/* Common Loading Factor Card */}
              <div className="p-4 rounded-2xl bg-white border border-[#E2E8F0] shadow-2xs space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black text-[#0F172A]">Common Loading</span>
                  {renderDelta(diffLoadingPct, true, true)}
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-[#F1F5F9]">
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan A</span>
                    <strong className="text-blue-700">{loadingPctA.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(loadingAreaA, displayUnit)}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#94A3B8] block">Plan B</span>
                    <strong className="text-purple-700">{loadingPctB.toFixed(1)}%</strong>
                    <span className="text-[10px] text-[#64748B] block">
                      {DimensionParser.formatArea(loadingAreaB, displayUnit)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Visual Stacked Area Distribution Bar */}
          <div className="p-4 rounded-2xl bg-[#F8FAFC] border border-[#E2E8F0] space-y-4">
            <h4 className="text-xs font-black uppercase tracking-wider text-[#334155] flex items-center gap-1.5">
              <Layers className="w-3.5 h-3.5 text-blue-600" />
              <span>Visual Space Allocation Comparison</span>
            </h4>

            {/* Plan A Bar */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between text-xs">
                <span className="font-black text-blue-800">
                  {auditA.auditName} ({DimensionParser.formatArea(superA, displayUnit)})
                </span>
                <span className="text-[11px] text-[#64748B]">
                  Carpet: {efficiencyA.toFixed(1)}% • Walls: {((totalWallsAreaA / (superA || 1)) * 100).toFixed(1)}% • Loading: {((loadingAreaA / (superA || 1)) * 100).toFixed(1)}%
                </span>
              </div>
              <div className="h-6 w-full rounded-xl bg-gray-200 overflow-hidden flex text-[10px] font-black text-white text-center leading-6">
                <div
                  style={{ width: `${Math.max(5, efficiencyA)}%` }}
                  className="bg-blue-600 truncate px-1"
                  title={`Carpet Area: ${DimensionParser.formatArea(carpetA, displayUnit)} (${efficiencyA.toFixed(1)}%)`}
                >
                  Carpet {efficiencyA.toFixed(0)}%
                </div>
                <div
                  style={{ width: `${Math.max(3, (totalWallsAreaA / (superA || 1)) * 100)}%` }}
                  className="bg-slate-500 truncate px-1"
                  title={`Walls: ${DimensionParser.formatArea(totalWallsAreaA, displayUnit)}`}
                >
                  Walls
                </div>
                <div
                  style={{ width: `${Math.max(3, (loadingAreaA / (superA || 1)) * 100)}%` }}
                  className="bg-amber-500 truncate px-1"
                  title={`Loading: ${DimensionParser.formatArea(loadingAreaA, displayUnit)}`}
                >
                  Loading
                </div>
              </div>
            </div>

            {/* Plan B Bar */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between text-xs">
                <span className="font-black text-purple-800">
                  {auditB?.auditName || 'Plan B'} ({DimensionParser.formatArea(superB, displayUnit)})
                </span>
                <span className="text-[11px] text-[#64748B]">
                  Carpet: {efficiencyB.toFixed(1)}% • Walls: {((totalWallsAreaB / (superB || 1)) * 100).toFixed(1)}% • Loading: {((loadingAreaB / (superB || 1)) * 100).toFixed(1)}%
                </span>
              </div>
              <div className="h-6 w-full rounded-xl bg-gray-200 overflow-hidden flex text-[10px] font-black text-white text-center leading-6">
                <div
                  style={{ width: `${Math.max(5, efficiencyB)}%` }}
                  className="bg-purple-600 truncate px-1"
                  title={`Carpet Area: ${DimensionParser.formatArea(carpetB, displayUnit)} (${efficiencyB.toFixed(1)}%)`}
                >
                  Carpet {efficiencyB.toFixed(0)}%
                </div>
                <div
                  style={{ width: `${Math.max(3, (totalWallsAreaB / (superB || 1)) * 100)}%` }}
                  className="bg-slate-500 truncate px-1"
                  title={`Walls: ${DimensionParser.formatArea(totalWallsAreaB, displayUnit)}`}
                >
                  Walls
                </div>
                <div
                  style={{ width: `${Math.max(3, (loadingAreaB / (superB || 1)) * 100)}%` }}
                  className="bg-amber-500 truncate px-1"
                  title={`Loading: ${DimensionParser.formatArea(loadingAreaB, displayUnit)}`}
                >
                  Loading
                </div>
              </div>
            </div>

            {/* Legend */}
            <div className="flex flex-wrap items-center gap-4 text-[11px] pt-1 text-[#64748B]">
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-blue-600" /> Usable Carpet Floor
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-slate-500" /> Internal & External Walls
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded-full bg-amber-500" /> Common Area Loading
              </span>
            </div>
          </div>

          {/* Room-by-Room Direct Comparison Table */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-xs uppercase tracking-wider text-[#334155] flex items-center gap-1.5">
                <Building className="w-3.5 h-3.5 text-blue-600" />
                <span>Room Dimensions & Area Breakdown ({matchedRooms.length} Spaces)</span>
              </h3>
            </div>

            <div className="border border-[#E2E8F0] rounded-2xl overflow-hidden shadow-2xs">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[#475569] font-bold">
                    <th className="py-2.5 px-4">Room Name</th>
                    <th className="py-2.5 px-3">Plan A Dimensions</th>
                    <th className="py-2.5 px-3">Plan A Area</th>
                    <th className="py-2.5 px-3">Plan B Dimensions</th>
                    <th className="py-2.5 px-3">Plan B Area</th>
                    <th className="py-2.5 px-4 text-right">Variance</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F1F5F9]">
                  {matchedRooms.map((row, idx) => {
                    const dimStrA = row.roomA
                      ? `${DimensionParser.formatLength(row.roomA.lengthMeters, displayUnit)} × ${DimensionParser.formatLength(row.roomA.widthMeters, displayUnit)}`
                      : '—';
                    const dimStrB = row.roomB
                      ? `${DimensionParser.formatLength(row.roomB.lengthMeters, displayUnit)} × ${DimensionParser.formatLength(row.roomB.widthMeters, displayUnit)}`
                      : '—';

                    return (
                      <tr key={idx} className="hover:bg-[#F8FAFC]">
                        <td className="py-2.5 px-4 font-bold text-[#0F172A]">
                          {row.name}
                        </td>
                        <td className="py-2.5 px-3 text-[#64748B]">
                          {dimStrA}
                        </td>
                        <td className="py-2.5 px-3 font-semibold text-blue-900">
                          {row.areaA !== null ? DimensionParser.formatArea(row.areaA, displayUnit) : '—'}
                        </td>
                        <td className="py-2.5 px-3 text-[#64748B]">
                          {dimStrB}
                        </td>
                        <td className="py-2.5 px-3 font-semibold text-purple-900">
                          {row.areaB !== null ? DimensionParser.formatArea(row.areaB, displayUnit) : '—'}
                        </td>
                        <td className="py-2.5 px-4 text-right">
                          {row.diff !== null ? (
                            renderDelta(row.diff)
                          ) : (
                            <span className="text-[10px] font-bold text-gray-400">
                              {row.areaA !== null ? 'Only in A' : 'Only in B'}
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-[#E2E8F0] bg-[#F8FAFC] flex items-center justify-between gap-3 shrink-0">
          <div className="text-xs text-[#64748B]">
            Comparing <strong>{auditA.auditName}</strong> vs <strong>{auditB?.auditName}</strong>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl shadow-xs transition-colors cursor-pointer"
          >
            Close Comparison
          </button>
        </div>
      </div>
    </div>
  );
};
