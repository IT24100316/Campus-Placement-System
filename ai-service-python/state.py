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
    # Inputs
    candidates: List[Dict[str, Any]]
    job_posting: Dict[str, Any]
    
    # Outputs populated by Analysis Agent
    analysis_results: NotRequired[List[CandidateResult]]
