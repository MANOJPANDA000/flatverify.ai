import React, { useState } from 'react';
import {
  Search,
  FolderKanban,
  FileCheck2,
  Trash2,
  Download,
  FileDown,
  Building,
  Calendar,
  Layers,
  Home,
  CheckCircle,
  ExternalLink,
  ChevronRight,
  Filter,
  Eye,
  Sliders,
  Scale,
  CheckSquare,
  Square,
  ArrowLeftRight,
} from 'lucide-react';
import { useSession } from '../context/SessionContext';
import { PropertyAudit, ReraPropertyType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { PdfReportGenerator } from '../utils/pdfGenerator';
import { PdfViewerModal } from '../components/PdfViewerModal';
import { AuditComparisonModal } from '../components/AuditComparisonModal';
import { ReraComplianceChecklist } from '../components/ReraComplianceChecklist';
import { NavTab } from '../components/Header';

interface AuditsViewProps {
  onNavigate: (tab: NavTab) => void;
}

export const AuditsView: React.FC<AuditsViewProps> = ({ onNavigate }) => {
  const { audits, deleteAudit, displayUnit, setDisplayUnit } = useSession();
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'scan' | 'calculator'>('all');
  const [selectedAudit, setSelectedAudit] = useState<PropertyAudit | null>(audits[0] || null);
  const [auditPropertyType, setAuditPropertyType] = useState<ReraPropertyType>('apartment');
  const [pdfAudit, setPdfAudit] = useState<PropertyAudit | null>(null);
  const [exportSuccessMessage, setExportSuccessMessage] = useState<string | null>(null);
  const [isExporting, setIsExporting] = useState(false);

  // Audit Comparison State
  const [isCompareOpen, setIsCompareOpen] = useState(false);
  const [compareIds, setCompareIds] = useState<string[]>([]);
  const [compareAId, setCompareAId] = useState<string | undefined>(undefined);
  const [compareBId, setCompareBId] = useState<string | undefined>(undefined);

  const filteredAudits = audits.filter(a => {
    const matchesType = filterType === 'all' || a.type === filterType;
    const q = searchQuery.toLowerCase();
    const matchesSearch =
      (a.auditName && a.auditName.toLowerCase().includes(q)) ||
      (a.builder && a.builder.toLowerCase().includes(q)) ||
      (a.project && a.project.toLowerCase().includes(q)) ||
      (a.configuration && a.configuration.toLowerCase().includes(q));
    return matchesType && matchesSearch;
  });

  const handleDelete = async (id: string, name: string) => {
    if (window.confirm(`Are you sure you want to delete audit "${name}"?`)) {
      await deleteAudit(id);
      setCompareIds(prev => prev.filter(item => item !== id));
      if (selectedAudit?.id === id) {
        setSelectedAudit(audits.find(a => a.id !== id) || null);
      }
    }
  };

  const handleExportPdf = (audit: PropertyAudit) => {
    try {
      setIsExporting(true);
      PdfReportGenerator.exportSummaryPdf(audit, displayUnit);
      setExportSuccessMessage(
        `Exported summary PDF for "${audit.auditName}" with calculated carpet area (${DimensionParser.formatArea(audit.carpetArea, displayUnit)}) and wall assumptions.`
      );
      setTimeout(() => setExportSuccessMessage(null), 5000);
    } catch (err) {
      console.error('Failed to export PDF summary:', err);
    } finally {
      setIsExporting(false);
    }
  };

  // Toggle selection for comparison (max 2)
  const handleToggleCompare = (id: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setCompareIds(prev => {
      if (prev.includes(id)) {
        return prev.filter(item => item !== id);
      }
      if (prev.length >= 2) {
        // Replace second item
        return [prev[0], id];
      }
      return [...prev, id];
    });
  };

  // Launch comparison directly
  const handleOpenComparison = (auditA?: string, auditB?: string) => {
    if (audits.length < 2) {
      alert('You need at least 2 saved audits to compare differences in calculated area and wall assumptions.');
      return;
    }

    const firstId = auditA || compareIds[0] || selectedAudit?.id || audits[0]?.id;
    const secondId =
      auditB ||
      compareIds[1] ||
      audits.find(a => a.id !== firstId)?.id ||
      audits[1]?.id;

    setCompareAId(firstId);
    setCompareBId(secondId);
    setIsCompareOpen(true);
  };

  return (
    <div className="space-y-6 pb-16">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-[#0F172A] tracking-tight">
            Saved Property Audits
          </h1>
          <p className="text-xs sm:text-sm text-[#64748B] mt-1">
            Browse, inspect, and generate official PDF reports for your verified floor plan audits.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            id="top-compare-audits-btn"
            type="button"
            onClick={() => handleOpenComparison()}
            disabled={audits.length < 2}
            className="px-3.5 py-2 text-xs font-bold bg-[#F8FAFC] hover:bg-purple-50 text-purple-800 border border-purple-200 rounded-xl shadow-xs flex items-center gap-1.5 transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
            title={audits.length < 2 ? 'Requires at least 2 saved audits' : 'Compare two audit reports side-by-side'}
          >
            <Scale className="w-3.5 h-3.5 text-purple-600" />
            <span>Compare Audits</span>
            {audits.length >= 2 && (
              <span className="w-5 h-5 rounded-full bg-purple-100 text-purple-800 text-[10px] flex items-center justify-center font-black">
                {compareIds.length > 0 ? `${compareIds.length}/2` : audits.length}
              </span>
            )}
          </button>

          {selectedAudit && (
            <button
              id="top-export-pdf-btn"
              type="button"
              onClick={() => handleExportPdf(selectedAudit)}
              disabled={isExporting}
              className="px-3.5 py-2 text-xs font-bold bg-[#1D4ED8] hover:bg-[#1E40AF] text-white rounded-xl shadow-xs shadow-blue-500/20 flex items-center gap-1.5 transition-colors cursor-pointer disabled:opacity-50"
            >
              <FileDown className="w-3.5 h-3.5" />
              <span>Export as PDF</span>
            </button>
          )}
          <button
            type="button"
            onClick={() => onNavigate('scanner')}
            className="px-3.5 py-2 text-xs font-bold bg-blue-600 hover:bg-blue-700 text-white rounded-xl shadow-xs transition-colors cursor-pointer"
          >
            + Scan New Blueprint
          </button>
        </div>
      </div>

      {/* Compare Selection Notification Banner */}
      {compareIds.length > 0 && (
        <div className="p-3.5 bg-gradient-to-r from-blue-50 via-indigo-50 to-purple-50 border border-purple-200 rounded-2xl flex flex-col sm:flex-row items-center justify-between gap-3 shadow-xs animate-in slide-in-from-top-2 duration-200">
          <div className="flex items-center gap-2.5 text-xs text-[#1E293B]">
            <div className="w-7 h-7 rounded-xl bg-purple-600 text-white flex items-center justify-center shrink-0 shadow-2xs">
              <Scale className="w-4 h-4" />
            </div>
            <div>
              <span className="font-black text-[#0F172A]">
                {compareIds.length === 1 ? '1 Audit selected for comparison' : '2 Audits selected for comparison'}
              </span>
              <span className="text-[#64748B] block sm:inline sm:ml-1.5">
                {compareIds.map(id => audits.find(a => a.id === id)?.auditName).join(' vs ')}
                {compareIds.length === 1 && ' — Select 1 more audit below or click Compare to auto-pair'}
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2 self-end sm:self-auto shrink-0">
            <button
              type="button"
              onClick={() => handleOpenComparison(compareIds[0], compareIds[1])}
              className="px-4 py-1.5 bg-purple-600 hover:bg-purple-700 text-white text-xs font-black rounded-xl shadow-xs transition-colors cursor-pointer flex items-center gap-1.5"
            >
              <ArrowLeftRight className="w-3.5 h-3.5" />
              <span>Compare Side-by-Side</span>
            </button>
            <button
              type="button"
              onClick={() => setCompareIds([])}
              className="px-3 py-1.5 bg-white hover:bg-gray-100 text-[#64748B] hover:text-[#0F172A] border border-[#CBD5E1] text-xs font-bold rounded-xl transition-colors cursor-pointer"
            >
              Clear
            </button>
          </div>
        </div>
      )}

      {/* Export Confirmation / Success Toast */}
      {exportSuccessMessage && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl text-xs font-medium text-emerald-900 flex items-center justify-between gap-3 shadow-xs animate-in fade-in duration-200">
          <div className="flex items-center gap-2">
            <CheckCircle className="w-4 h-4 text-emerald-600 shrink-0" />
            <span>{exportSuccessMessage}</span>
          </div>
          <div className="flex items-center gap-3 shrink-0">
            {selectedAudit && (
              <button
                type="button"
                onClick={() => setPdfAudit(selectedAudit)}
                className="text-emerald-700 hover:text-emerald-900 underline text-xs font-bold cursor-pointer"
              >
                Preview in Viewer
              </button>
            )}
            <button
              type="button"
              onClick={() => setExportSuccessMessage(null)}
              className="text-emerald-600 hover:text-emerald-800 font-bold p-1 cursor-pointer"
            >
              ✕
            </button>
          </div>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className="bg-white rounded-2xl p-4 border border-[#E2E8F0] shadow-xs flex flex-col sm:flex-row items-center justify-between gap-3">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-[#94A3B8] absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Search by project, builder, flat..."
            className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl pl-9 pr-3 py-2 text-xs font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
          />
        </div>

        <div className="flex items-center gap-1.5 self-start sm:self-auto bg-[#F1F5F9] p-1 rounded-xl">
          <button
            type="button"
            onClick={() => setFilterType('all')}
            className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
              filterType === 'all'
                ? 'bg-white text-blue-700 shadow-xs'
                : 'text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            All ({audits.length})
          </button>
          <button
            type="button"
            onClick={() => setFilterType('scan')}
            className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
              filterType === 'scan'
                ? 'bg-white text-blue-700 shadow-xs'
                : 'text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            Scans ({audits.filter(a => a.type === 'scan').length})
          </button>
          <button
            type="button"
            onClick={() => setFilterType('calculator')}
            className={`px-3 py-1 text-xs font-bold rounded-lg transition-all ${
              filterType === 'calculator'
                ? 'bg-white text-blue-700 shadow-xs'
                : 'text-[#64748B] hover:text-[#0F172A]'
            }`}
          >
            Manual ({audits.filter(a => a.type === 'calculator').length})
          </button>
        </div>
      </div>

      {/* Main Split: Left = Audits List, Right = Selected Audit Detail */}
      {filteredAudits.length === 0 ? (
        <div className="bg-white rounded-3xl p-12 text-center border border-[#E2E8F0] shadow-xs space-y-3">
          <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto">
            <FolderKanban className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-[#0F172A]">No Audits Found</h3>
          <p className="text-xs text-[#64748B] max-w-sm mx-auto">
            {searchQuery
              ? 'No property audits match your search query. Try clearing the filter.'
              : 'Start by scanning your first floor plan or creating a manual area calculation.'}
          </p>
          <button
            onClick={() => onNavigate('scanner')}
            className="mt-2 px-4 py-2 bg-blue-600 text-white rounded-xl text-xs font-bold shadow-xs hover:bg-blue-700"
          >
            Scan Blueprint
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Left: Audit List Cards */}
          <div className="lg:col-span-5 space-y-3">
            {filteredAudits.map(audit => {
              const isSelected = selectedAudit?.id === audit.id;

              return (
                <div
                  key={audit.id}
                  onClick={() => setSelectedAudit(audit)}
                  className={`p-4 rounded-2xl border transition-all cursor-pointer ${
                    isSelected
                      ? 'bg-blue-50/50 border-blue-500 shadow-xs ring-1 ring-blue-500/20'
                      : 'bg-white border-[#E2E8F0] hover:border-[#CBD5E1]'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="font-bold text-sm text-[#0F172A] truncate">
                          {audit.auditName}
                        </h3>
                        <span
                          className={`text-[9px] font-black uppercase px-1.5 py-0.5 rounded ${
                            audit.type === 'scan'
                              ? 'bg-blue-100 text-blue-800'
                              : 'bg-emerald-100 text-emerald-800'
                          }`}
                        >
                          {audit.type === 'scan' ? 'Scan' : 'Manual'}
                        </span>
                      </div>

                      <div className="text-xs text-[#64748B] mt-1 flex items-center gap-2">
                        <span>{audit.project || 'Independent Plan'}</span>
                        {audit.configuration && <span>• {audit.configuration}</span>}
                      </div>
                    </div>

                    <div className="text-right shrink-0">
                      <div className="font-black text-sm text-[#1D4ED8]">
                        {DimensionParser.formatArea(audit.carpetArea, displayUnit)}
                      </div>
                      <div className="text-[10px] text-[#94A3B8]">Carpet Area</div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between mt-3 pt-3 border-t border-[#F1F5F9] text-xs text-[#64748B]">
                    <div className="flex items-center gap-1 text-[11px]">
                      <Calendar className="w-3.5 h-3.5" />
                      <span>
                        {new Date(audit.timestamp).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </span>
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={e => handleToggleCompare(audit.id, e)}
                        className={`font-bold text-xs flex items-center gap-1 cursor-pointer transition-colors px-2 py-0.5 rounded-lg border ${
                          compareIds.includes(audit.id)
                            ? 'bg-purple-100 text-purple-800 border-purple-300'
                            : 'bg-white hover:bg-purple-50 text-gray-600 hover:text-purple-700 border-[#E2E8F0]'
                        }`}
                        title={compareIds.includes(audit.id) ? 'Remove from comparison' : 'Select for side-by-side comparison'}
                      >
                        {compareIds.includes(audit.id) ? (
                          <CheckSquare className="w-3 h-3 text-purple-700" />
                        ) : (
                          <Square className="w-3 h-3 text-gray-400" />
                        )}
                        <span>Compare</span>
                      </button>
                      <button
                        type="button"
                        onClick={e => {
                          e.stopPropagation();
                          handleExportPdf(audit);
                        }}
                        className="font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1 cursor-pointer"
                        title="Export as PDF"
                      >
                        <FileDown className="w-3 h-3" />
                        <span>Export PDF</span>
                      </button>
                      <button
                        type="button"
                        onClick={e => {
                          e.stopPropagation();
                          setPdfAudit(audit);
                        }}
                        className="font-bold text-gray-500 hover:text-gray-700 flex items-center gap-1 cursor-pointer"
                        title="Preview PDF"
                      >
                        <Eye className="w-3 h-3" />
                        <span>Preview</span>
                      </button>
                      <button
                        type="button"
                        onClick={e => {
                          e.stopPropagation();
                          handleDelete(audit.id, audit.auditName);
                        }}
                        className="text-gray-400 hover:text-red-600 p-1 cursor-pointer"
                        title="Delete audit"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Right: Detailed Inspection of Selected Audit */}
          {selectedAudit && (
            <div className="lg:col-span-7 bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-sm space-y-6">
              {/* Header Info */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-[#F1F5F9] gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-black text-[#0F172A]">
                      {selectedAudit.auditName}
                    </h2>
                    <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                      {selectedAudit.type === 'scan' ? 'Blueprint Scan' : 'Manual Audit'}
                    </span>
                  </div>
                  <p className="text-xs text-[#64748B] mt-0.5">
                    Logged on{' '}
                    {new Date(selectedAudit.timestamp).toLocaleDateString('en-US', {
                      month: 'long',
                      day: 'numeric',
                      year: 'numeric',
                    })}
                  </p>
                </div>

                <div className="flex flex-wrap items-center gap-2">
                  <button
                    id="detail-compare-btn"
                    type="button"
                    onClick={() => handleOpenComparison(selectedAudit.id)}
                    disabled={audits.length < 2}
                    className="px-3.5 py-2 bg-purple-50 hover:bg-purple-100 text-purple-700 border border-purple-200 text-xs font-bold rounded-xl flex items-center gap-1.5 transition-colors cursor-pointer disabled:opacity-40"
                    title="Compare this audit side-by-side with another saved report"
                  >
                    <Scale className="w-3.5 h-3.5 text-purple-600" />
                    <span>Compare with...</span>
                  </button>

                  <button
                    id="export-as-pdf-btn"
                    type="button"
                    onClick={() => handleExportPdf(selectedAudit)}
                    disabled={isExporting}
                    className="px-4 py-2 bg-[#1D4ED8] hover:bg-[#1E40AF] text-white text-xs font-bold rounded-xl shadow-xs shadow-blue-500/20 flex items-center gap-1.5 transition-colors cursor-pointer disabled:opacity-50"
                  >
                    <FileDown className="w-3.5 h-3.5" />
                    <span>Export as PDF</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPdfAudit(selectedAudit)}
                    className="px-3.5 py-2 bg-[#F8FAFC] hover:bg-[#F1F5F9] text-[#1D4ED8] border border-[#CBD5E1] text-xs font-bold rounded-xl flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <Eye className="w-3.5 h-3.5" />
                    <span>Preview</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => handleDelete(selectedAudit.id, selectedAudit.auditName)}
                    className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors cursor-pointer"
                    title="Delete audit"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Property Details Pill Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 p-4 bg-[#F8FAFC] rounded-2xl border border-[#E2E8F0] text-xs">
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Builder:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.builder || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Project:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.project || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Config:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.configuration || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Tower:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.tower || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Flat #:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.flat || 'N/A'}</span>
                </div>
                <div>
                  <span className="text-[#94A3B8] font-semibold block">Floor:</span>
                  <span className="font-bold text-[#0F172A]">{selectedAudit.floor || 'N/A'}</span>
                </div>
              </div>

              {/* Area Metrics Cards */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div className="p-3.5 rounded-2xl bg-blue-50 border border-blue-200">
                  <span className="text-[11px] font-bold text-blue-800 uppercase tracking-wide">
                    Carpet Area
                  </span>
                  <div className="text-base font-black text-blue-900 mt-1">
                    {DimensionParser.formatArea(selectedAudit.carpetArea, displayUnit)}
                  </div>
                  <span className="text-[10px] text-blue-700">Net usable floor</span>
                </div>

                <div className="p-3.5 rounded-2xl bg-gray-50 border border-gray-200">
                  <span className="text-[11px] font-bold text-gray-700 uppercase tracking-wide">
                    Built-up Area
                  </span>
                  <div className="text-base font-black text-gray-900 mt-1">
                    {DimensionParser.formatArea(selectedAudit.builtUpArea, displayUnit)}
                  </div>
                  <span className="text-[10px] text-gray-600">
                    +{selectedAudit.internalWallPercent}% internal walls
                  </span>
                </div>

                <div className="p-3.5 rounded-2xl bg-indigo-50 border border-indigo-200 col-span-2 sm:col-span-1">
                  <span className="text-[11px] font-bold text-indigo-800 uppercase tracking-wide">
                    Super Built-up
                  </span>
                  <div className="text-base font-black text-indigo-900 mt-1">
                    {DimensionParser.formatArea(selectedAudit.superBuiltUpArea, displayUnit)}
                  </div>
                  <span className="text-[10px] text-indigo-700">
                    +{selectedAudit.loadingPercent}% loading
                  </span>
                </div>
              </div>

              {/* Calculated Carpet Area & Wall Assumptions Summary Card */}
              <div className="p-4 bg-gradient-to-br from-[#F8FAFC] to-[#EFF6FF] rounded-2xl border border-blue-100 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Sliders className="w-4 h-4 text-blue-600" />
                    <h3 className="font-extrabold text-xs uppercase tracking-wider text-[#1E3A8A]">
                      Calculated Carpet Area & Wall Assumptions
                    </h3>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleExportPdf(selectedAudit)}
                    disabled={isExporting}
                    className="text-xs font-bold text-blue-700 hover:text-blue-900 flex items-center gap-1 cursor-pointer"
                  >
                    <FileDown className="w-3.5 h-3.5" />
                    <span>Export PDF</span>
                  </button>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 text-xs">
                  <div className="bg-white p-2.5 rounded-xl border border-[#E2E8F0] shadow-2xs">
                    <span className="text-[10px] font-bold text-[#64748B] block">Internal Walls</span>
                    <span className="font-extrabold text-[#0F172A] text-sm">
                      {selectedAudit.internalWallPercent.toFixed(1)}%
                    </span>
                    <span className="text-[10px] text-[#94A3B8] block mt-0.5">
                      {DimensionParser.formatArea(selectedAudit.internalWallArea, displayUnit)}
                    </span>
                  </div>

                  <div className="bg-white p-2.5 rounded-xl border border-[#E2E8F0] shadow-2xs">
                    <span className="text-[10px] font-bold text-[#64748B] block">External Walls</span>
                    <span className="font-extrabold text-[#0F172A] text-sm">
                      {selectedAudit.externalWallPercent.toFixed(1)}%
                    </span>
                    <span className="text-[10px] text-[#94A3B8] block mt-0.5">
                      {DimensionParser.formatArea(selectedAudit.externalWallArea, displayUnit)}
                    </span>
                  </div>

                  <div className="bg-white p-2.5 rounded-xl border border-[#E2E8F0] shadow-2xs">
                    <span className="text-[10px] font-bold text-[#64748B] block">Common Loading</span>
                    <span className="font-extrabold text-[#0F172A] text-sm">
                      {selectedAudit.loadingPercent.toFixed(1)}%
                    </span>
                    <span className="text-[10px] text-[#94A3B8] block mt-0.5">
                      {DimensionParser.formatArea(selectedAudit.loadingArea, displayUnit)}
                    </span>
                  </div>

                  <div className="bg-white p-2.5 rounded-xl border border-[#E2E8F0] shadow-2xs">
                    <span className="text-[10px] font-bold text-[#64748B] block">Usable Efficiency</span>
                    <span className="font-extrabold text-blue-700 text-sm">
                      {selectedAudit.superBuiltUpArea > 0
                        ? `${((selectedAudit.carpetArea / selectedAudit.superBuiltUpArea) * 100).toFixed(1)}%`
                        : 'N/A'}
                    </span>
                    <span className="text-[10px] text-[#94A3B8] block mt-0.5">
                      Carpet to Super Built-up
                    </span>
                  </div>
                </div>
              </div>

              {/* Room Breakdown Table */}
              <div className="space-y-2.5">
                <h3 className="font-bold text-xs uppercase tracking-wider text-[#475569]">
                  Verified Room Dimensions ({selectedAudit.rooms?.length || 0})
                </h3>

                <div className="border border-[#E2E8F0] rounded-2xl overflow-hidden shadow-2xs">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="bg-[#F8FAFC] border-b border-[#E2E8F0] text-[#475569] font-bold">
                        <th className="py-2.5 px-4">Room / Space</th>
                        <th className="py-2.5 px-3">Length</th>
                        <th className="py-2.5 px-3">Width</th>
                        <th className="py-2.5 px-4 text-right">Area</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#F1F5F9]">
                      {selectedAudit.rooms?.map((room, idx) => {
                        const sqM = room.lengthMeters * room.widthMeters;
                        const sqFt = DimensionParser.squareMetersToSquareFeet(sqM);

                        return (
                          <tr key={idx} className="hover:bg-[#F8FAFC]">
                            <td className="py-2.5 px-4 font-bold text-[#0F172A]">
                              <div className="flex items-center gap-1.5">
                                {room.name}
                                {room.isUserVerified && (
                                  <CheckCircle className="w-3 h-3 text-emerald-600 shrink-0" />
                                )}
                              </div>
                            </td>
                            <td className="py-2.5 px-3 text-[#64748B]">
                              {DimensionParser.formatLength(room.lengthMeters, displayUnit)}
                            </td>
                            <td className="py-2.5 px-3 text-[#64748B]">
                              {DimensionParser.formatLength(room.widthMeters, displayUnit)}
                            </td>
                            <td className="py-2.5 px-4 text-right font-extrabold text-[#0F172A]">
                              {DimensionParser.formatArea(sqFt, displayUnit)}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Notes */}
              {selectedAudit.notes && (
                <div className="p-4 bg-amber-50/70 border border-amber-200 rounded-2xl text-xs space-y-1">
                  <span className="font-bold text-amber-900 block">Audit Notes:</span>
                  <p className="text-amber-800 leading-relaxed">{selectedAudit.notes}</p>
                </div>
              )}

              {/* RERA Statutory Compliance Checklist */}
              <div className="pt-2">
                <ReraComplianceChecklist
                  propertyType={auditPropertyType || selectedAudit.propertyType || 'apartment'}
                  onPropertyTypeChange={setAuditPropertyType}
                  rooms={selectedAudit.rooms || []}
                  usableAreaSqFt={selectedAudit.usableArea || selectedAudit.carpetArea}
                  carpetAreaSqFt={selectedAudit.carpetArea}
                  internalWallPercent={selectedAudit.internalWallPercent}
                  internalWallAreaSqFt={selectedAudit.internalWallArea}
                  externalWallPercent={selectedAudit.externalWallPercent}
                  externalWallAreaSqFt={selectedAudit.externalWallArea}
                  loadingPercent={selectedAudit.loadingPercent}
                  loadingAreaSqFt={selectedAudit.loadingArea}
                  superBuiltUpAreaSqFt={selectedAudit.superBuiltUpArea}
                  displayUnit={displayUnit}
                  initialExpanded={true}
                />
              </div>
            </div>
          )}
        </div>
      )}

      {/* PDF Modal */}
      <PdfViewerModal
        isOpen={pdfAudit !== null}
        audit={pdfAudit}
        displayUnit={displayUnit}
        onClose={() => setPdfAudit(null)}
      />

      {/* Audit Comparison Modal */}
      <AuditComparisonModal
        isOpen={isCompareOpen}
        onClose={() => setIsCompareOpen(false)}
        audits={audits}
        initialAuditAId={compareAId}
        initialAuditBId={compareBId}
        displayUnit={displayUnit}
        onUnitChange={setDisplayUnit}
      />
    </div>
  );
};
