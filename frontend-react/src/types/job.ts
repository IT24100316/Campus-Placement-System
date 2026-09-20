export interface TargetDomain {
  id: number;
  name: string;
  description?: string;
  titleCount: number;
}

export interface JobTitle {
  id: number;
  title: string;
  targetDomainId: number;
  targetDomainName: string;
}

export type InternshipTypeOption = 'OnSite' | 'Hybrid' | 'Remote';

export interface CreateJobPayload {
  companyId?: string;
  recruiterEmail?: string;
  targetDomain: string;
  targetDomainId?: number;
  jobTitle: string;
  jobTitleId?: number;
  jobDescriptionSummary: string;
  internshipType: string;
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
}

export interface JobResponse {
  jobId: string;
  companyId: string;
  companyName: string;
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
