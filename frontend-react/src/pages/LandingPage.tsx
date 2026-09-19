import React from 'react';
import { Navbar } from '../components/layout/Navbar';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen flex flex-col bg-white text-on-surface">
      <Navbar />
      <main className="flex-1 pt-16">
        {/* Sections will be mounted here step by step */}
      </main>
    </div>
  );
};
