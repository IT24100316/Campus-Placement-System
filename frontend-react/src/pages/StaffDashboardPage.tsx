import React, { useState } from 'react';
import { Users, Building2, Sparkles, LogOut, ShieldCheck, Bell, UserCircle2, X } from 'lucide-react';
import { StaffStudentsView } from './StaffStudentsView';
import { StaffJobsView } from './StaffJobsView';
import { ApplicationsPage } from './ApplicationsPage';
import { Footer } from '../components/layout/Footer';

interface StaffDashboardPageProps {
  onLogout?: () => void;
  userEmail?: string;
}

// This is the main dashboard shell for University Staff!
// It acts as a container, holding the top navigation bar and switching between the Students, Jobs, and Applications views.
export const StaffDashboardPage: React.FC<StaffDashboardPageProps> = ({ onLogout, userEmail }) => {
  const [activeTab, setActiveTab] = useState<'students' | 'jobs' | 'applications'>('applications');
  const [profilePanelOpen, setProfilePanelOpen] = useState(false);
  
  const email = userEmail || 'staff@campusai.edu';

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
          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-3 pr-4 border-r border-slate-200">
              <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center border border-blue-100 shrink-0">
                <span className="text-sm font-bold text-blue-700">ST</span>
              </div>
              <div className="flex flex-col text-left">
                <span className="text-sm font-bold text-slate-900 flex items-center gap-1">
                  Staff Member
                  <ShieldCheck className="w-3.5 h-3.5 text-blue-600" />
                </span>
                <span className="text-xs font-medium text-slate-500">{email}</span>
              </div>
            </div>

            <button className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-lg transition-colors relative">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
            </button>
            
            <button
              onClick={() => setProfilePanelOpen(true)}
              className="flex items-center gap-2 px-3 py-1.5 text-sm font-semibold text-slate-600 hover:text-blue-700 hover:bg-slate-50 rounded-lg border border-transparent hover:border-slate-200 transition-all focus:outline-none"
              title="View Staff Profile"
            >
              <UserCircle2 className="w-4 h-4" />
              <span className="hidden sm:inline">My Profile</span>
            </button>
            <button 
              onClick={onLogout}
              className="flex items-center gap-2 px-3 py-1.5 text-sm font-semibold text-rose-600 hover:text-rose-700 hover:bg-rose-50 rounded-lg border border-transparent hover:border-rose-100 transition-all focus:outline-none"
            >
              <LogOut className="w-4 h-4" />
              <span className="hidden sm:inline">Logout</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <div className="flex-1 w-full pt-16 pb-20 xl:pb-0">
        {activeTab === 'applications' && <ApplicationsPage hideHeader={true} userEmail={email} onLogout={onLogout} />}
        
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
