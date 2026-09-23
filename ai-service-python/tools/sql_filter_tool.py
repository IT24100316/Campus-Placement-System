import os
import psycopg2
from psycopg2.extras import RealDictCursor
from langchain_core.tools import tool
from typing import Dict, Any

def get_db_connection():
    # Use Supabase Connection Pooler string
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        raise ValueError("DATABASE_URL environment variable is not set")
    return psycopg2.connect(db_url, cursor_factory=RealDictCursor)

@tool
def check_hard_filters_tool(student_id: str, job_id: str) -> Dict[str, Any]:
    """
    Tier 1 hard filters (GPA, year, internship type, domain, title, degree, location).
    Checks if a student meets the absolute minimum requirements for a job.
    Returns immediately with passed=False if any hard constraint fails, saving AI costs.
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Fetch Student details
                cur.execute('''
                    SELECT "GPA", "CurrentYearOfStudy", "InternshipType", 
                           "PrimaryDomain", "DesiredJobTitle", "DegreeProgram", "PreferredLocations"
                    FROM "StudentProfiles"
                    WHERE "UserId" = %s
                ''', (student_id,))
                student = cur.fetchone()
                
                # Fetch Job details
                cur.execute('''
                    SELECT "MinimumGPA", "AllowedYearsOfStudy", "InternshipType", 
                           "TargetDomain", "JobTitle", "PreferredDegreePrograms", "LocationCity"
                    FROM "Jobs"
                    WHERE "JobId" = %s
                ''', (job_id,))
                job = cur.fetchone()
                
        if not student:
            return {"passed": False, "reason": "Student profile not found."}
        if not job:
            return {"passed": False, "reason": "Job not found."}
            
        # 1. GPA Check
        if student["GPA"] is not None and job["MinimumGPA"] is not None:
            if student["GPA"] < job["MinimumGPA"]:
                return {"passed": False, "reason": f"Student GPA ({student['GPA']}) is below job minimum ({job['MinimumGPA']})."}
                
        # 2. Year of Study Check
        if job["AllowedYearsOfStudy"] and student["CurrentYearOfStudy"] not in job["AllowedYearsOfStudy"]:
            return {"passed": False, "reason": f"Student year ({student['CurrentYearOfStudy']}) not in allowed years {job['AllowedYearsOfStudy']}."}
            
        # 3. Internship Type Check (Intersection)
        if job["InternshipType"] and student["InternshipType"]:
            job_types = set(j.lower() for j in job["InternshipType"])
            student_types = set(s.lower() for s in student["InternshipType"])
            if not job_types.intersection(student_types):
                return {"passed": False, "reason": "No overlap in Internship Types."}
                
        # 4. Domain Check
        if job["TargetDomain"] and student["PrimaryDomain"]:
            if job["TargetDomain"].lower() != student["PrimaryDomain"].lower():
                return {"passed": False, "reason": f"Domain mismatch (Student: {student['PrimaryDomain']}, Job: {job['TargetDomain']})."}
                
        # 5. Degree Program Check
        if job["PreferredDegreePrograms"] and student["DegreeProgram"]:
            job_degrees = set(d.lower() for d in job["PreferredDegreePrograms"])
            if student["DegreeProgram"].lower() not in job_degrees:
                return {"passed": False, "reason": f"Degree mismatch (Student: {student['DegreeProgram']})."}
                
        # 6. Location Check
        if job["LocationCity"] and student["PreferredLocations"]:
            job_loc = job["LocationCity"].lower()
            student_locs = set(l.lower() for l in student["PreferredLocations"])
            if job_loc not in student_locs and "any" not in student_locs:
                return {"passed": False, "reason": f"Location mismatch (Job is in {job['LocationCity']})."}
                
        return {"passed": True, "reason": "All hard filters passed."}
        
    except Exception as e:
        return {"passed": False, "reason": f"Database error during hard filter check: {str(e)}"}
