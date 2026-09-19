import React, { useState } from 'react';
import { RegisterForm } from '../components/auth/RegisterForm';
import { PendingApprovalScreen } from '../components/auth/PendingApprovalScreen';
import type { RegistrationRecord } from '../types/auth';
import { Navbar } from '../components/layout/Navbar';
import { Footer } from '../components/layout/Footer';

interface RegisterPageProps {
  onBackToHome: () => void;
  onGoToAdmin: () => void;
}

export const RegisterPage: React.FC<RegisterPageProps> = ({ onBackToHome, onGoToAdmin }) => {
  const [submittedRecord, setSubmittedRecord] = useState<RegistrationRecord | null>(null);

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-on-surface">
      <Navbar />

      <main className="flex-1 pt-20 pb-16">
        {!submittedRecord ? (
          <RegisterForm
            onSuccess={(record) => setSubmittedRecord(record)}
            onNavigateLogin={onBackToHome}
          />
        ) : (
          <PendingApprovalScreen
            record={submittedRecord}
            onBackHome={onBackToHome}
            onRegisterAnother={() => setSubmittedRecord(null)}
            onGoToAdmin={onGoToAdmin}
          />
        )}
      </main>

      <Footer />
    </div>
  );
};
