from state import AgentState
from tools.sql_filter_tool import check_hard_filters_tool, get_db_connection

def tier1_node(state: AgentState) -> dict:
    """
    Tier 1 Node: Applies hard database filters to the initial list of students.
    Only students who pass the hard constraints are forwarded as `candidates`.
    Also fetches the actual student profiles and job posting from the DB so they are
    available in the state for the Analysis Agent.
    """
    job_id = state.get("job_id")
    student_ids = state.get("initial_student_ids", [])
    
    if not job_id or not student_ids:
        return {"candidates": [], "job_posting": {}}
        
    passed_candidates = []
    job_posting = None
    
    # We need the full profiles for the Analysis node, so we will fetch them manually here
    # Since check_hard_filters_tool already does the check, we'll run it, and if it passes, fetch the profile.
    # To optimize, we could fetch them all at once, but we'll keep it simple and reuse the tool.
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Fetch job posting
                cur.execute('SELECT * FROM "Jobs" WHERE "JobId" = %s', (job_id,))
                job_row = cur.fetchone()
                if job_row:
                    job_posting = dict(job_row)
                    
                # Evaluate each student
                for sid in student_ids:
                    # check_hard_filters_tool is a langchain tool, we can invoke it directly or call its func
                    res = check_hard_filters_tool.invoke({"student_id": sid, "job_id": job_id})
                    if res.get("passed", False):
                        # Fetch the full student profile for the next node
                        cur.execute('SELECT * FROM "StudentProfiles" WHERE "UserId" = %s', (sid,))
                        student_row = cur.fetchone()
                        if student_row:
                            passed_candidates.append(dict(student_row))
    except Exception as e:
        print(f"Error in Tier 1 Node: {e}")
        
    return {
        "job_posting": job_posting or {},
        "candidates": passed_candidates
    }
