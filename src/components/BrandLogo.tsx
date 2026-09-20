import React from 'react';

interface BrandLogoProps {
  className?: string;
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export const BrandLogo: React.FC<BrandLogoProps> = ({
  className = '',
  size = 'md',
  showText = true,
}) => {
  const iconSize = size === 'sm' ? 28 : size === 'lg' ? 44 : 36;

  return (
    <div className={`flex items-center gap-2.5 ${className}`}>
      {/* Original App Logo matching favicon.svg */}
      <div
        className="relative flex items-center justify-center shrink-0 drop-shadow-sm transition-transform group-hover:scale-105"
        style={{ width: iconSize, height: iconSize }}
      >
        <svg
          viewBox="0 0 64 64"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-full h-full"
        >
          <rect width="64" height="64" rx="16" fill="#1D4ED8" />
          <path
            d="M16 44V20L32 12L48 20V44L32 52L16 44Z"
            stroke="white"
            strokeWidth="3.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M32 12V52"
            stroke="white"
            strokeWidth="2.5"
            strokeDasharray="3 3"
          />
          <path
            d="M16 28L48 28"
            stroke="white"
            strokeWidth="2.5"
            strokeDasharray="3 3"
          />
          <circle cx="32" cy="32" r="4.5" fill="#60A5FA" />
        </svg>
      </div>

      {showText && (
        <div className="flex flex-col leading-none">
          <span className="font-black text-[18px] tracking-tight text-[#0F172A]">
            Flatverify<span className="text-[#2563EB]">.ai</span>
          </span>
          <span className="text-[11px] font-semibold text-[#64748B] tracking-tight mt-0.5">
            Understand your property
          </span>
        </div>
      )}
    </div>
  );
};

