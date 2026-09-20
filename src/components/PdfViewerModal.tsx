import React, { useEffect, useState } from 'react';
import { X, Download, Printer, Share2, Check, FileCheck } from 'lucide-react';
import { AreaDisplayUnit, PropertyAudit } from '../types';
import { PdfReportGenerator } from '../utils/pdfGenerator';

interface PdfViewerModalProps {
  isOpen: boolean;
  audit: PropertyAudit | null;
  displayUnit: AreaDisplayUnit;
  onClose: () => void;
}

export const PdfViewerModal: React.FC<PdfViewerModalProps> = ({
  isOpen,
  audit,
  displayUnit,
  onClose,
}) => {
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!isOpen || !audit) {
      if (pdfUrl) {
        URL.revokeObjectURL(pdfUrl);
        setPdfUrl(null);
      }
      return;
    }

    try {
      const doc = PdfReportGenerator.generateAuditPdf(audit, displayUnit);
      const blob = doc.output('blob');
      const url = URL.createObjectURL(blob);
      setPdfUrl(url);

      return () => {
        URL.revokeObjectURL(url);
      };
    } catch (err) {
      console.error('Failed to generate PDF preview:', err);
    }
  }, [isOpen, audit, displayUnit]);

  if (!isOpen || !audit) return null;

  const handleDownload = () => {
    try {
      const doc = PdfReportGenerator.generateAuditPdf(audit, displayUnit);
      const safeName = (audit.auditName || 'Property_Audit')
        .replace(/[^a-zA-Z0-9_-]/g, '_')
        .toLowerCase();
      doc.save(`${safeName}_flatverify_report.pdf`);
    } catch (err) {
      console.error('Failed to download PDF:', err);
    }
  };

  const handlePrint = () => {
    if (pdfUrl) {
      const printWindow = window.open(pdfUrl);
      if (printWindow) {
        printWindow.focus();
        printWindow.print();
      }
    }
  };

  const handleShare = async () => {
    if (navigator.share && pdfUrl) {
      try {
        const doc = PdfReportGenerator.generateAuditPdf(audit, displayUnit);
        const blob = doc.output('blob');
        const file = new File([blob], `${audit.auditName || 'report'}.pdf`, { type: 'application/pdf' });
        await navigator.share({
          title: audit.auditName || 'Flatverify Property Area Audit',
          text: `Area Audit for ${audit.project || audit.auditName}: Carpet Area ${audit.carpetArea} sq ft, Super Built-up Area ${audit.superBuiltUpArea} sq ft.`,
          files: [file],
        });
        return;
      } catch (_) {}
    }

    // Fallback: Copy link/summary to clipboard
    const text = `Flatverify.ai Audit: ${audit.auditName}
Carpet Area: ${audit.carpetArea.toFixed(1)} sq ft
Super Built-up Area: ${audit.superBuiltUpArea.toFixed(1)} sq ft
Internal Wall: ${audit.internalWallPercent}% | Loading: ${audit.loadingPercent}%`;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs">
      <div className="bg-white rounded-2xl w-full max-w-4xl h-[90vh] shadow-2xl border border-[#E2E8F0] overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F1F5F9] bg-[#F8FAFC]">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center">
              <FileCheck className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-base text-[#0F172A] truncate max-w-md">
                {audit.auditName || 'Property Audit PDF'}
              </h3>
              <p className="text-xs text-[#64748B]">Official Flatverify.ai Verification Document</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handleShare}
              className="px-3 py-1.5 text-xs font-bold text-[#475569] hover:text-[#0F172A] hover:bg-white border border-[#CBD5E1] rounded-lg flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Share2 className="w-3.5 h-3.5" />}
              {copied ? 'Summary Copied' : 'Share'}
            </button>

            <button
              type="button"
              onClick={handlePrint}
              className="px-3 py-1.5 text-xs font-bold text-[#475569] hover:text-[#0F172A] hover:bg-white border border-[#CBD5E1] rounded-lg flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
            >
              <Printer className="w-3.5 h-3.5" />
              Print
            </button>

            <button
              type="button"
              onClick={handleDownload}
              className="px-4 py-1.5 text-xs font-bold bg-[#1D4ED8] hover:bg-[#1E40AF] text-white rounded-lg flex items-center gap-1.5 shadow-xs shadow-blue-500/20 transition-colors cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              Download PDF
            </button>

            <button
              type="button"
              onClick={onClose}
              className="p-1.5 text-[#94A3B8] hover:text-[#0F172A] rounded-lg transition-colors ml-2"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* PDF Embedded Frame */}
        <div className="flex-1 bg-[#475569]/10 relative p-4 flex items-center justify-center">
          {pdfUrl ? (
            <iframe
              src={`${pdfUrl}#toolbar=0`}
              title="PDF Report Preview"
              className="w-full h-full rounded-xl border border-[#CBD5E1] bg-white shadow-md"
            />
          ) : (
            <div className="flex flex-col items-center justify-center text-[#64748B] gap-2">
              <div className="w-8 h-8 border-3 border-blue-600 border-t-transparent rounded-full animate-spin" />
              <span className="text-sm font-semibold">Generating Official Audit PDF...</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
