import { useState } from 'react';
import { LandingPage } from './pages/LandingPage';
import { RegisterPage } from './pages/RegisterPage';
import { AdminDashboardPage } from './pages/AdminDashboardPage';
import { Sparkles, Shield, UserPlus, Home } from 'lucide-react';

export type AppView = 'landing' | 'register' | 'admin';

function App() {
  const [currentView, setCurrentView] = useState<AppView>('landing');

  return (
    <div className="relative min-h-screen">
      {/* Current View Renderer */}
      {currentView === 'landing' && (
        <LandingPage
          onNavigateRegister={() => {
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onNavigateAdmin={() => {
            setCurrentView('admin');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {currentView === 'register' && (
        <RegisterPage
          onBackToHome={() => {
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onGoToAdmin={() => {
            setCurrentView('admin');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {currentView === 'admin' && (
        <AdminDashboardPage
          onBackToHome={() => {
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onNavigateRegister={() => {
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {/* Floating Demo View Quick-Switcher */}
      <div className="fixed bottom-4 right-4 z-50 flex items-center gap-1.5 p-1.5 bg-slate-900/90 backdrop-blur-md rounded-full shadow-xl border border-slate-700/60 text-white text-xs">
        <span className="flex items-center gap-1 pl-2 pr-1 text-[11px] font-semibold text-slate-400">
          <Sparkles className="w-3.5 h-3.5 text-amber-400" />
          Navigate:
        </span>
        <button
          type="button"
          onClick={() => {
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
            currentView === 'landing'
              ? 'bg-primary text-white font-semibold'
              : 'text-slate-300 hover:text-white hover:bg-slate-800'
          }`}
        >
          <Home className="w-3.5 h-3.5" />
          <span>Home</span>
        </button>

        <button
          type="button"
          onClick={() => {
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
            currentView === 'register'
              ? 'bg-primary text-white font-semibold'
              : 'text-slate-300 hover:text-white hover:bg-slate-800'
          }`}
        >
          <UserPlus className="w-3.5 h-3.5" />
          <span>Register</span>
        </button>

        <button
          type="button"
          onClick={() => {
            setCurrentView('admin');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
            currentView === 'admin'
              ? 'bg-primary text-white font-semibold'
              : 'text-slate-300 hover:text-white hover:bg-slate-800'
          }`}
        >
          <Shield className="w-3.5 h-3.5" />
          <span>Admin</span>
        </button>
      </div>
    </div>
  );
}

export default App;
