import React, { useState } from 'react';
import { RegisterForm } from '../components/auth/RegisterForm';
import { PendingApprovalScreen } from '../components/auth/PendingApprovalScreen';
import type { RegistrationRecord } from '../types/auth';
import { Navbar } from '../components/layout/Navbar';
import { Footer } from '../components/layout/Footer';

interface RegisterPageProps {
  onBackToHome: () => void;
  initialPendingRecord?: RegistrationRecord | null;
  onOpenLogin?: () => void;
  isAdmin?: boolean;
  onLogout?: () => void;
  userEmail?: string;
}

export const RegisterPage: React.FC<RegisterPageProps> = ({
  onBackToHome,
  initialPendingRecord = null,
  onOpenLogin,
  isAdmin,
  onLogout,
  userEmail,
}) => {
  const [submittedRecord, setSubmittedRecord] = useState<RegistrationRecord | null>(
    initialPendingRecord
  );

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-on-surface">
      <Navbar
        onNavigateHome={onBackToHome}
        onNavigateRegister={() => setSubmittedRecord(null)}
        onOpenLogin={onOpenLogin}
        isAdmin={isAdmin}
        onLogout={onLogout}
        userEmail={userEmail}
      />

      <main className="flex-1 pt-20 pb-16">
        {!submittedRecord ? (
          <RegisterForm
            onSuccess={(record) => setSubmittedRecord(record)}
            onNavigateLogin={onOpenLogin || onBackToHome}
          />
        ) : (
          <PendingApprovalScreen
            record={submittedRecord}
            onBackHome={onBackToHome}
            onRegisterAnother={() => setSubmittedRecord(null)}
          />
        )}
      </main>

      <Footer />
    </div>
  );
};
