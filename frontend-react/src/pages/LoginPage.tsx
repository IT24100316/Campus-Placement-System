import React, { useState } from 'react';
import {
  Building2,
  Users,
  ShieldCheck,
  Mail,
  Lock,
  Eye,
  EyeOff,
  ArrowRight,
  CheckCircle2,
  AlertCircle,
  Clock,
  Shield,
  Fingerprint,
  Home,
  ExternalLink,
} from 'lucide-react';
import { authService } from '../services/authService';
import type { RegistrationRecord } from '../types/auth';

export type LoginRole = 'recruiter' | 'staff' | 'admin';

interface LoginPageProps {
  onBackHome: () => void;
  onNavigateRegister: () => void;
  onLoginSuccess: (role: string) => void;
  onPendingFound: (record: RegistrationRecord) => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({
  onBackHome,
  onNavigateRegister,
  onLoginSuccess,
  onPendingFound,
}) => {
  const [selectedRole, setSelectedRole] = useState<LoginRole>('recruiter');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberDevice, setRememberDevice] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [authAlert, setAuthAlert] = useState<{
    type: 'error' | 'pending' | 'success';
    title: string;
    message: string;
    record?: RegistrationRecord;
  } | null>(null);

  // Switch role tabs and adjust context
  const handleRoleSelect = (role: LoginRole) => {
    setSelectedRole(role);
    setAuthAlert(null);
  };

  // Submit Handler
  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password) {
      setAuthAlert({
        type: 'error',
        title: 'Missing Credentials',
        message: 'Please provide both your account email and security password.',
      });
      return;
    }

    setIsLoading(true);
    setAuthAlert(null);

    try {
      const res = await authService.login(email, password);

      if (res.success) {
        setAuthAlert({
          type: 'success',
          title: 'Authentication Successful',
          message:
            res.role === 'Admin'
              ? 'Institutional clearance verified. Redirecting to Admin Approvals & Placement Cockpit...'
              : `Welcome back! Redirecting to ${res.role || 'Corporate'} dashboard...`,
        });

        setTimeout(() => {
          onLoginSuccess(res.role || (selectedRole === 'admin' ? 'Admin' : 'Company'));
        }, 800);
      } else if (res.isPending && res.record) {
        setAuthAlert({
          type: 'pending',
          title: 'Account Verification In Progress',
          message:
            res.record.role === 'staff'
              ? `Your staff profile under ${res.record.companyName} is under institutional review.`
              : 'Your employer registration is currently being verified by institutional admins.',
          record: res.record,
        });
      } else {
        setAuthAlert({
          type: 'error',
          title: 'Authentication Failed',
          message: res.message || 'Invalid email or password credentials. Please try again.',
        });
      }
    } catch {
      setAuthAlert({
        type: 'error',
        title: 'Connection Error',
        message: 'Unable to connect to placement auth services. Please verify network access.',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#f8f9ff] text-[#0b1c30] flex flex-col font-sans relative selection:bg-blue-100 selection:text-primary">
      {/* Top Header */}
      <header className="fixed top-0 left-0 w-full z-40 bg-white/90 backdrop-blur-md border-b border-slate-200/70 shadow-xs">
        <div className="h-16 w-full max-w-7xl mx-auto px-4 sm:px-6 flex items-center justify-between">
          {/* Brand Logo */}
          <button
            type="button"
            onClick={onBackHome}
            className="flex items-center gap-2.5 group focus:outline-none cursor-pointer"
          >
            <div className="w-9 h-9 rounded-xl bg-primary flex items-center justify-center text-white shadow-sm transition-transform group-hover:scale-105">
              <svg
                className="w-5 h-5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 2L2 7l10 5 10-5-10-5z" />
                <path d="M2 17l10 5 10-5" />
                <path d="M2 12l10 5 10-5" />
              </svg>
            </div>
            <div className="flex flex-col text-left">
              <span className="font-display text-lg font-bold tracking-tight text-[#0b1c30] leading-none">
                CampusAI
              </span>
              <span className="text-[11px] font-semibold text-slate-500 tracking-wider uppercase mt-1">
                Placement Engine
              </span>
            </div>
          </button>

          {/* Quick Nav Links */}
          <nav className="hidden md:flex items-center gap-6">
            <button
              type="button"
              onClick={onNavigateRegister}
              className="text-xs font-semibold text-slate-600 hover:text-primary transition-colors cursor-pointer"
            >
              Employer Registration
            </button>
          </nav>

          {/* Right Action / System Status */}
          <div className="flex items-center gap-3">
            <div className="hidden sm:flex items-center gap-1.5 px-3 py-1 bg-blue-50/80 border border-blue-100 rounded-full">
              <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse" />
              <span className="text-[11px] font-bold text-blue-900 tracking-wide uppercase">
                System Active
              </span>
            </div>
            <button
              type="button"
              onClick={onBackHome}
              className="p-2 rounded-lg text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-all cursor-pointer"
              title="Return to Home"
            >
              <Home className="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 pt-24 pb-16 px-4 sm:px-6 flex flex-col items-center justify-center relative">
        {/* Subtle Ambient Background Glows */}
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[32rem] h-[32rem] bg-blue-500/10 rounded-full blur-3xl pointer-events-none -z-10" />
        <div className="absolute bottom-16 left-1/3 w-80 h-80 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none -z-10" />

        {/* Centered Login Card */}
        <div className="w-full max-w-[500px] bg-white rounded-2xl shadow-xl border border-slate-200/80 p-6 sm:p-8 relative transition-all">
          {/* Card Header */}
          <div className="flex flex-col items-center text-center">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-primary text-[11px] font-bold uppercase tracking-wider mb-3">
              <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
              Campus Recruitment Portal
            </div>
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#0b1c30] tracking-tight">
              Welcome Back
            </h1>
            <p className="text-xs sm:text-sm text-slate-500 mt-1 max-w-sm">
              Sign in to access campus placement drives, candidate evaluations, and administrative controls.
            </p>
          </div>

          {/* Segmented 3-Role Switcher */}
          <div className="mt-6 p-1 bg-slate-100/90 rounded-xl flex items-center gap-1 border border-slate-200/60" role="tablist">
            {/* Company HR */}
            <button
              type="button"
              role="tab"
              aria-selected={selectedRole === 'recruiter'}
              onClick={() => handleRoleSelect('recruiter')}
              className={`flex-1 py-2 px-2 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                selectedRole === 'recruiter'
                  ? 'bg-white text-primary shadow-xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Building2 className="w-3.5 h-3.5" />
              <span>Company HR</span>
            </button>

            {/* Company Staff */}
            <button
              type="button"
              role="tab"
              aria-selected={selectedRole === 'staff'}
              onClick={() => handleRoleSelect('staff')}
              className={`flex-1 py-2 px-2 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                selectedRole === 'staff'
                  ? 'bg-white text-primary shadow-xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              <span>Company Staff</span>
            </button>

            {/* Institutional Admin */}
            <button
              type="button"
              role="tab"
              aria-selected={selectedRole === 'admin'}
              onClick={() => handleRoleSelect('admin')}
              className={`flex-1 py-2 px-2 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                selectedRole === 'admin'
                  ? 'bg-white text-indigo-700 shadow-xs font-bold'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>Admin</span>
            </button>
          </div>

          {/* Context Helper Strip */}
          <div className="mt-3 px-1 flex items-center text-xs">
            <span className="text-slate-500 flex items-center gap-1.5 text-[11px]">
              {selectedRole === 'recruiter' && (
                <>
                  <Building2 className="w-3.5 h-3.5 text-primary shrink-0" />
                  <span>Sign in with your corporate HR administrator email</span>
                </>
              )}
              {selectedRole === 'staff' && (
                <>
                  <Users className="w-3.5 h-3.5 text-primary shrink-0" />
                  <span>Sign in with your verified company staff / employee ID credentials</span>
                </>
              )}
              {selectedRole === 'admin' && (
                <>
                  <ShieldCheck className="w-3.5 h-3.5 text-indigo-600 shrink-0" />
                  <span>Sign in with institutional placement admin clearance</span>
                </>
              )}
            </span>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSignIn} className="mt-5 flex flex-col gap-4">
            {/* Email Input */}
            <div className="flex flex-col gap-1.5">
              <div className="flex justify-between items-center text-xs">
                <label className="font-semibold text-slate-700" htmlFor="login-page-email">
                  {selectedRole === 'recruiter' && 'Corporate HR Email'}
                  {selectedRole === 'staff' && 'Company Staff Email'}
                  {selectedRole === 'admin' && 'Institutional Admin Email'}
                  <span className="text-rose-500 ml-0.5">*</span>
                </label>
                <span className="font-mono text-[11px] text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                  {selectedRole === 'admin' ? '@campusai.edu' : 'Enterprise ID'}
                </span>
              </div>
              <div className="relative flex items-center">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 pointer-events-none" />
                <input
                  id="login-page-email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={
                    selectedRole === 'recruiter'
                      ? 'hr.director@company.com'
                      : selectedRole === 'staff'
                      ? 'talent.recruiter@company.com'
                      : 'admin@campusai.edu'
                  }
                  className="w-full h-11 pl-10 pr-3.5 rounded-xl bg-slate-50 border border-slate-200 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:ring-2 focus:ring-blue-100 focus:border-primary transition-all"
                />
              </div>
            </div>

            {/* Password Input */}
            <div className="flex flex-col gap-1.5">
              <div className="flex justify-between items-center text-xs">
                <label className="font-semibold text-slate-700" htmlFor="login-page-password">
                  Password <span className="text-rose-500">*</span>
                </label>
                <a
                  href="#forgot-password"
                  onClick={(e) => {
                    e.preventDefault();
                    setAuthAlert({
                      type: 'error',
                      title: 'Password Recovery',
                      message: 'Password reset requests are authenticated through institutional single sign-on. Please contact your system administrator.',
                    });
                  }}
                  className="text-[11px] font-semibold text-primary hover:underline"
                >
                  Forgot password?
                </a>
              </div>
              <div className="relative flex items-center">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 pointer-events-none" />
                <input
                  id="login-page-password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full h-11 pl-10 pr-10 rounded-xl bg-slate-50 border border-slate-200 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:bg-white focus:ring-2 focus:ring-blue-100 focus:border-primary transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 p-1 rounded text-slate-400 hover:text-slate-600 focus:outline-none cursor-pointer"
                  aria-label="Toggle password visibility"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Remember Device Checkbox */}
            <div className="flex items-center justify-between pt-0.5">
              <label className="flex items-center gap-2 cursor-pointer select-none text-xs text-slate-600">
                <input
                  type="checkbox"
                  checked={rememberDevice}
                  onChange={(e) => setRememberDevice(e.target.checked)}
                  className="w-4 h-4 rounded text-primary border-slate-300 focus:ring-primary focus:ring-offset-0 cursor-pointer"
                />
                <span>Remember this workstation for 30 days</span>
              </label>
            </div>

            {/* Status Alert Notification Card */}
            {authAlert && (
              <div
                className={`rounded-xl p-3.5 border transition-all text-xs ${
                  authAlert.type === 'error'
                    ? 'bg-rose-50 border-rose-200 text-rose-800'
                    : authAlert.type === 'pending'
                    ? 'bg-amber-50 border-amber-200 text-amber-900'
                    : 'bg-emerald-50 border-emerald-200 text-emerald-900'
                }`}
              >
                <div className="flex items-start gap-2.5">
                  {authAlert.type === 'error' && <AlertCircle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />}
                  {authAlert.type === 'pending' && <Clock className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />}
                  {authAlert.type === 'success' && <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />}
                  <div className="flex flex-col flex-1">
                    <span className="font-bold">{authAlert.title}</span>
                    <span className="mt-0.5 opacity-90">{authAlert.message}</span>
                    {authAlert.record && (
                      <button
                        type="button"
                        onClick={() => onPendingFound(authAlert.record!)}
                        className="mt-2 inline-flex items-center gap-1 font-bold text-amber-800 hover:text-amber-950 underline text-[11px] cursor-pointer"
                      >
                        <span>View Real-Time Pending Verification Status &rarr;</span>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full h-12 bg-primary hover:bg-blue-700 active:scale-[0.99] text-white font-semibold text-sm rounded-xl flex items-center justify-center gap-2 shadow-sm transition-all duration-200 cursor-pointer disabled:opacity-75 mt-1 group"
            >
              {isLoading ? (
                <div className="flex items-center gap-2">
                  <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Verifying Credentials...</span>
                </div>
              ) : (
                <>
                  <span>Sign In to Dashboard</span>
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                </>
              )}
            </button>
          </form>

          {/* Institutional Verification Status Banner */}
          <div className="mt-6 p-3.5 rounded-xl bg-blue-50/70 border border-blue-100 flex items-start gap-2.5 text-xs">
            <Shield className="w-4 h-4 text-primary shrink-0 mt-0.5" />
            <div className="flex flex-col text-slate-700">
              <span className="text-[11px] font-bold text-primary uppercase tracking-wide">
                Institutional Verification Notice
              </span>
              <p className="mt-0.5 text-slate-600 leading-relaxed text-[11px]">
                Recently registered? Newly submitted Company HR and Company Staff applications undergo institutional verification (typically 4–12 hours).
              </p>
              <button
                type="button"
                onClick={() => {
                  const recs = authService.getRegistrations();
                  const target = recs.find(
                    (r) =>
                      r.email.toLowerCase() === email.toLowerCase() ||
                      (selectedRole === 'staff' && r.role === 'staff') ||
                      (selectedRole === 'recruiter' && r.role === 'hr')
                  );
                  if (target) {
                    onPendingFound(target);
                  } else {
                    setAuthAlert({
                      type: 'pending',
                      title: 'Application Lookup',
                      message: 'Enter your registered email address and click Sign In to track your live application.',
                    });
                  }
                }}
                className="mt-1.5 inline-flex items-center gap-1 font-bold text-primary hover:underline text-[11px] cursor-pointer"
              >
                <span>Check Application Lifecycle Status</span>
                <ExternalLink className="w-3 h-3" />
              </button>
            </div>
          </div>

          {/* Registration Redirect Footer */}
          <div className="mt-6 pt-4 text-center border-t border-slate-100">
            <p className="text-xs text-slate-500">
              Don't have a verified employer account yet?{' '}
              <button
                type="button"
                onClick={onNavigateRegister}
                className="font-bold text-primary hover:underline ml-0.5 cursor-pointer"
              >
                Register your company &rarr;
              </button>
            </p>
            <p className="text-[11px] text-slate-400 mt-1">
              (Company Staff accounts are provisioned directly by placement administration)
            </p>
          </div>
        </div>

        {/* Security & Trust Indicators */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-slate-500 text-xs">
          <div className="flex items-center gap-1.5">
            <Lock className="w-3.5 h-3.5 text-slate-400" />
            <span>256-bit TLS Enforced</span>
          </div>
          <span className="text-slate-300">•</span>
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-3.5 h-3.5 text-slate-400" />
            <span>FERPA &amp; SOC-2 Certified</span>
          </div>
          <span className="text-slate-300">•</span>
          <div className="flex items-center gap-1.5">
            <Fingerprint className="w-3.5 h-3.5 text-slate-400" />
            <span>Multi-Factor Capable</span>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full bg-slate-100/80 border-t border-slate-200/80 py-4 px-6 text-xs text-slate-500">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <span className="font-bold text-slate-800">CampusAI</span>
            <span className="text-slate-300">|</span>
            <span>Institutional Placement System. ISO 27001 &amp; FERPA Compliant.</span>
          </div>
          <div className="flex items-center gap-5">
            <span className="hover:text-slate-800 cursor-pointer">Institutional Privacy</span>
            <span className="hover:text-slate-800 cursor-pointer">FERPA Disclosures</span>
            <span className="hover:text-slate-800 cursor-pointer">Audit Logs</span>
          </div>
        </div>
      </footer>
    </div>
  );
};
