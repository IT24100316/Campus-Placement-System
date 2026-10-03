import type { CompanyDashboardData } from '../types/company';

const API_BASE = 'http://localhost:5168/api';

const DEFAULT_DASHBOARD_DATA: CompanyDashboardData = {
  companyId: 'vir-default-1',
  companyName: 'Virtusa Corporation',
  industry: 'Information Technology & Digital Engineering',
  contactPersonName: 'Virtusa Campus Recruitment',
  contactPersonEmail: 'virtusa@company.com',
  phone: '+1 (555) 482-1920',
  orgCode: 'VIR-8821',
  stats: {
    activeJobDrives: 4,
    prescreenedStudents: 186,
    interviewsScheduled: 24,
    partnerUniversityReach: 34,
  },
  activeJobs: [
    {
      jobId: '22222222-2222-2222-2222-222222222222',
      jobTitle: 'Backend Engineering Co-op',
      targetDomain: 'Distributed Systems & APIs • 6 Months',
      jobDescriptionSummary: 'Build and scale high-throughput cloud microservices.',
      internshipType: ['Full-time', 'Hybrid'],
      locationCity: 'San Jose, CA',
      minimumGPA: 3.5,
      allowedYearsOfStudy: [3, 4],
      mandatorySkills: ['Python', 'Go', 'PostgreSQL'],
      niceToHaveSkills: ['Docker', 'Kubernetes'],
      preferredDegreePrograms: ['B.S. Computer Science'],
      stipendOffered: true,
      stipendAmountOrDetails: '$45 / hr',
      durationMonths: 6,
      applicationDeadline: '2026-04-15',
      createdAt: '2026-09-18T10:00:00.000Z',
      matchesVerified: 62,
      status: 'Active • Accepting',
    },
    {
      jobId: '33333333-3333-3333-3333-333333333333',
      jobTitle: 'Associate Machine Learning Engineer',
      targetDomain: 'AI Infrastructure • Class of 2025',
      jobDescriptionSummary: 'Train and deploy deep learning models and agentic workflows.',
      internshipType: ['Full-time'],
      locationCity: 'Austin, TX',
      minimumGPA: 3.6,
      allowedYearsOfStudy: [4],
      mandatorySkills: ['PyTorch', 'CUDA', 'Python'],
      niceToHaveSkills: ['FastAPI', 'LangChain'],
      preferredDegreePrograms: ['M.S. Machine Learning', 'B.S. CS'],
      stipendOffered: true,
      stipendAmountOrDetails: '$55 / hr',
      durationMonths: 6,
      applicationDeadline: '2026-03-31',
      createdAt: '2026-09-17T10:00:00.000Z',
      matchesVerified: 48,
      status: 'Active • Accepting',
    },
    {
      jobId: '44444444-4444-4444-4444-444444444444',
      jobTitle: 'Hardware Systems Intern',
      targetDomain: 'Embedded Firmware • Summer 2026',
      jobDescriptionSummary: 'Firmware development on ARM Cortex microcontrollers.',
      internshipType: ['Full-time', 'On-site'],
      locationCity: 'Boston, MA',
      minimumGPA: 3.4,
      allowedYearsOfStudy: [3, 4],
      mandatorySkills: ['C++', 'Verilog', 'RTOS'],
      niceToHaveSkills: ['Linux', 'SPI/I2C'],
      preferredDegreePrograms: ['B.S. Electrical & Computer Eng'],
      stipendOffered: true,
      stipendAmountOrDetails: '$40 / hr',
      durationMonths: 4,
      applicationDeadline: '2026-05-01',
      createdAt: '2026-09-16T10:00:00.000Z',
      matchesVerified: 76,
      status: 'Shortlist Review',
    },
  ],
  shortlistedCandidates: [],
};

export const companyService = {
  async getDashboardData(email?: string): Promise<CompanyDashboardData> {
    const targetEmail = email?.trim().toLowerCase() || 'virtusa@company.com';

    try {
      const url = `${API_BASE}/company/profile?email=${encodeURIComponent(targetEmail)}`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        return data as CompanyDashboardData;
      }
    } catch {
      // Backend offline fallback
    }

    // Dynamic fallback customized with known company names if offline
    let derivedName = 'Virtusa Corporation';
    if (targetEmail.includes('pasi')) derivedName = 'Pasi Tech Global';
    if (targetEmail.includes('acme')) derivedName = 'Acme Global Technologies Inc.';

    return {
      ...DEFAULT_DASHBOARD_DATA,
      companyName: derivedName,
      contactPersonEmail: targetEmail,
      orgCode: derivedName.substring(0, 3).toUpperCase() + '-8821',
    };
  },

  async deleteJob(jobId: string): Promise<boolean> {
    try {
      const url = `${API_BASE}/company/jobs/${jobId}`;
      const res = await fetch(url, { method: 'DELETE' });
      return res.ok;
    } catch {
      return false;
    }
  },

  async updateJob(jobId: string, updatedJob: any): Promise<boolean> {
    try {
      const url = `${API_BASE}/company/jobs/${jobId}`;
      const res = await fetch(url, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(updatedJob),
      });
      return res.ok;
    } catch {
      return false;
    }
  },

  async scheduleInterview(studentId: string, jobId: string, interviewDate: string, interviewTime: string, meetingLink?: string): Promise<boolean> {
    try {
      const url = `${API_BASE}/interviews/schedule`;
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          studentId,
          jobId,
          interviewDate,
          interviewTime,
          meetingLink
        }),
      });
      return res.ok;
    } catch {
      return false;
    }
  },

  async updateProfile(companyId: string, data: {
    companyName: string;
    industry: string;
    contactPersonName: string;
    contactPersonEmail: string;
    phone: string;
  }): Promise<{ success: boolean; message: string }> {
    try {
      const url = `${API_BASE}/company/profile/${companyId}`;
      const res = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      const json = await res.json().catch(() => ({}));
      return { success: res.ok, message: json.message || (res.ok ? 'Updated' : 'Failed') };
    } catch {
      return { success: false, message: 'Network error' };
    }
  },

  async deleteProfile(companyId: string): Promise<{ success: boolean; message: string }> {
    try {
      const url = `${API_BASE}/company/profile/${companyId}`;
      const res = await fetch(url, { method: 'DELETE' });
      const json = await res.json().catch(() => ({}));
      return { success: res.ok, message: json.message || (res.ok ? 'Deleted' : 'Failed') };
    } catch {
      return { success: false, message: 'Network error' };
    }
  },
};
