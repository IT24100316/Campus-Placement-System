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
      jobId: 'job-01',
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
      matchesVerified: 62,
      status: 'Active • Accepting',
    },
    {
      jobId: 'job-02',
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
      matchesVerified: 48,
      status: 'Active • Accepting',
    },
    {
      jobId: 'job-03',
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
      matchesVerified: 76,
      status: 'Shortlist Review',
    },
  ],
  shortlistedCandidates: [
    {
      id: 'cand-1',
      initials: 'EL',
      fullName: 'Elena Lin',
      university: 'Carnegie Mellon University',
      degree: 'B.S. Computer Science',
      batch: 'Class of 2026',
      gpa: 3.92,
      matchedOpening: 'Backend Engineering Co-op',
      matchScore: 98,
      competencies: ['Python', 'Distributed DBs', 'Go'],
      status: 'Shortlisted',
      statusColor: 'blue',
    },
    {
      id: 'cand-2',
      initials: 'AK',
      fullName: 'Aarav Kapoor',
      university: 'Georgia Institute of Technology',
      degree: 'M.S. Machine Learning',
      batch: 'Class of 2025',
      gpa: 3.88,
      matchedOpening: 'Associate Machine Learning Engineer',
      matchScore: 96,
      competencies: ['PyTorch', 'CUDA', 'C++'],
      status: 'Pre-screen Cleared',
      statusColor: 'emerald',
    },
    {
      id: 'cand-3',
      initials: 'MA',
      fullName: 'Maya Al-Mansoor',
      university: 'University of Illinois Urbana-Champaign',
      degree: 'B.S. Electrical & Computer Eng',
      batch: 'Class of 2026',
      gpa: 3.79,
      matchedOpening: 'Hardware Systems Intern',
      matchScore: 95,
      competencies: ['Verilog', 'RTOS', 'Firmware'],
      status: 'Interview Confirmed',
      statusColor: 'purple',
    },
  ],
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
};
