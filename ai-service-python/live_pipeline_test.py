import asyncio
import json
from dotenv import load_dotenv

load_dotenv()

from main import app, lifespan

async def run_full_pipeline():
    # Replace these IDs with real GUIDs from your database to run the live flow.
    job_id = "00000000-0000-0000-0000-000000000000"
    student_id = "11111111-1111-1111-1111-111111111111"
    initial_state = {
        "job_id": job_id,
        "initial_student_ids": [student_id],
        "evaluate_all": False,
    }
    config = {"configurable": {"thread_id": f"{job_id}:{student_id}"}}

    print("Running the orchestration graph through validation...")
    async with lifespan(app):
        final_state = await app.state.graph.ainvoke(initial_state, config=config)
    print("\nPipeline paused for human review. Analysis results:")
    print(json.dumps(final_state.get("analysis_results", []), indent=2))
    print("\nCheck 'analysis_run_log.txt' for the full detailed breakdown!")

if __name__ == "__main__":
    asyncio.run(run_full_pipeline())
