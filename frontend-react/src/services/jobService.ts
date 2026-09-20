import type { TargetDomain, JobTitle, CreateJobPayload, JobResponse } from '../types/job';

const API_BASE = 'http://localhost:5168/api';

export const jobService = {
  /**
   * Fetch all controlled Target Domains from the database
   */
  async getDomains(): Promise<TargetDomain[]> {
    try {
      const response = await fetch(`${API_BASE}/jobs/reference/domains`);
      if (!response.ok) {
        throw new Error(`Failed to load target domains: ${response.statusText}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching target domains from DB:', error);
      throw error;
    }
  },

  /**
   * Fetch controlled Job Titles for a selected Target Domain from the database
   */
  async getJobTitles(domainId?: number, domainName?: string): Promise<JobTitle[]> {
    try {
      const params = new URLSearchParams();
      if (domainId) params.append('domainId', domainId.toString());
      if (domainName) params.append('domain', domainName);

      const response = await fetch(`${API_BASE}/jobs/reference/titles?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Failed to load job titles: ${response.statusText}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching job titles from DB:', error);
      throw error;
    }
  },

  /**
   * Fetch controlled Internship Types from the backend enum (OnSite, Hybrid, Remote)
   */
  async getInternshipTypes(): Promise<string[]> {
    try {
      const response = await fetch(`${API_BASE}/jobs/reference/internship-types`);
      if (!response.ok) {
        throw new Error(`Failed to load internship types: ${response.statusText}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching internship types:', error);
      throw error;
    }
  },

  /**
   * Submit a new job posting to .NET API and save to Supabase database
   */
  async createJob(payload: CreateJobPayload): Promise<JobResponse> {
    const response = await fetch(`${API_BASE}/jobs`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      let errorDetails = 'Failed to create job posting.';
      try {
        const errorJson = await response.json();
        errorDetails = errorJson.message || errorJson.error || JSON.stringify(errorJson);
      } catch {
        errorDetails = await response.text();
      }
      throw new Error(errorDetails);
    }

    return await response.json();
  },
};
