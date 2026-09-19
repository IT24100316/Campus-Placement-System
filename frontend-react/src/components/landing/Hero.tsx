import React from 'react';

const universityPartners = [
  'IIT Delhi',
  'BITS Pilani',
  'Stanford CS',
  'IIT Bombay',
  'NUS Singapore',
];

export const Hero: React.FC = () => {
  return (
    <section className="max-w-7xl mx-auto px-6 pt-16 pb-20 lg:pt-24 lg:pb-28">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* Left: Hero Value Proposition */}
        <div className="lg:col-span-7 flex flex-col items-start">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-primary text-xs font-semibold uppercase tracking-wider mb-6">
            <span className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse"></span>
            Autonomous Recruitment Intelligence
          </div>

          <h1 className="font-display text-4xl sm:text-5xl lg:text-[52px] lg:leading-[1.15] text-on-surface font-extrabold tracking-tight mb-6">
            AI-Driven Candidate Matching &amp; Placement Automation
          </h1>

          <p className="font-body-lg text-lg text-on-surface-variant max-w-xl leading-relaxed mb-8">
            Connect verified university talent with top employers through explainable AI matching,
            automated screening, and seamless interview workflows.
          </p>

          <div className="flex flex-wrap items-center gap-4 mb-14 w-full sm:w-auto">
            <a
              href="#login"
              className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-lg bg-primary hover:bg-blue-700 text-white font-medium text-sm transition-all shadow-sm active:scale-[0.99]"
            >
              <span>Login to Dashboard</span>
              <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
            </a>
            <a
              href="#register-company"
              className="inline-flex items-center justify-center px-6 py-3 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-medium text-sm transition-all active:scale-[0.99]"
            >
              Register Company
            </a>
          </div>

          {/* University Trust Strip */}
          <div className="w-full pt-6 border-t border-slate-100">
            <p className="text-xs uppercase font-semibold text-slate-400 tracking-wider mb-4">
              Trusted by leading universities &amp; global employers
            </p>
            <div className="flex items-center flex-wrap gap-x-8 gap-y-3 text-slate-500 font-semibold text-sm">
              {universityPartners.map((partner, index) => (
                <React.Fragment key={partner}>
                  <span className="hover:text-slate-800 transition-colors cursor-default">
                    {partner}
                  </span>
                  {index < universityPartners.length - 1 && (
                    <span className="text-slate-300">•</span>
                  )}
                </React.Fragment>
              ))}
            </div>
          </div>
        </div>

        {/* Right: Candidate Match Preview Card */}
        <div className="lg:col-span-5">
          <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 lg:p-7 flex flex-col gap-6 hover:shadow-md transition-shadow">
            {/* Header bar inside card */}
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-2.5">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 ring-4 ring-emerald-50"></span>
                <span className="text-xs font-semibold text-slate-600 uppercase tracking-wide">
                  Autonomous Match Found
                </span>
              </div>
              <span className="text-xs font-medium text-slate-400">98.4% Confidence</span>
            </div>

            {/* Candidate Profile Snippet */}
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-xl bg-blue-50 text-primary font-bold text-base flex items-center justify-center border border-blue-100">
                  AM
                </div>
                <div>
                  <h3 className="font-headline-sm text-base font-semibold text-slate-900">
                    Arjun Mehta
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    B.Tech Computer Science • IIT Delhi &apos;25
                  </p>
                </div>
              </div>
              <span className="px-2.5 py-1 rounded-md bg-emerald-50 text-emerald-700 font-semibold text-xs border border-emerald-100">
                96% Match
              </span>
            </div>

            {/* Skill Badges */}
            <div className="flex flex-wrap gap-1.5">
              <span className="px-2.5 py-1 rounded-md bg-slate-50 text-slate-600 text-xs font-medium border border-slate-100">
                Distributed Systems
              </span>
              <span className="px-2.5 py-1 rounded-md bg-slate-50 text-slate-600 text-xs font-medium border border-slate-100">
                PyTorch
              </span>
              <span className="px-2.5 py-1 rounded-md bg-slate-50 text-slate-600 text-xs font-medium border border-slate-100">
                Go
              </span>
            </div>

            {/* Key Insights */}
            <div className="space-y-2.5 pt-1">
              <div className="flex items-center justify-between text-xs py-2 px-3 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Benchmark Ranking</span>
                <span className="font-semibold text-slate-900">Top 1% of Applicants</span>
              </div>
              <div className="flex items-center justify-between text-xs py-2 px-3 rounded-lg bg-slate-50 border border-slate-100">
                <span className="text-slate-600">Interview Status</span>
                <span className="font-semibold text-blue-600">Auto-Scheduled for Round 1</span>
              </div>
            </div>

            {/* Card Footer Verification */}
            <div className="pt-2 border-t border-slate-50 flex items-center justify-between text-xs text-slate-400">
              <span className="flex items-center gap-1.5">
                <span className="material-symbols-outlined text-[16px] text-emerald-600">
                  verified
                </span>
                Verified academic records
              </span>
              <span className="text-[11px] text-slate-400 font-mono">ID: #STU-8821</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
