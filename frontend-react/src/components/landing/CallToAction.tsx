import React from 'react';

export const CallToAction: React.FC = () => {
  return (
    <section id="cta" className="max-w-7xl mx-auto px-6 py-24 text-center">
      <div className="max-w-2xl mx-auto">
        <h2 className="font-display text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight mb-4">
          Transform Your Campus Placement Pipeline
        </h2>
        <p className="text-base text-slate-600 mb-8 leading-relaxed">
          Join top universities and progressive hiring teams managing placement drives with clarity
          and speed.
        </p>
        <div className="flex flex-wrap items-center justify-center gap-4">
          <a
            href="#register-company"
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg bg-primary hover:bg-blue-700 text-white font-semibold text-sm transition-all shadow-sm active:scale-[0.99]"
          >
            Register Company
          </a>
          <a
            href="#contact"
            className="inline-flex items-center justify-center px-6 py-3 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-medium text-sm transition-all active:scale-[0.99]"
          >
            Contact Sales
          </a>
        </div>
      </div>
    </section>
  );
};
