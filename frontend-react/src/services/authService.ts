import type {
  AccountApprovalStatus,
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
  {
    id: 'reg-init-2',
    role: 'staff',
    fullName: 'David Miller',
    email: 'd.miller@acmeglobal.tech',
    phone: '+1 (555) 345-6789',
    companyName: 'Acme Global Technologies Inc.',
    staffId: 'ACM-STF-1042',
    jobPosition: 'Senior Talent Acquisition Lead',
    status: 'Pending',
    submittedAt: 'Today, 11:15 AM',
    refCode: 'STF-2025-01948',
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
      const parsed: RegistrationRecord[] = JSON.parse(raw);
      // Ensure demo staff account is available if missing
      if (!parsed.some((r) => r.email.toLowerCase() === 'd.miller@acmeglobal.tech')) {
        const withStaff = [...parsed, INITIAL_REGISTRATIONS[1]];
        localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(withStaff));
        return withStaff;
      }
      return parsed;
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
          role: userRecord.role === 'staff' ? 'Company Staff' : 'Company HR',
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
        role: userRecord.role === 'staff' ? 'Company Staff' : 'Company HR',
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
        const roleLabel = data.role === 'CompanyStaff' ? 'Company Staff' : (data.role === 'CompanyHR' ? 'Company HR' : data.role);
        if (data.isPending) {
          const rec: RegistrationRecord = {
            id: data.email,
            role: data.role === 'CompanyStaff' ? 'staff' : 'hr',
            fullName: data.fullName || (data.role === 'CompanyStaff' ? 'Staff Member' : 'Company HR'),
            email: data.email,
            phone: '+1 (555) 000-0000',
            companyName: data.companyName || 'Enterprise Partner',
            staffId: data.staffId,
            jobPosition: data.jobPosition,
            status: 'Pending',
            submittedAt: 'Recently',
            refCode: data.role === 'CompanyStaff' ? 'STF-2025-ONLINE' : 'REG-2025-ONLINE',
          };
          return {
            success: false,
            isPending: true,
            role: roleLabel,
            record: rec,
            message: data.message || 'Your registration application is currently under administrative review.',
          };
        }
        return { success: true, role: roleLabel, message: data.message };
      }
    } catch {
      // Backend offline fallback
    }

    return { success: false, message: 'Invalid corporate or institutional credentials.' };
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

  async registerEmployeeByAdmin(data: {
    fullName: string;
    email: string;
    password?: string;
    companyId?: string;
    companyName?: string;
    staffId: string;
    jobPosition: string;
  }): Promise<{ success: boolean; message: string; record?: RegistrationRecord }> {
    const refCode = `EMP-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;

    try {
      const res = await fetch(`${API_BASE}/admin/register-employee`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fullName: data.fullName,
          email: data.email,
          password: data.password || 'StaffPass@2025!',
          companyId: data.companyId && data.companyId !== 'other' ? data.companyId : null,
          companyName: data.companyName,
          staffId: data.staffId,
          jobPosition: data.jobPosition,
        }),
      });

      const json = await res.json();
      if (!res.ok) {
        return {
          success: false,
          message: json.message || 'Failed to register employee on backend.',
        };
      }

      const newRecord: RegistrationRecord = {
        id: json.userId || (crypto.randomUUID ? crypto.randomUUID() : String(Date.now())),
        role: 'staff',
        fullName: json.fullName || data.fullName,
        email: json.email || data.email,
        phone: '+1 (555) 000-0000',
        companyName: json.companyName || data.companyName || 'Enterprise Employer',
        staffId: json.staffId || data.staffId,
        jobPosition: json.jobPosition || data.jobPosition,
        status: 'Approved',
        submittedAt: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        refCode,
      };

      const current = this.getRegistrations();
      const updated = [newRecord, ...current.filter((r) => r.email.toLowerCase() !== newRecord.email.toLowerCase())];
      localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(updated));

      return {
        success: true,
        message: 'Employee registered and saved to database successfully.',
        record: newRecord,
      };
    } catch {
      // Offline fallback
      const newRecord: RegistrationRecord = {
        id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
        role: 'staff',
        fullName: data.fullName,
        email: data.email,
        phone: '+1 (555) 000-0000',
        companyName: data.companyName || 'Enterprise Employer',
        staffId: data.staffId,
        jobPosition: data.jobPosition,
        status: 'Approved',
        submittedAt: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        refCode,
      };

      const current = this.getRegistrations();
      const updated = [newRecord, ...current];
      localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(updated));

      return {
        success: true,
        message: 'Employee registered locally (backend service unreachable).',
        record: newRecord,
      };
    }
  },

  async syncRegistrationsFromBackend(): Promise<RegistrationRecord[]> {
    try {
      const res = await fetch(`${API_BASE}/admin/pending-approvals`);
      if (res.ok) {
        const backendUsers: any[] = await res.json();
        const mapped: RegistrationRecord[] = backendUsers.map((u) => ({
          id: u.userId,
          role: u.role === 'Company HR' ? 'hr' : 'staff',
          fullName: u.fullName,
          email: u.email,
          phone: u.phone || '+1 (555) 000-0000',
          companyName: u.companyName,
          industry: u.industry,
          staffId: u.staffId,
          jobPosition: u.jobPosition,
          status: u.status as AccountApprovalStatus,
          submittedAt: new Date(u.createdAt).toLocaleDateString() + ' ' + new Date(u.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          refCode: `REG-${u.userId.substring(0, 8).toUpperCase()}`,
        }));

        if (mapped.length > 0) {
          const local = this.getRegistrations();
          const merged = [...mapped];
          for (const item of local) {
            if (!merged.some((m) => m.email.toLowerCase() === item.email.toLowerCase())) {
              merged.push(item);
            }
          }
          localStorage.setItem(STORAGE_KEY_REGISTRATIONS, JSON.stringify(merged));
          return merged;
        }
      }
    } catch {
      // Ignore network errors
    }
    return this.getRegistrations();
  },

  async fetchCompanies(): Promise<ApprovedCompanyOption[]> {
    try {
      const res = await fetch(`${API_BASE}/auth/companies`);
      if (res.ok) {
        const list: any[] = await res.json();
        if (list && list.length > 0) {
          const mapped: ApprovedCompanyOption[] = list.map((c) => ({
            id: c.id,
            name: c.name,
            industry: c.industry || 'Technology',
          }));
          localStorage.setItem(STORAGE_KEY_COMPANIES, JSON.stringify(mapped));
          return mapped;
        }
      }
    } catch {
      // fallback
    }
    return this.getCompanies();
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
