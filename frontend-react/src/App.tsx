import { useEffect, useState } from 'react';
import { Sparkles, Home, ShieldCheck, LogOut, Building2, PlusCircle, UserPlus, LogIn } from 'lucide-react';
import { LandingPage } from './pages/LandingPage';
import { RegisterPage } from './pages/RegisterPage';
import { AdminDashboardPage } from './pages/AdminDashboardPage';
import { LoginPage } from './pages/LoginPage';
import { HrLandingPage } from './pages/HrLandingPage';
import { ApplicationsPage } from './pages/ApplicationsPage';
import { StaffDashboardPage } from './pages/StaffDashboardPage';
import { JobPostingForm } from './components/company/JobPostingForm';
import { LoginModal } from './components/auth/LoginModal';

import type { RegistrationRecord } from './types/auth';
import { authService } from './services/authService';

export type AppView = 'landing' | 'register' | 'login' | 'admin' | 'hr' | 'hr-post-job' | 'applications' | 'staff';

function App() {
  const [currentUser, setCurrentUser] = useState<{ email: string; role: string; companyName?: string } | null>(() => {
    try {
      const saved = localStorage.getItem('campusai_auth_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [currentView, setCurrentView] = useState<AppView>(() => {
    try {
      const saved = localStorage.getItem('campusai_auth_user');
      if (saved) {
        const u = JSON.parse(saved);
        if (u?.role?.toLowerCase().includes('staff')) {
          return 'staff';
        }
      }
    } catch {}
    return 'landing';
  });

  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [pendingRecordForView, setPendingRecordForView] = useState<RegistrationRecord | null>(null);
  const [newlyCreatedJobId, setNewlyCreatedJobId] = useState<string | null>(null);

  useEffect(() => {
    if (!localStorage.getItem('token')) {
      setCurrentUser(null);
      localStorage.removeItem('campusai_auth_user');
      return;
    }

    authService.getCurrentUser()
      .then((user) => {
        const verifiedUser = { email: user.email, role: user.role, companyName: (user as any).companyName };
        setCurrentUser(verifiedUser);
        localStorage.setItem('campusai_auth_user', JSON.stringify(verifiedUser));
        if (user.role && user.role.toLowerCase().includes('staff')) {
          setCurrentView('staff');
        }
      })
      .catch(() => {
        setCurrentUser(null);
        localStorage.removeItem('campusai_auth_user');
      });
  }, []);

  const handleLogout = () => {
    authService.logout();
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
    } else if (normalizedRole.includes('staff')) {
      // Staff members go directly to the new Staff Dashboard
      setCurrentView('staff');
    } else if (
      normalizedRole === 'company hr' ||
      normalizedRole === 'companyhr' ||
      normalizedRole === 'company' ||
      normalizedRole === 'recruiter'
    ) {
      // Outside company HR redirected directly to dedicated HR Landing Page
      setCurrentView('hr');
    } else {
      setCurrentView('landing');
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const isStaff = currentUser?.role?.toLowerCase().includes('staff') || false;
  const isAdmin = currentUser?.role?.toLowerCase() === 'admin' || currentView === 'admin';
  const isHr = !isStaff && (currentView === 'hr' || (currentUser?.role && currentUser.role.toLowerCase().includes('company')));

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

      {currentView === 'applications' && (
        <ApplicationsPage 
          onNavigateDashboard={isStaff ? undefined : () => {
            setCurrentView('hr');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
          userRole={currentUser?.role}
          userEmail={currentUser?.email}
          onLogout={handleLogout}
        />
      )}

      {currentView === 'staff' && (
        <StaffDashboardPage 
          onLogout={handleLogout}
          userEmail={currentUser?.email}
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


    </div>
  );
}

export default App;
