import React, { useState, useMemo } from 'react';
import { Footer } from '../components/layout/Footer';
import { Building2, PlusCircle, Users, CheckCircle2, Bell, LogOut } from 'lucide-react';

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
  aiScreeningPoints: string[];
  careerObjectives: string;
  resumeFileName: string;
  resumeFileSize: string;
  avatarBgClass: string;
  avatarTextClass: string;
  role: string;
}

const mockCandidates: Candidate[] = [
  {
    id: '1',
    initials: 'ER',
    name: 'Elena Rostova',
    university: 'Carnegie Mellon University',
    graduationYear: '2026',
    gpa: 3.88,
    skills: ['C++20', 'FreeRTOS', 'Verilog / FPGA', 'RISC-V'],
    matchScore: 96,
    status: 'pending',
    aiScreeningPoints: [
      'Top 1% alignment for Hardware Systems role with proven 32-bit RISC-V pipelined core synthesis on Xilinx Artix-7 FPGA.',
      'Registrar-verified academic rigor with 3.88 GPA and top-tier grades in Operating Systems Design & Computer Architecture.',
      'Demonstrated production firmware development capability with direct FreeRTOS peripheral driver integration.'
    ],
    careerObjectives: 'Aspiring hardware systems and embedded software engineer seeking to leverage hands-on FPGA digital design, RTOS architecture, and high-speed firmware development skills in next-generation silicon and robotics infrastructure. Dedicated to building reliable, real-time autonomous systems.',
    resumeFileName: 'Elena_Rostova_Resume.pdf',
    resumeFileSize: '248 KB',
    avatarBgClass: 'bg-blue-50 border-blue-100',
    avatarTextClass: 'text-blue-600',
    role: 'Hardware Systems Intern',
  },
  {
    id: '2',
    initials: 'MV',
    name: 'Marcus Vance',
    university: 'Georgia Institute of Technology',
    graduationYear: '2026',
    gpa: 3.92,
    skills: ['Rust Embedded', 'ARM Cortex-M4', 'C++', 'PCB Altium'],
    matchScore: 91,
    status: 'pending',
    aiScreeningPoints: [
      'Bare-metal specialist with dedicated STM32 microcontroller firmware experience.',
      'Led Georgia Tech RoboJackets electrical hardware group.',
      'Completed CS 2110 (Computer Organization) and CS 2200 (Systems & Networks).'
    ],
    careerObjectives: 'Embedded systems engineer with a focus on real-time control applications.',
    resumeFileName: 'Marcus_Vance_Resume.pdf',
    resumeFileSize: '180 KB',
    avatarBgClass: 'bg-indigo-50 border-indigo-100',
    avatarTextClass: 'text-indigo-600',
    role: 'Embedded Systems Intern',
  },
  {
    id: '3',
    initials: 'SL',
    name: 'Sarah Lin',
    university: 'UC Berkeley',
    graduationYear: '2025',
    gpa: 3.84,
    skills: ['Apache Spark', 'Python (PySpark)', 'Distributed SQL', 'Kafka'],
    matchScore: 87,
    status: 'pending',
    aiScreeningPoints: [
      'Maintained streaming telemetry pipeline at Databricks during Summer 2024.',
      'Coursework in CS 186 (Databases) & CS 162 (Operating Systems).',
      'Strong distributed systems foundation.'
    ],
    careerObjectives: 'Data platform engineer passionate about big data scale.',
    resumeFileName: 'Sarah_Lin_Resume.pdf',
    resumeFileSize: '312 KB',
    avatarBgClass: 'bg-emerald-50 border-emerald-100',
    avatarTextClass: 'text-emerald-600',
    role: 'Data Platform Engineer',
  },
  {
    id: '4',
    initials: 'DK',
    name: 'David Kalu',
    university: 'Purdue University',
    graduationYear: '2026',
    gpa: 3.76,
    skills: ['ROS2 Humble', 'LiDAR SLAM', 'C++17', 'Gazebo'],
    matchScore: 82,
    status: 'pending',
    aiScreeningPoints: [
      'Solid autonomous navigation experience.',
      'Built visual-inertial odometry pipeline for Purdue Formula SAE Electric team.',
      'Proficient in sensor fusion algorithms.'
    ],
    careerObjectives: 'Robotics software engineer aiming to build safe autonomous vehicles.',
    resumeFileName: 'David_Kalu_CV.pdf',
    resumeFileSize: '1.2 MB',
    avatarBgClass: 'bg-amber-50 border-amber-100',
    avatarTextClass: 'text-amber-600',
    role: 'Autonomous Systems Intern',
  }
];

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
  const [expandedId, setExpandedId] = useState<string | null>('1'); // Expand first candidate by default
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const handleTabChange = (tab: 'pending' | 'approved' | 'disapproved') => {
    setActiveTab(tab);
    setExpandedId(null);
    setCurrentPage(1);
  };

  const filteredCandidates = useMemo(() => {
    return mockCandidates.filter(c => {
      const matchesTab = c.status === activeTab;
      const q = searchQuery.toLowerCase();
      const matchesSearch =
        c.name.toLowerCase().includes(q) ||
        c.university.toLowerCase().includes(q) ||
        c.skills.some(s => s.toLowerCase().includes(q));
      return matchesTab && matchesSearch;
    });
  }, [activeTab, searchQuery]);

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
          {paginatedCandidates.length === 0 ? (
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
                            <span className="material-symbols-outlined text-[13px]">verified</span> Verified {c.university.split(' ')[0]}
                          </span>
                        </div>
                        <p className="text-xs text-slate-500 mt-0.5">{c.university} • Class of {c.graduationYear} • GPA {c.gpa.toFixed(2)}</p>
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
                        <button type="button" className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-rose-50 hover:text-rose-600 text-slate-500 flex items-center justify-center transition-colors" title="Reject">
                          <span className="material-symbols-outlined text-[16px]">close</span>
                        </button>
                        <button type="button" className="w-8 h-8 rounded-lg border border-slate-200 hover:bg-emerald-50 hover:text-emerald-700 text-slate-500 flex items-center justify-center transition-colors" title="Approve">
                          <span className="material-symbols-outlined text-[16px]">check</span>
                        </button>
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
                                  <span>{point}</span>
                                </li>
                              ))}
                            </ul>
                          </div>
                          <div className="pt-2 border-t border-slate-100">
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">CAREER OBJECTIVES SUMMARY</h4>
                            <p className="text-xs text-slate-500 leading-relaxed">{c.careerObjectives}</p>
                          </div>
                        </div>

                        {/* Right Column */}
                        <div className="lg:col-span-5 flex flex-col justify-between gap-6 bg-slate-50 p-5 rounded-xl border border-slate-100">
                          <div className="space-y-4">
                            <div>
                              <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Education</h4>
                              <div className="text-sm font-semibold text-slate-900">{c.university}</div>
                              <p className="text-xs font-medium text-slate-900 mt-1">GPA: <span className="text-blue-700 font-bold">{c.gpa.toFixed(2)} / 4.0</span> • Class of {c.graduationYear}</p>
                            </div>
                            
                            <div>
                              <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Verified Documents</h4>
                              <div className="flex flex-col gap-2">
                                <div className="flex items-center justify-between p-2.5 bg-white rounded-lg border border-slate-200 hover:border-blue-600/40 transition-colors">
                                  <div className="flex items-center gap-2.5 min-w-0">
                                    <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-700 flex items-center justify-center shrink-0 border border-blue-100">
                                      <span className="material-symbols-outlined text-[18px]">description</span>
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                      <span className="text-xs font-semibold text-slate-900 truncate">{c.resumeFileName}</span>
                                      <span className="text-[11px] text-slate-500">PDF • {c.resumeFileSize} • Verified</span>
                                    </div>
                                  </div>
                                  <div className="flex items-center gap-1 shrink-0">
                                    <button type="button" className="p-1.5 rounded-md hover:bg-slate-100 text-slate-500 hover:text-blue-700 transition-colors" title="View Document">
                                      <span className="material-symbols-outlined text-[18px]">visibility</span>
                                    </button>
                                    <button type="button" className="p-1.5 rounded-md hover:bg-slate-100 text-slate-500 hover:text-blue-700 transition-colors" title="Download Document">
                                      <span className="material-symbols-outlined text-[18px]">download</span>
                                    </button>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                          
                          <div className="flex items-center gap-2 pt-2 border-t border-slate-200">
                            <button type="button" className="flex-1 py-2 px-3 text-xs font-semibold text-rose-600 bg-white border border-rose-200 rounded-lg hover:bg-rose-50 transition-colors text-center">
                              Reject
                            </button>
                            <button 
                              type="button" 
                              className="flex-[2] inline-flex items-center justify-center gap-1.5 py-2 px-3 text-xs font-semibold text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 transition-colors shadow-sm text-center"
                            >
                              <span className="material-symbols-outlined text-[16px]">check_circle</span>
                              Approve Candidate
                            </button>
                          </div>
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
      
      <Footer />
    </div>
  );
};
