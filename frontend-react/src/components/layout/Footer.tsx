import React from 'react';

const footerLinks = [
  { label: 'Security', href: '#security' },
  { label: 'Privacy', href: '#privacy' },
  { label: 'Terms', href: '#terms' },
  { label: 'Status', href: '#status' },
];

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-slate-100 bg-white py-12">
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo & Tagline */}
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 rounded-md bg-primary flex items-center justify-center text-white text-xs">
              <svg
                className="w-3.5 h-3.5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 2L2 7l10 5 10-5-10-5z" />
                <path d="M2 17l10 5 10-5" />
                <path d="M2 12l10 5 10-5" />
              </svg>
            </div>
            <span className="font-semibold text-slate-900 text-sm">CampusAI</span>
            <span className="text-slate-300">|</span>
            <span className="text-xs text-slate-500">Autonomous Placement Orchestration</span>
          </div>

          {/* Legal / Policy Links */}
          <div className="flex items-center gap-6 text-xs text-slate-500">
            {footerLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                className="hover:text-slate-900 transition-colors focus:outline-none"
              >
                {link.label}
              </a>
            ))}
          </div>

          {/* Copyright */}
          <div className="text-xs text-slate-400">
            &copy; {new Date().getFullYear()} CampusAI Inc. All rights reserved.
          </div>
        </div>
      </div>
    </footer>
  );
};
