import React, { useState } from 'react';
import {
  Building2,
  Lock,
  ShieldCheck,
  UploadCloud,
  FileText,
  Trash2,
  Eye,
  EyeOff,
  AlertCircle,
  Mail,
  Phone,
  ArrowRight,
} from 'lucide-react';
import type { RegistrationRecord } from '../../types/auth';
import { authService } from '../../services/authService';

interface RegisterFormProps {
  onSuccess: (record: RegistrationRecord) => void;
  onNavigateLogin?: () => void;
}

export const RegisterForm: React.FC<RegisterFormProps> = ({ onSuccess, onNavigateLogin }) => {
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form State
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [industry, setIndustry] = useState('Software, Cloud & Artificial Intelligence');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // BR Document State
  const [documentFile, setDocumentFile] = useState<File | null>(null);

  // Validation Errors State
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Password strength calculation
  const calculatePasswordStrength = (pwd: string): { score: number; label: string; color: string } => {
    if (!pwd) return { score: 0, label: 'Empty', color: 'bg-slate-200' };
    let score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (/[A-Z]/.test(pwd) && /[a-z]/.test(pwd)) score++;
    if (/[0-9]/.test(pwd) && /[^A-Za-z0-9]/.test(pwd)) score++;

    if (score <= 1) return { score: 1, label: 'Weak', color: 'bg-rose-500' };
    if (score === 2) return { score: 2, label: 'Fair', color: 'bg-amber-500' };
    if (score === 3) return { score: 3, label: 'Good', color: 'bg-blue-500' };
    return { score: 4, label: 'Strong', color: 'bg-emerald-500' };
  };

  const pwdStrength = calculatePasswordStrength(password);

  // Real-time field validation
  const validateForm = (): boolean => {
    const errs: Record<string, string> = {};

    if (!fullName.trim()) {
      errs.fullName = 'Full name of corporate representative is required.';
    } else if (fullName.trim().length < 2) {
      errs.fullName = 'Please enter at least 2 characters.';
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email.trim()) {
      errs.email = 'Corporate work email is required.';
    } else if (!emailRegex.test(email)) {
      errs.email = 'Please provide a valid corporate email address.';
    }

    const phoneRegex = /^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]{7,15}$/;
    if (!phone.trim()) {
      errs.phone = 'Contact telephone number is required.';
    } else if (!phoneRegex.test(phone.replace(/\s+/g, ''))) {
      errs.phone = 'Please provide a valid phone number (e.g. +1 555-234-5678).';
    }

    if (!password) {
      errs.password = 'Password is required.';
    } else if (password.length < 8) {
      errs.password = 'Password must be at least 8 characters long.';
    }

    if (!confirmPassword) {
      errs.confirmPassword = 'Confirmation password is required.';
    } else if (password !== confirmPassword) {
      errs.confirmPassword = 'Passwords do not match.';
    }

    if (!companyName.trim()) {
      errs.companyName = 'Registered company legal name is required.';
    }
    if (!industry) {
      errs.industry = 'Industry sector is required.';
    }
    if (!documentFile) {
      errs.document = 'Business Registration (BR) document is required for institutional verification.';
    }

    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const validExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
    const extension = file.name.split('.').pop()?.toLowerCase();
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB

    if (!extension || !validExtensions.includes(extension)) {
      setErrors((prev) => ({
        ...prev,
        document: 'Invalid file format. Please upload a PDF, PNG, or JPG.',
      }));
      return;
    }

    if (file.size > maxSizeBytes) {
      setErrors((prev) => ({
        ...prev,
        document: 'File size exceeds 10MB limit.',
      }));
      return;
    }

    setDocumentFile(file);
    setErrors((prev) => {
      const next = { ...prev };
      delete next.document;
      return next;
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsSubmitting(true);
    try {
      const record = await authService.registerHr({
        fullName,
        email,
        phone,
        companyName,
        industry,
        password,
        confirmPassword,
        documentName: documentFile?.name,
        documentSize: documentFile ? `${(documentFile.size / (1024 * 1024)).toFixed(1)} MB` : undefined,
        documentFile: documentFile ?? undefined,
      });
      onSuccess(record);
    } catch (error) {
      setErrors((previous) => ({
        ...previous,
        submit: error instanceof Error ? error.message : 'Registration could not be submitted.',
      }));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="w-full max-w-xl mx-auto py-8 px-4 sm:px-0">
      {/* Title & Badge Header */}
      <div className="w-full mb-8 text-center">
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 text-primary text-xs font-semibold uppercase tracking-wider mb-2 border border-blue-100">
          <ShieldCheck className="w-4 h-4 text-primary" />
          Institutional Employer Onboarding
        </span>
        <h1 className="font-display text-3xl font-extrabold text-on-surface tracking-tight mt-1">
          Register Your Organization
        </h1>
        <p className="font-body-md text-sm text-on-surface-variant mt-2 max-w-md mx-auto">
          Create your official enterprise profile to post campus placement drives, coordinate candidate evaluations, and hire verified university talent.
        </p>
      </div>

      {/* Main Card Container */}
      <div className="w-full bg-white rounded-2xl border border-slate-200/80 shadow-[0_4px_24px_rgba(11,28,48,0.06)] p-6 md:p-8 relative">
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-primary via-indigo-600 to-blue-500 rounded-t-2xl"></div>

        {/* Corporate Authority Notice */}
        <div className="mb-6 p-4 rounded-xl bg-blue-50/70 border-l-4 border-primary flex items-start gap-3">
          <Building2 className="w-5 h-5 text-primary shrink-0 mt-0.5" />
          <div className="flex flex-col">
            <span className="text-xs font-bold text-slate-900 uppercase tracking-wide">
              Corporate Representative Authority
            </span>
            <p className="text-xs text-slate-600 mt-0.5 leading-relaxed">
              Registering authorized officers possess institutional authority to sign placement agreements, post job openings, and rollout offers.
            </p>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Section 1: Authorized Officer Details */}
          <div className="space-y-4">
            <div className="border-b border-slate-100 pb-2">
              <h2 className="font-display text-sm font-bold text-slate-900 uppercase tracking-wider">
                1. Authorized Officer Details
              </h2>
            </div>

            {/* Full Name */}
            <div className="space-y-1">
              <label className="block text-xs font-semibold text-slate-700" htmlFor="fullName">
                Full Legal Name <span className="text-rose-500">*</span>
              </label>
              <input
                id="fullName"
                type="text"
                value={fullName}
                onChange={(e) => {
                  setFullName(e.target.value);
                  if (errors.fullName) setErrors((prev) => ({ ...prev, fullName: '' }));
                }}
                placeholder="e.g. Clara Vance"
                className={`w-full h-10 px-3.5 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                  errors.fullName
                    ? 'border-rose-400 focus:ring-rose-200'
                    : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                }`}
              />
              {errors.fullName && (
                <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                  <AlertCircle className="w-3.5 h-3.5" /> {errors.fullName}
                </p>
              )}
            </div>

            {/* Email & Phone Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Corporate Email */}
              <div className="space-y-1">
                <label className="block text-xs font-semibold text-slate-700" htmlFor="email">
                  Corporate Work Email <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value);
                      if (errors.email) setErrors((prev) => ({ ...prev, email: '' }));
                    }}
                    placeholder="name@company.com"
                    className={`w-full h-10 pl-9 pr-3.5 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                      errors.email
                        ? 'border-rose-400 focus:ring-rose-200'
                        : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                    }`}
                  />
                  <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                </div>
                {errors.email ? (
                  <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                    <AlertCircle className="w-3.5 h-3.5" /> {errors.email}
                  </p>
                ) : (
                  <p className="text-[11px] text-slate-500">Official company email domain required.</p>
                )}
              </div>

              {/* Phone Number */}
              <div className="space-y-1">
                <label className="block text-xs font-semibold text-slate-700" htmlFor="phone">
                  Direct Telephone Number <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="phone"
                    type="tel"
                    value={phone}
                    onChange={(e) => {
                      setPhone(e.target.value);
                      if (errors.phone) setErrors((prev) => ({ ...prev, phone: '' }));
                    }}
                    placeholder="+1 (555) 234-5678"
                    className={`w-full h-10 pl-9 pr-3.5 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                      errors.phone
                        ? 'border-rose-400 focus:ring-rose-200'
                        : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                    }`}
                  />
                  <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                </div>
                {errors.phone ? (
                  <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                    <AlertCircle className="w-3.5 h-3.5" /> {errors.phone}
                  </p>
                ) : (
                  <p className="text-[11px] text-slate-500">For verification & communications.</p>
                )}
              </div>
            </div>
          </div>

          {/* Section 2: Company Information */}
          <div className="space-y-4">
            <div className="border-b border-slate-100 pb-2">
              <h2 className="font-display text-sm font-bold text-slate-900 uppercase tracking-wider">
                2. Company Details
              </h2>
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-semibold text-slate-700" htmlFor="companyName">
                Registered Enterprise Legal Name <span className="text-rose-500">*</span>
              </label>
              <input
                id="companyName"
                type="text"
                value={companyName}
                onChange={(e) => {
                  setCompanyName(e.target.value);
                  if (errors.companyName) setErrors((prev) => ({ ...prev, companyName: '' }));
                }}
                placeholder="e.g. Acme Global Technologies Inc."
                className={`w-full h-10 px-3.5 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                  errors.companyName
                    ? 'border-rose-400 focus:ring-rose-200'
                    : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                }`}
              />
              {errors.companyName && (
                <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                  <AlertCircle className="w-3.5 h-3.5" /> {errors.companyName}
                </p>
              )}
            </div>

            <div className="space-y-1">
              <label className="block text-xs font-semibold text-slate-700" htmlFor="industry">
                Industry Sector <span className="text-rose-500">*</span>
              </label>
              <select
                id="industry"
                value={industry}
                onChange={(e) => setIndustry(e.target.value)}
                className="w-full h-10 px-3.5 rounded-lg bg-white text-sm text-slate-900 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-100 focus:border-primary cursor-pointer"
              >
                <option value="Software, Cloud & Artificial Intelligence">
                  Software, Cloud & Artificial Intelligence
                </option>
                <option value="Banking, Fintech & Quantitative Trading">
                  Banking, Fintech & Quantitative Trading
                </option>
                <option value="Biotech, Health Systems & Life Sciences">
                  Biotech, Health Systems & Life Sciences
                </option>
                <option value="Semiconductor & Hardware">Semiconductor & Hardware</option>
                <option value="Strategic Consulting & Advisory">
                  Strategic Consulting & Advisory
                </option>
                <option value="E-Commerce, Logistics & Retail">
                  E-Commerce, Logistics & Retail
                </option>
              </select>
            </div>
          </div>

          {/* Section 3: Account Security */}
          <div className="space-y-4">
            <div className="border-b border-slate-100 pb-2">
              <h2 className="font-display text-sm font-bold text-slate-900 uppercase tracking-wider">
                3. Account Security
              </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Password */}
              <div className="space-y-1">
                <label className="block text-xs font-semibold text-slate-700" htmlFor="password">
                  Create Password <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => {
                      setPassword(e.target.value);
                      if (errors.password) setErrors((prev) => ({ ...prev, password: '' }));
                    }}
                    placeholder="••••••••••••"
                    className={`w-full h-10 pl-9 pr-9 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                      errors.password
                        ? 'border-rose-400 focus:ring-rose-200'
                        : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                    }`}
                  />
                  <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-3 text-slate-400 hover:text-slate-600 focus:outline-none cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>

                {/* Password Strength Indicator */}
                {password && (
                  <div className="pt-1.5 flex items-center gap-2">
                    <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden flex gap-0.5">
                      <div className={`h-full flex-1 ${pwdStrength.score >= 1 ? pwdStrength.color : 'bg-slate-200'}`} />
                      <div className={`h-full flex-1 ${pwdStrength.score >= 2 ? pwdStrength.color : 'bg-slate-200'}`} />
                      <div className={`h-full flex-1 ${pwdStrength.score >= 3 ? pwdStrength.color : 'bg-slate-200'}`} />
                      <div className={`h-full flex-1 ${pwdStrength.score >= 4 ? pwdStrength.color : 'bg-slate-200'}`} />
                    </div>
                    <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wide">
                      {pwdStrength.label}
                    </span>
                  </div>
                )}
                {errors.password && (
                  <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                    <AlertCircle className="w-3.5 h-3.5" /> {errors.password}
                  </p>
                )}
              </div>

              {/* Confirm Password */}
              <div className="space-y-1">
                <label className="block text-xs font-semibold text-slate-700" htmlFor="confirmPassword">
                  Confirm Password <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    id="confirmPassword"
                    type={showPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => {
                      setConfirmPassword(e.target.value);
                      if (errors.confirmPassword) setErrors((prev) => ({ ...prev, confirmPassword: '' }));
                    }}
                    placeholder="••••••••••••"
                    className={`w-full h-10 pl-9 pr-3.5 rounded-lg bg-white text-sm text-slate-900 border transition-colors focus:outline-none focus:ring-2 ${
                      errors.confirmPassword
                        ? 'border-rose-400 focus:ring-rose-200'
                        : 'border-slate-200 focus:ring-blue-100 focus:border-primary'
                    }`}
                  />
                  <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3 pointer-events-none" />
                </div>
                {errors.confirmPassword && (
                  <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                    <AlertCircle className="w-3.5 h-3.5" /> {errors.confirmPassword}
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Section 4: Business Registration Document */}
          <div className="space-y-3">
            <div className="border-b border-slate-100 pb-2 flex items-center justify-between">
              <h2 className="font-display text-sm font-bold text-slate-900 uppercase tracking-wider">
                4. Business Registration (BR) Document
              </h2>
              <span className="text-[11px] text-slate-500">PDF, PNG, JPG (Max 10MB)</span>
            </div>

            {documentFile ? (
              <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center justify-between">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-10 h-10 rounded-lg bg-blue-100 text-primary flex items-center justify-center shrink-0">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div className="flex flex-col min-w-0">
                    <div className="flex items-center gap-1.5">
                      <span className="text-xs font-semibold text-slate-900 truncate">
                        {documentFile.name}
                      </span>
                      <span className="px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-700 text-[10px] font-semibold uppercase">
                        Attached
                      </span>
                    </div>
                    <span className="text-[11px] text-slate-500">
                      {(documentFile.size / (1024 * 1024)).toFixed(1)} MB • Ready for verification
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={() => setDocumentFile(null)}
                    className="p-1.5 text-rose-500 hover:bg-rose-50 rounded-md transition-colors cursor-pointer"
                    title="Remove Document"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ) : (
              <label className="relative p-6 rounded-xl border-2 border-dashed border-slate-200 hover:border-primary bg-slate-50/60 hover:bg-blue-50/20 transition-all flex flex-col items-center justify-center cursor-pointer text-center group">
                <input
                  type="file"
                  accept=".pdf,.png,.jpg,.jpeg"
                  onChange={handleFileUpload}
                  className="absolute inset-0 opacity-0 cursor-pointer w-full h-full"
                />
                <div className="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center mb-2 text-primary group-hover:scale-110 transition-transform">
                  <UploadCloud className="w-5 h-5" />
                </div>
                <p className="text-xs font-semibold text-slate-800">
                  Click to browse or drag & drop document
                </p>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Certificate of Incorporation, Tax ID, or Business License
                </p>
              </label>
            )}

            {errors.document && (
              <p className="text-xs text-rose-500 flex items-center gap-1 mt-1">
                <AlertCircle className="w-3.5 h-3.5" /> {errors.document}
              </p>
            )}
          </div>

          {/* Compliance Screening Callout */}
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-100 flex items-start gap-3">
            <ShieldCheck className="w-5 h-5 text-primary shrink-0 mt-0.5" />
            <div className="flex flex-col">
              <span className="text-xs font-bold text-slate-900">Institutional Review Notice</span>
              <p className="text-xs text-slate-600 mt-0.5 leading-relaxed">
                All submissions undergo manual review by the Placement Cell Administration before full access is activated.
              </p>
            </div>
          </div>

          {/* Submit Action */}
          {errors.submit && (
            <p className="text-sm text-rose-600 flex items-center gap-1.5">
              <AlertCircle className="w-4 h-4" /> {errors.submit}
            </p>
          )}
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full h-11 bg-primary hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm flex items-center justify-center gap-2 transition-all cursor-pointer active:scale-[0.99] disabled:opacity-70"
          >
            {isSubmitting ? (
              <span>Submitting for Verification...</span>
            ) : (
              <>
                <span>Submit Employer Registration</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>

          {/* Footer Navigation */}
          <div className="flex items-center justify-center gap-1.5 text-center pt-2">
            <span className="text-xs text-slate-600">Already registered with CampusAI?</span>
            <button
              type="button"
              onClick={onNavigateLogin}
              className="text-xs font-semibold text-primary hover:underline focus:outline-none cursor-pointer"
            >
              Sign in to Dashboard &rarr;
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
