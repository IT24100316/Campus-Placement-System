import React, { useState, useEffect } from 'react';
import {
  ShieldCheck,
  Check,
  X,
  Eye,
  Building2,
  Users,
  FileText,
  Clock,
  CheckCircle2,
  XCircle,
  Filter,
  ArrowLeft,
} from 'lucide-react';
import type { RegistrationRecord, AccountApprovalStatus } from '../../types/auth';
import { authService } from '../../services/authService';

interface AdminApprovalsViewProps {
  onBackToHome: () => void;
  onNavigateRegister: () => void;
}

export const AdminApprovalsView: React.FC<AdminApprovalsViewProps> = ({
  onBackToHome,
  onNavigateRegister,
}) => {
  const [records, setRecords] = useState<RegistrationRecord[]>([]);
  const [filter, setFilter] = useState<'all' | 'hr' | 'staff' | 'pending'>('pending');
  const [selectedRecord, setSelectedRecord] = useState<RegistrationRecord | null>(null);

  useEffect(() => {
    setRecords(authService.getRegistrations());
  }, []);

  const handleAction = (id: string, newStatus: 'Approved' | 'Rejected') => {
    const updated = authService.updateStatus(id, newStatus);
    setRecords([...updated]);
    if (selectedRecord && selectedRecord.id === id) {
      setSelectedRecord({ ...selectedRecord, status: newStatus });
    }
  };

  const filteredRecords = records.filter((r) => {
    if (filter === 'pending') return r.status === 'Pending';
    if (filter === 'hr') return r.role === 'hr';
    if (filter === 'staff') return r.role === 'staff';
    return true;
  });

  const pendingCount = records.filter((r) => r.status === 'Pending').length;
  const hrCount = records.filter((r) => r.role === 'hr').length;
  const staffCount = records.filter((r) => r.role === 'staff').length;
  const approvedCount = records.filter((r) => r.status === 'Approved').length;

  const renderStatusBadge = (status: AccountApprovalStatus) => {
    switch (status) {
      case 'Pending':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-200">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse"></span>
            Pending
          </span>
        );
      case 'Approved':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
            Approved
          </span>
        );
      case 'Rejected':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-800 border border-rose-200">
            <XCircle className="w-3.5 h-3.5 text-rose-600" />
            Rejected
          </span>
        );
    }
  };

  return (
    <div className="w-full max-w-7xl mx-auto py-8 px-4 sm:px-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-100 text-indigo-700 text-xs font-semibold uppercase tracking-wider mb-2">
            <ShieldCheck className="w-4 h-4 text-indigo-600" />
            Institutional Placement Office
          </div>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">
            Pending User Approvals
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Review corporate recruiter profiles, verify statutory documents, and authorize campus placement seats.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onNavigateRegister}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-semibold transition-all shadow-sm cursor-pointer"
          >
            <span>+ Test New Registration</span>
          </button>
          <button
            type="button"
            onClick={onBackToHome}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg bg-primary hover:bg-blue-700 text-white text-xs font-semibold transition-all shadow-sm cursor-pointer"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Portal</span>
          </button>
        </div>
      </div>

      {/* KPI Statistic Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 my-6">
        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex flex-col">
          <div className="flex items-center justify-between text-amber-600 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wide">Waiting Approval</span>
            <Clock className="w-4 h-4" />
          </div>
          <span className="text-2xl font-bold text-slate-900">{pendingCount}</span>
          <span className="text-[11px] text-slate-500 mt-0.5">Requires immediate review</span>
        </div>

        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex flex-col">
          <div className="flex items-center justify-between text-blue-600 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wide">Company HRs</span>
            <Building2 className="w-4 h-4" />
          </div>
          <span className="text-2xl font-bold text-slate-900">{hrCount}</span>
          <span className="text-[11px] text-slate-500 mt-0.5">Primary administrators</span>
        </div>

        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex flex-col">
          <div className="flex items-center justify-between text-indigo-600 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wide">Company Staff</span>
            <Users className="w-4 h-4" />
          </div>
          <span className="text-2xl font-bold text-slate-900">{staffCount}</span>
          <span className="text-[11px] text-slate-500 mt-0.5">Interviewers &amp; evaluators</span>
        </div>

        <div className="p-4 rounded-xl bg-white border border-slate-200/80 shadow-sm flex flex-col">
          <div className="flex items-center justify-between text-emerald-600 mb-1">
            <span className="text-xs font-semibold uppercase tracking-wide">Authorized Total</span>
            <CheckCircle2 className="w-4 h-4" />
          </div>
          <span className="text-2xl font-bold text-slate-900">{approvedCount}</span>
          <span className="text-[11px] text-slate-500 mt-0.5">Active enterprise seats</span>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
        <div className="inline-flex p-1 rounded-lg bg-slate-100 border border-slate-200 text-xs">
          <button
            type="button"
            onClick={() => setFilter('pending')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-all cursor-pointer ${
              filter === 'pending' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Pending ({pendingCount})
          </button>
          <button
            type="button"
            onClick={() => setFilter('all')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-all cursor-pointer ${
              filter === 'all' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            All Submissions ({records.length})
          </button>
          <button
            type="button"
            onClick={() => setFilter('hr')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-all cursor-pointer ${
              filter === 'hr' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            HR Accounts ({hrCount})
          </button>
          <button
            type="button"
            onClick={() => setFilter('staff')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-all cursor-pointer ${
              filter === 'staff' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Staff Accounts ({staffCount})
          </button>
        </div>

        <div className="text-xs text-slate-500 flex items-center gap-1.5">
          <Filter className="w-3.5 h-3.5" />
          <span>Showing {filteredRecords.length} accounts</span>
        </div>
      </div>

      {/* Main Approvals Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold uppercase tracking-wider">
                <th className="py-3.5 px-4">Applicant &amp; Email</th>
                <th className="py-3.5 px-4">Role</th>
                <th className="py-3.5 px-4">Corporate Entity</th>
                <th className="py-3.5 px-4">Designation / Staff ID</th>
                <th className="py-3.5 px-4">BR Document</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500">
                    <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2 opacity-80" />
                    <p className="font-semibold text-slate-800">No pending accounts found.</p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      All submitted corporate recruiter applications have been reviewed.
                    </p>
                  </td>
                </tr>
              ) : (
                filteredRecords.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/80 transition-colors">
                    {/* Applicant & Email */}
                    <td className="py-3.5 px-4">
                      <div className="flex flex-col">
                        <span className="font-semibold text-slate-900 text-sm">{item.fullName}</span>
                        <span className="text-slate-500">{item.email}</span>
                        <span className="text-[11px] text-slate-400 mt-0.5">{item.phone}</span>
                      </div>
                    </td>

                    {/* Role Badge */}
                    <td className="py-3.5 px-4">
                      {item.role === 'hr' ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-blue-50 text-blue-700 border border-blue-200">
                          <Building2 className="w-3 h-3" />
                          Company HR
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">
                          <Users className="w-3 h-3" />
                          Company Staff
                        </span>
                      )}
                    </td>

                    {/* Corporate Entity */}
                    <td className="py-3.5 px-4">
                      <div className="flex flex-col">
                        <span className="font-semibold text-slate-800">{item.companyName}</span>
                        <span className="text-[11px] text-slate-500">
                          {item.role === 'hr' ? item.industry : 'Affiliated Seat'}
                        </span>
                      </div>
                    </td>

                    {/* Designation / Staff ID */}
                    <td className="py-3.5 px-4">
                      {item.role === 'hr' ? (
                        <span className="text-slate-600 font-medium">Head of Talent Acquisition</span>
                      ) : (
                        <div className="flex flex-col">
                          <span className="font-semibold text-slate-800">{item.jobPosition}</span>
                          <span className="text-[11px] font-mono text-slate-500">
                            ID: {item.staffId}
                          </span>
                        </div>
                      )}
                    </td>

                    {/* BR Document */}
                    <td className="py-3.5 px-4">
                      {item.role === 'hr' ? (
                        <button
                          type="button"
                          onClick={() => setSelectedRecord(item)}
                          className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-medium transition-colors cursor-pointer"
                        >
                          <FileText className="w-3.5 h-3.5 text-primary" />
                          <span className="max-w-[120px] truncate">{item.documentName || 'BR_Doc.pdf'}</span>
                        </button>
                      ) : (
                        <span className="text-slate-400 text-[11px] italic">Not Required</span>
                      )}
                    </td>

                    {/* Status Badge */}
                    <td className="py-3.5 px-4">{renderStatusBadge(item.status)}</td>

                    {/* Actions */}
                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => setSelectedRecord(item)}
                          className="p-1.5 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-md transition-colors"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </button>

                        {item.status === 'Pending' && (
                          <>
                            <button
                              type="button"
                              onClick={() => handleAction(item.id, 'Approved')}
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-xs font-semibold transition-all shadow-xs cursor-pointer active:scale-95"
                              title="Approve User"
                            >
                              <Check className="w-3.5 h-3.5" />
                              <span>Approve</span>
                            </button>

                            <button
                              type="button"
                              onClick={() => handleAction(item.id, 'Rejected')}
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-md text-xs font-semibold transition-all cursor-pointer active:scale-95"
                              title="Reject User"
                            >
                              <X className="w-3.5 h-3.5" />
                              <span>Reject</span>
                            </button>
                          </>
                        )}

                        {item.status !== 'Pending' && (
                          <button
                            type="button"
                            onClick={() =>
                              handleAction(
                                item.id,
                                item.status === 'Approved' ? 'Rejected' : 'Approved'
                              )
                            }
                            className="text-[11px] text-slate-500 hover:text-slate-800 underline underline-offset-2 ml-1"
                          >
                            Change to {item.status === 'Approved' ? 'Reject' : 'Approve'}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Document & Applicant Detail Modal */}
      {selectedRecord && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xl w-full max-w-xl p-6 relative">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-primary" />
                <h3 className="font-display text-base font-bold text-slate-900">
                  Application Review — {selectedRecord.refCode}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setSelectedRecord(null)}
                className="p-1 rounded-md text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="py-4 space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3 p-3 bg-slate-50 rounded-xl">
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">Applicant Name</span>
                  <p className="font-bold text-slate-900 text-sm mt-0.5">{selectedRecord.fullName}</p>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">Role</span>
                  <p className="font-bold text-slate-900 text-sm mt-0.5">
                    {selectedRecord.role === 'hr' ? 'Company HR' : 'Company Staff'}
                  </p>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">Corporate Email</span>
                  <p className="font-semibold text-slate-800 mt-0.5">{selectedRecord.email}</p>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">Direct Phone</span>
                  <p className="font-semibold text-slate-800 mt-0.5">{selectedRecord.phone}</p>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">Registered Company</span>
                  <p className="font-bold text-primary mt-0.5">{selectedRecord.companyName}</p>
                </div>
                <div>
                  <span className="text-slate-400 uppercase font-semibold text-[10px]">
                    {selectedRecord.role === 'hr' ? 'Industry Vertical' : 'Staff ID / Designation'}
                  </span>
                  <p className="font-semibold text-slate-800 mt-0.5">
                    {selectedRecord.role === 'hr'
                      ? selectedRecord.industry
                      : `${selectedRecord.staffId} (${selectedRecord.jobPosition})`}
                  </p>
                </div>
              </div>

              {/* Document Preview Section */}
              {selectedRecord.role === 'hr' && (
                <div className="p-4 rounded-xl border border-slate-200 bg-white">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold text-slate-800">Business Registration Certificate</span>
                    <span className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1">
                      <CheckCircle2 className="w-3.5 h-3.5" /> 256-bit Encrypted
                    </span>
                  </div>
                  <div className="p-3 bg-slate-50 rounded-lg flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <FileText className="w-6 h-6 text-primary" />
                      <div>
                        <p className="font-semibold text-slate-900">{selectedRecord.documentName}</p>
                        <p className="text-[11px] text-slate-500">
                          {selectedRecord.documentSize || '2.4 MB'} • Verified Statutory Record
                        </p>
                      </div>
                    </div>
                    <span className="px-2 py-0.5 bg-blue-50 text-primary font-semibold text-[11px] rounded">
                      PDF Document
                    </span>
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between pt-2">
                <div>
                  <span className="text-slate-500">Current Status: </span>
                  {renderStatusBadge(selectedRecord.status)}
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      handleAction(selectedRecord.id, 'Rejected');
                      setSelectedRecord(null);
                    }}
                    className="px-4 py-2 rounded-lg bg-rose-50 text-rose-700 border border-rose-200 font-semibold hover:bg-rose-100 transition-colors"
                  >
                    Reject Application
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      handleAction(selectedRecord.id, 'Approved');
                      setSelectedRecord(null);
                    }}
                    className="px-4 py-2 rounded-lg bg-emerald-600 text-white font-semibold hover:bg-emerald-700 transition-colors"
                  >
                    Approve Application
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
