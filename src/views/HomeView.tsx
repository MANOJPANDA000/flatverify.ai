import React, { useState } from 'react';
import {
  ScanLine,
  Calculator,
  FileCheck2,
  TrendingUp,
  ShieldCheck,
  Building,
  ArrowRight,
  Sparkles,
  Info,
  Layers,
  ChevronRight,
} from 'lucide-react';
import { useSession } from '../context/SessionContext';
import { DimensionParser } from '../utils/dimensionParser';
import { PropertyAudit } from '../types';
import { PdfViewerModal } from '../components/PdfViewerModal';
import { NavTab } from '../components/Header';

interface HomeViewProps {
  onNavigate: (tab: NavTab) => void;
}

export const HomeView: React.FC<HomeViewProps> = ({ onNavigate }) => {
  const { audits, displayUnit } = useSession();
  const [selectedAuditForPdf, setSelectedAuditForPdf] = useState<PropertyAudit | null>(null);

  const recentAudits = audits.slice(0, 3);

  return (
    <div className="space-y-8 pb-12">
      {/* Hero Section */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#172B65] via-[#1E3A8A] to-[#2563EB] text-white p-6 sm:p-10 shadow-xl shadow-blue-900/10">
        <div className="absolute top-0 right-0 -mr-16 -mt-16 w-80 h-80 bg-blue-400/10 rounded-full blur-3xl pointer-events-none" />
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-blue-100 text-xs font-semibold mb-4">
            <Sparkles className="w-3.5 h-3.5 text-blue-300" />
            <span>AI-Assisted Blueprint Dimension Audit</span>
          </div>

          <h1 className="text-2xl sm:text-4xl font-extrabold tracking-tight leading-tight">
            Understand your true <span className="text-[#93C5FD]">carpet area</span> before booking.
          </h1>

          <p className="text-sm sm:text-base text-blue-100/90 mt-3 leading-relaxed">
            Extract floor plan dimensions automatically with OCR blueprint scanning, calculate RERA carpet area, inspect internal wall & loading assumptions, and export official audit PDF reports.
          </p>

          <div className="flex flex-wrap items-center gap-3 mt-6">
            <button
              type="button"
              onClick={() => onNavigate('scanner')}
              className="px-5 py-3 bg-white text-[#172B65] hover:bg-blue-50 font-black text-sm rounded-xl shadow-lg shadow-black/10 flex items-center gap-2 transition-transform active:scale-95 cursor-pointer"
            >
              <ScanLine className="w-4 h-4 text-[#2563EB]" />
              <span>Scan Blueprint Plan</span>
            </button>

            <button
              type="button"
              onClick={() => onNavigate('calculator')}
              className="px-5 py-3 bg-white/15 hover:bg-white/25 border border-white/20 text-white font-bold text-sm rounded-xl backdrop-blur-sm flex items-center gap-2 transition-transform active:scale-95 cursor-pointer"
            >
              <Calculator className="w-4 h-4" />
              <span>Manual Calculator</span>
            </button>
          </div>
        </div>
      </div>

      {/* Highlights / Fast Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
            <FileCheck2 className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-[#0F172A]">{audits.length}</div>
            <div className="text-xs font-semibold text-[#64748B]">Audits Documented</div>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-[#0F172A]">RERA Rule 2(k)</div>
            <div className="text-xs font-semibold text-[#64748B]">Legal Carpet Definition</div>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-black text-[#0F172A]">25% - 35%</div>
            <div className="text-xs font-semibold text-[#64748B]">Typical Market Loading</div>
          </div>
        </div>
      </div>

      {/* Recent Audits Section */}
      <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-xs">
        <div className="flex items-center justify-between pb-4 border-b border-[#F1F5F9]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center">
              <Building className="w-4 h-4" />
            </div>
            <div>
              <h2 className="font-bold text-base text-[#0F172A]">Recent Property Audits</h2>
              <p className="text-xs text-[#64748B]">Review your saved verified reports</p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => onNavigate('audits')}
            className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1 cursor-pointer"
          >
            <span>View All ({audits.length})</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        {recentAudits.length === 0 ? (
          <div className="py-12 text-center text-[#64748B]">
            <p className="text-sm">No audits saved yet.</p>
            <button
              onClick={() => onNavigate('scanner')}
              className="mt-3 px-4 py-2 bg-blue-600 text-white rounded-xl text-xs font-bold"
            >
              Scan Your First Plan
            </button>
          </div>
        ) : (
          <div className="divide-y divide-[#F1F5F9] mt-2">
            {recentAudits.map(audit => (
              <div
                key={audit.id}
                className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-[#F8FAFC] -mx-4 px-4 rounded-xl transition-colors"
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-sm text-[#0F172A] truncate">
                      {audit.auditName}
                    </h3>
                    <span
                      className={`text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded ${
                        audit.type === 'scan'
                          ? 'bg-blue-50 text-blue-700 border border-blue-200'
                          : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                      }`}
                    >
                      {audit.type === 'scan' ? 'Blueprint Scan' : 'Manual Calc'}
                    </span>
                  </div>

                  <div className="text-xs text-[#64748B] mt-0.5 flex items-center gap-3">
                    <span>
                      {audit.project ? `${audit.project} • ` : ''}
                      {audit.rooms?.length || 0} rooms
                    </span>
                    <span>•</span>
                    <span>
                      Updated{' '}
                      {new Date(audit.timestamp).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                      })}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-4 shrink-0 justify-between sm:justify-end">
                  <div className="text-left sm:text-right">
                    <div className="font-extrabold text-sm text-[#1D4ED8]">
                      {DimensionParser.formatArea(audit.carpetArea, displayUnit)}
                    </div>
                    <div className="text-[11px] text-[#64748B]">
                      Carpet Area ({audit.loadingPercent.toFixed(0)}% loading)
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => setSelectedAuditForPdf(audit)}
                    className="px-3 py-1.5 bg-[#F1F5F9] hover:bg-[#E2E8F0] text-[#0F172A] font-bold text-xs rounded-lg transition-colors cursor-pointer"
                  >
                    View PDF
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Educational Knowledge Section: RERA Carpet vs Super Built-up */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-xs space-y-3">
          <div className="flex items-center gap-2 text-blue-700 font-bold text-sm">
            <ShieldCheck className="w-5 h-5 text-blue-600" />
            <span>Understanding RERA Carpet Area</span>
          </div>
          <h3 className="font-black text-lg text-[#0F172A]">
            What is legally counted in your carpet area?
          </h3>
          <p className="text-xs text-[#475569] leading-relaxed">
            Under section 2(k) of the Real Estate (Regulation and Development) Act (RERA), <strong>Carpet Area</strong> means the net usable floor area of an apartment, excluding the area covered by external walls, areas under service shafts, exclusive balcony or verandah area, and exclusive open terrace area, but <em>including</em> the area covered by the internal partition walls of the apartment.
          </p>
          <div className="p-3 bg-[#F8FAFC] rounded-xl border border-[#E2E8F0] text-xs text-[#475569] space-y-1">
            <div>✓ <strong>Included:</strong> Living, Bedrooms, Kitchen, Bathrooms, internal walls.</div>
            <div>✗ <strong>Excluded:</strong> External perimeter walls, common corridors, lobbies, lift wells.</div>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-[#E2E8F0] shadow-xs space-y-3">
          <div className="flex items-center gap-2 text-indigo-700 font-bold text-sm">
            <Layers className="w-5 h-5 text-indigo-600" />
            <span>How Loading Affects Your Price</span>
          </div>
          <h3 className="font-black text-lg text-[#0F172A]">
            Why does Super Built-up Area matter?
          </h3>
          <p className="text-xs text-[#475569] leading-relaxed">
            Builders often quote a lower per-sq-ft price on the <strong>Super Built-up Area</strong> (which inflates the area by 25% to 35% with common lobby, clubhouse, and staircases). By auditing your true carpet area, you uncover the <em>real effective price</em> you pay for usable living space.
          </p>
          <div className="p-3 bg-[#F8FAFC] rounded-xl border border-[#E2E8F0] text-xs text-[#475569] space-y-1">
            <div>• <strong>Built-up Area:</strong> Usable Carpet Area + Internal Wall Area (~10-15%).</div>
            <div>• <strong>Super Built-up Area:</strong> Built-up Area + Common Loading Area (~25-35%).</div>
          </div>
        </div>
      </div>

      {/* PDF Modal */}
      <PdfViewerModal
        isOpen={selectedAuditForPdf !== null}
        audit={selectedAuditForPdf}
        displayUnit={displayUnit}
        onClose={() => setSelectedAuditForPdf(null)}
      />
    </div>
  );
};
