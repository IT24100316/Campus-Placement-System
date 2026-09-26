import React, { useState, useEffect, useMemo } from 'react';
import {
  LogOut,
  ShieldCheck,
  Building2,
  Briefcase,
  Users,
  CheckCircle2,
  Sparkles,
  ArrowRight,
  ChevronRight,
  ChevronLeft,
  Filter,
  Download,
  Calendar,
  Bell,
  SlidersHorizontal,
  PlusCircle,
  GraduationCap,
  Menu,
  X,
  Search,
  RotateCcw,
  Eye,
  Trash2,
  Edit,
} from 'lucide-react';
import type { CompanyDashboardData } from '../types/company';
import { companyService } from '../services/companyService';

interface HrLandingPageProps {
  userEmail?: string;
  initialCompanyName?: string;
  highlightedJobId?: string;
  onLogout?: () => void;
  onNavigateHome?: () => void;
  onNavigatePostJob?: () => void;
}

export const HrLandingPage: React.FC<HrLandingPageProps> = ({
  userEmail,
  initialCompanyName,
  highlightedJobId,
  onLogout,
  onNavigateHome,
  onNavigatePostJob,
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [dashboardData, setDashboardData] = useState<CompanyDashboardData | null>(null);
  const [interviewInvited, setInterviewInvited] = useState<Record<string, boolean>>({});

  // --- Active Placement Drives Filtering & Pagination State ---
  const [jobSearchQuery, setJobSearchQuery] = useState('');
  const [jobTypeFilter, setJobTypeFilter] = useState('all');
  const [jobStatusFilter, setJobStatusFilter] = useState('all');
  const [jobSortBy, setJobSortBy] = useState<'default' | 'matches-desc' | 'gpa-desc' | 'deadline-asc'>('default');
  const [jobsCurrentPage, setJobsCurrentPage] = useState(1);
  const [selectedJobDetails, setSelectedJobDetails] = useState<any>(null); // To store job details for view modal
  
  // --- Update Job State ---
  const [editingJob, setEditingJob] = useState<any>(null);
  const [showUpdateConfirmation, setShowUpdateConfirmation] = useState(false);
  
  // --- Delete Job State ---
  const [showDeleteConfirmation, setShowDeleteConfirmation] = useState(false);
  const [jobToDelete, setJobToDelete] = useState<string | null>(null);

  const JOBS_PER_PAGE = 6;

  // If a new job was just published, ensure we are on page 1 with clear filters so it's immediately visible
  useEffect(() => {
    if (highlightedJobId) {
      setJobsCurrentPage(1);
      setJobSearchQuery('');
      setJobTypeFilter('all');
      setJobStatusFilter('all');
      setJobSortBy('default');
    }
  }, [highlightedJobId]);

  // --- Screened Candidates Filtering & Pagination State ---
  const [candidatesSearchQuery, setCandidatesSearchQuery] = useState('');
  const [candidatesOpeningFilter, setCandidatesOpeningFilter] = useState('all');
  const [candidatesDegreeBatchFilter, setCandidatesDegreeBatchFilter] = useState('all');
  const [candidatesMinGpaFilter, setCandidatesMinGpaFilter] = useState<string>('');
  const [candidatesMaxGpaFilter, setCandidatesMaxGpaFilter] = useState<string>('');
  const [candidatesCustomCompetency, setCandidatesCustomCompetency] = useState<string>('');
  const [candidatesStatusFilter, setCandidatesStatusFilter] = useState('all');
  const [candidatesMinMatchScore, setCandidatesMinMatchScore] = useState<string>('');
  const [candidatesMaxMatchScore, setCandidatesMaxMatchScore] = useState<string>('');
  const [candidatesSortBy, setCandidatesSortBy] = useState<'default' | 'gpa-desc' | 'gpa-asc' | 'score-desc' | 'score-asc'>('default');
  const [candidatesPerPage, setCandidatesPerPage] = useState<number>(5);
  const [candidatesCurrentPage, setCandidatesCurrentPage] = useState(1);
  const [isCandidatesFilterOpen, setIsCandidatesFilterOpen] = useState(false);
  const [exportNotice, setExportNotice] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    companyService.getDashboardData(userEmail).then((data) => {
      if (isMounted) {
        setDashboardData(data);
        if (data && data.activeJobs && data.activeJobs.length > 0) {
          const activeJobsSorted = [...data.activeJobs].sort((a, b) => {
            const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            return dateB - dateA;
          });
          setCandidatesOpeningFilter(activeJobsSorted[0].jobTitle);
        }
      }
    });
    return () => {
      isMounted = false;
    };
  }, [userEmail]);

  const confirmDeleteJob = (jobId: string) => {
    setJobToDelete(jobId);
    setShowDeleteConfirmation(true);
  };

  const executeDeleteJob = async () => {
    if (!jobToDelete) return;
    const success = await companyService.deleteJob(jobToDelete);
    if (success && dashboardData) {
      setDashboardData({
        ...dashboardData,
        activeJobs: dashboardData.activeJobs.filter((j) => j.jobId !== jobToDelete),
      });
      alert('Job deleted successfully from database.');
    } else {
      alert('Failed to delete job.');
    }
    setShowDeleteConfirmation(false);
    setJobToDelete(null);
  };

  const handleUpdateJobChange = (field: string, value: any) => {
    if (editingJob) {
      setEditingJob({ ...editingJob, [field]: value });
    }
  };

  const submitUpdateJob = async () => {
    if (!editingJob) return;
    
    // Convert comma separated strings to arrays if needed
    const updatedJobPayload = {
      ...editingJob,
      mandatorySkills: typeof editingJob.mandatorySkills === 'string' 
        ? editingJob.mandatorySkills.split(',').map((s: string) => s.trim()) 
        : editingJob.mandatorySkills,
      niceToHaveSkills: typeof editingJob.niceToHaveSkills === 'string'
        ? editingJob.niceToHaveSkills.split(',').map((s: string) => s.trim())
        : editingJob.niceToHaveSkills,
      allowedYearsOfStudy: typeof editingJob.allowedYearsOfStudy === 'string'
        ? editingJob.allowedYearsOfStudy.split(',').map((s: string) => parseInt(s.trim(), 10)).filter((n: number) => !isNaN(n))
        : editingJob.allowedYearsOfStudy,
    };

    const success = await companyService.updateJob(editingJob.jobId, updatedJobPayload);
    if (success && dashboardData) {
      setDashboardData({
        ...dashboardData,
        activeJobs: dashboardData.activeJobs.map((j) => j.jobId === editingJob.jobId ? { ...j, ...updatedJobPayload } : j),
      });
      setShowUpdateConfirmation(false);
      setEditingJob(null);
      alert('Job updated successfully!');
    } else {
      alert('Failed to update job.');
    }
  };

  const companyName = dashboardData?.companyName || initialCompanyName || 'Virtusa Corporation';
  const orgCode = dashboardData?.orgCode || 'VIR-8821';
  const stats = dashboardData?.stats || {
    activeJobDrives: 4,
    prescreenedStudents: 186,
    interviewsScheduled: 24,
    partnerUniversityReach: 34,
  };
  const activeJobs = useMemo(() => dashboardData?.activeJobs ?? [], [dashboardData?.activeJobs]);
  const candidates = useMemo(() => dashboardData?.shortlistedCandidates ?? [], [dashboardData?.shortlistedCandidates]);

  const handleInvite = (id: string) => {
    setInterviewInvited((prev) => ({ ...prev, [id]: true }));
  };

  const handleExportDossier = () => {
    setExportNotice('Exporting candidate dossier with verified credentials...');
    setTimeout(() => {
      setExportNotice(null);
    }, 3000);
  };

  // --- Placement Drives Filtering & Pagination Logic ---
  const filteredJobs = useMemo(() => {
    let list = [...activeJobs];

    if (jobSearchQuery.trim()) {
      const q = jobSearchQuery.toLowerCase();
      list = list.filter(
        (j) =>
          j.jobTitle.toLowerCase().includes(q) ||
          j.targetDomain.toLowerCase().includes(q) ||
          j.locationCity.toLowerCase().includes(q) ||
          j.mandatorySkills.some((s) => s.toLowerCase().includes(q))
      );
    }

    if (jobTypeFilter !== 'all') {
      list = list.filter((j) =>
        j.internshipType.some((t) => t.toLowerCase().includes(jobTypeFilter.toLowerCase()))
      );
    }

    if (jobStatusFilter !== 'all') {
      list = list.filter((j) =>
        j.status.toLowerCase().includes(jobStatusFilter.toLowerCase())
      );
    }

    if (jobSortBy === 'matches-desc') {
      list.sort((a, b) => b.matchesVerified - a.matchesVerified);
    } else if (jobSortBy === 'gpa-desc') {
      list.sort((a, b) => b.minimumGPA - a.minimumGPA);
    } else if (jobSortBy === 'deadline-asc') {
      list.sort(
        (a, b) => new Date(a.applicationDeadline).getTime() - new Date(b.applicationDeadline).getTime()
      );
    } else {
      // Default: Strictly Latest to Oldest by createdAt descending
      list.sort((a, b) => {
        if (a.createdAt && b.createdAt) {
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        }
        if (a.createdAt && !b.createdAt) return -1;
        if (!a.createdAt && b.createdAt) return 1;
        return 0;
      });
    }

    return list;
  }, [activeJobs, jobSearchQuery, jobTypeFilter, jobStatusFilter, jobSortBy]);

  const totalJobPages = Math.max(1, Math.ceil(filteredJobs.length / JOBS_PER_PAGE));
  const safeJobsPage = Math.min(jobsCurrentPage, totalJobPages);

  const paginatedJobs = useMemo(() => {
    const start = (safeJobsPage - 1) * JOBS_PER_PAGE;
    return filteredJobs.slice(start, start + JOBS_PER_PAGE);
  }, [filteredJobs, safeJobsPage]);

  const activeJobFiltersCount =
    (jobSearchQuery ? 1 : 0) +
    (jobTypeFilter !== 'all' ? 1 : 0) +
    (jobStatusFilter !== 'all' ? 1 : 0) +
    (jobSortBy !== 'default' ? 1 : 0);

  const resetJobFilters = () => {
    setJobSearchQuery('');
    setJobTypeFilter('all');
    setJobStatusFilter('all');
    setJobSortBy('default');
    setJobsCurrentPage(1);
  };

  // --- Candidates Filtering & Pagination Logic ---
  const availableOpenings = useMemo(() => {
    const set = new Set<string>();
    activeJobs.forEach((j) => set.add(j.jobTitle));
    candidates.forEach((c) => set.add(c.matchedOpening));
    return Array.from(set);
  }, [activeJobs, candidates]);

  const availableDegreeBatches = useMemo(() => {
    const set = new Set<string>();
    candidates.forEach((c) => {
      set.add(c.degree);
      set.add(c.batch);
    });
    return Array.from(set);
  }, [candidates]);


  const filteredCandidates = useMemo(() => {
    const filtered = candidates.filter((c) => {
      const isInvited = interviewInvited[c.id];
      const effectiveStatus = isInvited ? 'Interview Invited' : c.status;

      if (candidatesSearchQuery.trim()) {
        const q = candidatesSearchQuery.toLowerCase();
        const matchesName = c.fullName.toLowerCase().includes(q);
        const matchesUni = c.university.toLowerCase().includes(q);
        const matchesDeg = c.degree.toLowerCase().includes(q);
        const matchesBatch = c.batch.toLowerCase().includes(q);
        const matchesOpening = c.matchedOpening.toLowerCase().includes(q);
        const matchesSkills = c.competencies.some((comp) => comp.toLowerCase().includes(q));
        if (!matchesName && !matchesUni && !matchesDeg && !matchesBatch && !matchesOpening && !matchesSkills) {
          return false;
        }
      }

      if (
        candidatesOpeningFilter !== 'all' &&
        c.matchedOpening.toLowerCase() !== candidatesOpeningFilter.toLowerCase()
      ) {
        return false;
      }

      if (candidatesDegreeBatchFilter !== 'all') {
        const target = candidatesDegreeBatchFilter.toLowerCase();
        if (!c.degree.toLowerCase().includes(target) && !c.batch.toLowerCase().includes(target)) {
          return false;
        }
      }

      const minGpa = parseFloat(candidatesMinGpaFilter);
      if (!isNaN(minGpa) && c.gpa < minGpa) {
        return false;
      }
      
      const maxGpa = parseFloat(candidatesMaxGpaFilter);
      if (!isNaN(maxGpa) && c.gpa > maxGpa) {
        return false;
      }

      if (candidatesCustomCompetency.trim() !== '') {
        const requiredSkills = candidatesCustomCompetency.split(',').map(s => s.trim().toLowerCase()).filter(s => s !== '');
        const hasAll = requiredSkills.every(reqSkill => 
          c.competencies.some(comp => comp.toLowerCase().includes(reqSkill))
        );
        if (!hasAll) return false;
      }

      if (candidatesStatusFilter !== 'all') {
        if (effectiveStatus.toLowerCase() !== candidatesStatusFilter.toLowerCase()) {
          return false;
        }
      }

      const minMatch = parseFloat(candidatesMinMatchScore);
      if (!isNaN(minMatch) && c.matchScore < minMatch) {
        return false;
      }
      
      const maxMatch = parseFloat(candidatesMaxMatchScore);
      if (!isNaN(maxMatch) && c.matchScore > maxMatch) {
        return false;
      }

      return true;
    });

    if (candidatesSortBy === 'gpa-desc') {
      filtered.sort((a, b) => Number(b.gpa) - Number(a.gpa));
    } else if (candidatesSortBy === 'gpa-asc') {
      filtered.sort((a, b) => Number(a.gpa) - Number(b.gpa));
    } else if (candidatesSortBy === 'score-desc') {
      filtered.sort((a, b) => b.matchScore - a.matchScore);
    } else if (candidatesSortBy === 'score-asc') {
      filtered.sort((a, b) => a.matchScore - b.matchScore);
    }

    return filtered;
  }, [
    candidates,
    interviewInvited,
    candidatesSearchQuery,
    candidatesOpeningFilter,
    candidatesDegreeBatchFilter,
    candidatesMinGpaFilter,
    candidatesMaxGpaFilter,
    candidatesCustomCompetency,
    candidatesStatusFilter,
    candidatesMinMatchScore,
    candidatesMaxMatchScore,
    candidatesSortBy,
  ]);

  const totalCandidatePages = Math.max(1, Math.ceil(filteredCandidates.length / candidatesPerPage));
  const safeCandidatePage = Math.min(candidatesCurrentPage, totalCandidatePages);

  const paginatedCandidates = useMemo(() => {
    const start = (safeCandidatePage - 1) * candidatesPerPage;
    return filteredCandidates.slice(start, start + candidatesPerPage);
  }, [filteredCandidates, safeCandidatePage, candidatesPerPage]);

  const activeCandidateFiltersCount =
    (candidatesSearchQuery ? 1 : 0) +
    (candidatesOpeningFilter !== 'all' ? 1 : 0) +
    (candidatesDegreeBatchFilter !== 'all' ? 1 : 0) +
    (candidatesMinGpaFilter !== '' ? 1 : 0) +
    (candidatesMaxGpaFilter !== '' ? 1 : 0) +
    (candidatesCustomCompetency.trim() !== '' ? 1 : 0) +
    (candidatesStatusFilter !== 'all' ? 1 : 0) +
    (candidatesMinMatchScore !== '' ? 1 : 0) +
    (candidatesMaxMatchScore !== '' ? 1 : 0) +
    (candidatesSortBy !== 'default' ? 1 : 0);

  const resetCandidateFilters = () => {
    setCandidatesSearchQuery('');
    setCandidatesOpeningFilter('all');
    setCandidatesDegreeBatchFilter('all');
    setCandidatesMinGpaFilter('');
    setCandidatesMaxGpaFilter('');
    setCandidatesCustomCompetency('');
    setCandidatesStatusFilter('all');
    setCandidatesMinMatchScore('');
    setCandidatesMaxMatchScore('');
    setCandidatesSortBy('default');
    setCandidatesCurrentPage(1);
  };

  // Generate initials for avatar badge
  const companyInitials = companyName
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase();

  return (
    <div className="min-h-screen flex flex-col bg-[#f8f9ff] text-[#0b1c30] font-sans selection:bg-blue-100 selection:text-primary">
      {/* -------------------------------------------------------------
          1. Authenticated Navigation Bar (Faithfully matched to UI/HR-LandingPage)
         ------------------------------------------------------------- */}
      <header className="fixed top-0 left-0 right-0 w-full z-50 bg-white/95 backdrop-blur-xl border-b border-slate-200 shadow-[0_1px_8px_rgba(15,23,42,0.04)]">
        <div className="h-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4">
          {/* Brand & Portal Links */}
          <div className="flex items-center gap-6 lg:gap-8">
            <button
              type="button"
              onClick={onNavigateHome}
              className="flex items-center gap-2.5 group focus:outline-none cursor-pointer"
            >
              <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center text-white shadow-sm transition-transform group-hover:scale-105">
                <svg
                  className="w-5 h-5"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M12 2L2 7l10 5 10-5-10-5z" />
                  <path d="M2 17l10 5 10-5" />
                  <path d="M2 12l10 5 10-5" />
                </svg>
              </div>
              <div className="flex flex-col text-left">
                <span className="font-display text-base font-bold text-slate-900 leading-none">
                  CampusAI
                </span>
                <span className="text-[10px] text-primary uppercase tracking-widest font-semibold mt-0.5">
                  Employer Portal
                </span>
              </div>
            </button>

            {/* Desktop Navigation removed as per user request */}
            <nav className="hidden xl:flex items-center gap-1.5">
            </nav>
          </div>

          {/* Recruiter & Company Profile Identity + Admin-Styled Logout */}
          <div className="flex items-center gap-3">
            {/* Registered Company Identity Pill (Fetched from DB) */}
            <div className="hidden sm:flex items-center gap-2.5 px-3 py-1.5 rounded-lg bg-slate-50 border border-slate-200/80 shadow-xs">
              <div className="w-7 h-7 rounded bg-primary text-white flex items-center justify-center text-xs font-bold font-mono">
                {companyInitials || 'CP'}
              </div>
              <div className="flex flex-col text-left leading-tight">
                <div className="flex items-center gap-1">
                  <span className="text-xs font-bold text-slate-900 max-w-[170px] truncate" title={companyName}>
                    {companyName}
                  </span>
                  <CheckCircle2 className="w-3.5 h-3.5 text-primary shrink-0" />
                </div>
                <span className="text-[10px] text-slate-500 truncate max-w-[170px]">
                  {dashboardData?.contactPersonName || userEmail || 'Verified HR Partner'}
                </span>
              </div>
            </div>

            {/* Notification Bell */}
            <button
              type="button"
              className="relative w-8 h-8 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer"
              title="Placement Notifications"
            >
              <Bell className="w-4 h-4" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-primary ring-2 ring-white"></span>
            </button>

            {/* --------------------------------------------------------
                LOGOUT BUTTON: Uses the exact same component styling
                and theme as the Admin dashboard logout button
               -------------------------------------------------------- */}
            <button
              type="button"
              onClick={onLogout}
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-rose-600 hover:text-white hover:bg-rose-600 border border-rose-200 hover:border-rose-600 px-3.5 py-2 rounded-lg transition-all shadow-xs focus:ring-2 focus:ring-rose-200 focus:outline-none cursor-pointer"
              title="Sign out of Employer Session"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Logout</span>
            </button>

            {/* Mobile Menu Toggle */}
            <button
              type="button"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="xl:hidden inline-flex items-center justify-center p-2 rounded-md text-slate-600 hover:text-slate-900 hover:bg-slate-100 focus:outline-none cursor-pointer"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div className="xl:hidden border-b border-slate-200 bg-white px-6 pt-3 pb-6 shadow-lg">
            <div className="flex flex-col space-y-3">
              <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-blue-50/80 border border-blue-100 text-blue-900 text-xs font-semibold">
                <Building2 className="w-4 h-4 text-primary" />
                <span className="font-bold">{companyName}</span>
                <span className="text-[10px] text-blue-600">({orgCode})</span>
              </div>

              <button
                type="button"
                onClick={() => {
                  
                  setMobileMenuOpen(false);
                }}
                className="text-left text-sm font-medium text-slate-700 hover:text-primary py-1.5"
              >
                Dashboard Overview
              </button>
              <button
                type="button"
                onClick={() => {
                  
                  setMobileMenuOpen(false);
                }}
                className="text-left text-sm font-medium text-slate-700 hover:text-primary py-1.5"
              >
                Placement Drives
              </button>
              <button
                type="button"
                onClick={() => {
                  
                  setMobileMenuOpen(false);
                }}
                className="text-left text-sm font-medium text-slate-700 hover:text-primary py-1.5"
              >
                Shortlisted Students
              </button>

              <div className="pt-3 border-t border-slate-100 flex flex-col gap-2">
                <button
                  type="button"
                  onClick={() => {
                    setMobileMenuOpen(false);
                    onLogout?.();
                  }}
                  className="flex items-center justify-center gap-2 text-center text-sm font-semibold text-rose-600 hover:bg-rose-50 border border-rose-200 py-2.5 rounded-lg shadow-xs cursor-pointer transition-colors"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Logout</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </header>

      {/* -------------------------------------------------------------
          2. Main Authenticated Employer Portal Content
         ------------------------------------------------------------- */}
      <main className="w-full pt-16 flex-1">
        <div className="flex flex-col w-full pb-16">


          {/* Welcome Hero & Primary Fast Action Hub */}
          <section className="w-full pt-8 pb-6 px-4 sm:px-6 lg:px-8">
            <div className="max-w-7xl mx-auto flex flex-col gap-6">
              {/* Title & Organization Identity */}
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                  <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-primary text-xs font-semibold uppercase tracking-wider mb-2">
                    <ShieldCheck className="w-4 h-4 text-primary" />
                    Verified Employer Dashboard
                  </div>
                  {/* DYNAMIC TITLE MENTIONING REGISTERED COMPANY NAME FROM DB */}
                  <h1 className="font-display text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 tracking-tight">
                    Welcome back, <span className="text-primary">{companyName}</span>
                  </h1>
                  <p className="text-sm sm:text-base text-slate-600 mt-1 max-w-3xl">
                    Manage your active campus drives, configure position eligibility criteria, and immediately review AI-screened candidate shortlists.
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className="font-mono text-xs text-slate-600 bg-white px-3 py-2 rounded-lg border border-slate-200 shadow-xs flex items-center gap-1.5">
                    <span className="text-slate-400">Org Code:</span>
                    <strong className="text-slate-900 font-bold">{orgCode}</strong>
                  </span>
                </div>
              </div>

              {/* Two High-Visibility Primary Core Action Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mt-1">
                {/* Primary Action A: Post a Job Opportunity */}
                <div className="relative bg-gradient-to-br from-primary to-blue-700 text-white p-6 sm:p-7 rounded-2xl shadow-md flex flex-col justify-between overflow-hidden group">
                  <div className="absolute -right-8 -bottom-8 w-40 h-40 bg-white/10 rounded-full blur-xl pointer-events-none group-hover:scale-125 transition-transform duration-500"></div>
                  <div className="flex flex-col gap-3 relative z-10">
                    <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur-md flex items-center justify-center">
                      <Briefcase className="w-6 h-6 text-white" />
                    </div>
                    <div>
                      <h2 className="font-display text-xl sm:text-2xl font-bold text-white">
                        Post a Job Opportunity
                      </h2>
                      <p className="text-white/85 text-xs sm:text-sm mt-1 leading-relaxed max-w-md">
                        Publish a new internship, co-op, or graduate role. Enforce strict eligibility gating: degree level, graduating batch, verified min GPA, and core competencies.
                      </p>
                    </div>
                  </div>
                  <div className="pt-6 flex items-center justify-between relative z-10">
                    <button
                      type="button"
                      onClick={() => {
                        if (onNavigatePostJob) {
                          onNavigatePostJob();
                        } else {
                          
                        }
                      }}
                      className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-primary font-semibold text-xs sm:text-sm hover:bg-slate-50 transition-all shadow-sm cursor-pointer"
                    >
                      <span>Create Opening</span>
                      <ArrowRight className="w-4 h-4" />
                    </button>
                    <span className="text-xs text-white/80 font-medium">Automated University Push</span>
                  </div>
                </div>

                {/* Primary Action B: View Selected Students */}
                <div className="relative bg-white border-2 border-blue-200 p-6 sm:p-7 rounded-2xl shadow-sm flex flex-col justify-between overflow-hidden hover:border-primary/60 transition-colors group">
                  <div className="flex flex-col gap-3">
                    <div className="flex items-center justify-between">
                      <div className="w-12 h-12 rounded-xl bg-blue-50 text-primary flex items-center justify-center">
                        <Users className="w-6 h-6 text-primary" />
                      </div>
                      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 text-emerald-800 text-xs font-semibold border border-emerald-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                        38 New Matches Ready
                      </span>
                    </div>
                    <div>
                      <h2 className="font-display text-xl sm:text-2xl font-bold text-slate-900">
                        View Selected Students
                      </h2>
                      <p className="text-slate-600 text-xs sm:text-sm mt-1 leading-relaxed max-w-md">
                        Access student applicants pre-screened and filtered by AI against your exact requirements. Zero unqualified resume clutter, 100% verified credentials.
                      </p>
                    </div>
                  </div>
                  <div className="pt-6 flex items-center justify-between">
                    <button
                      type="button"
                      onClick={() => {}}
                      className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-white font-semibold text-xs sm:text-sm hover:bg-blue-700 transition-all shadow-sm cursor-pointer"
                    >
                      <span>Review Shortlisted Pool</span>
                      <CheckCircle2 className="w-4 h-4" />
                    </button>
                    <span className="text-xs text-slate-500 font-medium">Min GPA ≥ 3.5 Verified</span>
                  </div>
                </div>
              </div>

              {/* Real-Time Metrics Row (4 KPI Pods) */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 pt-1">
                <div className="bg-white p-4 sm:p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
                  <div className="w-11 h-11 rounded-lg bg-blue-50 flex items-center justify-center text-primary shrink-0">
                    <Briefcase className="w-5 h-5 text-primary" />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-display text-2xl font-bold text-slate-900 leading-none">
                      {stats.activeJobDrives}
                    </span>
                    <span className="text-xs text-slate-500 font-medium mt-1">Active Job Drives</span>
                  </div>
                </div>

                <div className="bg-white p-4 sm:p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
                  <div className="w-11 h-11 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600 shrink-0">
                    <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-display text-2xl font-bold text-slate-900 leading-none">
                      {stats.prescreenedStudents}
                    </span>
                    <span className="text-xs text-slate-500 font-medium mt-1">Pre-screened Students</span>
                  </div>
                </div>

                <div className="bg-white p-4 sm:p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
                  <div className="w-11 h-11 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600 shrink-0">
                    <Calendar className="w-5 h-5 text-indigo-600" />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-display text-2xl font-bold text-slate-900 leading-none">
                      {stats.interviewsScheduled}
                    </span>
                    <span className="text-xs text-slate-500 font-medium mt-1">Interviews Scheduled</span>
                  </div>
                </div>

                <div className="bg-white p-4 sm:p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
                  <div className="w-11 h-11 rounded-lg bg-purple-50 flex items-center justify-center text-purple-600 shrink-0">
                    <GraduationCap className="w-5 h-5 text-purple-600" />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-display text-2xl font-bold text-slate-900 leading-none">
                      {stats.partnerUniversityReach}
                    </span>
                    <span className="text-xs text-slate-500 font-medium mt-1">Partner University Reach</span>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* -------------------------------------------------------------
              3. Active Placement Drives / Current Openings Section
             ------------------------------------------------------------- */}
          <section className="w-full py-6 px-4 sm:px-6 lg:px-8">
            <div className="max-w-7xl mx-auto flex flex-col gap-4">
              {/* Header with Title & Live Drives Count */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h2 className="font-display text-xl sm:text-2xl font-bold text-slate-900">
                    Active Placement Drives &amp; Openings
                  </h2>
                  <p className="text-xs sm:text-sm text-slate-500 mt-0.5">
                    Manage criteria, monitor auto-screened candidate volume, and invite matched students.
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-semibold text-primary bg-blue-50 px-3 py-1 rounded-full border border-blue-100">
                    Showing {filteredJobs.length} of {activeJobs.length} Active Drives
                  </span>
                  {onNavigatePostJob && (
                    <button
                      type="button"
                      onClick={onNavigatePostJob}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary text-white text-xs font-semibold hover:bg-blue-700 transition-colors shadow-xs cursor-pointer"
                      title="Post a new internship or placement opening"
                    >
                      <PlusCircle className="w-3.5 h-3.5" />
                      <span>Post New Opening</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Filtering & Search Toolbar for Drives */}
              <div className="bg-white p-3 sm:p-4 rounded-xl border border-slate-200 shadow-xs flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
                {/* Search Input */}
                <div className="relative flex-1">
                  <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                  <input
                    type="text"
                    placeholder="Search by role, domain, skills, city..."
                    value={jobSearchQuery}
                    onChange={(e) => {
                      setJobSearchQuery(e.target.value);
                      setJobsCurrentPage(1);
                    }}
                    className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-900 placeholder:text-slate-400 focus:bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all"
                  />
                  {jobSearchQuery && (
                    <button
                      type="button"
                      onClick={() => {
                        setJobSearchQuery('');
                        setJobsCurrentPage(1);
                      }}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 p-0.5"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>

                {/* Filter & Sort Controls */}
                <div className="flex flex-wrap sm:flex-nowrap items-center gap-2">
                  {/* Work / Internship Type */}
                  <select
                    value={jobTypeFilter}
                    onChange={(e) => {
                      setJobTypeFilter(e.target.value);
                      setJobsCurrentPage(1);
                    }}
                    className="pl-3 pr-8 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs font-medium text-slate-700 focus:bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                  >
                    <option value="all">All Work Types</option>
                    <option value="full-time">Full-time</option>
                    <option value="hybrid">Hybrid</option>
                    <option value="on-site">On-site</option>
                  </select>

                  {/* Status Filter */}
                  <select
                    value={jobStatusFilter}
                    onChange={(e) => {
                      setJobStatusFilter(e.target.value);
                      setJobsCurrentPage(1);
                    }}
                    className="pl-3 pr-8 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs font-medium text-slate-700 focus:bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                  >
                    <option value="all">All Statuses</option>
                    <option value="active">Active • Accepting</option>
                    <option value="shortlist">Shortlist Review</option>
                  </select>

                  {/* Sort By */}
                  <select
                    value={jobSortBy}
                    onChange={(e) => {
                      setJobSortBy(e.target.value as typeof jobSortBy);
                      setJobsCurrentPage(1);
                    }}
                    className="pl-3 pr-8 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs font-medium text-slate-700 focus:bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                  >
                    <option value="default">Default (Latest to Oldest)</option>
                    <option value="matches-desc">Matches (High to Low)</option>
                    <option value="gpa-desc">Min GPA (High to Low)</option>
                    <option value="deadline-asc">Deadline (Soonest)</option>
                  </select>

                  {/* Reset Button */}
                  {activeJobFiltersCount > 0 && (
                    <button
                      type="button"
                      onClick={resetJobFilters}
                      className="inline-flex items-center gap-1 px-3 py-2 rounded-lg text-xs font-semibold text-rose-600 hover:bg-rose-50 border border-rose-200 transition-colors shadow-xs cursor-pointer"
                      title="Clear active filters"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      <span>Reset</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Drives Grid (Paginated: 6 items per page) */}
              {paginatedJobs.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                  {paginatedJobs.map((job) => {
                    const isHighlighted = highlightedJobId === job.jobId;
                    const isRecent =
                      isHighlighted ||
                      (job.createdAt
                        ? Date.now() - new Date(job.createdAt).getTime() < 48 * 60 * 60 * 1000
                        : false);

                    return (
                      <div
                        key={job.jobId}
                        className={`rounded-xl p-5 flex flex-col justify-between transition-all group ${
                          isHighlighted
                            ? 'bg-blue-50/30 border-2 border-primary ring-4 ring-primary/15 shadow-md'
                            : 'bg-white border border-slate-200 shadow-xs hover:shadow-md hover:border-blue-200'
                        }`}
                      >
                        <div className="flex flex-col gap-3">
                          <div className="flex items-center justify-between gap-2 flex-wrap">
                            <div className="flex items-center gap-1.5 flex-wrap">
                              <span
                                className={`px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${
                                  job.status.includes('Active')
                                    ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                                    : 'bg-amber-50 text-amber-800 border-amber-200'
                                }`}
                              >
                                {job.status}
                              </span>
                              {isHighlighted ? (
                                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-primary text-white shadow-xs animate-pulse">
                                  <Sparkles className="w-3 h-3" />
                                  Just Posted
                                </span>
                              ) : isRecent ? (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-blue-50 text-primary border border-blue-200">
                                  <Sparkles className="w-2.5 h-2.5" />
                                  New
                                </span>
                              ) : null}
                            </div>
                            <div className="flex items-center gap-1.5 text-right ml-auto">
                              {job.createdAt && (
                                <span className="text-[10px] font-medium text-slate-400">
                                  {(() => {
                                    const diffHours = Math.round(
                                      (Date.now() - new Date(job.createdAt).getTime()) / (1000 * 60 * 60)
                                    );
                                    if (diffHours < 1) return 'Just now';
                                    if (diffHours < 24) return `${diffHours}h ago`;
                                    const diffDays = Math.round(diffHours / 24);
                                    return `${diffDays}d ago`;
                                  })()}
                                  {' • '}
                                </span>
                              )}
                              <span className="font-mono text-xs text-slate-400">
                                {job.internshipType.join(' • ')}
                              </span>
                            </div>
                          </div>

                        <div>
                          <h3 className="font-display text-base font-bold text-slate-900 group-hover:text-primary transition-colors">
                            {job.jobTitle}
                          </h3>
                          <p className="text-xs text-slate-500 mt-0.5 font-medium">{job.targetDomain}</p>
                          <p className="text-[11px] text-slate-500 mt-1.5 line-clamp-2 leading-relaxed">
                            {job.jobDescriptionSummary}
                          </p>
                        </div>

                        {/* Full Structured Job Details */}
                        <div className="grid grid-cols-2 gap-2 pt-2 mt-2 border-t border-slate-100">
                          <div className="flex flex-col gap-0.5">
                            <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Location</span>
                            <span className="text-xs text-slate-700 font-medium flex items-center gap-1">📍 {job.locationCity}</span>
                          </div>
                          <div className="flex flex-col gap-0.5">
                            <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Duration</span>
                            <span className="text-xs text-slate-700 font-medium">⏱️ {job.durationMonths} Months</span>
                          </div>
                          <div className="flex flex-col gap-0.5">
                            <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Compensation</span>
                            <span className="text-xs text-slate-700 font-medium">
                              💰 {job.stipendOffered ? job.stipendAmountOrDetails || 'Paid' : 'Unpaid'}
                            </span>
                          </div>
                          <div className="flex flex-col gap-0.5">
                            <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Deadline</span>
                            <span className="text-xs text-slate-700 font-medium">
                              📅 {new Date(job.applicationDeadline).toLocaleDateString()}
                            </span>
                          </div>
                        </div>

                        {/* Requirements & Skills */}
                        <div className="pt-2 mt-2 border-t border-slate-100">
                          <div className="flex flex-col gap-1.5">
                            <span className="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Key Requirements</span>
                            <div className="flex flex-wrap gap-1.5">
                              <span className="px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-100 text-[10px] font-semibold">
                                Min GPA: {job.minimumGPA}
                              </span>
                              <span className="px-2 py-0.5 rounded bg-purple-50 text-purple-800 border border-purple-100 text-[10px] font-semibold">
                                Year: {job.allowedYearsOfStudy.join(', ')}
                              </span>
                            </div>
                            <div className="flex flex-wrap gap-1.5 mt-1">
                              {job.mandatorySkills.map((s) => (
                                <span
                                  key={s}
                                  className="px-2 py-0.5 rounded bg-blue-50 text-blue-800 border border-blue-100 text-[10px] font-medium"
                                >
                                  {s}
                                </span>
                              ))}
                              {job.niceToHaveSkills.length > 0 && job.niceToHaveSkills.map((s) => (
                                <span
                                  key={`nice-${s}`}
                                  className="px-2 py-0.5 rounded bg-slate-50 text-slate-600 border border-slate-200 text-[10px] font-medium opacity-80"
                                >
                                  {s}
                                </span>
                              ))}
                            </div>
                          </div>
                        </div>

                        <div className="bg-slate-50 p-3 rounded-lg flex items-center justify-between mt-3 border border-slate-100 shadow-inner">
                          <div className="flex flex-col">
                            <span className="font-display text-lg font-bold text-slate-900">
                              {job.matchesVerified}
                            </span>
                            <span className="text-[10px] text-slate-500 font-medium">Matches Verified</span>
                          </div>
                          <span className="text-[11px] text-emerald-600 font-bold bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-100">
                            ✓ 100% Gated Match
                          </span>
                        </div>
                      </div>

                      <div className="pt-4 mt-4 border-t border-slate-100 flex flex-col gap-3">
                        <div className="flex flex-wrap items-center justify-between gap-2">
                          <button
                            type="button"
                            onClick={() => setSelectedJobDetails(job)}
                            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition-colors flex items-center gap-1.5 cursor-pointer shadow-xs"
                            title="View Full Job Details"
                          >
                            <Eye className="w-3.5 h-3.5" />
                            <span>View Details</span>
                          </button>

                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => {
                                setEditingJob({
                                  ...job,
                                  mandatorySkills: job.mandatorySkills.join(', '),
                                  niceToHaveSkills: job.niceToHaveSkills.join(', '),
                                  allowedYearsOfStudy: job.allowedYearsOfStudy.join(', '),
                                  applicationDeadline: new Date(job.applicationDeadline).toISOString().split('T')[0]
                                });
                              }}
                              className="px-2.5 py-1.5 rounded-md bg-blue-50 text-blue-600 hover:bg-blue-100 hover:text-blue-700 font-semibold text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
                              title="Update Criteria"
                            >
                              <Edit className="w-3.5 h-3.5" />
                              <span>Update</span>
                            </button>
                            <button
                              type="button"
                              onClick={() => confirmDeleteJob(job.jobId)}
                              className="px-2.5 py-1.5 rounded-md bg-rose-50 text-rose-600 hover:bg-rose-100 hover:text-rose-700 font-semibold text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
                              title="Delete Drive"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                              <span>Delete</span>
                            </button>
                          </div>
                        </div>

                        <button
                          type="button"
                          onClick={() => {
                            setCandidatesOpeningFilter(job.jobTitle);
                            setIsCandidatesFilterOpen(true);
                            
                            const element = document.getElementById('candidates-section');
                            element?.scrollIntoView({ behavior: 'smooth' });
                          }}
                          className="w-full py-2 bg-slate-900 text-white rounded-lg text-xs font-semibold hover:bg-slate-800 transition-colors flex items-center justify-center gap-1.5 cursor-pointer shadow-sm group"
                        >
                          <span>View Screened Candidates</span>
                          <ArrowRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
                        </button>
                      </div>
                    </div>
                  );
                })}
                </div>
              ) : (
                /* Empty Filter State */
                <div className="bg-white rounded-xl border border-slate-200 p-10 text-center flex flex-col items-center justify-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-blue-50 text-primary flex items-center justify-center">
                    <Search className="w-6 h-6 text-primary" />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900 text-base">No placement drives found</h3>
                    <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
                      No openings match your current search or filter criteria. Try adjusting the keywords or resetting filters.
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={resetJobFilters}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-primary text-white text-xs font-semibold hover:bg-blue-700 transition-colors shadow-xs cursor-pointer"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>Clear All Filters</span>
                  </button>
                </div>
              )}

              {/* Drives Pagination Bar (6 items per page) */}
              {filteredJobs.length > JOBS_PER_PAGE && (
                <div className="bg-white px-4 py-3 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
                  <span className="text-slate-500 font-medium">
                    Showing <strong className="text-slate-900 font-bold">{(safeJobsPage - 1) * JOBS_PER_PAGE + 1}</strong> to{' '}
                    <strong className="text-slate-900 font-bold">
                      {Math.min(safeJobsPage * JOBS_PER_PAGE, filteredJobs.length)}
                    </strong>{' '}
                    of <strong className="text-slate-900 font-bold">{filteredJobs.length}</strong> placement drives
                  </span>

                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      disabled={safeJobsPage <= 1}
                      onClick={() => setJobsCurrentPage((p) => Math.max(1, p - 1))}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer font-semibold"
                    >
                      <ChevronLeft className="w-4 h-4" />
                      <span>Prev</span>
                    </button>

                    {Array.from({ length: totalJobPages }, (_, i) => i + 1).map((page) => (
                      <button
                        key={page}
                        type="button"
                        onClick={() => setJobsCurrentPage(page)}
                        className={`w-8 h-8 rounded-lg text-xs font-bold transition-colors cursor-pointer ${
                          safeJobsPage === page
                            ? 'bg-primary text-white shadow-xs'
                            : 'text-slate-700 hover:bg-slate-100'
                        }`}
                      >
                        {page}
                      </button>
                    ))}

                    <button
                      type="button"
                      disabled={safeJobsPage >= totalJobPages}
                      onClick={() => setJobsCurrentPage((p) => Math.min(totalJobPages, p + 1))}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer font-semibold"
                    >
                      <span>Next</span>
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          </section>

          {/* -------------------------------------------------------------
              4. Candidate Shortlist & AI-Screened Student Queue Table
             ------------------------------------------------------------- */}
          <section id="candidates-section" className="w-full py-6 px-4 sm:px-6 lg:px-8">
            <div className="max-w-7xl mx-auto flex flex-col gap-4">
              {/* Section Header */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="font-display text-xl sm:text-2xl font-bold text-slate-900">
                      Recently Screened &amp; Matched Students
                    </h2>
                    <span className="px-2.5 py-0.5 rounded-full bg-primary/10 text-primary text-xs font-semibold">
                      Strict Gating Enforced
                    </span>
                  </div>
                  <p className="text-xs sm:text-sm text-slate-500 mt-0.5">
                    Pre-verified university candidates meeting 100% of your eligibility thresholds, matched to your specific job openings.
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {/* Toggle Advanced Filters Button */}
                  <button
                    type="button"
                    onClick={() => setIsCandidatesFilterOpen(!isCandidatesFilterOpen)}
                    className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all shadow-xs cursor-pointer border ${
                      isCandidatesFilterOpen || activeCandidateFiltersCount > 0
                        ? 'bg-blue-50 text-primary border-blue-200 ring-1 ring-blue-200'
                        : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <Filter className="w-3.5 h-3.5 text-primary" />
                    <span>Filter Cohort</span>
                    {activeCandidateFiltersCount > 0 && (
                      <span className="w-4 h-4 rounded-full bg-primary text-white text-[10px] flex items-center justify-center font-bold">
                        {activeCandidateFiltersCount}
                      </span>
                    )}
                  </button>

                  {/* Export Dossier Button */}
                  <button
                    type="button"
                    onClick={handleExportDossier}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-white border border-slate-200 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition-colors shadow-xs cursor-pointer"
                  >
                    <Download className="w-3.5 h-3.5 text-slate-500" />
                    <span>Export Dossier</span>
                  </button>
                </div>
              </div>

              {/* Toast Export Notice */}
              {exportNotice && (
                <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-900 flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-primary" />
                  <span>{exportNotice}</span>
                </div>
              )}

              {/* Quick Search Bar */}
              <div className="relative w-full mb-4">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  type="text"
                  placeholder="Quick search by candidate name, university, degree, opening, or skill..."
                  value={candidatesSearchQuery}
                  onChange={(e) => {
                    setCandidatesSearchQuery(e.target.value);
                    setCandidatesCurrentPage(1);
                  }}
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 placeholder:text-slate-400 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none shadow-xs transition-all"
                />
                {candidatesSearchQuery && (
                  <button
                    type="button"
                    onClick={() => {
                      setCandidatesSearchQuery('');
                      setCandidatesCurrentPage(1);
                    }}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Context Header for the current job */}
              {candidatesOpeningFilter !== 'all' && (
                <div className="mb-4 p-4 bg-blue-50 border border-blue-100 rounded-xl flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                      <Briefcase className="w-4 h-4 text-primary" />
                      Showing Candidates for: <span className="text-primary">{candidatesOpeningFilter}</span>
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">
                      {(() => {
                        const relatedJob = dashboardData?.activeJobs.find(j => j.jobTitle === candidatesOpeningFilter);
                        return relatedJob 
                          ? `Posted on ${relatedJob.createdAt ? new Date(relatedJob.createdAt).toLocaleDateString() : 'N/A'}` 
                          : 'Job details available.';
                      })()}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      const relatedJob = dashboardData?.activeJobs.find(j => j.jobTitle === candidatesOpeningFilter);
                      if (relatedJob) setSelectedJobDetails(relatedJob);
                    }}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white border border-blue-200 text-blue-700 hover:bg-blue-100 text-xs font-semibold transition-colors shadow-xs"
                  >
                    <Eye className="w-3.5 h-3.5" />
                    <span>View Job Details</span>
                  </button>
                </div>
              )}

              {/* Advanced Filter Cohort Drawer / Panel */}
              {isCandidatesFilterOpen && (
                <div className="bg-white p-4 sm:p-5 rounded-xl border border-blue-100 bg-blue-50/20 shadow-xs flex flex-col gap-4">
                  <div className="flex items-center justify-between border-b border-slate-200/80 pb-2">
                    <span className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
                      <SlidersHorizontal className="w-3.5 h-3.5 text-primary" />
                      Refine Candidate Cohort
                    </span>
                    {activeCandidateFiltersCount > 0 && (
                      <button
                        type="button"
                        onClick={resetCandidateFilters}
                        className="inline-flex items-center gap-1 text-xs font-semibold text-rose-600 hover:underline cursor-pointer"
                      >
                        <RotateCcw className="w-3 h-3" />
                        <span>Reset All Filters</span>
                      </button>
                    )}
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                    {/* 1. Matched Opening */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        1. Matched Opening
                      </label>
                      <select
                        disabled
                        value={candidatesOpeningFilter}
                        onChange={(e) => {
                          setCandidatesOpeningFilter(e.target.value);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-slate-50 border border-slate-200 text-xs font-medium text-slate-500 cursor-not-allowed opacity-70"
                      >
                        <option value="all">All Placement Drives</option>
                        {availableOpenings.map((op) => (
                          <option key={op} value={op}>
                            {op}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* 2. Degree & Batch */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        2. Degree &amp; Batch
                      </label>
                      <select
                        value={candidatesDegreeBatchFilter}
                        onChange={(e) => {
                          setCandidatesDegreeBatchFilter(e.target.value);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="all">All Degrees &amp; Batches</option>
                        {availableDegreeBatches.map((db) => (
                          <option key={db} value={db}>
                            {db}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* 3. Verified GPA Range */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        3. Verified GPA Range
                      </label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          step="0.01"
                          placeholder="Min"
                          value={candidatesMinGpaFilter}
                          onChange={(e) => { setCandidatesMinGpaFilter(e.target.value); setCandidatesCurrentPage(1); }}
                          className="w-1/2 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
                        />
                        <span className="text-slate-400 text-xs">-</span>
                        <input
                          type="number"
                          step="0.01"
                          placeholder="Max"
                          value={candidatesMaxGpaFilter}
                          onChange={(e) => { setCandidatesMaxGpaFilter(e.target.value); setCandidatesCurrentPage(1); }}
                          className="w-1/2 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
                        />
                      </div>
                    </div>

                    {/* 4. Core Competencies */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600 flex justify-between">
                        <span>4. Core Competencies</span>
                        <span className="text-[9px] text-slate-400 font-normal">(Comma separated)</span>
                      </label>
                      <input
                        type="text"
                        placeholder="e.g. Python, SQL"
                        value={candidatesCustomCompetency}
                        onChange={(e) => { setCandidatesCustomCompetency(e.target.value); setCandidatesCurrentPage(1); }}
                        className="w-full px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
                      />
                    </div>

                    {/* 5. Status */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        5. Candidate Status
                      </label>
                      <select
                        value={candidatesStatusFilter}
                        onChange={(e) => {
                          setCandidatesStatusFilter(e.target.value);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="all">All Statuses</option>
                        <option value="Shortlisted">Shortlisted</option>
                        <option value="Pre-screen Cleared">Pre-screen Cleared</option>
                        <option value="Interview Confirmed">Interview Confirmed</option>
                        <option value="Interview Invited">Interview Invited</option>
                      </select>
                    </div>

                    {/* 6. Match Score Range */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        6. AI Match Score Range
                      </label>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          placeholder="Min %"
                          value={candidatesMinMatchScore}
                          onChange={(e) => { setCandidatesMinMatchScore(e.target.value); setCandidatesCurrentPage(1); }}
                          className="w-1/2 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
                        />
                        <span className="text-slate-400 text-xs">-</span>
                        <input
                          type="number"
                          placeholder="Max %"
                          value={candidatesMaxMatchScore}
                          onChange={(e) => { setCandidatesMaxMatchScore(e.target.value); setCandidatesCurrentPage(1); }}
                          className="w-1/2 px-3 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
                        />
                      </div>
                    </div>

                    {/* 7. Sort By */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        7. Sort Results
                      </label>
                      <select
                        value={candidatesSortBy}
                        onChange={(e) => {
                          setCandidatesSortBy(e.target.value as any);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="default">Default Sort</option>
                        <option value="gpa-desc">GPA: High to Low</option>
                        <option value="gpa-asc">GPA: Low to High</option>
                        <option value="score-desc">Match Score: High to Low</option>
                        <option value="score-asc">Match Score: Low to High</option>
                      </select>
                    </div>
                  </div>
                </div>
              )}

              {/* Verified Candidates Table */}
              <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 text-xs uppercase tracking-wider font-semibold">
                        <th className="py-3 px-4">Candidate &amp; University</th>
                        <th className="py-3 px-4">Degree &amp; Batch</th>
                        <th className="py-3 px-4">Verified GPA</th>
                        {/* HIGH VISIBILITY: SPECIFIC JOB OPENING SCREENED FOR */}
                        <th className="py-3 px-4 bg-blue-50/40 border-l border-r border-blue-100/80">
                          <div className="flex items-center gap-1.5 text-primary">
                            <Briefcase className="w-3.5 h-3.5" />
                            <span>Matched Opening (Screened For)</span>
                          </div>
                        </th>
                        <th className="py-3 px-4">Core Competencies</th>
                        <th className="py-3 px-4 text-center">Resume / CV</th>
                        <th className="py-3 px-4 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-sm text-slate-800">
                      {paginatedCandidates.length > 0 ? (
                        paginatedCandidates.map((c) => {
                          const isInvited = interviewInvited[c.id];
                          return (
                            <tr key={c.id} className="hover:bg-slate-50/80 transition-colors">
                              {/* Candidate & University */}
                              <td className="py-3.5 px-4">
                                <div className="flex items-center gap-3">
                                  <div className="w-9 h-9 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-xs shrink-0 font-mono">
                                    {c.initials}
                                  </div>
                                  <div className="flex flex-col">
                                    <span className="font-semibold text-slate-900">{c.fullName}</span>
                                    <span className="text-slate-500 text-xs flex items-center gap-1 mt-0.5">
                                      <GraduationCap className="w-3 h-3 text-primary shrink-0" />
                                      <span className="font-medium text-slate-700">{c.university}</span>
                                    </span>
                                  </div>
                                </div>
                              </td>

                              {/* Degree & Batch */}
                              <td className="py-3.5 px-4">
                                <span className="font-medium text-slate-900 text-xs">{c.degree}</span>
                                <span className="block text-slate-500 text-[11px] mt-0.5">{c.batch}</span>
                              </td>

                              {/* Verified GPA */}
                              <td className="py-3.5 px-4">
                                <div className="inline-flex items-center gap-1 font-mono text-xs font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                                  <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                                  <span>{c.gpa} / 4.0</span>
                                </div>
                              </td>

                              {/* HIGH VISIBILITY: MATCHED OPENING (SCREENED FOR) */}
                              <td className="py-3.5 px-4 bg-blue-50/20 border-l border-r border-blue-100/60">
                                <div className="flex flex-col gap-1">
                                  <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-blue-50 border border-blue-200/80 text-blue-950 shadow-xs max-w-fit">
                                    <Briefcase className="w-3.5 h-3.5 text-primary shrink-0" />
                                    <strong className="font-bold text-xs text-slate-900 leading-none">
                                      {c.matchedOpening}
                                    </strong>
                                  </div>
                                  <div className="flex items-center gap-1.5 text-[11px] pl-0.5">
                                    <span className="inline-flex items-center gap-0.5 text-primary font-bold">
                                      <Sparkles className="w-3 h-3 text-primary" />
                                      {c.matchScore}% Match
                                    </span>
                                    <span className="text-slate-300">•</span>
                                    <span className="text-emerald-700 font-medium text-[10px]">
                                      Verified Criteria Met
                                    </span>
                                  </div>
                                </div>
                              </td>

                              {/* Competencies */}
                              <td className="py-3.5 px-4">
                                <div className="flex flex-wrap gap-1 max-w-xs">
                                  {c.competencies.map((comp) => (
                                    <span
                                      key={comp}
                                      className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 text-[11px] font-medium"
                                    >
                                      {comp}
                                    </span>
                                  ))}
                                </div>
                              </td>

                              {/* CV / Resume */}
                              <td className="py-3.5 px-4 text-center">
                                <a
                                  href={c.cvPdfUrl || '#'}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-slate-200 text-slate-700 bg-white hover:bg-slate-50 text-[11px] font-semibold transition-colors shadow-xs"
                                >
                                  <Eye className="w-3.5 h-3.5 text-primary" />
                                  <span>Review CV</span>
                                </a>
                              </td>

                              {/* Action */}
                              <td className="py-3.5 px-4 text-right">
                                {isInvited ? (
                                  <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-700">
                                    <CheckCircle2 className="w-3.5 h-3.5" />
                                    <span>Invited</span>
                                  </span>
                                ) : (
                                  <button
                                    type="button"
                                    onClick={() => handleInvite(c.id)}
                                    className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg bg-primary hover:bg-blue-700 text-white text-xs font-semibold transition-all shadow-xs cursor-pointer"
                                  >
                                    <span>Invite to Interview</span>
                                  </button>
                                )}
                              </td>
                            </tr>
                          );
                        })
                      ) : (
                        /* Empty Candidate Filter State */
                        <tr>
                          <td colSpan={7} className="py-10 px-4 text-center">
                            <div className="flex flex-col items-center justify-center gap-2">
                              <Users className="w-8 h-8 text-slate-300" />
                              <span className="font-semibold text-slate-800 text-sm">
                                No shortlisted students match your filters
                              </span>
                              <span className="text-xs text-slate-500 max-w-sm">
                                Try widening your GPA threshold, changing the matched opening, or clearing your search term.
                              </span>
                              <button
                                type="button"
                                onClick={resetCandidateFilters}
                                className="mt-2 inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold text-primary bg-blue-50 hover:bg-blue-100 transition-colors"
                              >
                                <RotateCcw className="w-3 h-3" />
                                <span>Reset Candidate Filters</span>
                              </button>
                            </div>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Table Footer with Configurable Pagination (5 / 10 / 20 items per page) */}
                <div className="bg-slate-50 px-4 py-3 flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-slate-200 text-xs">
                  {/* Left: Item Counter */}
                  <span className="text-slate-500 font-medium">
                    {filteredCandidates.length > 0 ? (
                      <>
                        Showing <strong className="text-slate-900 font-bold">{(safeCandidatePage - 1) * candidatesPerPage + 1}</strong> to{' '}
                        <strong className="text-slate-900 font-bold">
                          {Math.min(safeCandidatePage * candidatesPerPage, filteredCandidates.length)}
                        </strong>{' '}
                        of <strong className="text-slate-900 font-bold">{filteredCandidates.length}</strong> verified applicants
                      </>
                    ) : (
                      '0 applicants found'
                    )}
                  </span>

                  {/* Middle: Configurable Page Size (5 / 10 / 20) */}
                  <div className="flex items-center gap-2">
                    <span className="text-slate-500 text-[11px] font-medium">Per Page:</span>
                    <select
                      value={candidatesPerPage}
                      onChange={(e) => {
                        setCandidatesPerPage(Number(e.target.value));
                        setCandidatesCurrentPage(1);
                      }}
                      className="pl-2.5 pr-8 py-1 rounded-md bg-white border border-slate-200 text-xs font-semibold text-slate-700 focus:border-primary focus:outline-none cursor-pointer"
                    >
                      <option value={5}>5 Candidates</option>
                      <option value={10}>10 Candidates</option>
                      <option value={20}>20 Candidates</option>
                    </select>
                  </div>

                  {/* Right: Pagination Controls */}
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      disabled={safeCandidatePage <= 1}
                      onClick={() => setCandidatesCurrentPage((p) => Math.max(1, p - 1))}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer font-semibold"
                    >
                      <ChevronLeft className="w-3.5 h-3.5" />
                      <span>Prev</span>
                    </button>

                    {Array.from({ length: totalCandidatePages }, (_, i) => i + 1).map((page) => (
                      <button
                        key={page}
                        type="button"
                        onClick={() => setCandidatesCurrentPage(page)}
                        className={`w-7 h-7 rounded-lg text-xs font-bold transition-colors cursor-pointer ${
                          safeCandidatePage === page
                            ? 'bg-primary text-white shadow-xs'
                            : 'text-slate-700 hover:bg-slate-200/70'
                        }`}
                      >
                        {page}
                      </button>
                    ))}

                    <button
                      type="button"
                      disabled={safeCandidatePage >= totalCandidatePages}
                      onClick={() => setCandidatesCurrentPage((p) => Math.min(totalCandidatePages, p + 1))}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer font-semibold"
                    >
                      <span>Next</span>
                      <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </section>


        </div>
      </main>

      {/* -------------------------------------------------------------
          6. Verified Employer Footer (Matching UI/HR-LandingPage)
         ------------------------------------------------------------- */}
      <footer className="w-full bg-white border-t border-slate-200 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 pb-8">
            <div className="md:col-span-2 flex flex-col gap-3">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-lg bg-primary flex items-center justify-center text-white">
                  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M12 2L2 7l10 5 10-5-10-5z" />
                    <path d="M2 17l10 5 10-5" />
                    <path d="M2 12l10 5 10-5" />
                  </svg>
                </div>
                <span className="font-display text-base font-bold text-slate-900">
                  CampusAI for Employers
                </span>
              </div>
              <p className="text-xs text-slate-500 max-w-md leading-relaxed">
                Institutional-grade autonomous university recruitment infrastructure connecting verified external corporate employers with accredited universities nationwide.
              </p>
              <div className="flex items-center gap-2 pt-1">
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-slate-50 text-[11px] font-semibold text-slate-600 border border-slate-200">
                  <CheckCircle2 className="w-3 h-3 text-primary" />
                  SOC2 Type II Certified
                </span>
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-slate-50 text-[11px] font-semibold text-slate-600 border border-slate-200">
                  <ShieldCheck className="w-3 h-3 text-secondary" />
                  FERPA Compliant
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-2 text-xs">
              <span className="font-bold text-slate-900 uppercase tracking-wider mb-1">
                Employer Workspace
              </span>
              <a href="#dashboard" className="text-slate-600 hover:text-primary transition-colors">
                Dashboard Home
              </a>
              <a href="#jobs" className="text-slate-600 hover:text-primary transition-colors">
                Active Placement Drives
              </a>
              <a href="#candidates" className="text-slate-600 hover:text-primary transition-colors">
                Shortlisted Students
              </a>
              <a href="#support" className="text-slate-600 hover:text-primary transition-colors">
                Placement Desk Support
              </a>
            </div>

            <div className="flex flex-col gap-2 text-xs">
              <span className="font-bold text-slate-900 uppercase tracking-wider mb-1">
                Institutional &amp; Security
              </span>
              <span className="text-slate-600">FERPA Compliance Enforced</span>
              <span className="text-slate-600">Placement Directives &amp; Bylaws</span>
              <span className="text-slate-600">Corporate Partnership Agreement</span>
              <span className="text-slate-600">Encrypted Student Dossiers</span>
            </div>
          </div>

          <div className="pt-6 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-500">
            <p>
              © 2026 CampusAI Systems Inc. Logged in as <strong className="text-slate-900">{companyName}</strong> (Verified Corporate Partner). All rights reserved.
            </p>
            <span className="text-[11px] text-slate-400">
              Data Tier: Institutional High-Availability (PostgreSQL Live)
            </span>
          </div>
        </div>
      </footer>

      {/* -------------------------------------------------------------
          Job Details Modal
         ------------------------------------------------------------- */}
      {selectedJobDetails && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col animate-in fade-in zoom-in duration-200">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
              <div>
                <h2 className="text-xl font-display font-bold text-slate-900">
                  {selectedJobDetails.jobTitle}
                </h2>
                <p className="text-sm text-slate-500 font-medium mt-0.5 flex items-center gap-2">
                  <span>{selectedJobDetails.targetDomain}</span>
                  <span>•</span>
                  <span className="flex items-center gap-1">📍 {selectedJobDetails.locationCity}</span>
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelectedJobDetails(null)}
                className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-full transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto flex-1 space-y-6">
              
              {/* Top Overview Cards */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Duration</span>
                  <div className="text-sm font-semibold text-slate-900 mt-0.5">{selectedJobDetails.durationMonths} Months</div>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Compensation</span>
                  <div className="text-sm font-semibold text-slate-900 mt-0.5">{selectedJobDetails.stipendOffered ? selectedJobDetails.stipendAmountOrDetails || 'Paid' : 'Unpaid'}</div>
                </div>
                <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                  <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Deadline</span>
                  <div className="text-sm font-semibold text-slate-900 mt-0.5">{new Date(selectedJobDetails.applicationDeadline).toLocaleDateString()}</div>
                </div>
                <div className="bg-emerald-50 p-3 rounded-xl border border-emerald-100">
                  <span className="text-[10px] uppercase font-bold tracking-wider text-emerald-600">Matches Verified</span>
                  <div className="text-sm font-bold text-emerald-700 mt-0.5">{selectedJobDetails.matchesVerified} 100% Matches</div>
                </div>
              </div>

              {/* Description Section */}
              <section>
                <h3 className="text-sm font-bold text-slate-900 mb-2 flex items-center gap-1.5">
                  <Briefcase className="w-4 h-4 text-primary" />
                  Role Summary
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed bg-slate-50 p-4 rounded-xl border border-slate-100">
                  {selectedJobDetails.jobDescriptionSummary}
                </p>
              </section>

              {/* Requirements Grid */}
              <div className="grid md:grid-cols-2 gap-6">
                <section>
                  <h3 className="text-sm font-bold text-slate-900 mb-3 flex items-center gap-1.5">
                    <CheckCircle2 className="w-4 h-4 text-primary" />
                    Strict Gating Requirements
                  </h3>
                  <ul className="space-y-3">
                    <li className="flex flex-col gap-1">
                      <span className="text-xs text-slate-500 font-medium">Minimum Required GPA</span>
                      <div className="flex items-center gap-2">
                        <span className="px-2.5 py-1 rounded bg-amber-50 text-amber-800 border border-amber-100 text-xs font-bold">
                          {selectedJobDetails.minimumGPA} or higher
                        </span>
                      </div>
                    </li>
                    <li className="flex flex-col gap-1">
                      <span className="text-xs text-slate-500 font-medium">Allowed Years of Study</span>
                      <div className="flex items-center gap-2">
                        <span className="px-2.5 py-1 rounded bg-purple-50 text-purple-800 border border-purple-100 text-xs font-bold">
                          Year {selectedJobDetails.allowedYearsOfStudy.join(', ')}
                        </span>
                      </div>
                    </li>
                    <li className="flex flex-col gap-1">
                      <span className="text-xs text-slate-500 font-medium">Preferred Degree Programs</span>
                      <div className="flex flex-wrap gap-1.5">
                        {selectedJobDetails.preferredDegreePrograms.length > 0 ? selectedJobDetails.preferredDegreePrograms.map((deg: string) => (
                          <span key={deg} className="px-2 py-1 rounded bg-slate-100 text-slate-700 border border-slate-200 text-xs font-medium">
                            {deg}
                          </span>
                        )) : <span className="text-xs text-slate-400">Any matching degree</span>}
                      </div>
                    </li>
                  </ul>
                </section>

                <section>
                  <h3 className="text-sm font-bold text-slate-900 mb-3 flex items-center gap-1.5">
                    <Sparkles className="w-4 h-4 text-primary" />
                    Required Competencies
                  </h3>
                  <div className="space-y-4">
                    <div>
                      <span className="text-xs text-slate-500 font-medium block mb-2">Mandatory Skills</span>
                      <div className="flex flex-wrap gap-1.5">
                        {selectedJobDetails.mandatorySkills.map((s: string) => (
                          <span key={s} className="px-2.5 py-1 rounded bg-blue-50 text-blue-800 border border-blue-100 text-xs font-semibold">
                            {s}
                          </span>
                        ))}
                      </div>
                    </div>
                    <div>
                      <span className="text-xs text-slate-500 font-medium block mb-2">Nice-to-Have Skills</span>
                      <div className="flex flex-wrap gap-1.5">
                        {selectedJobDetails.niceToHaveSkills.length > 0 ? selectedJobDetails.niceToHaveSkills.map((s: string) => (
                          <span key={`nice-${s}`} className="px-2.5 py-1 rounded bg-slate-50 text-slate-600 border border-slate-200 text-xs font-medium">
                            {s}
                          </span>
                        )) : <span className="text-xs text-slate-400 italic">None specified</span>}
                      </div>
                    </div>
                  </div>
                </section>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-end gap-3 bg-slate-50">
              <button
                type="button"
                onClick={() => setSelectedJobDetails(null)}
                className="px-4 py-2 rounded-lg text-slate-700 text-sm font-bold hover:bg-slate-200 transition-colors cursor-pointer"
              >
                Close
              </button>
              <button
                type="button"
                onClick={() => {
                  setCandidatesOpeningFilter(selectedJobDetails.jobTitle);
                  setIsCandidatesFilterOpen(true);
                  
                  setSelectedJobDetails(null);
                  const element = document.getElementById('candidates-section');
                  element?.scrollIntoView({ behavior: 'smooth' });
                }}
                className="px-4 py-2 rounded-lg bg-primary text-white text-sm font-bold hover:bg-blue-700 transition-colors shadow-md cursor-pointer flex items-center gap-1.5"
              >
                View Screened Candidates
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* -------------------------------------------------------------
          Update Job Modal
         ------------------------------------------------------------- */}
      {editingJob && !showUpdateConfirmation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col animate-in fade-in zoom-in duration-200">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
              <h2 className="text-xl font-display font-bold text-slate-900">
                Update Job Drive: {editingJob.jobTitle}
              </h2>
              <button
                type="button"
                onClick={() => setEditingJob(null)}
                className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-full transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 overflow-y-auto flex-1 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Job Title</label>
                  <input type="text" value={editingJob.jobTitle} onChange={(e) => handleUpdateJobChange('jobTitle', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Target Domain</label>
                  <input type="text" value={editingJob.targetDomain} onChange={(e) => handleUpdateJobChange('targetDomain', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Job Description Summary</label>
                  <textarea rows={3} value={editingJob.jobDescriptionSummary} onChange={(e) => handleUpdateJobChange('jobDescriptionSummary', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm"></textarea>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Location City</label>
                  <input type="text" value={editingJob.locationCity} onChange={(e) => handleUpdateJobChange('locationCity', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Application Deadline</label>
                  <input type="date" value={editingJob.applicationDeadline} onChange={(e) => handleUpdateJobChange('applicationDeadline', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Minimum GPA</label>
                  <input type="number" step="0.01" value={editingJob.minimumGPA} onChange={(e) => handleUpdateJobChange('minimumGPA', parseFloat(e.target.value))} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Allowed Years of Study (comma separated)</label>
                  <input type="text" value={editingJob.allowedYearsOfStudy} onChange={(e) => handleUpdateJobChange('allowedYearsOfStudy', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Mandatory Skills (comma separated)</label>
                  <input type="text" value={editingJob.mandatorySkills} onChange={(e) => handleUpdateJobChange('mandatorySkills', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs font-semibold text-slate-700 mb-1">Nice-to-Have Skills (comma separated)</label>
                  <input type="text" value={editingJob.niceToHaveSkills} onChange={(e) => handleUpdateJobChange('niceToHaveSkills', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm" />
                </div>
              </div>
            </div>

            <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-end gap-3 bg-slate-50">
              <button
                type="button"
                onClick={() => setEditingJob(null)}
                className="px-4 py-2 rounded-lg text-slate-700 text-sm font-bold hover:bg-slate-200 transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => setShowUpdateConfirmation(true)}
                className="px-4 py-2 rounded-lg bg-blue-600 text-white text-sm font-bold hover:bg-blue-700 transition-colors shadow-md cursor-pointer"
              >
                Review Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* -------------------------------------------------------------
          Update Confirmation Modal
         ------------------------------------------------------------- */}
      {showUpdateConfirmation && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-md">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
                  <ShieldCheck className="w-5 h-5 text-amber-600" />
                </div>
                <h3 className="text-lg font-bold text-slate-900">Confirm Job Update</h3>
              </div>
              
              <div className="bg-amber-50/50 border border-amber-200/60 rounded-xl p-4 mb-6">
                <div className="flex gap-3">
                  <div className="mt-0.5">
                    <Sparkles className="w-4 h-4 text-amber-500" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-amber-900 mb-1">
                      CampusAI Pipeline Impact
                    </h4>
                    <p className="text-xs text-amber-800/80 leading-relaxed font-medium">
                      Modifying strict criteria (like GPA or Skills) will cause CampusAI to instantly re-score and re-qualify all current candidates.
                    </p>
                  </div>
                </div>
              </div>

              <p className="text-sm font-semibold text-slate-700 mb-6 text-center">
                Are you sure you want to apply these updates?
              </p>

              <div className="flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowUpdateConfirmation(false)}
                  className="px-4 py-2 rounded-lg text-slate-700 text-sm font-bold hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  Back to Editing
                </button>
                <button
                  type="button"
                  onClick={submitUpdateJob}
                  className="px-4 py-2 rounded-lg bg-amber-500 text-white text-sm font-bold hover:bg-amber-600 transition-colors shadow-md cursor-pointer flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  Apply Updates
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* -------------------------------------------------------------
          Delete Confirmation Modal
         ------------------------------------------------------------- */}
      {showDeleteConfirmation && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-md">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-rose-100 flex items-center justify-center flex-shrink-0">
                  <Trash2 className="w-5 h-5 text-rose-600" />
                </div>
                <h3 className="text-lg font-bold text-slate-900">Confirm Job Deletion</h3>
              </div>
              
              <div className="bg-rose-50/50 border border-rose-200/60 rounded-xl p-4 mb-6">
                <div className="flex gap-3">
                  <div className="mt-0.5">
                    <Trash2 className="w-4 h-4 text-rose-500" />
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-rose-900 mb-1">
                      CampusAI Pipeline Impact
                    </h4>
                    <p className="text-xs text-rose-800/80 leading-relaxed font-medium">
                      Deleting this active job opportunity will permanently remove it and all associated matched candidate flows from the platform. This action cannot be undone.
                    </p>
                  </div>
                </div>
              </div>

              <p className="text-sm font-semibold text-slate-700 mb-6 text-center">
                Are you sure you want to permanently delete this drive?
              </p>

              <div className="flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setShowDeleteConfirmation(false);
                    setJobToDelete(null);
                  }}
                  className="px-4 py-2 rounded-lg text-slate-700 text-sm font-bold hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={executeDeleteJob}
                  className="px-4 py-2 rounded-lg bg-rose-500 text-white text-sm font-bold hover:bg-rose-600 transition-colors shadow-md cursor-pointer flex items-center gap-1.5"
                >
                  <Trash2 className="w-4 h-4" />
                  Delete Drive
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
