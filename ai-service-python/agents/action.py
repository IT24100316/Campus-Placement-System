import os
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from tools.summary_tool import AdminEvaluationSummary
from tools.cv_tool import extract_cv_text_locally
from tools.github_tool import analyze_github_profile
from state import AgentState

def evaluate_single_candidate(student_data: dict, job_data: dict, cv_url: str) -> dict:
    # 1. Extract CV text locally and analyze GitHub
    cv_text = extract_cv_text_locally(cv_url)
    github_summary = analyze_github_profile(cv_text)

    print("\n" + "="*50)
    print("GITHUB SUMMARY GOING TO AI:")
    print(github_summary)
    print("="*50 + "\n")
    # 🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
    
    # 2. Securely load API Key
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY environment variable is not set")
        
    # 3. Initialize Gemini model
    llm = ChatGoogleGenerativeAI(
        model="gemini-3.5-flash-lite", 
        google_api_key=api_key,
        temperature=0.2
    )
    
    # 4. Bind Pydantic schema for structured output
    structured_llm = llm.with_structured_output(AdminEvaluationSummary)
    
    # 5. Construct ChatPromptTemplate
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are an expert HR evaluation engine. Assess the candidate against the job requirements based on their profile and CV. Provide your assessment strictly following the requested structure."),
        ("user", "Job Requirements:\n{job_data}\n\nCandidate Profile:\n{student_data}\n\nGitHub Stats:\n{github_summary}\n\nExtracted CV Text:\n{cv_text}")
    ])
    
    import decimal
    import datetime
    
    class CustomEncoder(json.JSONEncoder):
        def default(self, obj):
            if isinstance(obj, decimal.Decimal):
                return float(obj)
            if isinstance(obj, datetime.datetime):
                return obj.isoformat()
            return super().default(obj)

    # 6. Chain and Invoke asynchronously
    chain = prompt | structured_llm
    
    result = chain.invoke({
        "job_data": json.dumps(job_data, cls=CustomEncoder),
        "student_data": json.dumps(student_data, cls=CustomEncoder),
        "github_summary": github_summary,
        "cv_text": cv_text
    })
    
    # 7. Return dictionary via model_dump()
    return result.model_dump()

import asyncio

def action_node(state: AgentState) -> dict:
    """
    Agent 3: Summary Writer. 
    Takes passing candidates from Analysis and writes the AdminEvaluationSummary using Gemini.
    """
    job_posting = state.get("job_posting", {})
    candidates = state.get("candidates", [])
    analysis_results = state.get("analysis_results", [])
    
    # We will enrich the analysis_results with the summary
    enriched_results = []
    
    # Iterate through candidates who passed Analysis (they have a match_score)
    for result in analysis_results:
        student_id = result.get("student_id")
        student_data = next((c for c in candidates if str(c.get("UserId")) == str(student_id)), {})
        
        # In a real setup, cv_url comes from student profile
        cv_url = student_data.get("CvPdfUrl", "")
        
        try:
            print(f"Agent 3 generating summary for {student_id}...")
            summary = evaluate_single_candidate(student_data, job_posting, cv_url)
            result["summary"] = summary
        except Exception as e:
            print(f"Error generating summary for {student_id}: {e}")
            result["summary"] = {"error": str(e)}
            
        enriched_results.append(result)
        
    return {"analysis_results": enriched_results}

