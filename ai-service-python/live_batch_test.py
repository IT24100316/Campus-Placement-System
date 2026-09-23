import json
from unittest.mock import patch
from dotenv import load_dotenv

load_dotenv()

from agents.analysis import analysis_node
from state import AgentState

@patch('agents.analysis.check_skill_cache')
@patch('agents.analysis.save_skill_equivalence')
def run_batch_test(mock_save, mock_cache):
    # Force cache to return empty (cache miss for everything) so it all goes to Groq
    mock_cache.return_value = {}
    
    state: AgentState = {
        "job_posting": {
            "JobTitle": "Backend Engineer",
            "TargetDomain": "Software Development",
            "MandatorySkills": ["Python", "Django", "PostgreSQL"],
            "NiceToHaveSkills": ["Docker", "AWS"]
        },
        "candidates": [
            {
                # Perfect Match - Should score ~100
                "StudentId": "STU_1001",
                "Skills": ["Python", "Django Framework", "PostgreSQL"],
                "ToolsAndTechnologies": ["Docker", "Amazon Web Services"]
            },
            {
                # Close Match - Should pass (e.g. >= 60)
                "StudentId": "STU_1002",
                "Skills": ["Python", "Flask", "MySQL"], 
                "ToolsAndTechnologies": ["AWS"]
            },
            {
                # Terrible Match - Should fail (< 60)
                "StudentId": "STU_1003",
                "Skills": ["Java", "Spring Boot", "Oracle"],
                "ToolsAndTechnologies": ["Kubernetes"]
            },
            {
                # Partial Match - 1 Mandatory, 1 Nice - Should fail (< 60)
                "StudentId": "STU_1004",
                "Skills": ["Python", "React", "MongoDB"],
                "ToolsAndTechnologies": ["Docker"]
            },
            {
                # Perfect Match using weird naming - Should score ~100
                "StudentId": "STU_1005",
                "Skills": ["python 3", "django", "postgres"],
                "ToolsAndTechnologies": ["docker container", "aws ec2"]
            }
        ]
    }

    print("Running Analysis Agent in BATCH MODE with Groq...")
    print("Evaluating 5 candidates against a 60% threshold.")
    print("-" * 50)
    
    result = analysis_node(state)
    
    print("\nFINAL RESULTS (Passed Candidates Only):")
    print(json.dumps(result, indent=2))
    print("\nCheck 'analysis_run_log.txt' for the full detailed breakdown!")

if __name__ == "__main__":
    run_batch_test()
