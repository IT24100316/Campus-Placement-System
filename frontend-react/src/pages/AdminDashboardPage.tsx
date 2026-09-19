import React from 'react';
import { AdminApprovalsView } from '../components/admin/AdminApprovalsView';
import { Navbar } from '../components/layout/Navbar';
import { Footer } from '../components/layout/Footer';

interface AdminDashboardPageProps {
  onBackToHome: () => void;
  onNavigateRegister: () => void;
}

export const AdminDashboardPage: React.FC<AdminDashboardPageProps> = ({
  onBackToHome,
  onNavigateRegister,
}) => {
  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-on-surface">
      <Navbar
        onNavigateHome={onBackToHome}
        onNavigateRegister={onNavigateRegister}
      />
      <main className="flex-1 pt-20 pb-16">
        <AdminApprovalsView
          onBackToHome={onBackToHome}
          onNavigateRegister={onNavigateRegister}
        />
      </main>
      <Footer />
    </div>
  );
};
