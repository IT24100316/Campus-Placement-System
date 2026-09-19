import React, { useState } from 'react';
import {
  Lock,
  Mail,
  Eye,
  EyeOff,
  AlertCircle,
  X,
  Shield,
  Building2,
  ArrowRight,
  Sparkles,
} from 'lucide-react';
import { authService } from '../../services/authService';
import type { RegistrationRecord } from '../../types/auth';

interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLoginSuccess: (role: string) => void;
  onPendingFound: (record: RegistrationRecord) => void;
  onNavigateRegister: () => void;
}

export const LoginModal: React.FC<LoginModalProps> = ({
  isOpen,
  onClose,
  onLoginSuccess,
  onPendingFound,
  onNavigateRegister,
}) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  if (!isOpen) return null;

  const handleAutofillAdmin = () => {
    setEmail('admin@campusai.edu');
    setPassword('Admin@2025');
    setErrorMessage('');
  };

  const handleAutofillHr = () => {
    setEmail('c.vance@acmeglobal.tech');
    setPassword('Vanguard#2024Secure!');
    setErrorMessage('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password) {
      setErrorMessage('Please enter both your email and password.');
      return;
    }

    setIsLoading(true);
    setErrorMessage('');

    try {
      const res = await authService.login(email, password);
      if (res.success) {
        onClose();
        onLoginSuccess(res.role || 'Admin');
      } else if (res.isPending && res.record) {
        onClose();
        onPendingFound(res.record);
      } else {
        setErrorMessage(res.message || 'Invalid email or password.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in">
      <div className="bg-white rounded-2xl border border-slate-200 shadow-2xl w-full max-w-md p-6 sm:p-8 relative">
        {/* Close Button */}
        <button
          type="button"
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="text-center mb-6">
          <div className="w-12 h-12 rounded-xl bg-blue-50 text-primary flex items-center justify-center mx-auto mb-3 shadow-xs">
            <Lock className="w-6 h-6" />
          </div>
          <h2 className="font-display text-2xl font-bold text-slate-900 tracking-tight">
            Sign in to CampusAI
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Access your recruitment cockpit or administrative dashboard
          </p>
        </div>

        {/* Demo Quick-Autofill Helpers */}
        <div className="mb-5 p-3 rounded-xl bg-slate-50 border border-slate-200/80">
          <span className="flex items-center gap-1.5 text-[11px] font-bold text-slate-700 uppercase tracking-wide mb-2">
            <Sparkles className="w-3.5 h-3.5 text-amber-500" />
            Instant Demo Credentials:
          </span>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={handleAutofillAdmin}
              className="flex items-center justify-center gap-1.5 py-1.5 px-2.5 rounded-md bg-white border border-slate-200 hover:border-indigo-500 text-indigo-700 text-xs font-semibold shadow-2xs transition-all cursor-pointer"
            >
              <Shield className="w-3.5 h-3.5" />
              <span>Admin Login</span>
            </button>
            <button
              type="button"
              onClick={handleAutofillHr}
              className="flex items-center justify-center gap-1.5 py-1.5 px-2.5 rounded-md bg-white border border-slate-200 hover:border-blue-500 text-primary text-xs font-semibold shadow-2xs transition-all cursor-pointer"
            >
              <Building2 className="w-3.5 h-3.5" />
              <span>HR (Pending)</span>
            </button>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {errorMessage && (
            <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 flex items-start gap-2 text-rose-700 text-xs">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Email Field */}
          <div className="space-y-1">
            <label className="block text-xs font-semibold text-slate-700" htmlFor="login-email">
              Corporate / Admin Email
            </label>
            <div className="relative">
              <input
                id="login-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@campusai.edu"
                className="w-full h-10 pl-9 pr-3.5 rounded-lg bg-white text-sm text-slate-900 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-primary"
                required
              />
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
            </div>
          </div>

          {/* Password Field */}
          <div className="space-y-1">
            <label className="block text-xs font-semibold text-slate-700" htmlFor="login-password">
              Password
            </label>
            <div className="relative">
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full h-10 pl-9 pr-9 rounded-lg bg-white text-sm text-slate-900 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-primary"
                required
              />
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-3 text-slate-400 hover:text-slate-600 focus:outline-none"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Submit Action */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full h-11 bg-primary hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm flex items-center justify-center gap-2 transition-all cursor-pointer active:scale-[0.99] disabled:opacity-70 mt-2"
          >
            {isLoading ? (
              <span>Authenticating...</span>
            ) : (
              <>
                <span>Sign in to Cockpit</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>

          {/* Switch to Register */}
          <div className="text-center pt-2">
            <span className="text-xs text-slate-500">Need to onboard an enterprise? </span>
            <button
              type="button"
              onClick={() => {
                onClose();
                onNavigateRegister();
              }}
              className="text-xs font-semibold text-primary hover:underline cursor-pointer"
            >
              Create Account &rarr;
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
