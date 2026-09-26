import React, { useState, useMemo, useEffect } from 'react';
import { Footer } from '../components/layout/Footer';
import { Building2, PlusCircle, Users, CheckCircle2, Bell, LogOut, Loader2 } from 'lucide-react';

interface Candidate {
  id: string;
  initials: string;
  name: string;
  university: string;
  graduationYear: string;
  gpa: number;
  skills: string[];
  matchScore: number;
  status: 'pending' | 'approved' | 'disapproved';
  aiScreeningPoints: { topic: string; content: string }[];
  careerObjectives: string;
  resumeFileName: string;
  resumeFileSize: string;
  avatarBgClass: string;
  avatarTextClass: string;
  role: string;
  cvUrl?: string;
  jobDescription?: string;
  jobDuration?: number;
  jobStipend?: boolean;
  jobMinGPA?: number;
  jobMandatorySkills?: string[];
  jobNiceToHaveSkills?: string[];
  jobPreferredDegrees?: string[];
  jobAllowedYears?: number[];
  phone?: string;
  portfolioUrl?: string;
  tools?: string[];
  internshipType?: string[];
  preferredLocations?: string[];
  lectureSchedule?: string;
  degreeProgram?: string;
  academicStatus?: string;
}

// mockCandidates removed - fetching from real API

interface ApplicationsPageProps {
  onNavigateDashboard?: () => void;
  userRole?: string;
  userEmail?: string;
  onLogout?: () => void;
}

export const ApplicationsPage: React.FC<ApplicationsPageProps> = ({
  onNavigateDashboard,
  userRole,
  userEmail,
  onLogout,
}) => {
  const savedUserStr = typeof window !== 'undefined' ? localStorage.getItem('campusai_auth_user') : null;
  const savedUser = savedUserStr ? JSON.parse(savedUserStr) : null;
  const effectiveRole = userRole || savedUser?.role || '';
  const effectiveEmail = userEmail || savedUser?.email || 'staff@acmerecruiting.com';
  const isStaff = effectiveRole.toLowerCase().includes('staff');

  const [activeTab, setActiveTab] = useState<'pending' | 'approved' | 'disapproved'>('pending');
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchCandidates = async () => {
    try {
      setLoading(true);
      const res = await fetch('http://localhost:5168/api/Applications/pending-admin-approval');
      if (!res.ok) throw new Error('Failed to fetch');
      const data = await res.json();
      
      const mapped: Candidate[] = data.map((item: any) => {
        let aiPoints: { topic: string; content: string }[] = [{ topic: 'Status', content: 'Awaiting detailed AI analysis...' }];
        let careerObj = 'No AI summary available.';
        
        if (item.validationReport && item.validationReport !== '{}') {
          try {
            const parsed = JSON.parse(item.validationReport);
            aiPoints = [];
            if (parsed.technical_alignment) aiPoints.push({ topic: 'Technical Alignment', content: parsed.technical_alignment });
            if (parsed.identified_gaps) aiPoints.push({ topic: 'Identified Gaps', content: parsed.identified_gaps });
            if (parsed.project_relevance) aiPoints.push({ topic: 'Project Relevance', content: parsed.project_relevance });
            if (parsed.cv_strategic_insights) aiPoints.push({ topic: 'Strategic Insights', content: parsed.cv_strategic_insights });
            if (parsed.github_comprehensive_analysis) aiPoints.push({ topic: 'GitHub Analysis', content: parsed.github_comprehensive_analysis });
            if (parsed.approval_recommendation) aiPoints.push({ topic: 'Recommendation', content: parsed.approval_recommendation });
            
          } catch (e) {
            console.error('Failed to parse AI report', e);
          }
        }

        const nameParts = item.studentName.split(' ');
        const initials = nameParts.length > 1 ? `${nameParts[0][0]}${nameParts[1][0]}`.toUpperCase() : item.studentName.substring(0, 2).toUpperCase();
        
        let status: 'pending' | 'approved' | 'disapproved' = 'pending';
        if (item.status === 'Approved') status = 'approved';
        if (item.status === 'Rejected' || item.status === 'Disapproved') status = 'disapproved';

        return {
          id: item.applicationId || 'unknown',
          initials,
          name: item.studentName || 'Unknown Student',
          university: item.university || 'Unknown University',
          graduationYear: item.graduationYear || 'N/A',
          gpa: typeof item.gpa === 'number' ? item.gpa : 0,
          skills: Array.isArray(item.skills) ? item.skills : [],
          matchScore: item.matchScore || 0,
          status,
          aiScreeningPoints: aiPoints,
          careerObjectives: careerObj,
          resumeFileName: 'Candidate_CV.pdf',
          resumeFileSize: 'PDF',
          avatarBgClass: 'bg-blue-50 border-blue-100',
          avatarTextClass: 'text-blue-600',
          role: item.jobTitle || 'Unknown Role',
          jobDescription: item.jobDescription || 'No description provided.',
          jobDuration: item.jobDuration || 6,
          jobStipend: item.jobStipend || false,
          jobMinGPA: item.jobMinGPA || 0,
          jobMandatorySkills: item.mandatorySkills || [],
          jobNiceToHaveSkills: item.niceToHaveSkills || [],
          jobPreferredDegrees: item.preferredDegrees || [],
          jobAllowedYears: item.allowedYears || [],
          cvUrl: item.cvUrl || '#',
          phone: item.phone || '',
          portfolioUrl: item.portfolioUrl || '',
          tools: Array.isArray(item.tools) ? item.tools : [],
          internshipType: Array.isArray(item.internshipType) ? item.internshipType : [],
          preferredLocations: Array.isArray(item.preferredLocations) ? item.preferredLocations : [],
          lectureSchedule: item.lectureSchedule || '',
          degreeProgram: item.degreeProgram || '',
          academicStatus: item.academicStatus || ''
        };
      });
      setCandidates(mapped);
      if (mapped.length > 0) setExpandedId(mapped[0].id);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const [viewingJobFor, setViewingJobFor] = useState<Candidate | null>(null);
  const [viewingStudentFor, setViewingStudentFor] = useState<Candidate | null>(null);

  useEffect(() => {
    fetchCandidates();
  }, []);

  const handleAction = async (id: string, action: 'approve' | 'reject') => {
    try {
      const endpoint = action === 'approve' ? 'admin-approve' : 'admin-reject';
      const res = await fetch(`http://localhost:5168/api/Applications/${id}/${endpoint}`, {
        method: 'POST'
      });
      if (res.ok) {
        setCandidates(prev => prev.map(c => 
          c.id === id ? { ...c, status: action === 'approve' ? 'approved' : 'disapproved' } : c
        ));
      }
    } catch (err) {
      console.error('Action failed', err);
    }
  };

  const handleTabChange = (tab: 'pending' | 'approved' | 'disapproved') => {
    setActiveTab(tab);
    setExpandedId(null);
    setCurrentPage(1);
  };

  const filteredCandidates = useMemo(() => {
    return candidates.filter(c => {
      const matchesTab = c.status === activeTab;
      const q = searchQuery.toLowerCase();
      const matchesSearch =
        c.name.toLowerCase().includes(q) ||
        c.university.toLowerCase().includes(q) ||
        c.skills.some(s => s.toLowerCase().includes(q));
      return matchesTab && matchesSearch;
    });
  }, [candidates, activeTab, searchQuery]);

  const paginatedCandidates = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredCandidates.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredCandidates, currentPage]);

  const toggleAccordion = (id: string, e: React.MouseEvent) => {
    // Prevent toggle if clicking on quick action buttons
    if ((e.target as HTMLElement).closest('button')) return;
    setExpandedId(prev => (prev === id ? null : id));
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900 font-sans">
      {/* Authenticated Navigation Bar (Matched to HR-LandingPage) */}
      <header className="fixed top-0 left-0 right-0 w-full z-50 bg-white/95 backdrop-blur-xl border-b border-slate-200 shadow-[0_1px_8px_rgba(15,23,42,0.04)]">
        <div className="h-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4">
          {/* Brand & Portal Links */}
          <div className="flex items-center gap-6 lg:gap-8">
            <button
              type="button"
              onClick={isStaff ? undefined : onNavigateDashboard}
              className={`flex items-center gap-2.5 group focus:outline-none ${isStaff ? 'cursor-default' : 'cursor-pointer'}`}
            >
              <div className="w-8 h-8 rounded-lg bg-blue-700 flex items-center justify-center text-white shadow-sm transition-transform group-hover:scale-105">
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
                <span className="text-[10px] text-blue-700 uppercase tracking-widest font-semibold mt-0.5">
                  {isStaff ? 'Staff Portal' : 'Employer Portal'}
                </span>
              </div>
            </button>

            {/* Desktop Navigation - Hidden for Staff Members */}
            {!isStaff && (
              <nav className="hidden xl:flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={onNavigateDashboard}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer text-slate-600 hover:text-slate-900 hover:bg-slate-100"
                >
                  <Building2 className="w-4 h-4 text-slate-500" />
                  <span>Dashboard</span>
                </button>
                <button
                  type="button"
                  onClick={onNavigateDashboard}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer text-slate-600 hover:text-slate-900 hover:bg-slate-100"
                >
                  <PlusCircle className="w-4 h-4 text-slate-500" />
                  <span>Placement Drives</span>
                </button>
                <button
                  type="button"
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer bg-blue-50 text-blue-700 border border-blue-100"
                >
                  <Users className="w-4 h-4 text-blue-700" />
                  <span>Applications &amp; Matching</span>
                </button>
                <span className="text-slate-300 px-1 font-mono text-xs">|</span>
                <span className="px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-[11px] font-semibold inline-flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                  DB Synced
                </span>
              </nav>
            )}
          </div>

          {/* Recruiter / Staff Identity + Logout */}
          <div className="flex items-center gap-3">
            {/* Identity Pill */}
            {isStaff ? (
              <div className="hidden sm:flex items-center gap-2.5 px-3 py-1.5 rounded-lg bg-slate-50 border border-slate-200/80 shadow-xs">
                <div className="w-7 h-7 rounded bg-indigo-700 text-white flex items-center justify-center text-xs font-bold font-mono">
                  ST
                </div>
                <div className="flex flex-col text-left leading-tight">
                  <div className="flex items-center gap-1">
                    <span className="text-xs font-bold text-slate-900 max-w-[170px] truncate" title="Staff Member">
                      Staff Member
                    </span>
                    <CheckCircle2 className="w-3.5 h-3.5 text-indigo-700 shrink-0" />
                  </div>
                  <span className="text-[10px] text-slate-500 truncate max-w-[170px]" title={effectiveEmail}>
                    {effectiveEmail}
                  </span>
                </div>
              </div>
            ) : (
              <div className="hidden sm:flex items-center gap-2.5 px-3 py-1.5 rounded-lg bg-slate-50 border border-slate-200/80 shadow-xs">
                <div className="w-7 h-7 rounded bg-blue-700 text-white flex items-center justify-center text-xs font-bold font-mono">
                  AR
                </div>
                <div className="flex flex-col text-left leading-tight">
                  <div className="flex items-center gap-1">
                    <span className="text-xs font-bold text-slate-900 max-w-[170px] truncate" title="Acme Recruiting">
                      Acme Recruiting
                    </span>
                    <CheckCircle2 className="w-3.5 h-3.5 text-blue-700 shrink-0" />
                  </div>
                  <span className="text-[10px] text-slate-500 truncate max-w-[170px]">
                    hr@acmerecruiting.com
                  </span>
                </div>
              </div>
            )}

            {/* Notification Bell */}
            <button
              type="button"
              className="relative w-8 h-8 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer"
              title="Notifications"
            >
              <Bell className="w-4 h-4" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-blue-700 ring-2 ring-white"></span>
            </button>

            {/* LOGOUT BUTTON */}
            <button
              type="button"
              onClick={() => {
                if (onLogout) {
                  onLogout();
                } else {
                  localStorage.removeItem('campusai_auth_user');
                  localStorage.removeItem('token');
                  window.location.reload();
                }
              }}
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-rose-600 hover:text-white hover:bg-rose-600 border border-rose-200 hover:border-rose-600 px-3.5 py-2 rounded-lg transition-all shadow-xs focus:ring-2 focus:ring-rose-200 focus:outline-none cursor-pointer"
              title="Sign out of session"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Logout</span>
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl w-full mx-auto px-6 py-8 flex-1 flex flex-col gap-6 pt-24">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="font-bold text-2xl sm:text-3xl tracking-tight">Applications & Candidates</h1>
            <p className="text-sm text-slate-500 mt-1">Review, match, and evaluate verified student applicants for active roles.</p>
          </div>
          <div className="flex items-center gap-3">
            <button className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg border border-slate-200 bg-white text-sm font-medium hover:bg-slate-50 transition-colors shadow-sm">
              <span className="material-symbols-outlined text-[18px] text-slate-500">download</span>
              Export
            </button>
          </div>
        </div>

        {/* Unified Clean Filter & Search Bar */}
        <div className="bg-white p-3 sm:p-3.5 rounded-xl border border-slate-200 shadow-sm flex flex-col md:flex-row items-stretch md:items-center gap-3">
          <div className="relative flex-1 flex items-center">
            <span className="material-symbols-outlined absolute left-3.5 text-slate-400 text-[19px]">search</span>
            <input
              type="text"
              className="w-full pl-10 pr-4 py-2 text-sm bg-slate-50 border-0 rounded-lg placeholder:text-slate-500 focus:bg-white focus:ring-2 focus:ring-blue-600/20 outline-none transition-all"
              placeholder="Search by name, university, or skills like Python, AWS..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="flex items-center gap-2.5 flex-wrap sm:flex-nowrap">
            <select className="px-3 py-2 text-sm bg-slate-50 border-0 rounded-lg font-medium focus:ring-2 focus:ring-blue-600/20 outline-none cursor-pointer">
              <option value="">All Roles</option>
              <option value="hardware">Hardware Systems Intern</option>
              <option value="data">Data Platform Engineer</option>
              <option value="robotics">Autonomous Systems</option>
            </select>
            <select className="px-3 py-2 text-sm bg-slate-50 border-0 rounded-lg font-medium focus:ring-2 focus:ring-blue-600/20 outline-none cursor-pointer">
              <option value="">All Universities</option>
              <option value="cmu">Carnegie Mellon</option>
              <option value="gatech">Georgia Tech</option>
              <option value="berkeley">UC Berkeley</option>
              <option value="purdue">Purdue University</option>
            </select>
          </div>
        </div>

        {/* Status Tabs Segmented Bar */}
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div className="inline-flex bg-slate-100 p-1 rounded-xl">
            <button
              onClick={() => handleTabChange('pending')}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'pending' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              Pending
              <span className={`px-1.5 py-0.5 rounded-md text-[11px] font-bold ${activeTab === 'pending' ? 'bg-blue-50 text-blue-700' : 'bg-slate-200 text-slate-500'}`}>4</span>
            </button>
            <button
              onClick={() => handleTabChange('approved')}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'approved' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              Approved
              <span className={`px-1.5 py-0.5 rounded-md text-[11px] font-medium ${activeTab === 'approved' ? 'bg-blue-50 text-blue-700' : 'bg-slate-200 text-slate-500'}`}>0</span>
            </button>
            <button
              onClick={() => handleTabChange('disapproved')}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'disapproved' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              Disapproved
              <span className={`px-1.5 py-0.5 rounded-md text-[11px] font-medium ${activeTab === 'disapproved' ? 'bg-blue-50 text-blue-700' : 'bg-slate-200 text-slate-500'}`}>0</span>
            </button>
          </div>
          <span className="text-xs text-slate-500 hidden sm:inline-block">
            Showing <strong className="text-slate-900 font-semibold">{filteredCandidates.length > 0 ? ((currentPage - 1) * itemsPerPage) + 1 : 0}-{Math.min(currentPage * itemsPerPage, filteredCandidates.length)}</strong> of {filteredCandidates.length} candidates
          </span>
        </div>

        {/* Applicant List */}
        <div className="flex flex-col gap-3.5">
          {loading ? (
            <div className="py-12 flex flex-col items-center justify-center text-slate-500 bg-white rounded-xl border border-slate-200">
              <Loader2 className="w-8 h-8 animate-spin text-blue-600 mb-2" />
              <span>Loading applications...</span>
            </div>
          ) : paginatedCandidates.length === 0 ? (
            <div className="py-12 text-center text-slate-500 bg-white rounded-xl border border-slate-200">
              No candidates found matching your criteria.
            </div>
          ) : (
            paginatedCandidates.map(c => {
              const isExpanded = expandedId === c.id;
              return (
                <div key={c.id} className={`bg-white rounded-xl border transition-all ${isExpanded ? 'border-slate-300 shadow-md' : 'border-slate-200 shadow-sm hover:border-slate-300'}`}>
                  {/* Card Header / Collapsed Trigger */}
                  <div className="p-5 cursor-pointer flex flex-col sm:flex-row sm:items-center justify-between gap-4 select-none" onClick={(e) => toggleAccordion(c.id, e)}>
                    <div className="flex items-center gap-4 min-w-0">
                      <div className={`w-11 h-11 rounded-xl font-bold text-sm flex items-center justify-center shrink-0 border ${c.avatarBgClass} ${c.avatarTextClass}`}>
                        {c.initials}
                      </div>
                      <div className="flex flex-col min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-bold text-base text-slate-900">{c.name}</span>
                          <span className="text-xs font-medium text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full flex items-center gap-1">
                            <span className="material-symbols-outlined text-[13px]">verified</span> Verified {(c.university || 'Unknown').split(' ')[0]}
                          </span>
                        </div>
                        <p className="text-xs text-slate-500 mt-0.5">{c.university} • Class of {c.graduationYear} • GPA {(c.gpa || 0).toFixed(2)}</p>
                        <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                          {c.skills.map((skill, idx) => (
                            <span key={idx} className="px-2 py-0.5 text-xs bg-slate-100 text-slate-700 rounded-md font-medium">{skill}</span>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 self-end sm:self-center shrink-0">
                      <div className="flex items-center gap-2 bg-emerald-50 border border-emerald-100 px-3 py-1.5 rounded-lg">
                        <span className="text-sm font-extrabold text-emerald-700">{c.matchScore}%</span>
                        <span className="text-xs font-semibold text-emerald-800">Match</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        {c.status === 'pending' && (
                          <>
                            <button type="button" onClick={(e) => { e.stopPropagation(); handleAction(c.id, 'reject'); }} className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-rose-50 hover:text-rose-600 text-slate-500 flex items-center justify-center transition-colors" title="Reject">
                              <span className="material-symbols-outlined text-[16px]">close</span>
                            </button>
                            <button type="button" onClick={(e) => { e.stopPropagation(); handleAction(c.id, 'approve'); }} className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-emerald-50 hover:text-emerald-700 text-slate-500 flex items-center justify-center transition-colors" title="Approve">
                              <span className="material-symbols-outlined text-[16px]">check</span>
                            </button>
                          </>
                        )}
                        {c.status === 'approved' && <span className="text-xs font-bold text-emerald-600 mr-2">Approved</span>}
                        {c.status === 'disapproved' && <span className="text-xs font-bold text-rose-600 mr-2">Rejected</span>}
                        
                        <div className={`w-8 h-8 rounded-lg text-slate-500 flex items-center justify-center transition-transform duration-200 ${isExpanded ? 'rotate-180' : ''}`}>
                          <span className="material-symbols-outlined text-[18px]">expand_more</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Expanded Content */}
                  {isExpanded && (
                    <div className="px-6 pb-6 pt-2 border-t border-slate-200 flex flex-col gap-6">
                      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 pt-4">
                        
                        {/* Left Column */}
                        <div className="lg:col-span-7 flex flex-col gap-5">
                          <div>
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">AI Screening & Candidate Fit</h4>
                            <ul className="space-y-2.5 text-xs text-slate-900">
                              {c.aiScreeningPoints.map((point, idx) => (
                                <li key={idx} className="flex items-start gap-2.5">
                                  <span className="material-symbols-outlined text-emerald-600 text-[18px] shrink-0 mt-0.5">check_circle</span>
                                  <span>
                                    <strong className="font-semibold text-slate-900">{point.topic}: </strong>
                                    <span className="text-slate-600">{point.content}</span>
                                  </span>
                                </li>
                              ))}
                            </ul>
                          </div>
                        </div>

                        {/* Right Column (Job & Profile Details) */}
                        <div className="lg:col-span-5 flex flex-col gap-6 bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
                          
                          {/* Applied Role Summary (Click for details) */}
                          <div>
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Applied Role</h4>
                            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 flex items-center justify-between gap-4">
                              <div className="min-w-0">
                                <h3 className="text-sm font-bold text-slate-900 truncate">{c.role}</h3>
                                <p className="text-xs font-medium text-slate-500 mt-1 truncate" title={c.jobDescription}>{c.jobDescription}</p>
                              </div>
                              <button 
                                onClick={() => setViewingJobFor(c)}
                                className="shrink-0 px-3 py-1.5 bg-white border border-slate-200 text-xs font-semibold text-blue-600 rounded-lg shadow-sm hover:bg-slate-100 transition-colors flex items-center gap-1"
                              >
                                <span className="material-symbols-outlined text-[14px]">visibility</span>
                                View Details
                              </button>
                            </div>
                          </div>

                          {/* Separator */}
                          <div className="h-px w-full bg-slate-200"></div>
                          
                          {/* Candidate Profile Summary (Click for details) */}
                          <div className="pt-2">
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Candidate Profile</h4>
                            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 flex items-center justify-between gap-4">
                              <div className="min-w-0">
                                <h3 className="text-sm font-bold text-slate-900 truncate">{c.university}</h3>
                                <p className="text-xs font-medium text-slate-500 mt-1 truncate">GPA: {(c.gpa || 0).toFixed(2)} / 4.0 • Class of {c.graduationYear}</p>
                              </div>
                              <button 
                                onClick={() => setViewingStudentFor(c)}
                                className="shrink-0 px-3 py-1.5 bg-white border border-slate-200 text-xs font-semibold text-blue-600 rounded-lg shadow-sm hover:bg-slate-100 transition-colors flex items-center gap-1"
                              >
                                <span className="material-symbols-outlined text-[14px]">person</span>
                                View Profile
                              </button>
                            </div>
                          </div>
                          
                          {c.status === 'pending' && (
                            <div className="flex items-center gap-2 pt-4 border-t border-slate-200 mt-auto">
                              <button type="button" onClick={() => handleAction(c.id, 'reject')} className="flex-1 py-2.5 px-3 text-xs font-bold text-rose-600 bg-white border border-rose-200 rounded-lg hover:bg-rose-50 transition-colors text-center shadow-sm">
                                Reject
                              </button>
                              <button 
                                type="button" 
                                onClick={() => handleAction(c.id, 'approve')}
                                className="flex-[2] inline-flex items-center justify-center gap-1.5 py-2.5 px-3 text-xs font-bold text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 transition-colors shadow-sm text-center"
                              >
                                <span className="material-symbols-outlined text-[16px]">check_circle</span>
                                Approve Candidate
                              </button>
                            </div>
                          )}
                        </div>

                      </div>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>

        {/* Clean Pagination Controls */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-200 text-xs text-slate-500">
          <span>Page {currentPage} of {Math.max(1, Math.ceil(filteredCandidates.length / itemsPerPage))}</span>
          <div className="flex items-center gap-1">
            <button 
              disabled={currentPage === 1}
              onClick={() => setCurrentPage(p => p - 1)}
              className="px-2.5 py-1.5 rounded-lg border border-slate-200 hover:bg-slate-100 transition-colors text-slate-900 font-medium disabled:opacity-50"
            >
              Previous
            </button>
            <button className="px-3 py-1.5 rounded-lg bg-blue-700 text-white font-semibold">{currentPage}</button>
            <button 
              disabled={currentPage * itemsPerPage >= filteredCandidates.length}
              onClick={() => setCurrentPage(p => p + 1)}
              className="px-2.5 py-1.5 rounded-lg border border-slate-200 hover:bg-slate-100 transition-colors text-slate-900 font-medium disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      </main>

      {/* Student Profile Modal */}
      {viewingStudentFor && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden shadow-2xl">
            
            {/* Modal Header */}
            <div className="flex items-start justify-between p-6 pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-xl font-bold text-slate-900">{viewingStudentFor.name}</h3>
                <div className="text-sm font-medium text-slate-500 mt-1 flex items-center gap-2">
                  <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[16px]">school</span> {viewingStudentFor.university}</span>
                </div>
              </div>
              <button 
                onClick={() => setViewingStudentFor(null)}
                className="text-slate-400 hover:text-slate-600 transition-colors p-1"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto space-y-8">
              
              {/* Metric Cards */}
              <div className="grid grid-cols-4 gap-4">
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Cumulative GPA</span>
                  <span className="text-lg font-bold text-slate-900">{(viewingStudentFor.gpa || 0).toFixed(2)} <span className="text-slate-400 text-sm font-medium">/ 4.0</span></span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Status</span>
                  <span className="text-base font-bold text-slate-900">{viewingStudentFor.academicStatus || 'Student'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Schedule</span>
                  <span className="text-base font-bold text-slate-900">{viewingStudentFor.lectureSchedule || 'N/A'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Expected Grad</span>
                  <span className="text-base font-bold text-slate-900">Class of {viewingStudentFor.graduationYear}</span>
                </div>
              </div>

              {/* Grid Layout */}
              <div className="grid grid-cols-2 gap-8">
                
                {/* Left Column */}
                <div className="space-y-6">
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">person</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Contact & Profile</h4>
                    </div>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg shadow-sm">
                        <span className="text-xs font-semibold text-slate-500">Phone</span>
                        <span className="text-sm font-medium text-slate-900">{viewingStudentFor.phone || 'N/A'}</span>
                      </div>
                      <div className="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg shadow-sm">
                        <span className="text-xs font-semibold text-slate-500">Degree</span>
                        <span className="text-sm font-medium text-slate-900">{viewingStudentFor.degreeProgram || 'N/A'}</span>
                      </div>
                      {viewingStudentFor.portfolioUrl && (
                        <div className="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg shadow-sm">
                          <span className="text-xs font-semibold text-slate-500">Portfolio</span>
                          <a href={viewingStudentFor.portfolioUrl} target="_blank" rel="noreferrer" className="text-sm font-medium text-blue-600 hover:underline">View Portfolio</a>
                        </div>
                      )}
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">track_changes</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Career Objectives</h4>
                    </div>
                    <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 text-sm text-slate-700 leading-relaxed shadow-inner">
                      {viewingStudentFor.careerObjectives || 'No objectives specified.'}
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">work</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Work Preferences</h4>
                    </div>
                    <div className="space-y-3">
                      {viewingStudentFor.internshipType && viewingStudentFor.internshipType.length > 0 && (
                        <div>
                          <span className="block text-xs font-semibold text-slate-500 mb-2">Internship Type</span>
                          <div className="flex flex-wrap gap-2">
                            {viewingStudentFor.internshipType.map((type, i) => (
                              <span key={i} className="px-3 py-1 bg-white text-slate-700 text-xs font-bold rounded-md border border-slate-300 shadow-sm">
                                {type}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      {viewingStudentFor.preferredLocations && viewingStudentFor.preferredLocations.length > 0 && (
                        <div className="mt-4">
                          <span className="block text-xs font-semibold text-slate-500 mb-2">Locations</span>
                          <div className="flex flex-wrap gap-2">
                            {viewingStudentFor.preferredLocations.map((loc, i) => (
                              <span key={i} className="px-3 py-1 bg-white text-slate-700 text-xs font-bold rounded-md border border-slate-300 shadow-sm">
                                {loc}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Right Column */}
                <div className="space-y-6">
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">code</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Core Skills</h4>
                    </div>
                    {viewingStudentFor.skills && viewingStudentFor.skills.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {viewingStudentFor.skills.map((skill, i) => (
                          <span key={i} className="px-3 py-1.5 bg-blue-50 text-blue-700 text-sm font-semibold rounded-lg border border-blue-200 shadow-sm">
                            {skill}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-sm text-slate-500">No skills listed.</p>
                    )}
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">handyman</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Tools & Infra</h4>
                    </div>
                    {viewingStudentFor.tools && viewingStudentFor.tools.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {viewingStudentFor.tools.map((tool, i) => (
                          <span key={i} className="px-3 py-1.5 bg-white text-slate-600 text-sm font-semibold rounded-lg border border-slate-200 shadow-sm">
                            {tool}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-sm text-slate-500">No tools listed.</p>
                    )}
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">verified</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Verified Documents</h4>
                    </div>
                    <div className="flex flex-col gap-3">
                      <div className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-200 hover:border-blue-600/40 transition-colors shadow-sm">
                        <div className="flex items-center gap-3 min-w-0">
                          <div className="w-10 h-10 rounded-lg bg-white text-blue-700 flex items-center justify-center shrink-0 border border-slate-200 shadow-sm">
                            <span className="material-symbols-outlined text-[20px]">description</span>
                          </div>
                          <div className="flex flex-col min-w-0">
                            <span className="text-sm font-bold text-slate-900 truncate">{viewingStudentFor.resumeFileName}</span>
                            <span className="text-xs font-medium text-slate-500 mt-0.5">PDF • {viewingStudentFor.resumeFileSize} • System Verified</span>
                          </div>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          <button type="button" onClick={() => window.open(`https://docs.google.com/viewer?url=${encodeURIComponent(viewingStudentFor.cvUrl)}`, '_blank')} className="p-2 rounded-lg bg-white border border-slate-200 hover:border-blue-300 shadow-sm text-slate-600 hover:text-blue-700 transition-all flex items-center gap-1.5" title="View PDF">
                            <span className="material-symbols-outlined text-[16px]">visibility</span>
                            <span className="text-xs font-bold">View</span>
                          </button>
                          <button type="button" onClick={() => window.open(viewingStudentFor.cvUrl, '_blank')} className="p-2 rounded-lg bg-white border border-slate-200 hover:border-blue-300 shadow-sm text-slate-600 hover:text-blue-700 transition-all flex items-center gap-1.5" title="Download PDF">
                            <span className="material-symbols-outlined text-[16px]">download</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>

                </div>
              </div>
            </div>
            
            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex justify-end gap-3 rounded-b-2xl">
              <button 
                onClick={() => setViewingStudentFor(null)}
                className="px-5 py-2 text-sm font-semibold text-slate-700 hover:text-slate-900 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}



      {/* Job Details Modal */}
      {viewingJobFor && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden shadow-2xl">
            
            {/* Modal Header */}
            <div className="flex items-start justify-between p-6 pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-xl font-bold text-slate-900">{viewingJobFor.role}</h3>
                <div className="text-sm font-medium text-slate-500 mt-1 flex items-center gap-2">
                  <span>Software Engineering</span>
                  <span>•</span>
                  <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[16px]">location_on</span> Remote</span>
                </div>
              </div>
              <button 
                onClick={() => setViewingJobFor(null)}
                className="text-slate-400 hover:text-slate-600 transition-colors p-1"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto space-y-8">
              
              {/* 3 Metric Cards */}
              <div className="grid grid-cols-3 gap-4">
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Duration</span>
                  <span className="text-base font-semibold text-slate-900">{viewingJobFor.jobDuration} Months</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Compensation</span>
                  <span className="text-base font-semibold text-slate-900">{viewingJobFor.jobStipend ? 'Stipend Offered' : 'Unpaid'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Matches Verified</span>
                  <span className="text-sm font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-100 mt-1">100% Match</span>
                </div>
              </div>

              {/* Role Summary Box */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <span className="material-symbols-outlined text-[18px] text-blue-600">work</span>
                  <h4 className="text-base font-bold text-slate-900">Role Summary</h4>
                </div>
                <div className="bg-slate-50 p-5 rounded-xl border border-slate-200">
                  <p className="text-sm text-slate-700 leading-relaxed">{viewingJobFor.jobDescription}</p>
                </div>
              </div>

              {/* Requirements & Competencies Grid */}
              <div className="grid grid-cols-2 gap-8 pt-2">
                {/* Left: Strict Gating */}
                <div>
                  <div className="flex items-center gap-2 mb-4">
                    <span className="material-symbols-outlined text-[18px] text-blue-600">check_circle</span>
                    <h4 className="text-base font-bold text-slate-900">Strict Gating Requirements</h4>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <span className="block text-xs font-semibold text-slate-500 mb-1.5">Minimum Required GPA</span>
                      <span className="inline-block px-2.5 py-1 bg-amber-50 text-amber-700 text-sm font-semibold rounded-md border border-amber-100 shadow-sm">
                        {(viewingJobFor.jobMinGPA || 0).toFixed(1)} or higher
                      </span>
                    </div>
                    {viewingJobFor.jobAllowedYears && viewingJobFor.jobAllowedYears.length > 0 && (
                      <div>
                        <span className="block text-xs font-semibold text-slate-500 mb-1.5">Allowed Years of Study</span>
                        <span className="inline-block px-2.5 py-1 bg-purple-50 text-purple-700 text-sm font-semibold rounded-md border border-purple-100 shadow-sm">
                          Year {viewingJobFor.jobAllowedYears.join(', ')}
                        </span>
                      </div>
                    )}
                    {viewingJobFor.jobPreferredDegrees && viewingJobFor.jobPreferredDegrees.length > 0 && (
                      <div>
                        <span className="block text-xs font-semibold text-slate-500 mb-1.5">Preferred Degree Programs</span>
                        <div className="flex flex-wrap gap-2">
                          {viewingJobFor.jobPreferredDegrees.map((deg, i) => (
                            <span key={i} className="px-2.5 py-1 bg-slate-50 text-slate-600 text-xs font-semibold rounded-md border border-slate-200 shadow-sm">
                              {deg}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Right: Competencies */}
                <div>
                  <div className="flex items-center gap-2 mb-4">
                    <span className="material-symbols-outlined text-[18px] text-blue-600">auto_awesome</span>
                    <h4 className="text-base font-bold text-slate-900">Required Competencies</h4>
                  </div>
                  <div className="space-y-4">
                    {viewingJobFor.jobMandatorySkills && viewingJobFor.jobMandatorySkills.length > 0 && (
                      <div>
                        <span className="block text-xs font-semibold text-slate-500 mb-1.5">Mandatory Skills</span>
                        <div className="flex flex-wrap gap-2">
                          {viewingJobFor.jobMandatorySkills.map((skill, i) => (
                            <span key={i} className="px-2.5 py-1 bg-blue-50 text-blue-700 text-xs font-semibold rounded-md border border-blue-200 shadow-sm">
                              {skill}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                    {viewingJobFor.jobNiceToHaveSkills && viewingJobFor.jobNiceToHaveSkills.length > 0 && (
                      <div>
                        <span className="block text-xs font-semibold text-slate-500 mb-1.5">Nice-to-Have Skills</span>
                        <div className="flex flex-wrap gap-2">
                          {viewingJobFor.jobNiceToHaveSkills.map((skill, i) => (
                            <span key={i} className="px-2.5 py-1 bg-white text-slate-500 text-xs font-semibold rounded-md border border-slate-200 shadow-sm">
                              {skill}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

            </div>
            
            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex justify-end gap-3 rounded-b-2xl">
              <button 
                onClick={() => setViewingJobFor(null)}
                className="px-5 py-2 text-sm font-semibold text-slate-700 hover:text-slate-900 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
      
      <Footer />
    </div>
  );
};
