import React from 'react';
import { AreaDisplayUnit } from '../types';

interface AreaUnitControlProps {
  value: AreaDisplayUnit;
  onChanged: (unit: AreaDisplayUnit) => void;
  className?: string;
  size?: 'sm' | 'md';
}

export const AreaUnitControl: React.FC<AreaUnitControlProps> = ({
  value,
  onChanged,
  className = '',
  size = 'md',
}) => {
  const options: Array<{ key: AreaDisplayUnit; label: string; title: string }> = [
    {
      key: 'imperial',
      label: 'Sq. Ft.',
      title: 'Square Feet (Imperial) - Standard in brochures & real estate listings',
    },
    {
      key: 'metric',
      label: 'Sq. Meters',
      title: 'Square Meters (Metric) - Official statutory RERA & municipal standard',
    },
    {
      key: 'hybrid',
      label: 'Both (Dual)',
      title: 'Dual Format - Displays both Sq. Ft. and Sq. Meters side-by-side',
    },
  ];

  return (
    <div
      className={`inline-flex items-center bg-[#F1F5F9] p-1 rounded-xl border border-[#E2E8F0] shadow-xs ${className}`}
      role="group"
      aria-label="Select Area Unit"
    >
      {options.map(opt => {
        const isSelected = value === opt.key;
        return (
          <button
            key={opt.key}
            type="button"
            onClick={() => onChanged(opt.key)}
            title={opt.title}
            className={`cursor-pointer transition-all duration-150 rounded-lg font-bold text-center select-none whitespace-nowrap ${
              size === 'sm' ? 'px-2.5 py-1 text-xs' : 'px-3 py-1.5 text-xs'
            } ${
              isSelected
                ? 'bg-white text-[#1D4ED8] shadow-xs ring-1 ring-black/5 font-extrabold'
                : 'text-[#64748B] hover:text-[#0F172A] hover:bg-white/50'
            }`}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
};
