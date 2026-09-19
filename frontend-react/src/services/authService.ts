import type {
  ApprovedCompanyOption,
  CompanyHrRegistration,
  CompanyStaffRegistration,
  RegistrationRecord,
} from '../types/auth';

const STORAGE_KEY_REGISTRATIONS = 'campusai_registrations';
const STORAGE_KEY_COMPANIES = 'campusai_approved_companies';

const INITIAL_COMPANIES: ApprovedCompanyOption[] = [
  {
    id: 'acme-001',
    name: 'Acme Global Technologies Inc.',
    industry: 'Software, Cloud & Artificial Intelligence',
  },
  {
    id: 'strata-002',
    name: 'Strata Aerospace Dynamics',
    industry: 'Semiconductor & Hardware',
  },
  {
    id: 'nexus-003',
    name: 'Nexus Quantitative Labs',
    industry: 'Banking, Fintech & Quantitative Trading',
  },
];

const INITIAL_REGISTRATIONS: RegistrationRecord[] = [
  {
    id: 'reg-init-1',
    role: 'hr',
    fullName: 'Clara Vance',
    email: 'c.vance@acmeglobal.tech',
    phone: '+1 (555) 234-5678',
    companyName: 'Acme Global Technologies Inc.',
    industry: 'Software, Cloud & Artificial Intelligence',
    documentName: 'Acme_Incorporation_BR.pdf',
    documentSize: '2.4 MB',
    status: 'Pending',
    submittedAt: 'Today, 10:45 AM',
    refCode: 'REG-2025-08492',
  },
];

const API_BASE = 'http://localhost:5168/api';

export const authService = {
  getRegistrations(): RegistrationRecord[] {
    const raw = localStorage.getItem(STORAGE_KEY_REGISTRATIONS);
    if (!raw) {
      localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(INITIAL_REGISTRATIONS));
      return INITIAL_REGISTRATIONS;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return INITIAL_REGISTRATIONS;
    }
  },

  getCompanies(): ApprovedCompanyOption[] {
    const raw = localStorage.getItem(STORAGE_KEY_COMPANIES);
    if (!raw) {
      localStorage.setItem(STORAGE_KEY_COMPANIES, JSON.stringify(INITIAL_COMPANIES));
      return INITIAL_COMPANIES;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return INITIAL_COMPANIES;
    }
  },

  async login(
    email: string,
    password: string
  ): Promise<{
    success: boolean;
    role?: string;
    isPending?: boolean;
    message?: string;
    record?: RegistrationRecord;
  }> {
    const normalizedEmail = email.trim().toLowerCase();

    // 1. Check for seeded Admin credentials
    if (normalizedEmail === 'admin@campusai.edu' && password === 'Admin@2025') {
      try {
        await fetch(`${API_BASE}/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: normalizedEmail, password }),
        });
      } catch {
        // Backend offline fallback
      }
      return { success: true, role: 'Admin', message: 'Logged in as Institutional Administrator' };
    }

    // 2. Check in registered user records
    const records = this.getRegistrations();
    const userRecord = records.find((r) => r.email.toLowerCase() === normalizedEmail);

    if (userRecord) {
      if (userRecord.status === 'Pending') {
        return {
          success: false,
          isPending: true,
          record: userRecord,
          message: 'Your registration application is currently under administrative review.',
        };
      }
      if (userRecord.status === 'Rejected') {
        return {
          success: false,
          message: 'Your registration application has been declined by the administrator.',
        };
      }
      return {
        success: true,
        role: userRecord.role === 'hr' ? 'Company HR' : 'Company Staff',
        record: userRecord,
        message: 'Welcome back!',
      };
    }

    // 3. Fallback backend call
    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: normalizedEmail, password }),
      });
      if (res.ok) {
        const data = await res.json();
        return { success: true, role: data.role };
      }
    } catch {
      // Backend offline fallback
    }

    return { success: false, message: 'Invalid corporate email or password.' };
  },

  async registerHr(data: CompanyHrRegistration): Promise<RegistrationRecord> {
    const refCode = `REG-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;
    const newRecord: RegistrationRecord = {
      id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
      role: 'hr',
      fullName: data.fullName,
      email: data.email,
      phone: data.phone,
      companyName: data.companyName,
      industry: data.industry,
      documentName: data.documentName || 'Incorporation_Document.pdf',
      documentSize: data.documentSize || '1.8 MB',
      status: 'Pending',
      submittedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      refCode,
    };

    // Try sending to .NET backend API
    try {
      await fetch(`${API_BASE}/auth/register-hr`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fullName: data.fullName,
          email: data.email,
          phone: data.phone,
          companyName: data.companyName,
          industry: data.industry,
          password: data.password,
          businessRegistrationDocumentUrl: data.documentName || 'https://storage.campusai.local/docs/sample_br.pdf',
        }),
      });
    } catch {
      // Backend offline fallback
    }

    const current = this.getRegistrations();
    const updated = [newRecord, ...current];
    localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(updated));

    return newRecord;
  },

  async registerStaff(data: CompanyStaffRegistration): Promise<RegistrationRecord> {
    const refCode = `STF-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;
    const newRecord: RegistrationRecord = {
      id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
      role: 'staff',
      fullName: data.fullName,
      email: data.email,
      phone: data.phone || '+1 (555) 000-0000',
      companyName: data.companyName,
      staffId: data.staffId,
      jobPosition: data.jobPosition,
      status: 'Pending',
      submittedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      refCode,
    };

    // Try sending to .NET backend API
    try {
      await fetch(`${API_BASE}/auth/register-staff`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fullName: data.fullName,
          email: data.email,
          phone: data.phone,
          password: data.password,
          companyId: data.companyId,
          staffId: data.staffId,
          jobPosition: data.jobPosition,
        }),
      });
    } catch {
      // Backend offline fallback
    }

    const current = this.getRegistrations();
    const updated = [newRecord, ...current];
    localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(updated));

    return newRecord;
  },

  updateStatus(id: string, status: 'Approved' | 'Rejected'): RegistrationRecord[] {
    const current = this.getRegistrations();
    const target = current.find((r) => r.id === id);

    const updated = current.map((r) => (r.id === id ? { ...r, status } : r));
    localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(updated));

    // If HR approved, add their company to approved companies list for staff selection!
    if (target && target.role === 'hr' && status === 'Approved') {
      const companies = this.getCompanies();
      const exists = companies.some((c) => c.name.toLowerCase() === target.companyName.toLowerCase());
      if (!exists) {
        companies.push({
          id: target.id,
          name: target.companyName,
          industry: target.industry || 'Enterprise',
        });
        localStorage.setItem(STORAGE_KEY_COMPANIES, JSON.stringify(companies));
      }
    }

    return updated;
  },
};
