import React from 'react';
import { Ruler, ArrowLeftRight, Check, Compass, Scale } from 'lucide-react';
import { AreaDisplayUnit } from '../types';

export interface CalculatorUnitToggleProps {
  displayUnit: AreaDisplayUnit;
  onUnitChange: (unit: AreaDisplayUnit) => void;
  roomCount?: number;
  className?: string;
  variant?: 'banner' | 'compact';
}

export const CalculatorUnitToggle: React.FC<CalculatorUnitToggleProps> = ({
  displayUnit,
  onUnitChange,
  roomCount,
  className = '',
  variant = 'banner',
}) => {
  const options: Array<{
    key: AreaDisplayUnit;
    label: string;
    sublabel: string;
    inputBadge: string;
    outputBadge: string;
    description: string;
  }> = [
    {
      key: 'imperial',
      label: 'Imperial',
      sublabel: 'Sq. Ft.',
      inputBadge: 'Feet & Inches (ft/in)',
      outputBadge: 'Square Feet (sq ft)',
      description: 'Standard in developer brochures, sale deeds, and buyer listings',
    },
    {
      key: 'metric',
      label: 'Metric',
      sublabel: 'Sq. Meters',
      inputBadge: 'Meters & Centimeters (m/cm)',
      outputBadge: 'Square Meters (m²)',
      description: 'Official statutory RERA Section 2(k) & municipal approval standard',
    },
    {
      key: 'hybrid',
      label: 'Dual Format',
      sublabel: 'Both Units',
      inputBadge: 'Dual Display',
      outputBadge: 'Sq. Ft. + m²',
      description: 'Side-by-side comparative inspection for cross-verifying floor plans',
    },
  ];

  if (variant === 'compact') {
    return (
      <div
        className={`inline-flex items-center bg-[#F1F5F9] p-1 rounded-xl border border-[#E2E8F0] shadow-2xs ${className}`}
        role="group"
        aria-label="Measurement Unit Switcher"
      >
        <span className="text-[11px] font-bold text-[#475569] pl-1.5 pr-1 flex items-center gap-1">
          <ArrowLeftRight className="w-3 h-3 text-blue-600" />
          <span className="hidden sm:inline">Unit:</span>
        </span>
        {options.map(opt => {
          const isSelected = displayUnit === opt.key;
          return (
            <button
              key={opt.key}
              type="button"
              onClick={() => onUnitChange(opt.key)}
              title={`${opt.label} (${opt.sublabel}) - ${opt.description}`}
              className={`cursor-pointer transition-all duration-150 rounded-lg font-bold text-center text-xs px-2.5 py-1 select-none whitespace-nowrap ${
                isSelected
                  ? 'bg-white text-blue-700 shadow-xs ring-1 ring-black/5 font-black'
                  : 'text-[#64748B] hover:text-[#0F172A] hover:bg-white/50'
              }`}
            >
              {opt.sublabel}
            </button>
          );
        })}
      </div>
    );
  }

  // Banner variant with full context, input/output indicators, and sync status
  return (
    <div
      id="calculator-unit-toggle-banner"
      className={`bg-white rounded-2xl border border-[#E2E8F0] p-4 shadow-xs ${className}`}
    >
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-3 border-b border-[#F1F5F9]">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-blue-50 border border-blue-200 text-blue-700 flex items-center justify-center shrink-0">
            <Compass className="w-4 h-4" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-xs font-black uppercase tracking-wider text-[#0F172A]">
                Measurement Unit System
              </h3>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1">
                <Check className="w-2.5 h-2.5" />
                <span>Session Synced</span>
              </span>
            </div>
            <p className="text-[11px] text-[#64748B]">
              Switches input dimension fields and statutory area outputs simultaneously
            </p>
          </div>
        </div>

        {/* Sync Status Feedback */}
        {roomCount !== undefined && roomCount > 0 && (
          <div className="text-[11px] text-[#64748B] self-start md:self-auto flex items-center gap-1">
            <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500" />
            <span>
              All <strong className="text-[#0F172A]">{roomCount}</strong> rooms live-synced in{' '}
              <strong className="text-blue-700">
                {displayUnit === 'metric'
                  ? 'Metric (m/cm & m²)'
                  : displayUnit === 'imperial'
                  ? 'Imperial (ft/in & sq ft)'
                  : 'Dual Format'}
              </strong>
            </span>
          </div>
        )}
      </div>

      {/* Segmented Option Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-3">
        {options.map(opt => {
          const isSelected = displayUnit === opt.key;
          return (
            <button
              key={opt.key}
              type="button"
              onClick={() => onUnitChange(opt.key)}
              className={`p-3 rounded-xl border text-left transition-all cursor-pointer flex flex-col justify-between relative group ${
                isSelected
                  ? 'bg-blue-50/70 border-blue-500 ring-2 ring-blue-500/20 shadow-xs'
                  : 'bg-[#F8FAFC] border-[#E2E8F0] hover:bg-white hover:border-[#CBD5E1]'
              }`}
            >
              <div className="flex items-center justify-between w-full mb-1.5">
                <div className="flex items-center gap-1.5">
                  <span
                    className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                      isSelected
                        ? 'border-blue-600 bg-blue-600 text-white'
                        : 'border-[#CBD5E1] bg-white group-hover:border-blue-400'
                    }`}
                  >
                    {isSelected && <Check className="w-2.5 h-2.5 stroke-[3]" />}
                  </span>
                  <span className="text-xs font-black text-[#0F172A]">{opt.label}</span>
                </div>
                <span
                  className={`text-[11px] font-black px-2 py-0.5 rounded-md ${
                    isSelected
                      ? 'bg-blue-600 text-white shadow-2xs'
                      : 'bg-white text-[#475569] border border-[#E2E8F0]'
                  }`}
                >
                  {opt.sublabel}
                </span>
              </div>

              <div className="space-y-1 mt-1 text-[10px]">
                <div className="flex items-center justify-between text-[#64748B]">
                  <span>Inputs:</span>
                  <strong className="text-[#334155]">{opt.inputBadge}</strong>
                </div>
                <div className="flex items-center justify-between text-[#64748B]">
                  <span>Outputs:</span>
                  <strong className="text-blue-700">{opt.outputBadge}</strong>
                </div>
              </div>

              <p className="text-[10px] text-[#64748B] mt-2 pt-2 border-t border-[#F1F5F9] leading-tight">
                {opt.description}
              </p>
            </button>
          );
        })}
      </div>
    </div>
  );
};
