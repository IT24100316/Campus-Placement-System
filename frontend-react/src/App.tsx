import { useState } from 'react';
import { LandingPage } from './pages/LandingPage';
import { RegisterPage } from './pages/RegisterPage';
import { AdminDashboardPage } from './pages/AdminDashboardPage';
import { LoginPage } from './pages/LoginPage';
import { LoginModal } from './components/auth/LoginModal';
import { Sparkles, UserPlus, Home, LogIn } from 'lucide-react';
import type { RegistrationRecord } from './types/auth';

export type AppView = 'landing' | 'register' | 'login' | 'admin';

function App() {
  const [currentView, setCurrentView] = useState<AppView>('landing');
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [pendingRecordForView, setPendingRecordForView] = useState<RegistrationRecord | null>(null);

  return (
    <div className="relative min-h-screen">
      {/* Current View Renderer */}
      {currentView === 'landing' && (
        <LandingPage
          onNavigateRegister={() => {
            setPendingRecordForView(null);
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onOpenLogin={() => {
            setCurrentView('login');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {currentView === 'register' && (
        <RegisterPage
          key={pendingRecordForView ? pendingRecordForView.id : 'fresh-reg'}
          initialPendingRecord={pendingRecordForView}
          onBackToHome={() => {
            setPendingRecordForView(null);
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onOpenLogin={() => {
            setCurrentView('login');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {currentView === 'login' && (
        <LoginPage
          onBackHome={() => {
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onNavigateRegister={() => {
            setPendingRecordForView(null);
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onLoginSuccess={(role) => {
            if (role === 'Admin') {
              setCurrentView('admin');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            } else {
              // Return home or admin demo
              setCurrentView('landing');
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }
          }}
          onPendingFound={(record) => {
            setPendingRecordForView(record);
            setCurrentView('register');
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
            setPendingRecordForView(null);
            setCurrentView('register');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {/* Global Authentication Modal */}
      <LoginModal
        isOpen={isLoginOpen}
        onClose={() => setIsLoginOpen(false)}
        onLoginSuccess={(role) => {
          setIsLoginOpen(false);
          if (role === 'Admin') {
            setCurrentView('admin');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }
        }}
        onPendingFound={(record) => {
          setIsLoginOpen(false);
          setPendingRecordForView(record);
          setCurrentView('register');
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
        onNavigateRegister={() => {
          setIsLoginOpen(false);
          setPendingRecordForView(null);
          setCurrentView('register');
          window.scrollTo({ top: 0, behavior: 'smooth' });
        }}
      />

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
            setCurrentView('login');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
            currentView === 'login'
              ? 'bg-primary text-white font-semibold'
              : 'text-slate-300 hover:text-white hover:bg-slate-800'
          }`}
        >
          <LogIn className="w-3.5 h-3.5" />
          <span>Login</span>
        </button>
      </div>
    </div>
  );
}

export default App;
