import React, { useState } from 'react';
import { X, Check, Eye, Trash2, ArrowRight, Layers, Plus } from 'lucide-react';
import { DimensionParser } from '../utils/dimensionParser';
import { ROOM_CATEGORIES } from '../data/roomCategories';

export interface PendingRoomPair {
  id: string;
  name: string;
  lengthStr: string;
  widthStr: string;
  isExcluded: boolean;
}

interface OcrDimensionReviewModalProps {
  isOpen: boolean;
  rawText: string;
  initialPairs: PendingRoomPair[];
  onClose: () => void;
  onApply: (confirmedPairs: PendingRoomPair[]) => void;
}

export const OcrDimensionReviewModal: React.FC<OcrDimensionReviewModalProps> = ({
  isOpen,
  rawText,
  initialPairs,
  onClose,
  onApply,
}) => {
  const [pairs, setPairs] = useState<PendingRoomPair[]>(initialPairs);
  const [showRawOcr, setShowRawOcr] = useState(false);

  if (!isOpen) return null;

  const updatePair = (id: string, updates: Partial<PendingRoomPair>) => {
    setPairs(prev =>
      prev.map(p => (p.id === id ? { ...p, ...updates } : p))
    );
  };

  const removePair = (id: string) => {
    setPairs(prev => prev.filter(p => p.id !== id));
  };

  const addNewPair = () => {
    const newId = `custom_pair_${Date.now()}`;
    setPairs(prev => [
      ...prev,
      {
        id: newId,
        name: `Room ${prev.length + 1}`,
        lengthStr: "12' 0\"",
        widthStr: "10' 0\"",
        isExcluded: false,
      },
    ]);
  };

  const handleConfirm = () => {
    const validPairs = pairs.filter(p => !p.isExcluded && p.lengthStr && p.widthStr);
    onApply(validPairs);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
      <div className="bg-white rounded-2xl w-full max-w-2xl shadow-2xl border border-[#E2E8F0] overflow-hidden flex flex-col max-h-[88vh] animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F1F5F9] bg-[#F8FAFC]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center">
              <Layers className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-base text-[#0F172A]">Review Extracted Blueprint Dimensions</h3>
              <p className="text-xs text-[#64748B]">Verify room labels & detected dimension pairs</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-[#94A3B8] hover:text-[#0F172A] rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Area */}
        <div className="p-6 overflow-y-auto space-y-4 flex-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#475569] uppercase tracking-wider">
              {pairs.filter(p => !p.isExcluded).length} Rooms Identified
            </span>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setShowRawOcr(!showRawOcr)}
                className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1 cursor-pointer"
              >
                <Eye className="w-3.5 h-3.5" />
                {showRawOcr ? 'Hide Raw OCR Text' : 'View Raw OCR Text'}
              </button>
              <button
                type="button"
                onClick={addNewPair}
                className="text-xs font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 px-2.5 py-1 rounded-lg flex items-center gap-1 border border-emerald-200 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                Add Dimension
              </button>
            </div>
          </div>

          {showRawOcr && (
            <div className="bg-[#1E293B] text-[#E2E8F0] p-3.5 rounded-xl text-xs font-mono max-h-40 overflow-y-auto border border-[#334155] whitespace-pre-wrap">
              {rawText || 'No OCR text extracted'}
            </div>
          )}

          {/* List of Detected Pairs */}
          <div className="space-y-3">
            {pairs.map((pair, idx) => {
              const lenM = DimensionParser.parseDimensionToMeters(pair.lengthStr);
              const widM = DimensionParser.parseDimensionToMeters(pair.widthStr);
              const sqFt = DimensionParser.squareMetersToSquareFeet(lenM * widM);

              return (
                <div
                  key={pair.id}
                  className={`p-3.5 rounded-xl border transition-all ${
                    pair.isExcluded
                      ? 'bg-[#F8FAFC] border-[#E2E8F0] opacity-50'
                      : 'bg-white border-[#CBD5E1] shadow-2xs hover:border-blue-400'
                  }`}
                >
                  <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 items-center">
                    {/* Room Name */}
                    <div className="sm:col-span-5">
                      <label className="block text-[11px] font-bold text-[#64748B] mb-1">
                        Room {idx + 1} Name
                      </label>
                      <input
                        type="text"
                        value={pair.name}
                        disabled={pair.isExcluded}
                        onChange={e => updatePair(pair.id, { name: e.target.value })}
                        className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-xs font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                      />
                    </div>

                    {/* Length */}
                    <div className="sm:col-span-3">
                      <label className="block text-[11px] font-bold text-[#64748B] mb-1">
                        Length
                      </label>
                      <input
                        type="text"
                        value={pair.lengthStr}
                        disabled={pair.isExcluded}
                        onChange={e => updatePair(pair.id, { lengthStr: e.target.value })}
                        placeholder={'e.g. 12\' 6"'}
                        className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-xs font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                      />
                    </div>

                    {/* Width */}
                    <div className="sm:col-span-3">
                      <label className="block text-[11px] font-bold text-[#64748B] mb-1">
                        Width
                      </label>
                      <input
                        type="text"
                        value={pair.widthStr}
                        disabled={pair.isExcluded}
                        onChange={e => updatePair(pair.id, { widthStr: e.target.value })}
                        placeholder={'e.g. 10\' 0"'}
                        className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-xs font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                      />
                    </div>

                    {/* Actions */}
                    <div className="sm:col-span-1 flex items-center justify-end gap-1">
                      <button
                        type="button"
                        onClick={() => removePair(pair.id)}
                        className="p-1 text-[#94A3B8] hover:text-red-600 rounded-md"
                        title="Delete dimension"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  {!pair.isExcluded && sqFt > 0 && (
                    <div className="flex items-center justify-between text-[11px] text-[#64748B] mt-2 pt-2 border-t border-[#F1F5F9]">
                      <span>
                        Parsed: {DimensionParser.formatFeetInches(lenM)} × {DimensionParser.formatFeetInches(widM)}
                      </span>
                      <span className="font-bold text-blue-700">
                        {DimensionParser.formatArea(sqFt, 'imperial')}
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-[#F1F5F9] bg-[#F8FAFC]">
          <span className="text-xs text-[#64748B]">
            Dimensions will be transferred to your live verification checklist.
          </span>
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-bold text-[#64748B] hover:text-[#0F172A] rounded-xl"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleConfirm}
              className="px-5 py-2.5 bg-[#1D4ED8] hover:bg-[#1E40AF] text-white font-bold text-xs rounded-xl shadow-xs shadow-blue-500/20 flex items-center gap-2 cursor-pointer"
            >
              <Check className="w-4 h-4" />
              Confirm & Apply Rooms
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
