from state import AgentState
from tools.sql_filter_tool import check_hard_filters_tool, fetch_job_posting, fetch_all_student_ids, fetch_student_profile

def tier1_node(state: AgentState) -> dict:
    """
    Tier 1 Node: Applies hard database filters to the initial list of students.
    Only students who pass the hard constraints are forwarded as `candidates`.
    Also fetches the actual student profiles and job posting from the DB so they are
    available in the state for the Analysis Agent.
    """
    job_id = state.get("job_id")
    student_ids = state.get("initial_student_ids", [])
    evaluate_all = state.get("evaluate_all", False)
    
    if not job_id:
        return {"candidates": [], "job_posting": {}}
    if not student_ids and not evaluate_all:
        return {"candidates": [], "job_posting": {}}
        
    passed_candidates = []
    job_posting = None
    
    # We need the full profiles for the Analysis node, so we will fetch them manually here
    # Since check_hard_filters_tool already does the check, we'll run it, and if it passes, fetch the profile.
    # To optimize, we could fetch them all at once, but we'll keep it simple and reuse the tool.
    
    try:
        job_posting = fetch_job_posting(job_id)
        
        # If evaluate_all is True, query all students
        if evaluate_all:
            student_ids = fetch_all_student_ids()
            
        # Evaluate each student
        for sid in student_ids:
            # check_hard_filters_tool is a langchain tool, we can invoke it directly or call its func
            res = check_hard_filters_tool.invoke({"student_id": sid, "job_id": job_id})
            if res.get("passed", False):
                # Fetch the full student profile for the next node
                student_profile = fetch_student_profile(sid)
                if student_profile:
                    passed_candidates.append(student_profile)
    except Exception as e:
        print(f"Error in Tier 1 Node: {e}")
        
    print(f"✅ Tier 1 Filter finished! Passed {len(passed_candidates)} candidates.")
    
    return {
        "job_posting": job_posting or {},
        "candidates": passed_candidates
    }
