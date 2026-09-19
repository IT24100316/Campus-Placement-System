import React from 'react';
import {
  Hourglass,
  CheckCircle2,
  RotateCw,
  Gavel,
  Key,
  FileText,
  BellRing,
  ArrowLeft,
  UserPlus,
  ShieldCheck,
} from 'lucide-react';
import type { RegistrationRecord } from '../../types/auth';

interface PendingApprovalScreenProps {
  record: RegistrationRecord;
  onBackHome: () => void;
  onRegisterAnother: () => void;
}

export const PendingApprovalScreen: React.FC<PendingApprovalScreenProps> = ({
  record,
  onBackHome,
  onRegisterAnother,
}) => {
  return (
    <div className="w-full max-w-2xl mx-auto py-8 px-4 sm:px-0 flex flex-col gap-6">
      {/* Top Banner Card */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 sm:p-8 flex flex-col items-center text-center relative overflow-hidden">
        <div className="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center text-primary shadow-sm mb-4">
          <Hourglass className="w-7 h-7 text-primary animate-pulse" />
        </div>

        {/* Status Badge */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1 bg-amber-50 border border-amber-200 rounded-full mb-4">
          <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
          <span className="text-xs uppercase tracking-wider text-amber-800 font-bold">
            Pending • Waiting for Admin Approval
          </span>
        </div>

        <h1 className="font-display text-2xl sm:text-3xl font-extrabold text-slate-900 mb-2 tracking-tight">
          Registration Submitted Successfully
        </h1>

        <p className="text-sm text-slate-600 max-w-lg leading-relaxed">
          Thank you for registering. Your corporate profile and verification credentials have been
          forwarded to the Placement Administration Cell for institutional review.
        </p>

        {/* Reference Strip */}
        <div className="w-full flex items-center justify-center gap-4 py-2.5 px-4 mt-6 bg-slate-50 border border-slate-100 rounded-xl text-xs text-slate-600">
          <span className="font-mono text-primary font-bold">Ref: {record.refCode}</span>
          <span className="text-slate-300">•</span>
          <span>Submitted: {record.submittedAt}</span>
        </div>
      </div>

      {/* Verification Lifecycle Stepper */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 sm:p-8">
        <div className="flex items-center justify-between pb-4 mb-6 border-b border-slate-100">
          <div className="flex items-center gap-2.5">
            <ShieldCheck className="w-5 h-5 text-primary" />
            <h2 className="font-display text-base font-bold text-slate-900">
              Verification Lifecycle
            </h2>
          </div>
          <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Step 2 of 4
          </span>
        </div>

        <div className="relative flex flex-col gap-6 pl-2">
          {/* Vertical Track Line */}
          <div className="absolute left-[19px] top-4 bottom-4 w-0.5 bg-slate-100"></div>

          {/* Step 1: Completed */}
          <div className="relative flex items-start gap-4">
            <div className="relative z-10 w-9 h-9 rounded-full bg-emerald-500 flex items-center justify-center text-white shadow-sm shrink-0">
              <CheckCircle2 className="w-5 h-5" />
            </div>
            <div className="flex flex-col pt-0.5">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-slate-900">Application Submitted</span>
                <span className="px-2 py-0.5 bg-emerald-50 text-emerald-700 text-[10px] font-bold rounded uppercase">
                  Completed
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                Profile metadata and statutory documentation uploaded.
              </p>
            </div>
          </div>

          {/* Step 2: In Progress */}
          <div className="relative flex items-start gap-4">
            <div className="relative z-10 w-9 h-9 rounded-full bg-primary text-white flex items-center justify-center shadow-sm shrink-0">
              <RotateCw className="w-5 h-5 animate-spin" />
            </div>
            <div className="flex flex-col pt-0.5">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-slate-900">
                  Document &amp; Domain Verification
                </span>
                <span className="px-2 py-0.5 bg-blue-50 text-primary text-[10px] font-bold rounded uppercase">
                  In Progress
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                Validation of corporate identity and academic recruiting credentials.
              </p>
              <span className="text-[11px] text-slate-400 mt-1 font-mono">
                Estimated Turnaround: 4–12 business hours
              </span>
            </div>
          </div>

          {/* Step 3: Pending */}
          <div className="relative flex items-start gap-4 opacity-50">
            <div className="relative z-10 w-9 h-9 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center shrink-0">
              <Gavel className="w-4 h-4" />
            </div>
            <div className="flex flex-col pt-0.5">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-slate-700">Admin Final Sign-off</span>
                <span className="px-2 py-0.5 bg-slate-100 text-slate-500 text-[10px] font-semibold rounded uppercase">
                  Pending
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                Placement Cell Dean review and recruitment clearance.
              </p>
            </div>
          </div>

          {/* Step 4: Pending */}
          <div className="relative flex items-start gap-4 opacity-50">
            <div className="relative z-10 w-9 h-9 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center shrink-0">
              <Key className="w-4 h-4" />
            </div>
            <div className="flex flex-col pt-0.5">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-slate-700">Account Activation</span>
                <span className="px-2 py-0.5 bg-slate-100 text-slate-500 text-[10px] font-semibold rounded uppercase">
                  Pending
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                Full dashboard access, student search, and job posting unlocked.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Submitted Details Summary Card */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 sm:p-8">
        <div className="flex items-center justify-between pb-3 mb-4 border-b border-slate-100">
          <h2 className="font-display text-base font-bold text-slate-900">
            Submitted Profile Summary
          </h2>
          <span className="font-mono text-xs px-2.5 py-1 bg-slate-100 rounded-md text-slate-600 font-semibold">
            {record.refCode}
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 py-2">
          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              Role
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">
              {record.role === 'hr' ? 'Company HR (Administrator)' : 'Company Staff (Interviewer)'}
            </p>
          </div>

          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              Applicant Name
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">{record.fullName}</p>
          </div>

          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              Corporate Entity
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">{record.companyName}</p>
          </div>

          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              {record.role === 'hr' ? 'Industry Vertical' : 'Job Position'}
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">
              {record.role === 'hr' ? record.industry : record.jobPosition}
            </p>
          </div>

          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              Corporate Email
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">{record.email}</p>
          </div>

          <div>
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
              {record.role === 'hr' ? 'Contact Telephone' : 'Employee ID'}
            </span>
            <p className="text-sm font-bold text-slate-900 mt-0.5">
              {record.role === 'hr' ? record.phone : record.staffId}
            </p>
          </div>
        </div>

        {/* BR Document info for HR */}
        {record.role === 'hr' && record.documentName && (
          <div className="mt-4 p-3.5 bg-slate-50 border border-slate-100 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-9 h-9 rounded-lg bg-blue-100 text-primary flex items-center justify-center shrink-0">
                <FileText className="w-5 h-5" />
              </div>
              <div className="flex flex-col min-w-0">
                <span className="text-xs font-semibold text-slate-900 truncate">
                  {record.documentName}
                </span>
                <span className="text-[11px] text-slate-500">
                  {record.documentSize || '2.4 MB'} • Encrypted Upload
                </span>
              </div>
            </div>
            <span className="px-2.5 py-1 bg-amber-100 text-amber-800 text-[10px] font-bold rounded uppercase">
              Under Review
            </span>
          </div>
        )}
      </div>

      {/* Dispatched Notification Card */}
      <div className="bg-slate-50 border border-slate-200/80 rounded-2xl p-5 flex items-start gap-3.5">
        <div className="w-8 h-8 rounded-full bg-blue-100 text-primary flex items-center justify-center shrink-0 mt-0.5">
          <BellRing className="w-4 h-4" />
        </div>
        <div className="flex flex-col">
          <h3 className="text-xs font-bold text-slate-900">Email Notification Dispatched</h3>
          <p className="text-xs text-slate-600 mt-0.5 leading-relaxed">
            You will receive an automated confirmation email as soon as your account is reviewed and
            approved by an administrator.
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-wrap items-center justify-between gap-3 pt-2">
        <button
          type="button"
          onClick={onBackHome}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs transition-all shadow-sm cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Return to Home</span>
        </button>

        <button
          type="button"
          onClick={onRegisterAnother}
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs transition-all cursor-pointer"
        >
          <UserPlus className="w-4 h-4" />
          <span>Register Another</span>
        </button>
      </div>
    </div>
  );
};
