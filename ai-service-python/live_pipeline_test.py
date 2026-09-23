import json
from dotenv import load_dotenv

load_dotenv()

from main import app_graph

def test_full_pipeline():
    # Replace these IDs with real GUIDs from your Supabase database
    # to actually test the full pipeline flow
    initial_state = {
        "job_id": "00000000-0000-0000-0000-000000000000",
        "initial_student_ids": [
            "11111111-1111-1111-1111-111111111111",
            "22222222-2222-2222-2222-222222222222"
        ]
    }

    print("Running the Orchestration Graph (Planner -> Action -> Tier 1 -> Analysis -> Validation)...")
    try:
        final_state = app_graph.invoke(initial_state)
        print("\nPipeline execution complete! Final Analysis Results (Passed Candidates):")
        print(json.dumps(final_state.get("analysis_results", []), indent=2))
        print("\nCheck 'analysis_run_log.txt' for the full detailed breakdown!")
    except Exception as e:
        print(f"\nPipeline failed. Ensure you put real database IDs in the script. Error: {e}")

if __name__ == "__main__":
    test_full_pipeline()
