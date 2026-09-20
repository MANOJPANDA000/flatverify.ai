import React, { useState } from 'react';
import {
  ArrowLeftRight,
  Calculator,
  Copy,
  Check,
  Scale,
  Sparkles,
  Info,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import { AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

export interface QuickUnitConverterProps {
  displayUnit: AreaDisplayUnit;
  onUnitChange: (unit: AreaDisplayUnit) => void;
  carpetAreaSqFt: number;
  builtUpAreaSqFt?: number;
  superBuiltUpAreaSqFt?: number;
  className?: string;
}

export const QuickUnitConverter: React.FC<QuickUnitConverterProps> = ({
  displayUnit,
  onUnitChange,
  carpetAreaSqFt,
  builtUpAreaSqFt = 0,
  superBuiltUpAreaSqFt = 0,
  className = '',
}) => {
  // Scratchpad converter state
  const [scratchValue, setScratchValue] = useState<string>('1000');
  const [scratchDirection, setScratchDirection] = useState<'sqft_to_sqm' | 'sqm_to_sqft'>('sqft_to_sqm');
  const [copied, setCopied] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);

  const numVal = parseFloat(scratchValue) || 0;
  const convertedValue =
    scratchDirection === 'sqft_to_sqm'
      ? DimensionParser.squareFeetToSquareMeters(numVal)
      : DimensionParser.squareMetersToSquareFeet(numVal);

  const handleCopy = () => {
    const textToCopy =
      scratchDirection === 'sqft_to_sqm'
        ? `${scratchValue} sq ft = ${convertedValue.toFixed(2)} sq m`
        : `${scratchValue} sq m = ${convertedValue.toFixed(2)} sq ft`;
    navigator.clipboard.writeText(textToCopy);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const carpetSqM = DimensionParser.squareFeetToSquareMeters(carpetAreaSqFt);
  const builtUpSqM = DimensionParser.squareFeetToSquareMeters(builtUpAreaSqFt);
  const superSqM = DimensionParser.squareFeetToSquareMeters(superBuiltUpAreaSqFt);

  return (
    <div
      id="quick-unit-converter"
      className={`bg-white rounded-2xl border border-[#E2E8F0] shadow-xs overflow-hidden ${className}`}
    >
      {/* Header bar with primary Quick-Toggle */}
      <div className="p-4 bg-gradient-to-r from-[#F8FAFC] to-[#F1F5F9] border-b border-[#E2E8F0] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-blue-600/10 border border-blue-600/20 flex items-center justify-center text-blue-700 shrink-0">
            <ArrowLeftRight className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h4 className="text-xs font-black text-[#0F172A] tracking-tight uppercase">
                Quick Unit Converter
              </h4>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                Active: {displayUnit === 'imperial' ? 'Sq. Ft.' : displayUnit === 'metric' ? 'Sq. Meters' : 'Dual (Both)'}
              </span>
            </div>
            <p className="text-[11px] text-[#64748B]">
              Switch formats or convert values instantly
            </p>
          </div>
        </div>

        {/* Quick Format Selector Pills */}
        <div
          className="inline-flex items-center bg-white p-1 rounded-xl border border-[#CBD5E1] shadow-2xs"
          role="group"
          aria-label="Toggle Unit Display"
        >
          <button
            type="button"
            onClick={() => onUnitChange('imperial')}
            title="Square Feet (Brochures & standard listings)"
            className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
              displayUnit === 'imperial'
                ? 'bg-blue-600 text-white shadow-xs font-extrabold'
                : 'text-[#64748B] hover:text-[#0F172A] hover:bg-slate-50'
            }`}
          >
            Sq. Ft.
          </button>
          <button
            type="button"
            onClick={() => onUnitChange('metric')}
            title="Square Meters (Statutory RERA & municipal drawings)"
            className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
              displayUnit === 'metric'
                ? 'bg-blue-600 text-white shadow-xs font-extrabold'
                : 'text-[#64748B] hover:text-[#0F172A] hover:bg-slate-50'
            }`}
          >
            Sq. Meters
          </button>
          <button
            type="button"
            onClick={() => onUnitChange('hybrid')}
            title="Dual Format (Shows both Sq. Ft. and Sq. Meters simultaneously)"
            className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-all cursor-pointer ${
              displayUnit === 'hybrid'
                ? 'bg-blue-600 text-white shadow-xs font-extrabold'
                : 'text-[#64748B] hover:text-[#0F172A] hover:bg-slate-50'
            }`}
          >
            Both (Dual)
          </button>
        </div>
      </div>

      {/* Live Calculated Area Conversion Matrix */}
      <div className="p-4 space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
          {/* Carpet Area */}
          <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0] flex flex-col justify-between">
            <div className="text-[11px] font-bold text-[#64748B] flex items-center justify-between">
              <span>Carpet Area</span>
              <span className="text-[10px] text-blue-600 font-extrabold">RERA</span>
            </div>
            <div className="mt-1">
              <div className="font-extrabold text-[#0F172A] text-sm">
                {DimensionParser.format(carpetAreaSqFt, 1)}{' '}
                <span className="text-xs font-semibold text-[#64748B]">sq ft</span>
              </div>
              <div className="text-[11px] font-bold text-blue-700 mt-0.5">
                = {DimensionParser.format(carpetSqM, 2)}{' '}
                <span className="text-[10px] font-normal text-[#64748B]">sq m</span>
              </div>
            </div>
          </div>

          {/* Built-up Area */}
          <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0] flex flex-col justify-between">
            <div className="text-[11px] font-bold text-[#64748B]">
              <span>Built-up Area</span>
            </div>
            <div className="mt-1">
              <div className="font-extrabold text-[#0F172A] text-sm">
                {DimensionParser.format(builtUpAreaSqFt, 1)}{' '}
                <span className="text-xs font-semibold text-[#64748B]">sq ft</span>
              </div>
              <div className="text-[11px] font-bold text-blue-700 mt-0.5">
                = {DimensionParser.format(builtUpSqM, 2)}{' '}
                <span className="text-[10px] font-normal text-[#64748B]">sq m</span>
              </div>
            </div>
          </div>

          {/* Super Built-up Area */}
          <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0] flex flex-col justify-between">
            <div className="text-[11px] font-bold text-[#64748B] flex items-center justify-between">
              <span>Super Built-up</span>
              <span className="text-[10px] text-amber-600 font-bold">Quoted</span>
            </div>
            <div className="mt-1">
              <div className="font-extrabold text-[#0F172A] text-sm">
                {DimensionParser.format(superBuiltUpAreaSqFt, 1)}{' '}
                <span className="text-xs font-semibold text-[#64748B]">sq ft</span>
              </div>
              <div className="text-[11px] font-bold text-blue-700 mt-0.5">
                = {DimensionParser.format(superSqM, 2)}{' '}
                <span className="text-[10px] font-normal text-[#64748B]">sq m</span>
              </div>
            </div>
          </div>
        </div>

        {/* Toggleable Scratchpad / On-the-Fly Area Converter */}
        <div className="border border-[#E2E8F0] rounded-xl overflow-hidden">
          <button
            type="button"
            onClick={() => setIsExpanded(!isExpanded)}
            className="w-full px-3 py-2 bg-[#FAFCFF] hover:bg-blue-50/50 flex items-center justify-between text-left text-xs font-bold text-[#334155] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2">
              <Calculator className="w-3.5 h-3.5 text-blue-600" />
              <span>Instant Custom Area Converter & Formula</span>
            </div>
            {isExpanded ? (
              <ChevronUp className="w-3.5 h-3.5 text-[#64748B]" />
            ) : (
              <ChevronDown className="w-3.5 h-3.5 text-[#64748B]" />
            )}
          </button>

          {isExpanded && (
            <div className="p-3 bg-white space-y-3 border-t border-[#E2E8F0]">
              <div className="flex flex-col sm:flex-row items-center gap-2">
                <div className="flex-1 w-full relative">
                  <input
                    type="number"
                    min="0"
                    step="any"
                    value={scratchValue}
                    onChange={e => setScratchValue(e.target.value)}
                    placeholder="Enter value..."
                    className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-xs font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-16"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[11px] font-bold text-[#64748B]">
                    {scratchDirection === 'sqft_to_sqm' ? 'Sq. Ft.' : 'Sq. Meters'}
                  </span>
                </div>

                <button
                  type="button"
                  onClick={() =>
                    setScratchDirection(
                      scratchDirection === 'sqft_to_sqm' ? 'sqm_to_sqft' : 'sqft_to_sqm'
                    )
                  }
                  className="p-2 bg-[#F1F5F9] hover:bg-[#E2E8F0] rounded-xl border border-[#CBD5E1] text-[#475569] transition-colors cursor-pointer shrink-0"
                  title="Reverse conversion direction"
                >
                  <ArrowLeftRight className="w-3.5 h-3.5" />
                </button>

                <div className="flex-1 w-full bg-[#EFF6FF] border border-blue-200 rounded-xl px-3 py-2 flex items-center justify-between text-xs">
                  <div className="truncate">
                    <span className="text-[11px] text-blue-700 block font-medium">Converted:</span>
                    <strong className="text-sm font-black text-blue-950">
                      {DimensionParser.format(convertedValue, 2)}{' '}
                      <span className="text-xs font-semibold">
                        {scratchDirection === 'sqft_to_sqm' ? 'sq m' : 'sq ft'}
                      </span>
                    </strong>
                  </div>

                  <button
                    type="button"
                    onClick={handleCopy}
                    className="p-1.5 bg-white hover:bg-blue-100 text-blue-700 rounded-lg transition-colors cursor-pointer shrink-0 border border-blue-200"
                    title="Copy conversion"
                  >
                    {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>

              {/* Standard Conversion Formula Note */}
              <div className="p-2.5 bg-[#F8FAFC] rounded-lg border border-[#E2E8F0] text-[11px] text-[#64748B] flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5">
                  <Scale className="w-3.5 h-3.5 text-blue-600 shrink-0" />
                  <span>
                    Standard Ratio: <strong>1 m² = 10.7639 ft²</strong> (1 ft² = 0.0929 m²)
                  </span>
                </div>
                <span className="text-[10px] font-bold text-slate-400 hidden sm:inline">
                  IS 962 / NBC Standard
                </span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
