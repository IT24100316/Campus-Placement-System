import React, { useState, useEffect } from 'react';
import { Search, MapPin, GraduationCap } from 'lucide-react';

interface StudentProfile {
  userId: string;
  fullName: string;
  universityName: string;
  degreeProgram: string;
  gpa: number;
  skills: string[];
  campusIdPhotoUrl?: string;
  phone?: string;
  portfolioUrl?: string;
  academicStatus?: string;
  expectedGraduationDate?: string;
  careerObjectivesSummary?: string;
  toolsAndTechnologies?: string[];
  internshipType?: string[];
  lectureScheduleType?: string;
  preferredLocations?: string[];
  cvPdfUrl?: string;
}

export const StaffStudentsView: React.FC = () => {
  const [students, setStudents] = useState<StudentProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedStudent, setSelectedStudent] = useState<StudentProfile | null>(null);

  const fetchStudents = async () => {
    try {
      setLoading(true);
      const res = await fetch(`http://localhost:5168/api/Students/directory?search=${encodeURIComponent(search)}&page=${page}&pageSize=12`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}` // Adjust depending on your auth scheme
        }
      });
      if (!res.ok) throw new Error('Failed to fetch students');
      const data = await res.json();
      setStudents(data.items);
      setTotalPages(Math.ceil(data.totalCount / data.pageSize));
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      fetchStudents();
    }, 500);
    return () => clearTimeout(delayDebounceFn);
  }, [search, page]);

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
            placeholder="Search students by name, university, or skills..."
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
      ) : students.length === 0 ? (
        <div className="bg-white p-12 rounded-xl border border-slate-200 text-center">
          <p className="text-slate-500">No students found matching your search.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {students.map((student) => (
            <div 
              key={student.userId} 
              className="bg-white border border-slate-200 rounded-xl p-5 hover:shadow-md transition-shadow cursor-pointer flex flex-col"
              onClick={() => setSelectedStudent(student)}
            >
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-700 font-bold text-lg">
                  {student.fullName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 truncate max-w-[150px]">{student.fullName}</h3>
                  <div className="flex items-center gap-1 text-xs text-slate-500">
                    <MapPin className="w-3 h-3" />
                    <span className="truncate max-w-[130px]">{student.universityName}</span>
                  </div>
                </div>
              </div>
              
              <div className="space-y-2 mb-4 flex-1">
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <GraduationCap className="w-4 h-4 text-slate-400" />
                  <span className="truncate">{student.degreeProgram}</span>
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-700">
                  <div className="w-4 h-4 flex items-center justify-center text-slate-400 font-bold text-[10px]">GPA</div>
                  <span>{student.gpa.toFixed(2)}</span>
                </div>
              </div>

              <div className="flex flex-wrap gap-1 mt-auto">
                {(student.skills || []).slice(0, 3).map((skill, idx) => (
                  <span key={idx} className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[10px] font-medium border border-slate-200">
                    {skill}
                  </span>
                ))}
                {(student.skills || []).length > 3 && (
                  <span className="px-2 py-0.5 bg-slate-50 text-slate-500 rounded-md text-[10px] font-medium border border-slate-200">
                    +{(student.skills || []).length - 3}
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
      {selectedStudent && (
        <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden shadow-2xl">
            
            {/* Modal Header */}
            <div className="flex items-start justify-between p-6 pb-4 border-b border-slate-100">
              <div>
                <h3 className="text-xl font-bold text-slate-900">{selectedStudent.fullName}</h3>
                <div className="text-sm font-medium text-slate-500 mt-1 flex items-center gap-2">
                  <span className="flex items-center gap-1"><span className="material-symbols-outlined text-[16px]">school</span> {selectedStudent.universityName}</span>
                </div>
              </div>
              <button 
                onClick={() => setSelectedStudent(null)}
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
                  <span className="text-lg font-bold text-slate-900">{(selectedStudent.gpa || 0).toFixed(2)} <span className="text-slate-400 text-sm font-medium">/ 4.0</span></span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Status</span>
                  <span className="text-base font-bold text-slate-900">{selectedStudent.academicStatus || 'Student'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Schedule</span>
                  <span className="text-base font-bold text-slate-900">{selectedStudent.lectureScheduleType || 'N/A'}</span>
                </div>
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 flex flex-col items-center justify-center text-center">
                  <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">Expected Grad</span>
                  <span className="text-base font-bold text-slate-900">{selectedStudent.expectedGraduationDate ? new Date(selectedStudent.expectedGraduationDate).getFullYear() : 'N/A'}</span>
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
                        <span className="text-sm font-medium text-slate-900">{selectedStudent.phone || 'N/A'}</span>
                      </div>
                      <div className="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg shadow-sm">
                        <span className="text-xs font-semibold text-slate-500">Degree</span>
                        <span className="text-sm font-medium text-slate-900">{selectedStudent.degreeProgram || 'N/A'}</span>
                      </div>
                      {selectedStudent.portfolioUrl && (
                        <div className="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg shadow-sm">
                          <span className="text-xs font-semibold text-slate-500">Portfolio</span>
                          <a href={selectedStudent.portfolioUrl} target="_blank" rel="noreferrer" className="text-sm font-medium text-blue-600 hover:underline">View Portfolio</a>
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
                      {selectedStudent.careerObjectivesSummary || 'No objectives specified.'}
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <span className="material-symbols-outlined text-[18px] text-blue-600">work</span>
                      <h4 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Work Preferences</h4>
                    </div>
                    <div className="space-y-3">
                      {selectedStudent.internshipType && selectedStudent.internshipType.length > 0 && (
                        <div>
                          <span className="block text-xs font-semibold text-slate-500 mb-2">Internship Type</span>
                          <div className="flex flex-wrap gap-2">
                            {selectedStudent.internshipType.map((type, i) => (
                              <span key={i} className="px-3 py-1 bg-white text-slate-700 text-xs font-bold rounded-md border border-slate-300 shadow-sm">
                                {type}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                      {selectedStudent.preferredLocations && selectedStudent.preferredLocations.length > 0 && (
                        <div className="mt-4">
                          <span className="block text-xs font-semibold text-slate-500 mb-2">Locations</span>
                          <div className="flex flex-wrap gap-2">
                            {selectedStudent.preferredLocations.map((loc, i) => (
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
                    {selectedStudent.skills && selectedStudent.skills.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {selectedStudent.skills.map((skill, i) => (
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
                    {selectedStudent.toolsAndTechnologies && selectedStudent.toolsAndTechnologies.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {selectedStudent.toolsAndTechnologies.map((tool, i) => (
                          <span key={i} className="px-3 py-1.5 bg-white text-slate-600 text-sm font-semibold rounded-lg border border-slate-200 shadow-sm">
                            {tool}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-sm text-slate-500">No tools listed.</p>
                    )}
                  </div>

                  {selectedStudent.cvPdfUrl && (
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
                              <span className="text-sm font-bold text-slate-900 truncate">Resume.pdf</span>
                              <span className="text-xs font-medium text-slate-500 mt-0.5">PDF • System Verified</span>
                            </div>
                          </div>
                          <div className="flex items-center gap-2 shrink-0">
                            <button type="button" onClick={() => window.open(`https://docs.google.com/viewer?url=${encodeURIComponent(selectedStudent.cvPdfUrl || '')}`, '_blank')} className="p-2 rounded-lg bg-white border border-slate-200 hover:border-blue-300 shadow-sm text-slate-600 hover:text-blue-700 transition-all flex items-center gap-1.5" title="View PDF">
                              <span className="material-symbols-outlined text-[16px]">visibility</span>
                              <span className="text-xs font-bold">View</span>
                            </button>
                            <button type="button" onClick={() => window.open(selectedStudent.cvPdfUrl || '', '_blank')} className="p-2 rounded-lg bg-white border border-slate-200 hover:border-blue-300 shadow-sm text-slate-600 hover:text-blue-700 transition-all flex items-center gap-1.5" title="Download PDF">
                              <span className="material-symbols-outlined text-[16px]">download</span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
            
            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex justify-end gap-3 rounded-b-2xl">
              <button 
                onClick={() => setSelectedStudent(null)}
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
