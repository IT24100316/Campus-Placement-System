import os
import asyncio
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from agents.planner.planner_models import EvaluationRubric
from tools.cv_tool import extract_cv_text_locally

async def generate_evaluation_rubric(job_posting: dict) -> str:
    """Uses LLM to analyze the Job Posting and generate a specific rubric for downstream agents."""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return "No specific instructions provided (Missing API Key)."
        
    llm = ChatGoogleGenerativeAI(
        model="gemini-3.5-flash-lite", 
        google_api_key=api_key,
        temperature=0.2
    )
    
    structured_llm = llm.with_structured_output(EvaluationRubric)
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are the Head Chef HR orchestrator. Analyze the given job posting and write a brief, 3-4 sentence rubric that tells the reviewer agent what soft skills, hidden contexts, or specific experiences to highlight in the final summary."),
        ("user", "Job Posting:\n{job_posting}")
    ])
    
    chain = prompt | structured_llm
    
    try:
        result = await chain.ainvoke({"job_posting": str(job_posting)})
        return result.summary_rubric
    except Exception as e:
        print(f"Failed to generate rubric: {e}")
        return "Focus on the candidate's alignment with the stated job requirements."

async def preparse_candidate_cvs(candidates: list) -> list:
    """Downloads and parses CVs concurrently for the students to speed up downstream agents."""
    async def fetch_cv(student):
        cv_url = student.get("CvPdfUrl")
        if cv_url:
            try:
                cv_text = await extract_cv_text_locally(cv_url)
                student["cv_text"] = cv_text
            except Exception as e:
                print(f"Failed to extract CV for {student.get('UserId')}: {e}")
                student["cv_text"] = ""
        else:
            student["cv_text"] = ""
        return student

    tasks = [fetch_cv(c) for c in candidates]
    return await asyncio.gather(*tasks)
