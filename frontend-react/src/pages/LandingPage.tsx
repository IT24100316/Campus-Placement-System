import React from 'react';
import { Navbar } from '../components/layout/Navbar';
import { Hero } from '../components/landing/Hero';
import { Metrics } from '../components/landing/Metrics';
import { Features } from '../components/landing/Features';
import { DualAudience } from '../components/landing/DualAudience';
import { CallToAction } from '../components/landing/CallToAction';
import { Footer } from '../components/layout/Footer';

interface LandingPageProps {
  onNavigateRegister?: () => void;
  onOpenLogin?: () => void;
  onNavigateAdmin?: () => void;
  isAdmin?: boolean;
  onLogout?: () => void;
  userEmail?: string;
}

export const LandingPage: React.FC<LandingPageProps> = ({
  onNavigateRegister,
  onOpenLogin,
  onNavigateAdmin,
  isAdmin,
  onLogout,
  userEmail,
}) => {
  return (
    <div className="min-h-screen flex flex-col bg-white text-on-surface">
      <Navbar
        onNavigateHome={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
        onNavigateRegister={onNavigateRegister}
        onOpenLogin={onOpenLogin}
        onNavigateAdmin={onNavigateAdmin}
        isAdmin={isAdmin}
        onLogout={onLogout}
        userEmail={userEmail}
      />
      <main className="flex-1 pt-16">
        <Hero onNavigateRegister={onNavigateRegister} onNavigateLogin={onOpenLogin} />
        <Metrics />
        <Features />
        <DualAudience onNavigateRegister={onNavigateRegister} />
        <CallToAction onNavigateRegister={onNavigateRegister} />
      </main>
      <Footer />
    </div>
  );
};
