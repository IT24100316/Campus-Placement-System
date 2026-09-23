import json
import os
from typing import List, Dict, Any, Tuple
from pydantic import BaseModel, Field
from langchain_core.prompts import ChatPromptTemplate

from state import AgentState, SkillBreakdown, CandidateResult
from tools.skill_equivalence_tool import canonicalize_pair, check_skill_cache, save_skill_equivalence
from tools.llm_equivalence_tool import check_llm_equivalence_batch

def normalize_skill(skill: str) -> str:
    """Lowercase, trim leading/trailing whitespace."""
    if not skill:
        return ""
    return str(skill).strip().lower()

def normalize_skill_list(skills: List[str]) -> List[str]:
    if not skills:
        return []
    return [normalize_skill(s) for s in skills if s and str(s).strip()]

def analysis_node(state: AgentState) -> dict:
    """
    The Analysis Agent node for LangGraph.
    Performs Tier 2 Semantic Skill Matching on a batch of candidates.
    Applies a threshold of 60% and logs the results.
    """
    candidates = state.get("candidates", [])
    job = state.get("job_posting", {})
    
    job_mandatory = normalize_skill_list(job.get("MandatorySkills", []))
    job_nice = normalize_skill_list(job.get("NiceToHaveSkills", []))
    
    # 1. Gather all unmatched skills across all candidates
    candidate_data = {} # {student_id: {"breakdown": [], "pending": []}}
    all_pending_pairs = set()
    
    for idx, student in enumerate(candidates):
        student_id = student.get("StudentId", f"student_{idx}")
        student_skills = normalize_skill_list(student.get("Skills", []))
        student_tools = normalize_skill_list(student.get("ToolsAndTechnologies", []))
        
        breakdown = []
        pending = []
        
        def process_category(req_skills, stud_skills, category_name):
            for req in req_skills:
                if req in stud_skills:
                    breakdown.append({
                        "required_skill": req, "category": category_name,
                        "student_skill": req, "match": True,
                        "resolution": "exact", "reason": "Exact normalized skill match."
                    })
                    continue
                if not stud_skills:
                    breakdown.append({
                        "required_skill": req, "category": category_name,
                        "student_skill": None, "match": False,
                        "resolution": "no_match", "reason": "Student has no skills listed in this category."
                    })
                    continue
                pending.append((req, category_name, stud_skills))
                for stud_sk in stud_skills:
                    all_pending_pairs.add((req, stud_sk))
                    
        process_category(job_mandatory, student_skills, "mandatory")
        process_category(job_nice, student_tools, "nice_to_have")
        
        candidate_data[student_id] = {"breakdown": breakdown, "pending": pending}

    # 2. Check DB Cache for all pairs
    cache_results = check_skill_cache(list(all_pending_pairs))
    
    # 3. Determine LLM Misses globally
    llm_misses = set()
    for req, stud_sk in all_pending_pairs:
        ca, cb = canonicalize_pair(req, stud_sk)
        if (ca, cb) not in cache_results:
            llm_misses.add((req, stud_sk))
            
    # 4. Batch LLM call for all unique missing pairs
    llm_results_dict = check_llm_equivalence_batch(list(llm_misses))
    for pair, res in llm_results_dict.items():
        save_skill_equivalence(pair[0], pair[1], res.is_match, res.reason)
        
    # Combine results
    def is_match_func(req, stud_sk):
        ca, cb = canonicalize_pair(req, stud_sk)
        if (ca, cb) in cache_results:
            return cache_results[(ca, cb)]["IsMatch"], cache_results[(ca, cb)]["Reason"], "cached_equivalent"
        if (req, stud_sk) in llm_results_dict:
            res = llm_results_dict[(req, stud_sk)]
            return res.is_match, res.reason, "llm_equivalent"
        return False, "No exact or verified equivalent skill.", "no_match"

    # 5. Resolve scores & filtering
    final_results = []
    log_lines = [
        "==================================================",
        "ANALYSIS AGENT BATCH RUN LOG",
        "==================================================",
        f"Job Title: {job.get('JobTitle', 'Unknown')}",
        f"Candidates processed: {len(candidates)}",
        f"Threshold to pass: 60%",
        "--------------------------------------------------\n"
    ]
    
    mandatory_total = len(job_mandatory)
    nice_total = len(job_nice)
    
    for student_id, data in candidate_data.items():
        breakdown = data["breakdown"]
        
        for req, cat, stud_skills in data["pending"]:
            match_found = False
            for stud_sk in stud_skills:
                match, reason, resolution = is_match_func(req, stud_sk)
                if match:
                    breakdown.append({
                        "required_skill": req, "category": cat,
                        "student_skill": stud_sk, "match": True,
                        "resolution": resolution, "reason": reason
                    })
                    match_found = True
                    break
            
            if not match_found:
                breakdown.append({
                    "required_skill": req, "category": cat,
                    "student_skill": None, "match": False,
                    "resolution": "no_match", "reason": "No exact or verified equivalent skill."
                })
                
        # Calculate Score
        mandatory_matches = sum(1 for b in breakdown if b["category"] == "mandatory" and b["match"])
        nice_matches = sum(1 for b in breakdown if b["category"] == "nice_to_have" and b["match"])
        
        score = 0.0
        if mandatory_total > 0:
            score += (mandatory_matches / mandatory_total) * 60.0
        else:
            score += 60.0 
            
        if nice_total > 0:
            score += (nice_matches / nice_total) * 40.0
        else:
            score += 40.0
            
        final_score = int(round(score))
        
        # Logging for this student
        status = "PASSED" if final_score >= 60 else "FAILED"
        log_lines.append(f"Student ID: {student_id}")
        log_lines.append(f"Score: {final_score}/100 [{status}]")
        log_lines.append(f"Mandatory Matches: {mandatory_matches}/{mandatory_total}")
        log_lines.append(f"Nice-to-Have Matches: {nice_matches}/{nice_total}")
        log_lines.append("Breakdown:")
        for b in breakdown:
            m_str = "[Y]" if b["match"] else "[N]"
            log_lines.append(f"  {m_str} {b['category'].upper()}: req '{b['required_skill']}' -> stud '{b['student_skill']}'")
            log_lines.append(f"      (Resolution: {b['resolution']} | Reason: {b['reason']})")
        log_lines.append("-" * 50 + "\n")
        
        if final_score >= 60:
            final_results.append({
                "student_id": student_id,
                "match_score": final_score,
                "skill_breakdown": breakdown
            })
            
    # 6. Write to Log file
    log_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "analysis_run_log.txt")
    with open(log_path, "w", encoding="utf-8") as f:
        f.write("\n".join(log_lines))
            
    return {
        "analysis_results": final_results
    }
