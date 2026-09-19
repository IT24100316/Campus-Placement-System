import React, { useState } from 'react';

interface NavLink {
  label: string;
  href: string;
}

const navLinks: NavLink[] = [
  { label: 'Solutions', href: '#features' },
  { label: 'Universities', href: '#dual-audience' },
  { label: 'Features', href: '#features' },
  { label: 'Metrics', href: '#metrics' },
];

interface NavbarProps {
  onNavigateHome?: () => void;
  onNavigateRegister?: () => void;
  onNavigateAdmin?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  onNavigateHome,
  onNavigateRegister,
  onNavigateAdmin,
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 w-full z-50 bg-white/90 backdrop-blur-md border-b border-slate-100 transition-all">
      <div className="h-16 w-full max-w-7xl mx-auto px-6 flex items-center justify-between">
        {/* Brand Logo */}
        <button
          type="button"
          onClick={onNavigateHome}
          className="flex items-center gap-2.5 group focus:outline-none cursor-pointer"
        >
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white shadow-sm transition-transform group-hover:scale-105">
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
          <span className="font-display text-lg font-bold tracking-tight text-on-surface">
            CampusAI
          </span>
        </button>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="text-sm font-medium text-on-surface-variant hover:text-primary transition-colors focus:outline-none"
            >
              {link.label}
            </a>
          ))}
          {onNavigateAdmin && (
            <button
              type="button"
              onClick={onNavigateAdmin}
              className="text-sm font-semibold text-indigo-600 hover:text-indigo-800 transition-colors cursor-pointer"
            >
              Admin Approvals
            </button>
          )}
        </nav>

        {/* Action Buttons */}
        <div className="hidden sm:flex items-center gap-3">
          <button
            type="button"
            onClick={onNavigateRegister}
            className="text-sm font-medium text-slate-700 hover:text-primary px-3 py-2 rounded-md transition-colors focus:outline-none cursor-pointer"
          >
            Register
          </button>
          <button
            type="button"
            onClick={onNavigateAdmin || onNavigateRegister}
            className="inline-flex items-center justify-center text-sm font-semibold text-white bg-primary hover:bg-blue-700 px-4 py-2 rounded-lg transition-all shadow-sm focus:ring-2 focus:ring-blue-300 focus:outline-none active:scale-[0.99] cursor-pointer"
          >
            Login to Dashboard
          </button>
        </div>

        {/* Mobile Menu Toggle Button */}
        <button
          type="button"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden inline-flex items-center justify-center p-2 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-primary cursor-pointer"
          aria-expanded={mobileMenuOpen}
          aria-label="Toggle navigation menu"
        >
          <span className="material-symbols-outlined text-[24px]">
            {mobileMenuOpen ? 'close' : 'menu'}
          </span>
        </button>
      </div>

      {/* Mobile Dropdown Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-slate-200 bg-white px-6 pt-3 pb-6 shadow-lg">
          <div className="flex flex-col space-y-3">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-sm font-medium text-slate-700 hover:text-primary py-1.5 transition-colors"
              >
                {link.label}
              </a>
            ))}
            {onNavigateAdmin && (
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  onNavigateAdmin();
                }}
                className="text-left text-sm font-semibold text-indigo-600 hover:text-indigo-800 py-1.5 transition-colors cursor-pointer"
              >
                Admin Approvals
              </button>
            )}
            <div className="pt-3 border-t border-slate-100 flex flex-col gap-2.5">
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  onNavigateRegister?.();
                }}
                className="text-center text-sm font-medium text-slate-700 hover:text-primary py-2 rounded-md border border-slate-200 cursor-pointer"
              >
                Register
              </button>
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  (onNavigateAdmin || onNavigateRegister)?.();
                }}
                className="text-center text-sm font-semibold text-white bg-primary hover:bg-blue-700 py-2 rounded-lg shadow-sm cursor-pointer"
              >
                Login to Dashboard
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
};
