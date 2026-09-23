import pytest
from unittest.mock import patch, MagicMock
from agents.analysis import analysis_node, normalize_skill, normalize_skill_list
from tools.skill_equivalence_tool import canonicalize_pair
from state import AgentState

def test_normalization():
    assert normalize_skill(" Python ") == "python"
    assert normalize_skill_list([" ReactJS ", "Node.js"]) == ["reactjs", "node.js"]

@patch('agents.analysis.check_skill_cache')
@patch('agents.analysis.save_skill_equivalence')
@patch('agents.analysis.check_llm_equivalence_batch')
def test_analysis_node_filtering(mock_llm, mock_save, mock_cache):
    # Setup mock returns
    mock_cache.return_value = {
        canonicalize_pair("react", "reactjs"): {"IsMatch": True, "Reason": "Alias"},
        canonicalize_pair("node.js", "nodejs"): {"IsMatch": True, "Reason": "Spelling"}
    }
    
    # LLM mock returns for java vs javascript
    mock_llm.return_value = {}

    state: AgentState = {
        "job_posting": {
            "JobTitle": "Software Engineer",
            "MandatorySkills": ["React", "Node.js", "Java"],
            "NiceToHaveSkills": ["AWS"]
        },
        "candidates": [
            {
                "StudentId": "student_pass",
                "Skills": ["ReactJS", "NodeJS", "Java"], # 3/3 mandatory = 60 points
                "ToolsAndTechnologies": ["AWS"] # 1/1 nice = 40 points -> total 100
            },
            {
                "StudentId": "student_fail",
                "Skills": ["Python", "C++"], # 0/3 mandatory = 0 points
                "ToolsAndTechnologies": ["Git"] # 0/1 nice = 0 points -> total 0
            }
        ]
    }
    
    result = analysis_node(state)
    
    analysis_results = result.get("analysis_results", [])
    
    # Only "student_pass" should be in results because 100 >= 60, "student_fail" (0) should be dropped.
    assert len(analysis_results) == 1
    assert analysis_results[0]["student_id"] == "student_pass"
    assert analysis_results[0]["match_score"] == 100
