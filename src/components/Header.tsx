import React from 'react';
import {
  LayoutDashboard,
  Calculator,
  ScanLine,
  FolderKanban,
  UserCheck,
  User,
} from 'lucide-react';
import { BrandLogo } from './BrandLogo';
import { AreaUnitControl } from './AreaUnitControl';
import { useSession } from '../context/SessionContext';

export type NavTab = 'home' | 'calculator' | 'scanner' | 'audits' | 'account';

interface HeaderProps {
  activeTab: NavTab;
  onTabChange: (tab: NavTab) => void;
}

export const Header: React.FC<HeaderProps> = ({ activeTab, onTabChange }) => {
  const { displayUnit, setDisplayUnit, user, audits } = useSession();

  const navItems: Array<{ key: NavTab; label: string; icon: React.ReactNode; badge?: number }> = [
    { key: 'home', label: 'Dashboard', icon: <LayoutDashboard className="w-4 h-4" /> },
    { key: 'calculator', label: 'Calculator', icon: <Calculator className="w-4 h-4" /> },
    { key: 'scanner', label: 'Scan Blueprint', icon: <ScanLine className="w-4 h-4" /> },
    {
      key: 'audits',
      label: 'Saved Audits',
      icon: <FolderKanban className="w-4 h-4" />,
      badge: audits.length > 0 ? audits.length : undefined,
    },
    { key: 'account', label: 'Settings', icon: <User className="w-4 h-4" /> },
  ];

  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-[#E2E8F0] transition-shadow">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 gap-4">
          {/* Logo */}
          <div
            onClick={() => onTabChange('home')}
            className="cursor-pointer select-none shrink-0"
          >
            <BrandLogo size="md" />
          </div>

          {/* Center Navigation Links (Desktop) */}
          <nav className="hidden md:flex items-center gap-1 bg-[#F8FAFC] p-1 rounded-xl border border-[#E2E8F0]">
            {navItems.map(item => {
              const isActive = activeTab === item.key;
              return (
                <button
                  key={item.key}
                  type="button"
                  onClick={() => onTabChange(item.key)}
                  className={`relative flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all duration-150 cursor-pointer ${
                    isActive
                      ? 'bg-white text-[#1D4ED8] shadow-xs ring-1 ring-black/5 font-extrabold'
                      : 'text-[#64748B] hover:text-[#0F172A] hover:bg-white/60'
                  }`}
                >
                  {item.icon}
                  <span>{item.label}</span>
                  {item.badge !== undefined && (
                    <span
                      className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
                        isActive
                          ? 'bg-blue-100 text-blue-700'
                          : 'bg-gray-200 text-gray-700'
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>

          {/* Right Controls: Unit Toggle & User Status */}
          <div className="flex items-center gap-3">
            <AreaUnitControl
              value={displayUnit}
              onChanged={setDisplayUnit}
              size="sm"
              className="hidden sm:inline-flex"
            />

            <button
              type="button"
              onClick={() => onTabChange('account')}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-bold transition-colors cursor-pointer ${
                user.isGuest
                  ? 'bg-[#F8FAFC] border-[#E2E8F0] text-[#64748B] hover:border-gray-400'
                  : 'bg-blue-50 border-blue-200 text-blue-800'
              }`}
            >
              {user.isGuest ? (
                <User className="w-3.5 h-3.5 text-[#94A3B8]" />
              ) : (
                <UserCheck className="w-3.5 h-3.5 text-blue-600" />
              )}
              <span className="hidden sm:inline">
                {user.isGuest ? 'Guest Mode' : user.displayName}
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Navigation Bar (Bottom) */}
      <div className="md:hidden flex items-center justify-around border-t border-[#E2E8F0] bg-white px-2 py-1.5">
        {navItems.map(item => {
          const isActive = activeTab === item.key;
          return (
            <button
              key={item.key}
              type="button"
              onClick={() => onTabChange(item.key)}
              className={`flex flex-col items-center gap-1 py-1 px-2.5 rounded-lg text-[10px] font-bold transition-all ${
                isActive ? 'text-[#1D4ED8]' : 'text-[#64748B]'
              }`}
            >
              <div className="relative">
                {item.icon}
                {item.badge !== undefined && (
                  <span className="absolute -top-1.5 -right-2.5 px-1 rounded-full text-[9px] font-black bg-blue-600 text-white leading-none">
                    {item.badge}
                  </span>
                )}
              </div>
              <span>{item.label}</span>
            </button>
          );
        })}
      </div>
    </header>
  );
};
