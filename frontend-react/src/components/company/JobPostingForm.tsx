import React, { useState, useEffect } from 'react';
import {
  Rocket,
  Bookmark,
  Calendar,
  MapPin,
  DollarSign,
  AlertCircle,
  CheckCircle2,
  X,
  ArrowLeft,
  Building2,
  Loader2,
  RotateCcw,
} from 'lucide-react';
import type { TargetDomain, JobTitle, JobResponse } from '../../types/job';
import { jobService } from '../../services/jobService';

interface JobPostingFormProps {
  userEmail?: string;
  companyName?: string;
  onCancel: () => void;
  onJobCreated?: (newJob: JobResponse) => void;
}

const SRI_LANKAN_DEGREE_PROGRAMS = [
  'BSc (Hons) in Software Engineering',
  'BSc (Hons) in Computer Science',
  'BSc (Hons) in Information Technology',
  'BSc (Hons) in Data Science',
  'BSc (Hons) in Cybersecurity',
  'BSc (Hons) in Computer Systems & Network Engineering',
  'BSc (Hons) in Information Systems',
  'BSc (Hons) in Artificial Intelligence',
];

export const JobPostingForm: React.FC<JobPostingFormProps> = ({
  userEmail,
  companyName = 'Virtusa Corporation',
  onCancel,
  onJobCreated,
}) => {
  // --- Database Reference State ---
  const [domains, setDomains] = useState<TargetDomain[]>([]);
  const [availableTitles, setAvailableTitles] = useState<JobTitle[]>([]);
  const [internshipTypes, setInternshipTypes] = useState<string[]>([]);
  const [isLoadingReferences, setIsLoadingReferences] = useState(true);
  const [isLoadingTitles, setIsLoadingTitles] = useState(false);

  // --- Form Fields ---
  const [selectedDomainName, setSelectedDomainName] = useState<string>('');
  const [selectedDomainId, setSelectedDomainId] = useState<number | undefined>(undefined);
  const [selectedJobTitle, setSelectedJobTitle] = useState<string>('');
  const [selectedJobTitleId, setSelectedJobTitleId] = useState<number | undefined>(undefined);

  const [durationMonths, setDurationMonths] = useState<number>(6);
  const [selectedInternshipType, setSelectedInternshipType] = useState<string>('Hybrid');
  const [locationCity, setLocationCity] = useState<string>('Colombo, Sri Lanka');

  // Default deadline 45 days in future formatted as YYYY-MM-DD
  const [applicationDeadline, setApplicationDeadline] = useState<string>(() => {
    const d = new Date();
    d.setDate(d.getDate() + 45);
    return d.toISOString().split('T')[0];
  });

  const [stipendOffered, setStipendOffered] = useState<boolean>(true);
  const [stipendDetails, setStipendDetails] = useState<string>('LKR 75,000 / month + Transport Allowance');

  const [jobDescription, setJobDescription] = useState<string>(
    'Join our Enterprise Platform team as a software engineering intern. You will collaborate with senior engineers to design and deploy scalable microservices, participate in agile sprint ceremonies, and contribute directly to production deployments.'
  );

  const [minimumGPA, setMinimumGPA] = useState<number>(3.0);
  const [allowedCohorts, setAllowedCohorts] = useState<number[]>([3, 4]);

  // Skill Tags
  const [mandatorySkills, setMandatorySkills] = useState<string[]>([
    'C# / .NET',
    'React',
    'PostgreSQL',
    'Data Structures & Algorithms',
  ]);
  const [mandatoryInput, setMandatoryInput] = useState<string>('');

  const [niceToHaveSkills, setNiceToHaveSkills] = useState<string[]>([
    'Docker',
    'AWS / Azure',
    'CI/CD Pipelines',
    'REST APIs',
  ]);
  const [niceInput, setNiceInput] = useState<string>('');

  const [preferredDegrees, setPreferredDegrees] = useState<string[]>([
    'BSc (Hons) in Software Engineering',
    'BSc (Hons) in Computer Science',
  ]);

  // UI Feedback States
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [draftSavedMessage, setDraftSavedMessage] = useState<string | null>(null);

  // 1. Fetch Controlled Reference Data from Backend Database
  const loadReferenceData = async () => {
    setIsLoadingReferences(true);
    setErrorMessage(null);

    try {
      const [domainsData, typesData] = await Promise.all([
        jobService.getDomains(),
        jobService.getInternshipTypes(),
      ]);

      setDomains(domainsData);
      setInternshipTypes(typesData);

      // Pre-select first domain if available (e.g. Software Engineering)
      if (domainsData.length > 0) {
        const defaultDomain =
          domainsData.find((d) => d.name === 'Software Engineering') || domainsData[0];
        setSelectedDomainName(defaultDomain.name);
        setSelectedDomainId(defaultDomain.id);
      }

      if (typesData.length > 0 && !typesData.includes(selectedInternshipType)) {
        setSelectedInternshipType(typesData[0]);
      }
    } catch (err: any) {
      setErrorMessage(
        `Failed to load reference metadata from database: ${err.message || 'Server connection failed'}. Please ensure the .NET backend is running on http://localhost:5168.`
      );
    } finally {
      setIsLoadingReferences(false);
    }
  };

  useEffect(() => {
    loadReferenceData();
  }, []);

  // 2. Dependent Job Titles: Fetch when selected domain changes
  useEffect(() => {
    if (!selectedDomainName) {
      setAvailableTitles([]);
      setSelectedJobTitle('');
      setSelectedJobTitleId(undefined);
      return;
    }

    let isMounted = true;
    setIsLoadingTitles(true);

    jobService
      .getJobTitles(selectedDomainId, selectedDomainName)
      .then((titles) => {
        if (!isMounted) return;
        setAvailableTitles(titles);

        // Pre-select the first valid title for this domain
        if (titles.length > 0) {
          setSelectedJobTitle(titles[0].title);
          setSelectedJobTitleId(titles[0].id);
        } else {
          setSelectedJobTitle('');
          setSelectedJobTitleId(undefined);
        }
      })
      .catch((err) => {
        if (!isMounted) return;
        console.error('Failed to load dependent titles:', err);
      })
      .finally(() => {
        if (isMounted) setIsLoadingTitles(false);
      });

    return () => {
      isMounted = false;
    };
  }, [selectedDomainName, selectedDomainId]);

  // Handle Domain Change
  const handleDomainChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const domainName = e.target.value;
    setSelectedDomainName(domainName);
    const domainObj = domains.find((d) => d.name === domainName);
    setSelectedDomainId(domainObj?.id);
    setSelectedJobTitle('');
    setSelectedJobTitleId(undefined);
  };

  // Handle Job Title Change
  const handleJobTitleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const title = e.target.value;
    setSelectedJobTitle(title);
    const titleObj = availableTitles.find((t) => t.title === title);
    setSelectedJobTitleId(titleObj?.id);
  };

  // Tag Handlers: Mandatory Skills
  const handleAddMandatorySkill = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      const val = mandatoryInput.replace(',', '').trim();
      if (val && !mandatorySkills.includes(val)) {
        setMandatorySkills([...mandatorySkills, val]);
        setMandatoryInput('');
      }
    }
  };

  const handleRemoveMandatorySkill = (skill: string) => {
    setMandatorySkills(mandatorySkills.filter((s) => s !== skill));
  };

  // Tag Handlers: Nice-to-Have Skills
  const handleAddNiceSkill = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      const val = niceInput.replace(',', '').trim();
      if (val && !niceToHaveSkills.includes(val)) {
        setNiceToHaveSkills([...niceToHaveSkills, val]);
        setNiceInput('');
      }
    }
  };

  const handleRemoveNiceSkill = (skill: string) => {
    setNiceToHaveSkills(niceToHaveSkills.filter((s) => s !== skill));
  };

  // Cohort Checkbox Handler
  const handleCohortToggle = (year: number) => {
    if (allowedCohorts.includes(year)) {
      if (allowedCohorts.length > 1) {
        setAllowedCohorts(allowedCohorts.filter((y) => y !== year));
      }
    } else {
      setAllowedCohorts([...allowedCohorts, year].sort((a, b) => a - b));
    }
  };

  // Degree Program Toggle
  const handleDegreeToggle = (deg: string) => {
    if (preferredDegrees.includes(deg)) {
      setPreferredDegrees(preferredDegrees.filter((d) => d !== deg));
    } else {
      setPreferredDegrees([...preferredDegrees, deg]);
    }
  };

  // Save as Draft Handlers
  const handleSaveDraft = () => {
    setDraftSavedMessage(
      `Opportunity configuration for "${selectedJobTitle || 'Untitled Role'}" saved as an in-memory draft.`
    );
    setTimeout(() => setDraftSavedMessage(null), 4000);
  };

  // Form Submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setSuccessMessage(null);

    // 1. Validation
    if (!selectedDomainName) {
      setErrorMessage('Please select a Target Domain.');
      return;
    }

    if (!selectedJobTitle) {
      setErrorMessage('Please select a Job Title from the controlled database options.');
      return;
    }

    if (!selectedInternshipType) {
      setErrorMessage('Please select an Internship Type.');
      return;
    }

    if (!jobDescription.trim() || jobDescription.trim().length < 10) {
      setErrorMessage('Please provide a descriptive job summary (minimum 10 characters).');
      return;
    }

    if (!locationCity.trim()) {
      setErrorMessage('Primary Location / City cannot be empty.');
      return;
    }

    if (minimumGPA < 0.0 || minimumGPA > 4.0) {
      setErrorMessage('Minimum Cumulative GPA must be between 0.00 and 4.00.');
      return;
    }

    if (durationMonths < 1 || durationMonths > 24) {
      setErrorMessage('Duration must be between 1 and 24 months.');
      return;
    }

    const deadlineDate = new Date(applicationDeadline);
    if (isNaN(deadlineDate.getTime()) || deadlineDate <= new Date()) {
      setErrorMessage('Application deadline must be a valid future date.');
      return;
    }

    setIsSubmitting(true);

    try {
      const payload = {
        recruiterEmail: userEmail,
        targetDomain: selectedDomainName,
        targetDomainId: selectedDomainId,
        jobTitle: selectedJobTitle,
        jobTitleId: selectedJobTitleId,
        jobDescriptionSummary: jobDescription.trim(),
        internshipType: selectedInternshipType,
        locationCity: locationCity.trim(),
        minimumGPA: Number(minimumGPA.toFixed(2)),
        allowedYearsOfStudy: allowedCohorts,
        mandatorySkills: mandatorySkills,
        niceToHaveSkills: niceToHaveSkills,
        preferredDegreePrograms: preferredDegrees,
        stipendOffered: stipendOffered,
        stipendAmountOrDetails: stipendOffered ? stipendDetails.trim() : undefined,
        durationMonths: Number(durationMonths),
        applicationDeadline: new Date(applicationDeadline).toISOString(),
      };

      const createdJob = await jobService.createJob(payload);

      setSuccessMessage(
        `Job opportunity "${createdJob.jobTitle}" created successfully in Supabase database! Redirecting to Placement Drives...`
      );

      setTimeout(() => {
        if (onJobCreated) {
          onJobCreated(createdJob);
        } else {
          onCancel();
        }
      }, 1500);
    } catch (err: any) {
      console.error('Job creation error:', err);
      setErrorMessage(err.message || 'An unexpected error occurred while saving the job to the database.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const selectedDomainObj = domains.find((d) => d.name === selectedDomainName);

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 antialiased pb-24">
      {/* 1. Header Toolbar */}
      <header className="sticky top-0 z-40 bg-white border-b border-slate-200 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          {/* Left Brand & Breadcrumb */}
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={onCancel}
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-600 hover:text-slate-900 bg-slate-100 hover:bg-slate-200/80 px-2.5 py-1.5 rounded-lg transition-colors cursor-pointer"
              title="Return to HR Dashboard"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back</span>
            </button>

            <div className="h-4 w-px bg-slate-200 hidden sm:block"></div>

            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-primary text-white flex items-center justify-center font-bold text-xs shadow-xs">
                CAI
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-bold text-slate-900 tracking-tight">CampusAI</span>
                  <span className="px-1.5 py-0.5 rounded bg-blue-50 border border-blue-200 text-primary text-[10px] font-mono font-semibold">
                    ENTERPRISE
                  </span>
                </div>
                <span className="text-[11px] text-slate-500 hidden sm:block">
                  Recruiter Portal &bull; {companyName}
                </span>
              </div>
            </div>
          </div>

          {/* Right Actions */}
          <div className="flex items-center gap-3">
            <div className="hidden md:flex items-center gap-2 px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-[11px] font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              DB Reference Engine Active
            </div>

            <button
              type="button"
              onClick={handleSaveDraft}
              className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white border border-slate-200 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition-colors shadow-xs cursor-pointer"
            >
              <Bookmark className="w-3.5 h-3.5 text-slate-500" />
              <span>Save Draft</span>
            </button>

            <button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting || isLoadingReferences}
              className="inline-flex items-center gap-2 px-4 sm:px-5 py-2 rounded-xl bg-primary text-white text-xs sm:text-sm font-semibold hover:bg-blue-700 transition-all shadow-sm disabled:opacity-50 cursor-pointer"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Publishing...</span>
                </>
              ) : (
                <>
                  <Rocket className="w-4 h-4" />
                  <span>Publish Opportunity</span>
                </>
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Container */}
      <main className="max-w-4xl mx-auto pt-8 px-4 sm:px-6">
        {/* Breadcrumbs Navigation */}
        <nav className="flex items-center gap-2 text-xs font-medium text-slate-500 mb-3">
          <button type="button" onClick={onCancel} className="hover:text-primary transition-colors cursor-pointer">
            Recruiter Portal
          </button>
          <span className="text-slate-300">/</span>
          <button type="button" onClick={onCancel} className="hover:text-primary transition-colors cursor-pointer">
            Job Postings
          </button>
          <span className="text-slate-300">/</span>
          <span className="text-primary font-semibold">Create New Opening</span>
        </nav>

        {/* Page Title & Subtitle */}
        <div className="mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">
              Post a Job Opportunity
            </h1>
            <p className="text-xs sm:text-sm text-slate-600 mt-1">
              Publish a campus internship or full-time placement role for student applicants.
            </p>
          </div>

          <div className="flex items-center gap-2 self-start sm:self-auto shrink-0 bg-blue-50/60 border border-blue-100 px-3 py-1.5 rounded-lg text-xs text-primary font-medium">
            <Building2 className="w-3.5 h-3.5" />
            <span>Posting as <strong>{companyName}</strong></span>
          </div>
        </div>

        {/* Feedback Banners */}
        {errorMessage && (
          <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-sm flex items-start gap-3 shadow-xs">
            <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div className="flex-1">
              <strong className="font-semibold block">Validation Error</strong>
              <p className="text-xs sm:text-sm text-rose-700 mt-0.5">{errorMessage}</p>
              {domains.length === 0 && (
                <button
                  type="button"
                  onClick={loadReferenceData}
                  disabled={isLoadingReferences}
                  className="mt-2.5 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-rose-600 text-white text-xs font-semibold hover:bg-rose-700 transition-colors shadow-xs cursor-pointer disabled:opacity-50"
                >
                  <RotateCcw className={`w-3.5 h-3.5 ${isLoadingReferences ? 'animate-spin' : ''}`} />
                  <span>{isLoadingReferences ? 'Connecting to DB...' : 'Retry DB Connection'}</span>
                </button>
              )}
            </div>
            <button type="button" onClick={() => setErrorMessage(null)} className="text-rose-500 hover:text-rose-700 p-1">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {draftSavedMessage && (
          <div className="mb-6 p-3 rounded-xl bg-slate-100 border border-slate-300 text-slate-800 text-xs flex items-center justify-between shadow-xs">
            <div className="flex items-center gap-2">
              <Bookmark className="w-4 h-4 text-slate-600" />
              <span>{draftSavedMessage}</span>
            </div>
            <button type="button" onClick={() => setDraftSavedMessage(null)} className="text-slate-500 hover:text-slate-700">
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {successMessage && (
          <div className="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-sm flex items-center gap-3 shadow-xs">
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
            <div className="flex-1 font-medium">{successMessage}</div>
          </div>
        )}

        {/* The Form */}
        <form onSubmit={handleSubmit} className="flex flex-col gap-6">
          {/* ========================================================
              SECTION 1: Position Overview (Reference-Data Driven)
             ======================================================== */}
          <section className="bg-white rounded-2xl border border-slate-200 p-6 sm:p-8 shadow-xs hover:shadow transition-shadow">
            <div className="flex items-center gap-3 pb-6 border-b border-slate-100">
              <div className="w-8 h-8 rounded-full bg-blue-50 text-primary flex items-center justify-center font-bold text-sm">
                1
              </div>
              <div>
                <h2 className="font-display text-lg font-bold text-slate-900 tracking-tight">
                  Position Overview
                </h2>
                <p className="text-xs sm:text-sm text-slate-500">
                  Core parameters, domain focus, and logistical structure.
                </p>
              </div>
            </div>

            <div className="mt-6 space-y-6">
              {/* Target Domain Dropdown (Controlled Reference Data) */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs sm:text-sm font-semibold text-slate-800" htmlFor="target-domain">
                    Target Domain <span className="text-rose-500">*</span>
                  </label>
                  <span className="text-[11px] text-primary font-mono font-medium">
                    {domains.length} Controlled Computing Domains in DB
                  </span>
                </div>

                <div className="relative">
                  <select
                    id="target-domain"
                    value={selectedDomainName}
                    onChange={handleDomainChange}
                    disabled={isLoadingReferences}
                    className="w-full rounded-xl border border-slate-200 pl-3.5 pr-9 py-2.5 text-xs sm:text-sm text-slate-900 bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all cursor-pointer font-medium"
                    required
                  >
                    <option value="" disabled>
                      -- Select Target Domain from Database Registry --
                    </option>
                    {domains.map((dom) => (
                      <option key={dom.id} value={dom.name}>
                        {dom.name} ({dom.titleCount} Titles)
                      </option>
                    ))}
                  </select>
                </div>

                {selectedDomainObj?.description && (
                  <p className="text-xs text-slate-500 mt-1.5 leading-relaxed">
                    {selectedDomainObj.description}
                  </p>
                )}
              </div>

              {/* Job Title (Dependent Controlled Reference Dropdown) */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs sm:text-sm font-semibold text-slate-800" htmlFor="job-title">
                    Job Title <span className="text-rose-500">*</span>
                  </label>
                  <span className="text-[11px] text-slate-500 font-mono">
                    {isLoadingTitles
                      ? 'Syncing titles from DB...'
                      : `${availableTitles.length} titles available for this domain`}
                  </span>
                </div>

                <div className="relative">
                  <select
                    id="job-title"
                    value={selectedJobTitle}
                    onChange={handleJobTitleChange}
                    disabled={!selectedDomainName || isLoadingTitles || availableTitles.length === 0}
                    className="w-full rounded-xl border border-slate-200 pl-3.5 pr-9 py-2.5 text-xs sm:text-sm text-slate-900 bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all cursor-pointer font-medium disabled:bg-slate-50 disabled:text-slate-400"
                    required
                  >
                    {availableTitles.length === 0 ? (
                      <option value="">-- Select a Target Domain above first --</option>
                    ) : (
                      availableTitles.map((t) => (
                        <option key={t.id} value={t.title}>
                          {t.title}
                        </option>
                      ))
                    )}
                  </select>
                </div>

                <p className="text-[11px] text-slate-500 mt-1.5">
                  Controlled by reference database: only titles strictly mapped to &quot;{selectedDomainName || 'selected domain'}&quot; are selectable.
                </p>
              </div>

              {/* 2-Column: Duration & Internship Type */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                {/* Duration */}
                <div>
                  <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-1.5" htmlFor="duration-months">
                    Duration (Months) <span className="text-rose-500">*</span>
                  </label>
                  <select
                    id="duration-months"
                    value={durationMonths}
                    onChange={(e) => setDurationMonths(Number(e.target.value))}
                    className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-xs sm:text-sm text-slate-900 bg-white focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all cursor-pointer"
                  >
                    <option value={3}>3 Months (Summer Term)</option>
                    <option value={6}>6 Months (Semester Co-op)</option>
                    <option value={9}>9 Months (Extended Placement)</option>
                    <option value={12}>12 Months (Full Placement Year)</option>
                  </select>
                </div>

                {/* Primary Location */}
                <div>
                  <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-1.5" htmlFor="primary-location">
                    Primary Location / City <span className="text-rose-500">*</span>
                  </label>
                  <div className="relative">
                    <MapPin className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                    <input
                      id="primary-location"
                      type="text"
                      value={locationCity}
                      onChange={(e) => setLocationCity(e.target.value)}
                      placeholder="e.g. Colombo, Sri Lanka (or Hybrid Bay Area)"
                      className="w-full rounded-xl border border-slate-200 pl-10 pr-4 py-2.5 text-xs sm:text-sm text-slate-900 placeholder:text-slate-400 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all"
                      required
                    />
                  </div>
                </div>
              </div>

              {/* Internship Type Badges (Controlled Backend Enum: OnSite | Hybrid | Remote) */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-2">
                  Internship Type / Locality Mode <span className="text-rose-500">*</span>
                </label>
                <div className="flex flex-wrap gap-2.5">
                  {(internshipTypes.length > 0 ? internshipTypes : ['OnSite', 'Hybrid', 'Remote']).map((type) => {
                    const isSelected = selectedInternshipType === type;
                    return (
                      <button
                        key={type}
                        type="button"
                        onClick={() => setSelectedInternshipType(type)}
                        className={`px-4 py-2 rounded-xl text-xs font-semibold tracking-wide border transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-primary text-white border-primary shadow-xs'
                            : 'bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100 hover:text-slate-900'
                        }`}
                      >
                        {type === 'OnSite' ? 'On-Site' : type}
                      </button>
                    );
                  })}
                </div>
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Controlled backend enum values: free-text values are strictly prohibited.
                </p>
              </div>

              {/* Application Deadline */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-1.5" htmlFor="application-deadline">
                  Application Deadline <span className="text-rose-500">*</span>
                </label>
                <div className="relative max-w-sm">
                  <Calendar className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  <input
                    id="application-deadline"
                    type="date"
                    value={applicationDeadline}
                    onChange={(e) => setApplicationDeadline(e.target.value)}
                    min={new Date().toISOString().split('T')[0]}
                    className="w-full rounded-xl border border-slate-200 pl-10 pr-4 py-2.5 text-xs sm:text-sm text-slate-900 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all cursor-pointer"
                    required
                  />
                </div>
              </div>

              {/* Stipend & Compensation Package Card */}
              <div className="rounded-xl bg-slate-50/80 border border-slate-200 p-4 sm:p-5 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <DollarSign className="w-4 h-4 text-primary" />
                    <span className="text-xs sm:text-sm font-bold text-slate-900">
                      Stipend &amp; Compensation Package
                    </span>
                  </div>

                  {/* Toggle Switch */}
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={stipendOffered}
                      onChange={(e) => setStipendOffered(e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                    <span className="ml-2.5 text-xs font-semibold text-slate-700">
                      {stipendOffered ? 'Stipend Offered' : 'Unpaid / Voluntary'}
                    </span>
                  </label>
                </div>

                {stipendOffered && (
                  <div>
                    <input
                      type="text"
                      value={stipendDetails}
                      onChange={(e) => setStipendDetails(e.target.value)}
                      placeholder="e.g. LKR 75,000 / month + housing / transport allowance"
                      className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-xs sm:text-sm text-slate-900 bg-white placeholder:text-slate-400 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all"
                    />
                  </div>
                )}
              </div>

              {/* Job Description Summary */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs sm:text-sm font-semibold text-slate-800" htmlFor="job-description">
                    Job Description Summary <span className="text-rose-500">*</span>
                  </label>
                  <span className="text-[11px] text-slate-500 font-mono">
                    {jobDescription.length} / 2000 chars
                  </span>
                </div>
                <textarea
                  id="job-description"
                  rows={5}
                  value={jobDescription}
                  onChange={(e) => setJobDescription(e.target.value)}
                  placeholder="Detail role scope, mentorship programs, key deliverables, and everyday impact for applicants..."
                  maxLength={2000}
                  className="w-full rounded-xl border border-slate-200 p-4 text-xs sm:text-sm text-slate-900 placeholder:text-slate-400 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all leading-relaxed"
                  required
                />
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Saved directly to Supabase and formatted on student portals.
                </p>
              </div>
            </div>
          </section>

          {/* ========================================================
              SECTION 2: Hard Requirements (Eligibility Gating)
             ======================================================== */}
          <section className="bg-white rounded-2xl border border-slate-200 p-6 sm:p-8 shadow-xs hover:shadow transition-shadow">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-6 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-blue-50 text-primary flex items-center justify-center font-bold text-sm">
                  2
                </div>
                <div>
                  <h2 className="font-display text-lg font-bold text-slate-900 tracking-tight">
                    Hard Requirements (Eligibility Gating)
                  </h2>
                  <p className="text-xs sm:text-sm text-slate-500">
                    Automated screening criteria to qualify student applicants.
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-rose-50 text-rose-700 text-xs font-semibold border border-rose-200 self-start sm:self-auto">
                <span className="w-1.5 h-1.5 rounded-full bg-rose-600"></span>
                Strict Eligibility
              </span>
            </div>

            <div className="mt-6 space-y-6">
              {/* Minimum GPA Input */}
              <div className="max-w-md">
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-1.5" htmlFor="minimum-gpa">
                  Minimum Cumulative GPA <span className="text-rose-500">*</span>
                </label>
                <div className="flex items-center gap-3">
                  <input
                    id="minimum-gpa"
                    type="number"
                    min="0.00"
                    max="4.00"
                    step="0.01"
                    value={minimumGPA}
                    onChange={(e) => setMinimumGPA(parseFloat(e.target.value) || 0)}
                    className="w-32 rounded-xl border border-slate-200 px-3.5 py-2.5 text-xs sm:text-sm font-semibold text-slate-900 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all"
                    required
                  />
                  <span className="text-xs text-slate-500 font-medium">/ 4.00 max scale</span>
                </div>
                <p className="text-[11px] text-rose-600 mt-1.5 flex items-center gap-1">
                  <AlertCircle className="w-3.5 h-3.5" />
                  Applicants below this threshold are flagged or disqualified during automated intake.
                </p>
              </div>

              {/* Allowed Academic Cohorts / Years of Study */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-2">
                  Allowed Academic Cohorts / Years of Study <span className="text-rose-500">*</span>
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {[
                    { year: 1, label: 'Freshman / 1st Year', sub: 'Class of 2028' },
                    { year: 2, label: 'Sophomore / 2nd Year', sub: 'Class of 2027' },
                    { year: 3, label: 'Junior / 3rd Year', sub: 'Class of 2026' },
                    { year: 4, label: 'Senior / Final Year (Year 4)', sub: 'Class of 2025' },
                  ].map((cohort) => {
                    const isChecked = allowedCohorts.includes(cohort.year);
                    return (
                      <label
                        key={cohort.year}
                        className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-colors ${
                          isChecked
                            ? 'border-primary/40 bg-blue-50/40 hover:bg-blue-50'
                            : 'border-slate-200 hover:bg-slate-50'
                        }`}
                      >
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={() => handleCohortToggle(cohort.year)}
                          className="rounded text-primary focus:ring-primary border-slate-300 w-4 h-4 cursor-pointer"
                        />
                        <div>
                          <span className="text-xs sm:text-sm font-medium text-slate-900 block">
                            {cohort.label}
                          </span>
                          <span className="text-[11px] text-slate-500">{cohort.sub}</span>
                        </div>
                      </label>
                    );
                  })}
                </div>
              </div>

              {/* Mandatory Technical Skills (Interactive Tag Input) */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-2">
                  Mandatory Technical Skills
                </label>
                <div className="p-3 rounded-xl border border-slate-200 bg-white focus-within:border-primary focus-within:ring-1 focus-within:ring-primary">
                  <div className="flex flex-wrap items-center gap-2">
                    {mandatorySkills.map((skill) => (
                      <span
                        key={skill}
                        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-slate-100 text-slate-800 font-mono text-xs"
                      >
                        {skill}
                        <button
                          type="button"
                          onClick={() => handleRemoveMandatorySkill(skill)}
                          className="text-slate-400 hover:text-rose-600 transition-colors cursor-pointer"
                          title="Remove skill"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </span>
                    ))}
                    <input
                      type="text"
                      value={mandatoryInput}
                      onChange={(e) => setMandatoryInput(e.target.value)}
                      onKeyDown={handleAddMandatorySkill}
                      placeholder="+ Add skill (Press Enter or Comma)"
                      className="border-0 focus:ring-0 text-xs py-1 px-2 text-slate-800 placeholder:text-slate-400 bg-transparent min-w-[170px] grow outline-none"
                    />
                  </div>
                </div>
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Students must match mandatory skills for direct interview routing.
                </p>
              </div>
            </div>
          </section>

          {/* ========================================================
              SECTION 3: Preferred Criteria
             ======================================================== */}
          <section className="bg-white rounded-2xl border border-slate-200 p-6 sm:p-8 shadow-xs hover:shadow transition-shadow">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-6 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-blue-50 text-primary flex items-center justify-center font-bold text-sm">
                  3
                </div>
                <div>
                  <h2 className="font-display text-lg font-bold text-slate-900 tracking-tight">
                    Preferred Criteria
                  </h2>
                  <p className="text-xs sm:text-sm text-slate-500">
                    Bonus attributes used to rank and elevate top-percentile candidates.
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-50 text-indigo-700 text-xs font-semibold border border-indigo-200 self-start sm:self-auto">
                <span className="w-1.5 h-1.5 rounded-full bg-indigo-600"></span>
                Weighted Criteria
              </span>
            </div>

            <div className="mt-6 space-y-6">
              {/* Target Academic Majors (Selectable Pill Chips) */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-2">
                  Target Academic Majors / Degree Programs
                </label>
                <div className="flex flex-wrap gap-2">
                  {SRI_LANKAN_DEGREE_PROGRAMS.map((degree) => {
                    const isSelected = preferredDegrees.includes(degree);
                    return (
                      <button
                        key={degree}
                        type="button"
                        onClick={() => handleDegreeToggle(degree)}
                        className={`px-3.5 py-1.5 rounded-full text-xs font-medium tracking-wide border transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-primary text-white border-primary shadow-xs'
                            : 'bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100 hover:text-slate-900'
                        }`}
                      >
                        {isSelected ? `✓ ${degree}` : `+ ${degree}`}
                      </button>
                    );
                  })}
                </div>
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Select Sri Lankan degree specializations prioritized for candidate matching algorithms.
                </p>
              </div>

              {/* Nice-to-Have Skills (Tag Input) */}
              <div>
                <label className="block text-xs sm:text-sm font-semibold text-slate-800 mb-2">
                  Nice-to-Have Skills
                </label>
                <div className="p-3 rounded-xl border border-slate-200 bg-white focus-within:border-primary focus-within:ring-1 focus-within:ring-primary">
                  <div className="flex flex-wrap items-center gap-2">
                    {niceToHaveSkills.map((skill) => (
                      <span
                        key={skill}
                        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-blue-50 text-blue-900 font-mono text-xs border border-blue-100"
                      >
                        {skill}
                        <button
                          type="button"
                          onClick={() => handleRemoveNiceSkill(skill)}
                          className="text-blue-400 hover:text-rose-600 transition-colors cursor-pointer"
                          title="Remove skill"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </span>
                    ))}
                    <input
                      type="text"
                      value={niceInput}
                      onChange={(e) => setNiceInput(e.target.value)}
                      onKeyDown={handleAddNiceSkill}
                      placeholder="+ Add preferred skill (Press Enter)"
                      className="border-0 focus:ring-0 text-xs py-1 px-2 text-slate-800 placeholder:text-slate-400 bg-transparent min-w-[170px] grow outline-none"
                    />
                  </div>
                </div>
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Candidates possessing preferred skills receive boosted ranking in the matching feed.
                </p>
              </div>
            </div>
          </section>

          {/* Bottom Action Bar */}
          <div className="flex items-center justify-between pt-4 pb-12 border-t border-slate-200">
            <button
              type="button"
              onClick={onCancel}
              className="px-5 py-2.5 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 text-xs sm:text-sm font-medium transition-colors cursor-pointer"
            >
              Cancel
            </button>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={handleSaveDraft}
                className="px-5 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-700 text-xs sm:text-sm font-semibold hover:bg-slate-50 transition-colors shadow-xs cursor-pointer"
              >
                Save as Draft
              </button>

              <button
                type="submit"
                disabled={isSubmitting || isLoadingReferences}
                className="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl bg-primary text-white text-xs sm:text-sm font-semibold hover:bg-blue-700 transition-all shadow-sm disabled:opacity-50 cursor-pointer"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Publishing to Database...</span>
                  </>
                ) : (
                  <>
                    <Rocket className="w-4 h-4" />
                    <span>Publish Opportunity</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </main>
    </div>
  );
};
