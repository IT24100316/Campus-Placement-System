from typing import TypedDict, List, Dict, Any, Optional
from typing_extensions import NotRequired

class SkillBreakdown(TypedDict):
    required_skill: str
    category: str  # "mandatory" or "nice_to_have"
    student_skill: Optional[str]
    match: bool
    resolution: str  # "exact", "cached_equivalent", "llm_equivalent", "no_match"
    reason: str

class CandidateResult(TypedDict):
    student_id: str
    match_score: int
    skill_breakdown: List[SkillBreakdown]

class AgentState(TypedDict):
    # Inputs from HTTP request
    job_id: str
    initial_student_ids: List[str]
    
    # State tracking
    job_posting: NotRequired[Dict[str, Any]]
    candidates: NotRequired[List[Dict[str, Any]]]
    
    # Outputs populated by Analysis Agent
    analysis_results: NotRequired[List[CandidateResult]]
