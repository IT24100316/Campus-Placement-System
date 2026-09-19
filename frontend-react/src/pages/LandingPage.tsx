import React from 'react';
import { Navbar } from '../components/layout/Navbar';
import { Hero } from '../components/landing/Hero';
import { Metrics } from '../components/landing/Metrics';
import { Features } from '../components/landing/Features';
import { DualAudience } from '../components/landing/DualAudience';
import { CallToAction } from '../components/landing/CallToAction';
import { Footer } from '../components/layout/Footer';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen flex flex-col bg-white text-on-surface">
      <Navbar />
      <main className="flex-1 pt-16">
        <Hero />
        <Metrics />
        <Features />
        <DualAudience />
        <CallToAction />
      </main>
      <Footer />
    </div>
  );
};
