import { useState } from 'react';
import { LandingPage } from './pages/LandingPage';
import { RegisterPage } from './pages/RegisterPage';
import { AdminDashboardPage } from './pages/AdminDashboardPage';
import { LoginPage } from './pages/LoginPage';
import { HrLandingPage } from './pages/HrLandingPage';
import { JobPostingForm } from './components/company/JobPostingForm';
import { LoginModal } from './components/auth/LoginModal';
import { Sparkles, UserPlus, Home, LogIn, ShieldCheck, LogOut, Building2, PlusCircle } from 'lucide-react';
import type { RegistrationRecord } from './types/auth';

export type AppView = 'landing' | 'register' | 'login' | 'admin' | 'hr' | 'hr-post-job';

function App() {
  const [currentView, setCurrentView] = useState<AppView>('landing');
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [pendingRecordForView, setPendingRecordForView] = useState<RegistrationRecord | null>(null);
  const [newlyCreatedJobId, setNewlyCreatedJobId] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<{ email: string; role: string; companyName?: string } | null>(() => {
    try {
      const saved = localStorage.getItem('campusai_auth_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const handleLogout = () => {
    setCurrentUser(null);
    localStorage.removeItem('campusai_auth_user');
    setCurrentView('landing');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleLoginSuccess = (role: string, userEmail?: string, companyName?: string) => {
    const normalizedRole = role.toLowerCase();
    const email = userEmail || (normalizedRole === 'admin' ? 'admin@campusai.edu' : 'virtusa@company.com');
    const user = { email, role, companyName };
    setCurrentUser(user);
    localStorage.setItem('campusai_auth_user', JSON.stringify(user));

    if (normalizedRole === 'admin') {
      setCurrentView('admin');
    } else if (
      normalizedRole === 'company hr' ||
      normalizedRole === 'companyhr' ||
      normalizedRole === 'company' ||
      normalizedRole === 'recruiter' ||
      normalizedRole === 'staff' ||
      normalizedRole === 'company staff'
    ) {
      // Outside company HR / Staff redirected directly to dedicated HR Landing Page
      setCurrentView('hr');
    } else {
      setCurrentView('landing');
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const isAdmin = currentUser?.role?.toLowerCase() === 'admin' || currentView === 'admin';
  const isHr = currentView === 'hr' || (currentUser?.role && currentUser.role.toLowerCase().includes('company'));

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
          onNavigateAdmin={() => {
            setCurrentView('admin');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          isAdmin={isAdmin}
          onLogout={handleLogout}
          userEmail={currentUser?.email || 'admin@campusai.edu'}
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
          isAdmin={isAdmin}
          onLogout={handleLogout}
          userEmail={currentUser?.email || 'admin@campusai.edu'}
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
          onLoginSuccess={handleLoginSuccess}
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
          onLogout={handleLogout}
          userEmail={currentUser?.email || 'admin@campusai.edu'}
        />
      )}

      {currentView === 'hr' && (
        <HrLandingPage
          userEmail={currentUser?.email}
          initialCompanyName={currentUser?.companyName}
          highlightedJobId={newlyCreatedJobId || undefined}
          onLogout={handleLogout}
          onNavigateHome={() => {
            setCurrentView('landing');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onNavigatePostJob={() => {
            setNewlyCreatedJobId(null);
            setCurrentView('hr-post-job');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {currentView === 'hr-post-job' && (
        <JobPostingForm
          userEmail={currentUser?.email}
          companyName={currentUser?.companyName || 'Virtusa Corporation'}
          onCancel={() => {
            setCurrentView('hr');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          onJobCreated={(createdJob) => {
            if (createdJob?.jobId) {
              setNewlyCreatedJobId(createdJob.jobId);
            }
            setCurrentView('hr');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />
      )}

      {/* Global Authentication Modal */}
      <LoginModal
        isOpen={isLoginOpen}
        onClose={() => setIsLoginOpen(false)}
        onLoginSuccess={(role, email, companyName) => {
          setIsLoginOpen(false);
          handleLoginSuccess(role, email, companyName);
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

        {isAdmin ? (
          <>
            <button
              type="button"
              onClick={() => {
                setCurrentView('admin');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                currentView === 'admin'
                  ? 'bg-indigo-600 text-white font-semibold'
                  : 'text-indigo-300 hover:text-white hover:bg-slate-800'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5 text-indigo-400" />
              <span>Admin Approvals</span>
            </button>
            <button
              type="button"
              onClick={handleLogout}
              className="flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer text-rose-300 hover:text-white hover:bg-rose-900/60"
              title="Sign out of Admin Session"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span>Logout</span>
            </button>
          </>
        ) : isHr ? (
          <>
            <button
              type="button"
              onClick={() => {
                setCurrentView('hr');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                currentView === 'hr'
                  ? 'bg-primary text-white font-semibold'
                  : 'text-blue-300 hover:text-white hover:bg-slate-800'
              }`}
            >
              <Building2 className="w-3.5 h-3.5 text-blue-400" />
              <span>Employer Portal</span>
            </button>
            <button
              type="button"
              onClick={() => {
                setCurrentView('hr-post-job');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                currentView === 'hr-post-job'
                  ? 'bg-primary text-white font-semibold'
                  : 'text-blue-300 hover:text-white hover:bg-slate-800'
              }`}
            >
              <PlusCircle className="w-3.5 h-3.5 text-blue-400" />
              <span>Post Job</span>
            </button>
            <button
              type="button"
              onClick={handleLogout}
              className="flex items-center gap-1 px-3 py-1.5 rounded-full transition-all cursor-pointer text-rose-300 hover:text-white hover:bg-rose-900/60"
              title="Sign out of Employer Session"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span>Logout</span>
            </button>
          </>
        ) : (
          <>
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
          </>
        )}
      </div>
    </div>
  );
}

export default App;
