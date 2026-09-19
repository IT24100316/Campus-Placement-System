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
  onNavigateAdmin?: () => void;
  onOpenLogin?: () => void;
}

export const LandingPage: React.FC<LandingPageProps> = ({
  onNavigateRegister,
  onNavigateAdmin,
  onOpenLogin,
}) => {
  return (
    <div className="min-h-screen flex flex-col bg-white text-on-surface">
      <Navbar
        onNavigateHome={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
        onNavigateRegister={onNavigateRegister}
        onNavigateAdmin={onNavigateAdmin}
        onOpenLogin={onOpenLogin}
      />
      <main className="flex-1 pt-16">
        <Hero onNavigateRegister={onNavigateRegister} onNavigateLogin={onOpenLogin || onNavigateAdmin} />
        <Metrics />
        <Features />
        <DualAudience onNavigateRegister={onNavigateRegister} />
        <CallToAction onNavigateRegister={onNavigateRegister} />
      </main>
      <Footer />
    </div>
  );
};
