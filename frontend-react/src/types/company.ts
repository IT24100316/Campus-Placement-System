export interface ActiveJobDrive {
  jobId: string;
  jobTitle: string;
  targetDomain: string;
  jobDescriptionSummary: string;
  internshipType: string[];
  locationCity: string;
  minimumGPA: number;
  allowedYearsOfStudy: number[];
  mandatorySkills: string[];
  niceToHaveSkills: string[];
  preferredDegreePrograms: string[];
  stipendOffered: boolean;
  stipendAmountOrDetails?: string;
  durationMonths: number;
  applicationDeadline: string;
  matchesVerified: number;
  status: string;
}

export interface ShortlistedCandidate {
  id: string;
  initials: string;
  fullName: string;
  university: string;
  degree: string;
  batch: string;
  gpa: number;
  matchedOpening: string;
  matchScore: number;
  competencies: string[];
  status: string;
  statusColor: string;
}

export interface CompanyDashboardData {
  companyId: string;
  companyName: string;
  industry: string;
  contactPersonName: string;
  contactPersonEmail: string;
  phone: string;
  orgCode: string;
  stats: {
    activeJobDrives: number;
    prescreenedStudents: number;
    interviewsScheduled: number;
    partnerUniversityReach: number;
  };
  activeJobs: ActiveJobDrive[];
  shortlistedCandidates: ShortlistedCandidate[];
}
