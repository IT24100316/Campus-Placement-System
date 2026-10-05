import React, { useState, useEffect } from 'react';
import { Users, Building2, Sparkles, LogOut, ShieldCheck, Bell, UserCircle2, X } from 'lucide-react';
import { StaffStudentsView } from './StaffStudentsView';
import { StaffJobsView } from './StaffJobsView';
import { ApplicationsPage } from './ApplicationsPage';
import { Footer } from '../components/layout/Footer';
import { API_BASE } from '../config/api';

interface StaffDashboardPageProps {
  onLogout?: () => void;
  userEmail?: string;
}


// This is the main dashboard shell for University Staff!
// It acts as a container, holding the top navigation bar and switching between the Students, Jobs, and Applications views.
export const StaffDashboardPage: React.FC<StaffDashboardPageProps> = ({ onLogout, userEmail }) => {
  const [activeTab, setActiveTab] = useState<'students' | 'jobs' | 'applications'>('applications');
  const [profilePanelOpen, setProfilePanelOpen] = useState(false);
  const [memoCount, setMemoCount] = useState(0);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [forceMemoFilter, setForceMemoFilter] = useState<'all' | 'action_required' | 'no_action_required'>('all');
  
  const email = userEmail || 'staff@campusai.edu';

  useEffect(() => {
    const fetchMemoCount = async () => {
      try {
        const res = await fetch(`${API_BASE}/Applications/memos/action-required/count`);
        if (res.ok) {
          const data = await res.json();
          setMemoCount(data.count || 0);
        }
      } catch (err) {
        console.error('Failed to fetch memo count', err);
      }
    };
    fetchMemoCount();
  }, []);

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900 font-sans">
      {/* Top Navigation Bar (Desktop) */}
      <header className="fixed top-0 left-0 right-0 w-full z-50 bg-white/95 backdrop-blur-xl border-b border-slate-200 shadow-[0_1px_8px_rgba(15,23,42,0.04)]">
        <div className="h-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4">
          
          {/* Brand */}
          <div className="flex items-center gap-6 lg:gap-8">
            <div className="flex items-center gap-2.5 group cursor-default">
              <div className="w-8 h-8 rounded-lg bg-blue-700 flex items-center justify-center text-white shadow-sm transition-transform group-hover:scale-105">
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2L2 7l10 5 10-5-10-5z" />
                  <path d="M2 17l10 5 10-5" />
                  <path d="M2 12l10 5 10-5" />
                </svg>
              </div>
              <div className="flex flex-col text-left">
                <span className="font-display text-base font-bold text-slate-900 leading-none">CampusAI</span>
                <span className="text-[10px] text-blue-700 uppercase tracking-widest font-semibold mt-0.5">Staff Portal</span>
              </div>
            </div>

            {/* Desktop Tabs */}
            <nav className="hidden xl:flex items-center gap-1.5 ml-4">
              <button
                onClick={() => setActiveTab('students')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${activeTab === 'students' ? 'bg-blue-50 text-blue-700 border border-blue-100' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'}`}
              >
                <Users className={`w-4 h-4 ${activeTab === 'students' ? 'text-blue-700' : 'text-slate-500'}`} />
                <span>Students Directory</span>
              </button>
              <button
                onClick={() => setActiveTab('jobs')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${activeTab === 'jobs' ? 'bg-blue-50 text-blue-700 border border-blue-100' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'}`}
              >
                <Building2 className={`w-4 h-4 ${activeTab === 'jobs' ? 'text-blue-700' : 'text-slate-500'}`} />
                <span>Jobs Directory</span>
              </button>
              <button
                onClick={() => setActiveTab('applications')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${activeTab === 'applications' ? 'bg-blue-50 text-blue-700 border border-blue-100' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'}`}
              >
                <Sparkles className={`w-4 h-4 ${activeTab === 'applications' ? 'text-blue-700' : 'text-slate-500'}`} />
                <span>AI Matching & Approvals</span>
              </button>
            </nav>
          </div>

          {/* Right Actions */}
          <div className="flex items-center gap-3">
            {/* Profile Identity Pill */}
            <div className="hidden sm:flex items-center gap-2.5 px-3 py-1.5 rounded-lg bg-slate-50 border border-slate-200/80 shadow-xs">
              <div className="w-7 h-7 rounded bg-blue-700 text-white flex items-center justify-center text-xs font-bold font-mono">
                ST
              </div>
              <div className="flex flex-col text-left leading-tight">
                <div className="flex items-center gap-1">
                  <span className="text-xs font-bold text-slate-900 max-w-[170px] truncate" title="Staff Member">
                    Staff Member
                  </span>
                  <ShieldCheck className="w-3.5 h-3.5 text-blue-600 shrink-0" />
                </div>
                <span className="text-[10px] text-slate-500 truncate max-w-[170px]">
                  {email}
                </span>
              </div>
            </div>

            {/* Notification Bell */}
            <div className="relative">
              <button 
                onClick={() => setNotificationsOpen(!notificationsOpen)}
                className="relative w-8 h-8 rounded-lg flex items-center justify-center text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer focus:outline-none ml-1"
              >
                <Bell className="w-4 h-4" />
                {memoCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-blue-700 rounded-full ring-2 ring-white"></span>
                )}
              </button>
              
              {/* Notification Dropdown */}
              {notificationsOpen && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setNotificationsOpen(false)}></div>
                  <div className="absolute right-0 mt-2 w-80 bg-white border border-slate-200 shadow-xl rounded-xl z-50 overflow-hidden flex flex-col">
                    <div className="px-4 py-3 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
                      <h3 className="text-sm font-bold text-slate-800">Alerts</h3>
                      <span className="text-[10px] font-semibold bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">
                        {memoCount > 0 ? 1 : 0} New
                      </span>
                    </div>
                    
                    <div className="max-h-[300px] overflow-y-auto">
                      {memoCount === 0 ? (
                        <div className="p-6 text-center text-slate-500 text-sm">
                          No new notifications at this time.
                        </div>
                      ) : (
                        <button
                          type="button"
                          onClick={() => {
                            setNotificationsOpen(false);
                            setActiveTab('applications');
                            setForceMemoFilter('action_required');
                          }}
                          className="w-full text-left px-4 py-3 border-b border-slate-50 hover:bg-slate-50 transition-colors cursor-pointer flex items-start gap-3"
                        >
                          <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 mt-0.5">
                            <Sparkles className="w-4 h-4" />
                          </div>
                          <div className="flex-1">
                            <p className="text-xs text-slate-600 leading-snug">
                              <span className="font-bold text-slate-900">You have {memoCount} Action Required Memos</span> to review.
                            </p>
                            <p className="text-[10px] text-slate-400 mt-1">Click to view applications</p>
                          </div>
                        </button>
                      )}
                    </div>
                  </div>
                </>
              )}
            </div>
            
            {/* My Profile Button */}
            <button
              onClick={() => setProfilePanelOpen(true)}
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-700 hover:text-white hover:bg-blue-700 border border-blue-700/30 hover:border-blue-700 px-3 py-2 rounded-lg transition-all shadow-xs focus:ring-2 focus:ring-blue-200 focus:outline-none cursor-pointer ml-1"
              title="View Staff Profile"
            >
              <UserCircle2 className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">My Profile</span>
            </button>
            
            {/* Logout Button */}
            <button 
              onClick={onLogout}
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-rose-600 hover:text-white hover:bg-rose-600 border border-rose-200 hover:border-rose-600 px-3 py-2 rounded-lg transition-all shadow-xs focus:ring-2 focus:ring-rose-200 focus:outline-none cursor-pointer"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Logout</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <div className="flex-1 w-full pt-16 pb-20 xl:pb-0">
        {activeTab === 'applications' && <ApplicationsPage hideHeader={true} userEmail={email} onLogout={onLogout} forceMemoFilter={forceMemoFilter} />}
        
        {activeTab === 'students' && (
          <main className="max-w-7xl w-full mx-auto px-6 py-8">
            <div className="mb-6">
              <h1 className="font-bold text-2xl sm:text-3xl tracking-tight">Students Directory</h1>
              <p className="text-sm text-slate-500 mt-1">Browse and search through all registered students.</p>
            </div>
            <StaffStudentsView />
          </main>
        )}

        {activeTab === 'jobs' && (
          <main className="max-w-7xl w-full mx-auto px-6 py-8">
            <div className="mb-6">
              <h1 className="font-bold text-2xl sm:text-3xl tracking-tight">Jobs Directory</h1>
              <p className="text-sm text-slate-500 mt-1">Browse all active job placement drives across all companies.</p>
            </div>
            <StaffJobsView />
          </main>
        )}
      </div>

      {/* Bottom Navigation Bar (Mobile / Tablet) */}
      <div className="xl:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 z-50 px-2 py-2 flex justify-around shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
        <button
          onClick={() => setActiveTab('students')}
          className={`flex flex-col items-center p-2 rounded-lg min-w-[72px] transition-colors ${activeTab === 'students' ? 'text-blue-700' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-50'}`}
        >
          <Users className="w-5 h-5 mb-1" />
          <span className="text-[10px] font-semibold">Students</span>
        </button>
        <button
          onClick={() => setActiveTab('jobs')}
          className={`flex flex-col items-center p-2 rounded-lg min-w-[72px] transition-colors ${activeTab === 'jobs' ? 'text-blue-700' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-50'}`}
        >
          <Building2 className="w-5 h-5 mb-1" />
          <span className="text-[10px] font-semibold">Jobs</span>
        </button>
        <button
          onClick={() => setActiveTab('applications')}
          className={`flex flex-col items-center p-2 rounded-lg min-w-[72px] transition-colors ${activeTab === 'applications' ? 'text-blue-700' : 'text-slate-500 hover:text-slate-900 hover:bg-slate-50'}`}
        >
          <Sparkles className="w-5 h-5 mb-1" />
          <span className="text-[10px] font-semibold">Matching</span>
        </button>
      </div>

      <Footer />

      {/* PROFILE SLIDE-OVER PANEL */}
      {profilePanelOpen && (
        <div className="fixed inset-0 z-[100] flex justify-end">
          <div className="absolute inset-0 bg-slate-900/30 backdrop-blur-sm transition-opacity" onClick={() => setProfilePanelOpen(false)}></div>
          <div className="relative w-full max-w-md bg-white h-full shadow-2xl flex flex-col transform transition-transform">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-900">Staff Profile</h2>
              <button onClick={() => setProfilePanelOpen(false)} className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 flex-1 overflow-y-auto bg-slate-50/50">
              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm mb-6 flex flex-col items-center text-center">
                <div className="w-16 h-16 rounded-2xl bg-blue-100 text-blue-700 flex items-center justify-center text-2xl font-bold font-mono mb-4">
                  ST
                </div>
                <h3 className="font-bold text-lg text-slate-900">University Staff</h3>
                <p className="text-sm text-slate-500 mt-1">{email}</p>
                <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-50 text-emerald-700 rounded-full text-xs font-semibold">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  Verified Member
                </div>
              </div>
              
              <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
                <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/50">
                  <p className="text-xs font-bold text-slate-500 uppercase tracking-wider">Role Details</p>
                </div>
                <div className="p-5 space-y-4">
                  <div>
                    <p className="text-xs text-slate-400 font-medium mb-1">Account Type</p>
                    <p className="text-sm font-semibold text-slate-900">Administrator / Staff</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium mb-1">Permissions</p>
                    <p className="text-sm font-semibold text-slate-900">Student & Job Management, Application Approval</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
