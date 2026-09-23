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
  MessageSquare,
  Bell,
  SlidersHorizontal,
  PlusCircle,
  GraduationCap,
  Menu,
  X,
  Search,
  RotateCcw,
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
  onNavigateApplications?: () => void;
}

export const HrLandingPage: React.FC<HrLandingPageProps> = ({
  userEmail,
  initialCompanyName,
  highlightedJobId,
  onLogout,
  onNavigateHome,
  onNavigatePostJob,
  onNavigateApplications,
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [dashboardData, setDashboardData] = useState<CompanyDashboardData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [interviewInvited, setInterviewInvited] = useState<Record<string, boolean>>({});
  const [activeTab, setActiveTab] = useState<'dashboard' | 'jobs' | 'candidates'>('dashboard');

  // --- Active Placement Drives Filtering & Pagination State ---
  const [jobSearchQuery, setJobSearchQuery] = useState('');
  const [jobTypeFilter, setJobTypeFilter] = useState('all');
  const [jobStatusFilter, setJobStatusFilter] = useState('all');
  const [jobSortBy, setJobSortBy] = useState<'default' | 'matches-desc' | 'gpa-desc' | 'deadline-asc'>('default');
  const [jobsCurrentPage, setJobsCurrentPage] = useState(1);
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
  const [candidatesMinGpaFilter, setCandidatesMinGpaFilter] = useState<number>(0);
  const [candidatesCompetencyFilter, setCandidatesCompetencyFilter] = useState('all');
  const [candidatesStatusFilter, setCandidatesStatusFilter] = useState('all');
  const [candidatesMinMatchScore, setCandidatesMinMatchScore] = useState<number>(0);
  const [candidatesPerPage, setCandidatesPerPage] = useState<number>(5);
  const [candidatesCurrentPage, setCandidatesCurrentPage] = useState(1);
  const [isCandidatesFilterOpen, setIsCandidatesFilterOpen] = useState(false);
  const [exportNotice, setExportNotice] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    setIsLoading(true);
    companyService.getDashboardData(userEmail).then((data) => {
      if (isMounted) {
        setDashboardData(data);
        setIsLoading(false);
      }
    });
    return () => {
      isMounted = false;
    };
  }, [userEmail]);

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

  const availableCompetencies = useMemo(() => {
    const set = new Set<string>();
    candidates.forEach((c) => c.competencies.forEach((comp) => set.add(comp)));
    return Array.from(set).sort();
  }, [candidates]);

  const filteredCandidates = useMemo(() => {
    return candidates.filter((c) => {
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

      if (candidatesMinGpaFilter > 0 && c.gpa < candidatesMinGpaFilter) {
        return false;
      }

      if (candidatesCompetencyFilter !== 'all') {
        const skill = candidatesCompetencyFilter.toLowerCase();
        if (!c.competencies.some((comp) => comp.toLowerCase() === skill)) {
          return false;
        }
      }

      if (candidatesStatusFilter !== 'all') {
        if (effectiveStatus.toLowerCase() !== candidatesStatusFilter.toLowerCase()) {
          return false;
        }
      }

      if (candidatesMinMatchScore > 0 && c.matchScore < candidatesMinMatchScore) {
        return false;
      }

      return true;
    });
  }, [
    candidates,
    interviewInvited,
    candidatesSearchQuery,
    candidatesOpeningFilter,
    candidatesDegreeBatchFilter,
    candidatesMinGpaFilter,
    candidatesCompetencyFilter,
    candidatesStatusFilter,
    candidatesMinMatchScore,
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
    (candidatesMinGpaFilter > 0 ? 1 : 0) +
    (candidatesCompetencyFilter !== 'all' ? 1 : 0) +
    (candidatesStatusFilter !== 'all' ? 1 : 0) +
    (candidatesMinMatchScore > 0 ? 1 : 0);

  const resetCandidateFilters = () => {
    setCandidatesSearchQuery('');
    setCandidatesOpeningFilter('all');
    setCandidatesDegreeBatchFilter('all');
    setCandidatesMinGpaFilter(0);
    setCandidatesCompetencyFilter('all');
    setCandidatesStatusFilter('all');
    setCandidatesMinMatchScore(0);
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

            {/* Desktop Navigation */}
            <nav className="hidden xl:flex items-center gap-1.5">
              <button
                type="button"
                onClick={() => setActiveTab('dashboard')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${
                  activeTab === 'dashboard'
                    ? 'bg-blue-50 text-primary border border-blue-100'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <Building2 className="w-4 h-4 text-primary" />
                <span>Dashboard</span>
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('jobs')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${
                  activeTab === 'jobs'
                    ? 'bg-blue-50 text-primary border border-blue-100'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <PlusCircle className="w-4 h-4 text-slate-500" />
                <span>Placement Drives</span>
              </button>
              <button
                type="button"
                onClick={onNavigateApplications}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${
                  activeTab === 'candidates'
                    ? 'bg-blue-50 text-primary border border-blue-100'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <Users className="w-4 h-4 text-slate-500" />
                <span>Applications &amp; Matching</span>
              </button>
              <span className="text-slate-300 px-1 font-mono text-xs">|</span>
              <span className="px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-[11px] font-semibold inline-flex items-center gap-1">
                <span className={`w-1.5 h-1.5 rounded-full ${isLoading ? 'bg-amber-500 animate-pulse' : 'bg-emerald-500 animate-pulse'}`}></span>
                {isLoading ? 'Syncing DB...' : 'DB Synced'}
              </span>
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
                  setActiveTab('dashboard');
                  setMobileMenuOpen(false);
                }}
                className="text-left text-sm font-medium text-slate-700 hover:text-primary py-1.5"
              >
                Dashboard Overview
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveTab('jobs');
                  setMobileMenuOpen(false);
                }}
                className="text-left text-sm font-medium text-slate-700 hover:text-primary py-1.5"
              >
                Placement Drives
              </button>
              <button
                type="button"
                onClick={() => {
                  setActiveTab('candidates');
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
          {/* Live Academic Session Banner */}
          <section className="w-full bg-blue-50/60 border-b border-blue-100 py-2.5 px-4 sm:px-6 lg:px-8">
            <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-2 text-xs text-slate-600">
              <div className="flex items-center gap-2">
                <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                <span className="font-semibold uppercase tracking-wider text-emerald-800 text-[11px]">
                  Active Campus Drive Session: Fall 2025 / Spring 2026
                </span>
                <span className="text-slate-300 font-mono hidden sm:inline">|</span>
                <span className="text-slate-600 hidden md:inline">
                  Institutional placement portals currently open across 34 partnered universities.
                </span>
              </div>
              <div className="flex items-center gap-4 text-[11px]">
                <span className="flex items-center gap-1 font-medium text-slate-700">
                  <ShieldCheck className="w-3.5 h-3.5 text-primary" />
                  FERPA &amp; Registrar Compliant
                </span>
                <span className="hidden sm:flex items-center gap-1 font-medium text-indigo-700">
                  <Sparkles className="w-3.5 h-3.5 text-indigo-600" />
                  Live AI Screening Active
                </span>
              </div>
            </div>
          </section>

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
                          setActiveTab('jobs');
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
                      onClick={() => setActiveTab('candidates')}
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
                          <p className="text-xs text-slate-500 mt-0.5">{job.targetDomain}</p>
                          <p className="text-[11px] text-slate-400 mt-0.5 flex items-center gap-1">
                            <span>📍</span>
                            <span>{job.locationCity}</span>
                          </p>
                        </div>

                        <div className="flex flex-wrap gap-1.5 pt-1">
                          <span className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 text-[11px] font-medium">
                            Min GPA: {job.minimumGPA}
                          </span>
                          {job.mandatorySkills.slice(0, 3).map((s) => (
                            <span
                              key={s}
                              className="px-2 py-0.5 rounded bg-blue-50 text-blue-800 text-[11px] font-medium"
                            >
                              {s}
                            </span>
                          ))}
                          {job.mandatorySkills.length > 3 && (
                            <span className="px-1.5 py-0.5 rounded bg-slate-50 text-slate-500 text-[10px] font-medium">
                              +{job.mandatorySkills.length - 3}
                            </span>
                          )}
                        </div>

                        <div className="bg-slate-50 p-3 rounded-lg flex items-center justify-between mt-1 border border-slate-100">
                          <div className="flex flex-col">
                            <span className="font-display text-lg font-bold text-slate-900">
                              {job.matchesVerified}
                            </span>
                            <span className="text-[10px] text-slate-500">Matches Verified</span>
                          </div>
                          <span className="text-xs text-primary font-semibold">100% Gated Match</span>
                        </div>
                      </div>

                      <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between">
                        <button
                          type="button"
                          onClick={() => {
                            setCandidatesOpeningFilter(job.jobTitle);
                            setIsCandidatesFilterOpen(true);
                            setActiveTab('candidates');
                            const element = document.getElementById('candidates-section');
                            element?.scrollIntoView({ behavior: 'smooth' });
                          }}
                          className="text-primary text-xs font-semibold hover:underline flex items-center gap-1 cursor-pointer"
                        >
                          <span>View Matched Candidates</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          className="text-slate-400 hover:text-slate-700 p-1 cursor-pointer"
                          title="Edit Criteria"
                        >
                          <SlidersHorizontal className="w-4 h-4" />
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
              <div className="relative w-full">
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
                        value={candidatesOpeningFilter}
                        onChange={(e) => {
                          setCandidatesOpeningFilter(e.target.value);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
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

                    {/* 3. Verified GPA */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        3. Verified GPA Threshold
                      </label>
                      <select
                        value={candidatesMinGpaFilter}
                        onChange={(e) => {
                          setCandidatesMinGpaFilter(Number(e.target.value));
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="0">All GPA Ranges</option>
                        <option value="3.5">Min GPA ≥ 3.50</option>
                        <option value="3.7">Min GPA ≥ 3.70</option>
                        <option value="3.8">Min GPA ≥ 3.80</option>
                        <option value="3.9">Min GPA ≥ 3.90</option>
                      </select>
                    </div>

                    {/* 4. Core Competencies */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        4. Core Competencies
                      </label>
                      <select
                        value={candidatesCompetencyFilter}
                        onChange={(e) => {
                          setCandidatesCompetencyFilter(e.target.value);
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="all">All Competencies</option>
                        {availableCompetencies.map((comp) => (
                          <option key={comp} value={comp}>
                            {comp}
                          </option>
                        ))}
                      </select>
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

                    {/* 6. Match Score */}
                    <div className="flex flex-col gap-1">
                      <label className="text-[11px] font-semibold text-slate-600">
                        6. AI Match Score
                      </label>
                      <select
                        value={candidatesMinMatchScore}
                        onChange={(e) => {
                          setCandidatesMinMatchScore(Number(e.target.value));
                          setCandidatesCurrentPage(1);
                        }}
                        className="pl-3 pr-8 py-2 rounded-lg bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none cursor-pointer"
                      >
                        <option value="0">All Match Scores</option>
                        <option value="90">≥ 90% AI Match</option>
                        <option value="95">≥ 95% AI Match</option>
                        <option value="98">≥ 98% AI Match</option>
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
                        <th className="py-3 px-4">Status</th>
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

                              {/* Status */}
                              <td className="py-3.5 px-4">
                                <span
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${
                                    isInvited
                                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                                      : c.statusColor === 'emerald'
                                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                                      : c.statusColor === 'purple'
                                      ? 'bg-purple-50 text-purple-800 border-purple-200'
                                      : 'bg-blue-50 text-blue-800 border-blue-200'
                                  }`}
                                >
                                  {isInvited ? 'Interview Invited' : c.status}
                                </span>
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


          {/* -------------------------------------------------------------
              5. Institutional Support & Placement Desk Contact Card
             ------------------------------------------------------------- */}
          <section className="w-full pt-2 pb-6 px-4 sm:px-6 lg:px-8">
            <div className="max-w-7xl mx-auto">
              <div className="bg-slate-100/90 border border-slate-200 rounded-2xl p-6 flex flex-col md:flex-row items-center justify-between gap-4">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
                    <MessageSquare className="w-6 h-6 text-primary" />
                  </div>
                  <div className="flex flex-col">
                    <h3 className="font-display text-base font-bold text-slate-900">
                      Campus Placement Officer Dedicated Desk
                    </h3>
                    <p className="text-xs sm:text-sm text-slate-600">
                      Need to coordinate an on-campus presentation day, custom testing slots, or multi-campus tie-ups? Our university relations desk is available 24/7.
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <button
                    type="button"
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-white border border-slate-200 text-slate-800 text-xs font-semibold hover:bg-slate-50 transition-colors shadow-xs cursor-pointer"
                  >
                    <Calendar className="w-4 h-4 text-slate-600" />
                    <span>Request Campus Day</span>
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-primary hover:bg-blue-700 text-white text-xs font-semibold transition-all shadow-xs cursor-pointer"
                  >
                    <MessageSquare className="w-4 h-4" />
                    <span>Message Placement Desk</span>
                  </button>
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
    </div>
  );
};
