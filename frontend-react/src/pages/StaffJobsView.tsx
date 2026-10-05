import React, { useState, useEffect } from 'react';
import { Search, MapPin, Building2, Calendar } from 'lucide-react';

interface JobFeedDto {
  jobId: string;
  companyName: string;
  jobTitle: string;
  locationCity: string;
  internshipType: string[];
  applicationDeadline: string;
  tags: string[];
  description: string;
  requirements: string[];
  jobStipend?: boolean;
  jobDuration?: number;
  jobMinGPA?: number;
  niceToHaveSkills?: string[];
  preferredDegrees?: string[];
  allowedYears?: number[];
}

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5168/api';

export const StaffJobsView: React.FC = () => {
  const [jobs, setJobs] = useState<JobFeedDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedJob, setSelectedJob] = useState<JobFeedDto | null>(null);

  // Fetches the latest job postings from the server, including pagination and searching!
  // We grab a dozen jobs at a time to keep things loading nice and fast.
  const fetchJobs = async () => {
    try {
      setLoading(true);
      const res = await fetch(`${API_BASE}/Jobs/feed?search=${encodeURIComponent(search)}&page=${page}&pageSize=12`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      if (!res.ok) throw new Error('Failed to fetch jobs');
      const data = await res.json();
      setJobs(data.items);
      setTotalPages(Math.ceil(data.totalCount / data.pageSize));
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Listens for changes when the user types in the search box.
  // It waits half a second before searching so we don't spam the server with every single keystroke!
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchJobs();
    }, 500);
    return () => clearTimeout(delayDebounceFn);
  }, [search, page]);

  // When a staff member clicks on a job card, this fetches the full details (like nice-to-have skills or GPA limits).
  // It then pops open a nice detailed modal so they can see everything in one place.
  const handleJobClick = async (job: JobFeedDto) => {
    try {
      const res = await fetch(`${API_BASE}/Job/${job.jobId}`, {
        headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
      });
      if (res.ok) {
        const data = await res.json();
        setSelectedJob({
          ...job,
          description: data.jobDescriptionSummary || job.description,
          requirements: data.mandatorySkills || job.requirements,
          jobStipend: data.stipendOffered,
          jobDuration: data.durationMonths,
          jobMinGPA: data.minimumGPA,
          niceToHaveSkills: data.niceToHaveSkills || [],
          preferredDegrees: data.preferredDegreePrograms || [],
          allowedYears: data.allowedYearsOfStudy || []
        });
      } else {
        setSelectedJob(job);
      }
    } catch (e) {
      setSelectedJob(job);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Search Header */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="relative w-full max-w-md">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-slate-400" />
          </div>
          <input
            type="text"
            className="block w-full pl-10 pr-3 py-2 border border-slate-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 text-sm"
            placeholder="Search active jobs by title or company..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
      </div>

      {/* Grid */}
      {loading ? (
        <div className="flex justify-center p-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-700"></div>
        </div>
      ) : jobs.length === 0 ? (
        <div className="bg-white p-12 rounded-xl border border-slate-200 text-center">
          <p className="text-slate-500">No active jobs found.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {jobs.map((job) => (
            <div 
              key={job.jobId} 
              className="bg-white border border-slate-200 rounded-xl p-5 hover:shadow-md transition-shadow cursor-pointer flex flex-col"
              onClick={() => handleJobClick(job)}
            >
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-12 bg-indigo-50 rounded-lg flex items-center justify-center text-indigo-700">
                  <Building2 className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 truncate max-w-[150px]">{job.jobTitle}</h3>
                  <div className="flex items-center gap-1 text-xs text-slate-500">
                    <span className="truncate max-w-[130px] font-semibold">{job.companyName}</span>
                  </div>
                </div>
              </div>
              
              <div className="space-y-2 mb-4 flex-1">
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <MapPin className="w-4 h-4 text-slate-400" />
                  <span className="truncate">{job.locationCity} ({job.internshipType?.[0] || 'OnSite'})</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <Calendar className="w-4 h-4 text-slate-400" />
                  <span>Deadline: {job.applicationDeadline ? new Date(job.applicationDeadline).toLocaleDateString() : 'N/A'}</span>
                </div>
              </div>

              <div className="flex flex-wrap gap-1 mt-auto">
                {(job.tags || []).slice(0, 3).map((tag, idx) => (
                  <span key={idx} className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[10px] font-medium border border-slate-200">
                    {tag}
                  </span>
                ))}
                {(job.tags || []).length > 3 && (
                  <span className="px-2 py-0.5 bg-slate-50 text-slate-500 rounded-md text-[10px] font-medium border border-slate-200">
                    +{(job.tags || []).length - 3}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination */}
      {!loading && totalPages > 1 && (
        <div className="flex justify-center items-center gap-2 mt-4">
          <button 
            disabled={page === 1}
            onClick={() => setPage(p => p - 1)}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-50"
          >
            Previous
          </button>
          <span className="text-sm font-medium text-slate-600">
            Page {page} of {totalPages}
          </span>
          <button 
            disabled={page === totalPages}
            onClick={() => setPage(p => p + 1)}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:bg-slate-50"
          >
            Next
          </button>
        </div>
      )}

      {/* Detail Modal */}
      {selectedJob && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden shadow-2xl">
            
            {/* Modal Header */}
            <div className="flex items-start justify-between p-6 pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-xl font-bold text-slate-900">{selectedJob.jobTitle}</h3>
                <div className="text-sm font-medium text-slate-500 mt-1 flex items-center gap-2">
                  <span>{selectedJob.companyName}</span>
                  <span>•</span>
                  <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[16px]">location_on</span> {selectedJob.locationCity} ({selectedJob.internshipType?.join(', ') || 'Remote'})</span>
                </div>
              </div>
              <button 
                onClick={() => setSelectedJob(null)}
                className="text-slate-400 hover:text-slate-600 transition-colors p-1"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto space-y-8">
              
              {/* Metric Cards */}
              <div className="grid grid-cols-3 gap-4">
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Duration</span>
                  <span className="text-base font-semibold text-slate-900">{selectedJob.jobDuration || 6} Months</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Compensation</span>
                  <span className="text-base font-semibold text-slate-900">{selectedJob.jobStipend ? 'Stipend Offered' : 'Unpaid'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Deadline</span>
                  <span className="text-sm font-bold text-slate-900 mt-1">{new Date(selectedJob.applicationDeadline).toLocaleDateString()}</span>
                </div>
              </div>

              {/* Role Summary Box */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <span className="material-symbols-outlined text-[18px] text-blue-600">work</span>
                  <h4 className="text-base font-bold text-slate-900">Role Summary</h4>
                </div>
                <div className="bg-slate-50 p-5 rounded-xl border border-slate-200">
                  <p className="text-sm text-slate-700 leading-relaxed">{selectedJob.description || 'No description provided.'}</p>
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
                        {(selectedJob.jobMinGPA || 0).toFixed(1)} or higher
                      </span>
                    </div>
                    <div>
                      <span className="block text-xs font-semibold text-slate-500 mb-1.5">Allowed Years of Study</span>
                      <div className="flex flex-wrap gap-1.5">
                        {(selectedJob.allowedYears && selectedJob.allowedYears.length > 0) ? selectedJob.allowedYears.map(y => (
                          <span key={y} className="px-2.5 py-1 bg-fuchsia-50 text-fuchsia-700 text-sm font-semibold rounded-md border border-fuchsia-100 shadow-sm">
                            Year {y}
                          </span>
                        )) : (
                          <span className="text-sm text-slate-500 italic">Any</span>
                        )}
                      </div>
                    </div>
                    <div>
                      <span className="block text-xs font-semibold text-slate-500 mb-1.5">Preferred Degree Programs</span>
                      <div className="flex flex-wrap gap-1.5">
                        {(selectedJob.preferredDegrees && selectedJob.preferredDegrees.length > 0) ? selectedJob.preferredDegrees.map((deg, idx) => (
                          <span key={idx} className="px-2.5 py-1 bg-slate-50 text-slate-700 text-sm font-semibold rounded-md border border-slate-200 shadow-sm">
                            {deg}
                          </span>
                        )) : (
                          <span className="text-sm text-slate-500 italic">Any</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Right: Competencies */}
                <div>
                  <div className="flex items-center gap-2 mb-4">
                    <span className="material-symbols-outlined text-[18px] text-blue-600">psychology</span>
                    <h4 className="text-base font-bold text-slate-900">Required Competencies</h4>
                  </div>
                  
                  <div className="space-y-4">
                    <div>
                      <span className="block text-xs font-semibold text-slate-500 mb-2">Mandatory Skills</span>
                      <div className="flex flex-wrap gap-1.5">
                        {(selectedJob.requirements && selectedJob.requirements.length > 0) ? selectedJob.requirements.map((skill, idx) => (
                          <span key={idx} className="px-2.5 py-1 bg-blue-50 text-blue-700 text-sm font-semibold rounded-md border border-blue-100 shadow-sm">
                            {skill}
                          </span>
                        )) : (
                          <span className="text-sm text-slate-500 italic">None specified</span>
                        )}
                      </div>
                    </div>
                    
                    <div>
                      <span className="block text-xs font-semibold text-slate-500 mb-2">Nice-to-Have Skills</span>
                      <div className="flex flex-wrap gap-1.5">
                        {(selectedJob.niceToHaveSkills && selectedJob.niceToHaveSkills.length > 0) ? selectedJob.niceToHaveSkills.map((skill, idx) => (
                          <span key={idx} className="px-2.5 py-1 bg-white text-slate-600 text-sm font-medium rounded-md border border-slate-200 shadow-sm">
                            {skill}
                          </span>
                        )) : (
                          <span className="text-sm text-slate-500 italic">None specified</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

            </div>
            
            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex justify-end gap-3 rounded-b-2xl">
              <button 
                onClick={() => setSelectedJob(null)}
                className="px-5 py-2 text-sm font-semibold text-slate-700 hover:text-slate-900 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
