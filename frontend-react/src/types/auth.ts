export type RegistrationRole = 'hr' | 'staff' | 'student';

export type AccountApprovalStatus = 'Pending' | 'Approved' | 'Rejected';

export interface CompanyHrRegistration {
  fullName: string;
  email: string;
  phone: string;
  companyName: string;
  industry: string;
  password: string;
  confirmPassword: string;
  documentName?: string;
  documentSize?: string;
  documentFile?: File;
}

export interface CompanyStaffRegistration {
  fullName: string;
  email: string;
  phone: string;
  password: string;
  confirmPassword: string;
  companyId: string;
  companyName: string;
  staffId: string;
  jobPosition: string;
}

export interface RegistrationRecord {
  id: string;
  role: RegistrationRole;
  fullName: string;
  email: string;
  phone: string;
  companyName: string;
  industry?: string;
  staffId?: string;
  jobPosition?: string;
  universityName?: string;
  campusIdPhotoUrl?: string;
  documentName?: string;
  documentSize?: string;
  documentUrl?: string;
  status: AccountApprovalStatus;
  submittedAt: string;
  refCode: string;
}

export interface ApprovedCompanyOption {
  id: string;
  name: string;
  industry: string;
}
