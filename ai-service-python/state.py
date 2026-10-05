from typing import TypedDict, List, Dict, Any, Optional
from typing_extensions import NotRequired

# Describes exactly how well a student matches a single job requirement!
class SkillBreakdown(TypedDict):
    required_skill: str
    category: str  # "mandatory" or "nice_to_have"
    student_skill: Optional[str]
    match: bool
    resolution: str  # "exact", "cached_equivalent", "llm_equivalent", "no_match"
    reason: str

# Holds the final matching score and breakdown for a student applying to a job.
class CandidateResult(TypedDict):
    student_id: str
    match_score: int
    skill_breakdown: List[SkillBreakdown]

# The grand central station for our AI Graph!
# It holds everything the agents need as they pass work down the line.
class AgentState(TypedDict):
    # Inputs from HTTP request
    job_id: str
    initial_student_ids: List[str]
    evaluate_all: NotRequired[bool]
    
    # State tracking
    job_posting: NotRequired[Dict[str, Any]]
    candidates: NotRequired[List[Dict[str, Any]]]
    
    # Outputs populated by Analysis Agent
    analysis_results: NotRequired[List[CandidateResult]]
    
    # HITL Control
    human_approved: NotRequired[bool]
