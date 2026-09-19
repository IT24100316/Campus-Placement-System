import React from 'react';

interface DualAudienceProps {
  onNavigateRegister?: () => void;
}

export const DualAudience: React.FC<DualAudienceProps> = ({ onNavigateRegister }) => {
  return (
    <section id="dual-audience" className="border-t border-slate-100 bg-slate-50/40 py-24">
      <div className="max-w-7xl mx-auto px-6">
        <div className="max-w-xl mb-16">
          <h2 className="font-display text-3xl font-bold text-slate-900 tracking-tight mb-3">
            Built for Both Sides of Placement
          </h2>
          <p className="text-base text-slate-600 leading-relaxed">
            One unified ecosystem for enterprise hiring teams and university placement cells.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-12">
          {/* Column 1: For Company HRs */}
          <div className="p-8 lg:p-10 rounded-2xl bg-white border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow flex flex-col justify-between">
            <div>
              <div className="text-xs font-bold text-primary tracking-wider uppercase mb-3">
                For Company HRs
              </div>
              <h3 className="font-headline-sm text-xl font-bold text-slate-900 mb-6">
                Streamline High-Volume Campus Hiring
              </h3>
              <ul className="space-y-4 mb-8">
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-primary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Access pre-vetted campus talent with standardized evaluation benchmarks.
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-primary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Deploy custom assessment pipelines aligned with your engineering ladders.
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-primary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Automated verification of academic credentials, GPAs, and roll records.
                  </span>
                </li>
              </ul>
            </div>
            <div>
              <button
                type="button"
                onClick={onNavigateRegister}
                className="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-blue-700 group focus:outline-none cursor-pointer"
              >
                <span>Register as Employer</span>
                <span className="material-symbols-outlined text-[16px] group-hover:translate-x-0.5 transition-transform">
                  chevron_right
                </span>
              </button>
            </div>
          </div>

          {/* Column 2: For University Admins */}
          <div className="p-8 lg:p-10 rounded-2xl bg-white border border-slate-200/80 shadow-sm hover:shadow-md transition-shadow flex flex-col justify-between">
            <div>
              <div className="text-xs font-bold text-secondary tracking-wider uppercase mb-3">
                For University Admins
              </div>
              <h3 className="font-headline-sm text-xl font-bold text-slate-900 mb-6">
                Maximize Batch Placement Outcomes
              </h3>
              <ul className="space-y-4 mb-8">
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-secondary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Real-time placement records and automated compliance/accreditation exports.
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-secondary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Live student tracker to monitor interview rounds and offer status seamlessly.
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="material-symbols-outlined text-secondary text-[20px] shrink-0 mt-0.5">
                    check
                  </span>
                  <span className="text-sm text-slate-600 leading-relaxed">
                    Vetted corporate recruiters adhering strictly to university placement guidelines.
                  </span>
                </li>
              </ul>
            </div>
            <div>
              <a
                href="#explore-university"
                className="inline-flex items-center gap-1.5 text-sm font-semibold text-secondary hover:text-indigo-700 group focus:outline-none"
              >
                <span>Explore University Suite</span>
                <span className="material-symbols-outlined text-[16px] group-hover:translate-x-0.5 transition-transform">
                  chevron_right
                </span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
