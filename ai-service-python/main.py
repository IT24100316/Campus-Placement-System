import os
import asyncio
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from dotenv import load_dotenv

from agents.action import evaluate_single_candidate
from fastapi.middleware.cors import CORSMiddleware

# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app
app = FastAPI(title="Agent 3 - Evaluation Engine", version="1.0")

# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define Pydantic request models
class CandidatePayload(BaseModel):
    application_id: str
    student_data: Dict[str, Any]
    cv_url: str

class BatchEvaluationRequest(BaseModel):
    job_data: Dict[str, Any]
    candidates: List[CandidatePayload]

@app.post("/api/v1/evaluate-batch")
async def evaluate_batch(request: BatchEvaluationRequest):
    job_data = request.job_data
    candidates = request.candidates
    
    # Process a single candidate and return the result mapping
    async def process_candidate(candidate):
        eval_result = await evaluate_single_candidate(candidate.student_data, job_data, candidate.cv_url)
        return {
            "application_id": candidate.application_id,
            "evaluation": eval_result
        }
    
    # Process all candidates concurrently using asyncio.gather
    tasks = [process_candidate(candidate) for candidate in candidates]
    
    try:
        results = await asyncio.gather(*tasks)
        return {"evaluations": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
