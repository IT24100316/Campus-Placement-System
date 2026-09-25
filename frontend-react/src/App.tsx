import { useEffect, useState } from 'react';
import { LandingPage } from './pages/LandingPage';
import { RegisterPage } from './pages/RegisterPage';
import { AdminDashboardPage } from './pages/AdminDashboardPage';
import { LoginPage } from './pages/LoginPage';
import { HrLandingPage } from './pages/HrLandingPage';
import { ApplicationsPage } from './pages/ApplicationsPage';
import { JobPostingForm } from './components/company/JobPostingForm';
import { LoginModal } from './components/auth/LoginModal';

import type { RegistrationRecord } from './types/auth';
import { authService } from './services/authService';

export type AppView = 'landing' | 'register' | 'login' | 'admin' | 'hr' | 'hr-post-job' | 'applications';

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

  useEffect(() => {
    if (!localStorage.getItem('token')) {
      setCurrentUser(null);
      localStorage.removeItem('campusai_auth_user');
      return;
    }

    authService.getCurrentUser()
      .then((user) => {
        const verifiedUser = { email: user.email, role: user.role };
        setCurrentUser(verifiedUser);
        localStorage.setItem('campusai_auth_user', JSON.stringify(verifiedUser));
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
          onNavigateDashboard={() => {
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

      {/* Floating Demo View Quick-Switcher removed as per user request */}
    </div>
  );
}

export default App;
