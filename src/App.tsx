import React, { useState } from 'react';
import { SessionProvider } from './context/SessionContext';
import { Header, NavTab } from './components/Header';
import { HomeView } from './views/HomeView';
import { CalculatorView } from './views/CalculatorView';
import { ScannerView } from './views/ScannerView';
import { AuditsView } from './views/AuditsView';
import { AccountView } from './views/AccountView';
import { ShieldCheck, Ruler, FileText } from 'lucide-react';

export const AppContent: React.FC = () => {
  const [activeTab, setActiveTab] = useState<NavTab>('home');

  return (
    <div className="min-h-screen flex flex-col bg-[#F8F9FD] text-[#0F172A]">
      {/* Navigation Header */}
      <Header activeTab={activeTab} onTabChange={setActiveTab} />

      {/* Main View Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        {activeTab === 'home' && <HomeView onNavigate={setActiveTab} />}
        {activeTab === 'calculator' && <CalculatorView />}
        {activeTab === 'scanner' && <ScannerView />}
        {activeTab === 'audits' && <AuditsView onNavigate={setActiveTab} />}
        {activeTab === 'account' && <AccountView />}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-[#E2E8F0] py-8 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#64748B]">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-[#0F172A]">Flatverify.ai</span>
            <span>•</span>
            <span className="font-semibold text-blue-700">Understand your property</span>
            <span className="hidden sm:inline">•</span>
            <span className="hidden sm:inline">RERA Property Carpet Area & Blueprint Verification</span>
          </div>

          <div className="flex items-center gap-6">
            <button
              onClick={() => setActiveTab('calculator')}
              className="hover:text-blue-600 transition-colors"
            >
              Calculator
            </button>
            <button
              onClick={() => setActiveTab('scanner')}
              className="hover:text-blue-600 transition-colors"
            >
              Blueprint Scanner
            </button>
            <button
              onClick={() => setActiveTab('audits')}
              className="hover:text-blue-600 transition-colors"
            >
              Saved Audits
            </button>
            <button
              onClick={() => setActiveTab('account')}
              className="hover:text-blue-600 transition-colors"
            >
              Settings
            </button>
          </div>

          <div>
            © {new Date().getFullYear()} Flatverify.ai. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  );
};

export default function App() {
  return (
    <SessionProvider>
      <AppContent />
    </SessionProvider>
  );
}
