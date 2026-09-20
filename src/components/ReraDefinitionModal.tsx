import React, { useState, useEffect } from 'react';
import {
  X,
  Building2,
  Home,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  HelpCircle,
  FileText,
  ShieldAlert,
  ArrowRight,
  Layers,
  Info,
  Download,
} from 'lucide-react';
import { AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { downloadFile } from '../utils/downloadHelper';

export interface ReraDefinitionModalProps {
  isOpen: boolean;
  onClose: () => void;
  displayUnit?: AreaDisplayUnit;
  initialTab?: 'comparison' | 'balcony' | 'utility' | 'checklist';
}

export const ReraDefinitionModal: React.FC<ReraDefinitionModalProps> = ({
  isOpen,
  onClose,
  displayUnit = 'imperial',
  initialTab = 'comparison',
}) => {
  const [activeTab, setActiveTab] = useState<'comparison' | 'balcony' | 'utility' | 'checklist'>(initialTab);

  // Sync initialTab when modal opens
  useEffect(() => {
    if (isOpen) {
      setActiveTab(initialTab);
    }
  }, [isOpen, initialTab]);

  // Handle ESC key press
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-950/60 backdrop-blur-xs overflow-y-auto animate-in fade-in duration-200"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="rera-modal-title"
    >
      <div
        className="bg-white rounded-3xl border border-[#CBD5E1] shadow-2xl max-w-3xl w-full my-auto overflow-hidden text-[#0F172A] relative flex flex-col max-h-[90vh]"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="p-5 sm:p-6 bg-linear-to-r from-blue-50/80 via-indigo-50/40 to-slate-50 border-b border-[#E2E8F0] flex items-start justify-between gap-4 shrink-0">
          <div className="flex items-start gap-3.5">
            <div className="w-11 h-11 rounded-2xl bg-blue-600 text-white flex items-center justify-center shrink-0 shadow-xs mt-0.5">
              <Building2 className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 id="rera-modal-title" className="text-lg sm:text-xl font-black tracking-tight text-[#0F172A]">
                  RERA Area Definitions & Rules
                </h2>
                <span className="px-2 py-0.5 text-[10px] font-black uppercase tracking-wider bg-blue-100 text-blue-800 rounded-full border border-blue-200">
                  Act Section 2(k)
                </span>
              </div>
              <p className="text-xs sm:text-sm text-[#64748B] mt-1">
                Statutory legal distinction between <strong>Carpet Area</strong> vs <strong>Built-up Area</strong>, clarifying Balcony and Utility room classifications.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 text-[#64748B] hover:text-[#0F172A] hover:bg-slate-200/60 rounded-xl transition-colors shrink-0"
            aria-label="Close dialog"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="px-5 sm:px-6 pt-3 bg-white border-b border-[#E2E8F0] flex gap-2 overflow-x-auto scrollbar-none shrink-0">
          <button
            type="button"
            onClick={() => setActiveTab('comparison')}
            className={`pb-2.5 px-3 text-xs font-bold border-b-2 whitespace-nowrap transition-colors flex items-center gap-1.5 ${
              activeTab === 'comparison'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>Carpet vs Built-up Area</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('balcony')}
            className={`pb-2.5 px-3 text-xs font-bold border-b-2 whitespace-nowrap transition-colors flex items-center gap-1.5 ${
              activeTab === 'balcony'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            <Home className="w-3.5 h-3.5" />
            <span>Balcony Categorization</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('utility')}
            className={`pb-2.5 px-3 text-xs font-bold border-b-2 whitespace-nowrap transition-colors flex items-center gap-1.5 ${
              activeTab === 'utility'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            <Building2 className="w-3.5 h-3.5" />
            <span>Utility Area (Inside vs Outside)</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('checklist')}
            className={`pb-2.5 px-3 text-xs font-bold border-b-2 whitespace-nowrap transition-colors flex items-center gap-1.5 ${
              activeTab === 'checklist'
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            <CheckCircle2 className="w-3.5 h-3.5" />
            <span>Buyer Safeguards</span>
          </button>
        </div>

        {/* Tab Content Body */}
        <div className="p-5 sm:p-6 overflow-y-auto space-y-6 flex-1 text-xs sm:text-sm leading-relaxed">
          {/* TAB 1: Comparison */}
          {activeTab === 'comparison' && (
            <div className="space-y-6">
              {/* Statutory Quotation */}
              <div className="p-4 bg-blue-50/60 rounded-2xl border border-blue-200/80">
                <div className="flex items-start gap-2.5">
                  <FileText className="w-5 h-5 text-blue-700 shrink-0 mt-0.5" />
                  <div>
                    <span className="font-black text-xs uppercase tracking-wide text-blue-900 block">
                      The Real Estate (Regulation & Development) Act, 2016 — Section 2(k)
                    </span>
                    <blockquote className="italic text-xs text-blue-950 mt-1.5 font-medium leading-relaxed">
                      &ldquo;Carpet area means the net usable floor area of an apartment, excluding the area covered by the external walls, areas under services shafts, exclusive balcony or verandah area and exclusive open terrace area, but includes the area covered by the internal partition walls of the apartment.&rdquo;
                    </blockquote>
                  </div>
                </div>
              </div>

              {/* Side-by-Side Comparison Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Carpet Area Box */}
                <div className="p-4 rounded-2xl bg-[#F0FDF4] border border-emerald-200 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 text-[10px] font-black uppercase tracking-wide bg-emerald-700 text-white rounded">
                      RERA Carpet Area
                    </span>
                    <span className="text-[11px] font-bold text-emerald-800">Legal Sale Basis</span>
                  </div>
                  <h3 className="text-base font-black text-emerald-950">
                    Net Usable Floor Area + Internal Partition Walls
                  </h3>
                  <p className="text-xs text-emerald-900">
                    The actual enclosed area on which you can spread a carpet inside the apartment, bounded by the inner faces of the outer walls.
                  </p>

                  <div className="space-y-2 pt-2 border-t border-emerald-200/80 text-xs">
                    <div className="font-bold text-emerald-950 flex items-center gap-1.5">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                      <span>INCLUDED in Carpet Area:</span>
                    </div>
                    <ul className="space-y-1 pl-5 list-disc text-emerald-900 text-[11px]">
                      <li>Living room, bedrooms, dining room, study, pooja room</li>
                      <li>Kitchen, bathrooms, toilets, washrooms, walk-in closets</li>
                      <li><strong>Utility area INSIDE the external perimeter wall</strong></li>
                      <li>Internal non-loadbearing partition walls between rooms</li>
                    </ul>

                    <div className="font-bold text-rose-950 flex items-center gap-1.5 pt-1">
                      <XCircle className="w-4 h-4 text-rose-600 shrink-0" />
                      <span>STRICTLY EXCLUDED from Carpet Area:</span>
                    </div>
                    <ul className="space-y-1 pl-5 list-disc text-rose-900 text-[11px]">
                      <li>Balconies, verandahs, and open terraces (even if private)</li>
                      <li>External boundary and facade walls</li>
                      <li>Dry balconies outside the external perimeter wall</li>
                      <li>Plumbing shafts, duct shafts, lift wells, common lobbies</li>
                    </ul>
                  </div>
                </div>

                {/* Built-up Area Box */}
                <div className="p-4 rounded-2xl bg-[#EFF6FF] border border-blue-200 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 text-[10px] font-black uppercase tracking-wide bg-blue-700 text-white rounded">
                      Built-Up Area (Plinth)
                    </span>
                    <span className="text-[11px] font-bold text-blue-800">Total Structural Footprint</span>
                  </div>
                  <h3 className="text-base font-black text-blue-950">
                    Carpet Area + Walls + Exclusive Balconies
                  </h3>
                  <p className="text-xs text-blue-900">
                    The total structural floor footprint of the specific flat, measured up to the outer perimeter face of the exterior walls plus all dedicated balconies.
                  </p>

                  <div className="space-y-2 pt-2 border-t border-blue-200/80 text-xs">
                    <div className="font-bold text-blue-950 flex items-center gap-1.5">
                      <CheckCircle2 className="w-4 h-4 text-blue-600 shrink-0" />
                      <span>INCLUDED in Built-up Area:</span>
                    </div>
                    <ul className="space-y-1 pl-5 list-disc text-blue-900 text-[11px]">
                      <li>Everything in RERA Carpet Area</li>
                      <li><strong>External perimeter walls (100% outer face or 50% shared)</strong></li>
                      <li><strong>All exclusive balconies & attached verandahs</strong></li>
                      <li><strong>Dry balconies & outdoor utility projections</strong></li>
                      <li>Exclusive open terrace area (demarcated in schedule)</li>
                    </ul>

                    <div className="font-bold text-slate-700 flex items-center gap-1.5 pt-1">
                      <XCircle className="w-4 h-4 text-slate-500 shrink-0" />
                      <span>NOT in Built-up Area (Belongs in Super Built-up):</span>
                    </div>
                    <ul className="space-y-1 pl-5 list-disc text-slate-700 text-[11px]">
                      <li>Common corridors, staircase landings, and lift lobbies</li>
                      <li>Clubhouse, security room, overhead tanks, generator rooms</li>
                    </ul>
                  </div>
                </div>
              </div>

              {/* Mathematical Summary Table */}
              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-3">
                <h4 className="font-black text-xs sm:text-sm text-[#0F172A] uppercase tracking-wide">
                  Summary Matrix: Where Every Element Goes
                </h4>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="border-b border-slate-200 text-slate-500 font-bold">
                        <th className="py-2 px-2">Space / Architectural Element</th>
                        <th className="py-2 px-2 text-center">In RERA Carpet Area?</th>
                        <th className="py-2 px-2 text-center">In Built-up Area?</th>
                        <th className="py-2 px-2">Statutory Treatment</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200">
                      <tr>
                        <td className="py-2 px-2 font-bold text-slate-900">Bedrooms, Living, Dining, Bathrooms</td>
                        <td className="py-2 px-2 text-center text-emerald-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-slate-600">Net usable floor plate</td>
                      </tr>
                      <tr className="bg-emerald-50/50">
                        <td className="py-2 px-2 font-bold text-emerald-950">Utility Area (INSIDE outer wall)</td>
                        <td className="py-2 px-2 text-center text-emerald-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-emerald-900 font-medium">Net usable floor enclosed within perimeter</td>
                      </tr>
                      <tr className="bg-amber-50/50">
                        <td className="py-2 px-2 font-bold text-amber-950">Balcony / Verandah (Attached)</td>
                        <td className="py-2 px-2 text-center text-rose-600 font-black">NO ✗</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-amber-900 font-medium">Specifically excluded by Sec 2(k); disclosed in separate schedule</td>
                      </tr>
                      <tr className="bg-amber-50/50">
                        <td className="py-2 px-2 font-bold text-amber-950">Dry Balcony / Utility (OUTSIDE outer wall)</td>
                        <td className="py-2 px-2 text-center text-rose-600 font-black">NO ✗</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-amber-900 font-medium">Cantilevered outdoor service space; added to Built-up only</td>
                      </tr>
                      <tr>
                        <td className="py-2 px-2 font-bold text-slate-900">Internal Partition Walls</td>
                        <td className="py-2 px-2 text-center text-emerald-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-slate-600">Explicitly included under RERA Sec 2(k)</td>
                      </tr>
                      <tr>
                        <td className="py-2 px-2 font-bold text-slate-900">External Perimeter Walls</td>
                        <td className="py-2 px-2 text-center text-rose-600 font-black">NO ✗</td>
                        <td className="py-2 px-2 text-center text-blue-700 font-black">YES ✓</td>
                        <td className="py-2 px-2 text-slate-600">Exterior boundary walls form plinth/built-up boundary</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: Balcony Categorization */}
          {activeTab === 'balcony' && (
            <div className="space-y-5">
              <div className="p-4 bg-amber-50/80 rounded-2xl border border-amber-200 space-y-3">
                <div className="flex items-center gap-2 text-amber-900 font-black text-sm">
                  <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0" />
                  <span>The Law on Balconies: Strictly Excluded from Carpet Area</span>
                </div>
                <p className="text-xs text-amber-950 leading-relaxed font-medium">
                  Under <strong>RERA Section 2(k)</strong>, no matter how a developer designs an attached balcony—whether it is cantilevered, recessed under the upper slab, or surrounded by railings—it <strong>CANNOT</strong> be counted as Carpet Area.
                </p>
              </div>

              <div className="space-y-3">
                <h4 className="font-extrabold text-sm text-[#0F172A]">
                  Common Balcony Questions & Official Answers
                </h4>

                <div className="space-y-3">
                  <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200">
                    <span className="font-bold text-xs text-slate-900 block">
                      1. What if the builder provides full-height sliding glass or grills on the balcony?
                    </span>
                    <p className="text-xs text-slate-600 mt-1">
                      <strong>It remains Built-up Area only.</strong> Merely glazing or placing sliding doors along an outer railing does not convert a balcony into RERA Carpet Area. Unless the municipal authority sanctioned the enclosed space as an internal habitable room in the approved building plan, it cannot be legally sold or charged as carpet area.
                    </p>
                  </div>

                  <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200">
                    <span className="font-bold text-xs text-slate-900 block">
                      2. How should the builder quote the cost of my balcony?
                    </span>
                    <p className="text-xs text-slate-600 mt-1">
                      Under statutory RERA rules, property agreements must disclose:
                      <br />
                      • <strong>Carpet Area</strong> (mandatory pricing baseline)
                      <br />
                      • <strong>Exclusive Balcony Area</strong> (disclosed as a separate distinct line item)
                      <br />
                      A builder is not allowed to blend the two together into a single inflated &quot;carpet area&quot; figure.
                    </p>
                  </div>

                  <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200">
                    <span className="font-bold text-xs text-slate-900 block">
                      3. Where does the balcony appear in our app?
                    </span>
                    <p className="text-xs text-slate-600 mt-1">
                      When you tag a space as <strong>&quot;Exclusive Balcony&quot;</strong> in our calculator, its area is immediately excluded from the RERA Carpet Area and routed straight to the <strong>Built-up Area</strong> calculation, maintaining 100% legal compliance.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: Utility Categorization */}
          {activeTab === 'utility' && (
            <div className="space-y-5">
              <div className="p-4 bg-emerald-50/80 rounded-2xl border border-emerald-200 space-y-3">
                <div className="flex items-center gap-2 text-emerald-900 font-black text-sm">
                  <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
                  <span>The Definitive Rule for Utility Areas</span>
                </div>
                <p className="text-xs text-emerald-950 leading-relaxed font-medium">
                  The statutory classification of a utility area or wash space depends entirely on its position relative to the <strong>continuous external perimeter wall</strong> of the flat.
                </p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Inside Wall */}
                <div className="p-4 bg-emerald-50/50 rounded-2xl border border-emerald-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-black text-xs text-emerald-900 uppercase tracking-wide">
                      Scenario A: Inside Outer Wall
                    </span>
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-600 text-white">
                      Carpet Area ✓
                    </span>
                  </div>
                  <h4 className="font-black text-sm text-emerald-950">
                    Enclosed Utility / Washing Alcove
                  </h4>
                  <p className="text-xs text-emerald-900 leading-relaxed">
                    If the utility space is situated <strong>inside</strong> the flat&apos;s external structural wall (e.g. adjacent to the kitchen, enclosed with internal partitions), it is legally classified as <strong>Net Usable Floor Area</strong>.
                  </p>
                  <div className="p-2.5 bg-white rounded-xl border border-emerald-200 text-[11px] text-emerald-800">
                    <strong>RERA Ruling:</strong> Treated exactly like a kitchen, pantry, or bathroom. Included in Carpet Area.
                  </div>
                </div>

                {/* Outside Wall */}
                <div className="p-4 bg-amber-50/50 rounded-2xl border border-amber-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-black text-xs text-amber-900 uppercase tracking-wide">
                      Scenario B: Outside Outer Wall
                    </span>
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-amber-600 text-white">
                      Built-up Only
                    </span>
                  </div>
                  <h4 className="font-black text-sm text-amber-950">
                    Dry Balcony / Service Balcony
                  </h4>
                  <p className="text-xs text-amber-900 leading-relaxed">
                    If the utility area projects beyond the external perimeter wall as a cantilevered dry balcony or open wash terrace, it is legally an <strong>exclusive service balcony</strong>.
                  </p>
                  <div className="p-2.5 bg-white rounded-xl border border-amber-200 text-[11px] text-amber-800">
                    <strong>RERA Ruling:</strong> Excluded from Carpet Area. Counted exclusively in Built-up Area.
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: Buyer Safeguards */}
          {activeTab === 'checklist' && (
            <div className="space-y-5">
              <div className="p-4 bg-indigo-50/80 rounded-2xl border border-indigo-200 space-y-2">
                <div className="flex items-center gap-2 text-indigo-900 font-black text-sm">
                  <ShieldAlert className="w-5 h-5 text-indigo-700 shrink-0" />
                  <span>Statutory Buyer Protections Under RERA</span>
                </div>
                <p className="text-xs text-indigo-950 leading-relaxed font-medium">
                  Always demand the officially sanctioned RERA carpet area certificate from the developer. Do not rely on marketing brochures that advertise ambiguous &quot;Usable Area&quot; or &quot;Saleable Area&quot;.
                </p>
              </div>

              <div className="space-y-2.5">
                <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="w-6 h-6 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    1
                  </div>
                  <div>
                    <h5 className="font-bold text-xs text-slate-900">Per-Square-Foot Rate Must Be on RERA Carpet Area</h5>
                    <p className="text-xs text-slate-600 mt-0.5">
                      It is a legal violation under RERA for a promoter to quote or bill apartment base prices based on &quot;Super Built-up Area&quot;. The statutory base price must strictly be linked to the RERA carpet area.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="w-6 h-6 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    2
                  </div>
                  <div>
                    <h5 className="font-bold text-xs text-slate-900">Mandatory Refund for Negative Deviation</h5>
                    <p className="text-xs text-slate-600 mt-0.5">
                      If the actual delivered carpet area upon physical possession is less than what was promised in the registered agreement, the promoter is required by law to refund the difference with interest.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="w-6 h-6 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    3
                  </div>
                  <div>
                    <h5 className="font-bold text-xs text-slate-900">Verify Balcony Inclusions in Sale Agreement</h5>
                    <p className="text-xs text-slate-600 mt-0.5">
                      Ensure your agreement clearly lists carpet area and balcony area separately. If the agreement merges balcony sq ft into the &quot;Carpet Area&quot; row, raise an immediate objection with reference to Section 2(k).
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 sm:p-5 bg-slate-50 border-t border-[#E2E8F0] flex flex-wrap items-center justify-between gap-3 shrink-0">
          <div className="text-[11px] text-[#64748B] flex items-center gap-1.5">
            <Info className="w-3.5 h-3.5 text-blue-600 shrink-0" />
            <span>Formulated strictly per RERA Act Section 2(k) guidelines.</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => downloadFile('/flutter_rera_calculator.zip', 'flutter_rera_calculator.zip')}
              className="px-3.5 py-2 text-xs font-bold bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded-xl transition-colors flex items-center gap-1.5 cursor-pointer shadow-2xs"
              title="Download complete Flutter app project (.zip)"
            >
              <Download className="w-3.5 h-3.5 text-blue-600" />
              <span>Download Flutter App (.zip)</span>
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2 text-xs font-bold bg-[#0F172A] hover:bg-slate-800 text-white rounded-xl transition-colors cursor-pointer"
            >
              Got it, thanks
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
