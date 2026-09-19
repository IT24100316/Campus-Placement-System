import React, { useState } from 'react';
import { RegisterForm } from '../components/auth/RegisterForm';
import { PendingApprovalScreen } from '../components/auth/PendingApprovalScreen';
import type { RegistrationRecord } from '../types/auth';
import { Navbar } from '../components/layout/Navbar';
import { Footer } from '../components/layout/Footer';

interface RegisterPageProps {
  onBackToHome: () => void;
  onGoToAdmin: () => void;
  initialPendingRecord?: RegistrationRecord | null;
  onOpenLogin?: () => void;
}

export const RegisterPage: React.FC<RegisterPageProps> = ({
  onBackToHome,
  onGoToAdmin,
  initialPendingRecord = null,
  onOpenLogin,
}) => {
  const [submittedRecord, setSubmittedRecord] = useState<RegistrationRecord | null>(
    initialPendingRecord
  );

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-on-surface">
      <Navbar
        onNavigateHome={onBackToHome}
        onNavigateRegister={() => setSubmittedRecord(null)}
        onNavigateAdmin={onGoToAdmin}
        onOpenLogin={onOpenLogin}
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
