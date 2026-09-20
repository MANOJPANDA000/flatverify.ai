import React, { useState } from 'react';
import {
  User,
  ShieldCheck,
  Sliders,
  Database,
  Trash2,
  LogOut,
  LogIn,
  Check,
  Sparkles,
  Info,
  Building,
  Ruler,
} from 'lucide-react';
import { useSession } from '../context/SessionContext';
import { AreaUnitControl } from '../components/AreaUnitControl';

export const AccountView: React.FC = () => {
  const {
    user,
    login,
    logout,
    displayUnit,
    setDisplayUnit,
    defaultInternalWallPercent,
    setDefaultInternalWallPercent,
    defaultExternalWallPercent,
    setDefaultExternalWallPercent,
    defaultLoadingPercent,
    setDefaultLoadingPercent,
    clearAllData,
    audits,
  } = useSession();

  const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
  const [emailInput, setEmailInput] = useState('');
  const [nameInput, setNameInput] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);

  const handleLoginSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!emailInput.trim()) return;
    login(emailInput.trim(), nameInput.trim() || undefined);
    setIsLoginModalOpen(false);
  };

  const handleClearData = () => {
    if (
      window.confirm(
        'Are you sure you want to delete all saved audits and floor plan records from local storage? This cannot be undone.'
      )
    ) {
      clearAllData();
      alert('All local audit records have been cleared.');
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8 pb-16">
      {/* Page Title */}
      <div>
        <h1 className="text-2xl font-black text-[#0F172A] tracking-tight">
          Settings & Account
        </h1>
        <p className="text-xs sm:text-sm text-[#64748B] mt-1">
          Configure default measurement units, audit calculation assumptions, and manage your account.
        </p>
      </div>

      {/* User Profile Card */}
      <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-700 text-white flex items-center justify-center font-black text-xl shadow-md shadow-blue-500/20">
            {user.isGuest ? 'G' : user.displayName.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base font-extrabold text-[#0F172A]">
                {user.isGuest ? 'Guest Session' : user.displayName}
              </h2>
              <span
                className={`text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full ${
                  user.isGuest
                    ? 'bg-amber-100 text-amber-800'
                    : 'bg-emerald-100 text-emerald-800'
                }`}
              >
                {user.isGuest ? 'Offline Guest' : 'Account Active'}
              </span>
            </div>
            <p className="text-xs text-[#64748B] mt-0.5">
              {user.isGuest
                ? 'Audits are stored locally on this device. Sign in to sync across devices.'
                : user.email}
            </p>
          </div>
        </div>

        <div>
          {user.isGuest ? (
            <button
              type="button"
              onClick={() => setIsLoginModalOpen(true)}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl shadow-xs flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <LogIn className="w-4 h-4" />
              <span>Sign In / Create Account</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={logout}
              className="px-4 py-2 bg-[#F1F5F9] hover:bg-red-50 text-[#64748B] hover:text-red-700 text-xs font-bold rounded-xl border border-[#E2E8F0] flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <LogOut className="w-4 h-4" />
              <span>Switch to Guest</span>
            </button>
          )}
        </div>
      </div>

      {/* Preferences & Defaults */}
      <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-xs space-y-6">
        <h2 className="text-base font-bold text-[#0F172A] pb-3 border-b border-[#F1F5F9] flex items-center gap-2">
          <Sliders className="w-4 h-4 text-blue-600" />
          <span>Audit & Calculation Preferences</span>
        </h2>

        {/* Default Unit Toggle */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <label className="block text-sm font-bold text-[#0F172A]">
              Default Display Unit
            </label>
            <p className="text-xs text-[#64748B]">
              Preferred unit for showing areas on screen and exported PDFs
            </p>
          </div>

          <AreaUnitControl
            value={displayUnit}
            onChanged={setDisplayUnit}
            size="md"
          />
        </div>

        <hr className="border-[#F1F5F9]" />

        {/* Default Internal Wall Assumption */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-xs font-bold text-[#0F172A]">
            <span>Default Internal Wall Thickness</span>
            <span className="text-blue-700 font-extrabold">{defaultInternalWallPercent}%</span>
          </div>
          <p className="text-xs text-[#64748B]">
            Applied automatically to convert usable room areas to Built-up Area.
          </p>
          <input
            type="range"
            min="5"
            max="20"
            step="0.5"
            value={defaultInternalWallPercent}
            onChange={e => setDefaultInternalWallPercent(parseFloat(e.target.value))}
            className="w-full accent-blue-600 cursor-pointer"
          />
          <div className="flex justify-between text-[10px] text-[#94A3B8]">
            <span>5%</span>
            <span>12% (Recommended)</span>
            <span>20%</span>
          </div>
        </div>

        <hr className="border-[#F1F5F9]" />

        {/* Default Loading Assumption */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-xs font-bold text-[#0F172A]">
            <span>Default Developer Common Loading Factor</span>
            <span className="text-blue-700 font-extrabold">{defaultLoadingPercent}%</span>
          </div>
          <p className="text-xs text-[#64748B]">
            Estimated share of common areas (corridors, lifts, lobbies) in Super Built-up area.
          </p>
          <input
            type="range"
            min="15"
            max="50"
            step="1"
            value={defaultLoadingPercent}
            onChange={e => setDefaultLoadingPercent(parseFloat(e.target.value))}
            className="w-full accent-blue-600 cursor-pointer"
          />
          <div className="flex justify-between text-[10px] text-[#94A3B8]">
            <span>15%</span>
            <span>30% (Standard Multi-Storey)</span>
            <span>50%</span>
          </div>
        </div>
      </div>

      {/* RERA Regulatory Compliance Reference Card */}
      <div className="bg-[#FFFDF7] rounded-3xl p-6 border border-[#FDE68A] shadow-xs space-y-3">
        <div className="flex items-center gap-2 text-amber-900 font-bold text-sm">
          <ShieldCheck className="w-5 h-5 text-amber-600" />
          <span>RERA Section 2(k) Carpet Area Norms</span>
        </div>
        <p className="text-xs text-[#78350F] leading-relaxed">
          The Real Estate (Regulation and Development) Act mandates that developers market and sell properties strictly on <strong>Carpet Area</strong>.
          Balconies, private terraces, external walls, and common areas must be billed transparently and cannot be surreptitiously blended into usable carpet area.
        </p>
        <div className="text-xs text-[#92400E] font-medium pt-1">
          Flatverify.ai calculations adhere to the legal RERA carpet area computation model.
        </div>
      </div>

      {/* Data Management Card */}
      <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-xs space-y-4">
        <h2 className="text-base font-bold text-[#0F172A] pb-3 border-b border-[#F1F5F9] flex items-center gap-2">
          <Database className="w-4 h-4 text-gray-500" />
          <span>Local Storage & Privacy</span>
        </h2>

        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-xs font-bold text-[#0F172A]">
              Saved Local Audits ({audits.length} Records)
            </h3>
            <p className="text-xs text-[#64748B]">
              All photos and blueprints are processed directly inside your browser. No images are transmitted to external ad trackers.
            </p>
          </div>

          <button
            type="button"
            onClick={handleClearData}
            className="px-4 py-2 bg-red-50 hover:bg-red-100 text-red-700 text-xs font-bold rounded-xl border border-red-200 flex items-center gap-1.5 transition-colors shrink-0 cursor-pointer"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Clear Local Storage</span>
          </button>
        </div>
      </div>

      {/* Sign In Modal */}
      {isLoginModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl border border-[#E2E8F0] overflow-hidden p-6 space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-2.5 pb-2 border-b border-[#F1F5F9]">
              <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center">
                <User className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-base text-[#0F172A]">Account Sign In</h3>
                <p className="text-xs text-[#64748B]">Access and preserve your property audits</p>
              </div>
            </div>

            <form onSubmit={handleLoginSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#475569] mb-1">
                  Full Name
                </label>
                <input
                  type="text"
                  value={nameInput}
                  onChange={e => setNameInput(e.target.value)}
                  placeholder="e.g. Rahul Sharma"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#475569] mb-1">
                  Email Address <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  required
                  value={emailInput}
                  onChange={e => setEmailInput(e.target.value)}
                  placeholder="rahul@example.com"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsLoginModalOpen(false)}
                  className="px-4 py-2 text-xs font-bold text-[#64748B] hover:text-[#0F172A] rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl shadow-xs"
                >
                  Continue
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
