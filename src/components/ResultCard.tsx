import React, { useState, useRef } from 'react';
import { HelpCircle, Info } from 'lucide-react';
import { AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

interface ResultCardProps {
  title: string;
  value: number | null;
  icon: React.ReactNode;
  subtitle: string;
  highlighted?: boolean;
  displayUnit?: AreaDisplayUnit;
  badge?: string;
  tooltipText?: string;
  onInfoClick?: () => void;
  infoButtonTitle?: string;
}

export const ResultCard: React.FC<ResultCardProps> = ({
  title,
  value,
  icon,
  subtitle,
  highlighted = false,
  displayUnit = 'imperial',
  badge,
  tooltipText,
  onInfoClick,
  infoButtonTitle = 'View RERA definition',
}) => {
  const [showTooltip, setShowTooltip] = useState(false);
  const tooltipTimeoutRef = useRef<number | null>(null);

  const handleMouseEnter = () => {
    if (tooltipTimeoutRef.current) clearTimeout(tooltipTimeoutRef.current);
    setShowTooltip(true);
  };

  const handleMouseLeave = () => {
    tooltipTimeoutRef.current = window.setTimeout(() => {
      setShowTooltip(false);
    }, 150);
  };

  return (
    <div
      className={`relative p-4 rounded-2xl border transition-all duration-200 ${
        highlighted
          ? 'bg-[#EEF3FF] border-[#BFD0FF] shadow-xs ring-1 ring-[#BFD0FF]/40'
          : 'bg-white border-[#E2E8F0] hover:border-[#CBD5E1]'
      }`}
    >
      <div className="flex items-start gap-3.5">
        <div
          className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${
            highlighted ? 'bg-white text-[#2563EB] shadow-xs' : 'bg-[#F8FAFC] text-[#64748B]'
          }`}
        >
          {icon}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5 flex-wrap">
            <h4 className="font-bold text-[14px] text-[#0F172A] tracking-tight">
              {title}
            </h4>

            {(tooltipText || onInfoClick) && (
              <div
                className="relative inline-flex items-center"
                onMouseEnter={handleMouseEnter}
                onMouseLeave={handleMouseLeave}
              >
                <button
                  type="button"
                  onClick={e => {
                    e.stopPropagation();
                    if (onInfoClick) onInfoClick();
                  }}
                  className="p-1 rounded-full text-blue-600 hover:text-blue-800 hover:bg-blue-100/60 transition-colors focus:outline-hidden focus:ring-1 focus:ring-blue-400 cursor-pointer"
                  title={infoButtonTitle}
                  aria-label={infoButtonTitle}
                >
                  <HelpCircle className="w-3.5 h-3.5" />
                </button>

                {/* Floating Tooltip */}
                {showTooltip && tooltipText && (
                  <div
                    role="tooltip"
                    className="absolute left-1/2 -translate-x-1/2 bottom-full mb-2 z-40 w-64 p-2.5 bg-slate-900 text-white text-[11px] leading-snug rounded-xl shadow-xl border border-slate-700 pointer-events-auto animate-in fade-in zoom-in-95 duration-150"
                  >
                    <p className="font-medium">{tooltipText}</p>
                    {onInfoClick && (
                      <button
                        type="button"
                        onClick={e => {
                          e.stopPropagation();
                          setShowTooltip(false);
                          onInfoClick();
                        }}
                        className="mt-1.5 pt-1.5 border-t border-slate-700 w-full text-left font-bold text-blue-300 hover:text-blue-200 flex items-center justify-between cursor-pointer"
                      >
                        <span>Click for RERA definitions guide</span>
                        <span>→</span>
                      </button>
                    )}
                    {/* Tooltip caret */}
                    <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-slate-900" />
                  </div>
                )}
              </div>
            )}

            {badge && (
              <span className="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-blue-100 text-blue-700">
                {badge}
              </span>
            )}
          </div>
          <p className="text-[12px] text-[#64748B] mt-0.5 leading-snug">
            {subtitle}
          </p>
        </div>

        {value !== null && !isNaN(value) && (
          <div className="text-right shrink-0">
            <div
              className={`font-black text-[17px] tracking-tight leading-none ${
                highlighted ? 'text-[#1D4ED8]' : 'text-[#0F172A]'
              }`}
            >
              {DimensionParser.formatArea(value, displayUnit)}
            </div>
            {displayUnit !== 'hybrid' && (
              <div className="text-[11px] text-[#94A3B8] font-medium mt-1">
                {displayUnit === 'imperial'
                  ? `${DimensionParser.format(DimensionParser.squareFeetToSquareMeters(value), 1)} sq m`
                  : `${DimensionParser.format(value, 0)} sq ft`}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

