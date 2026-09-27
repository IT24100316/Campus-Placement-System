import os
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from tools.summary_tool import AdminEvaluationSummary
from tools.cv_tool import extract_cv_text_locally
from tools.github_tool import analyze_github_profile

async def evaluate_single_candidate(student_data: dict, job_data: dict, cv_url: str, cv_text: str = None, evaluation_rubric: str = "") -> dict:
    # 1. Use pre-extracted CV text from Agent 1 if available
    if not cv_text:
        cv_text = await extract_cv_text_locally(cv_url)
    
    github_summary = analyze_github_profile(cv_text)

    print("\n" + "="*50)
    print(f"GITHUB SUMMARY FOR [{student_data.get('FullName', 'Unknown')}] GOING TO AI:")
    try:
        print(github_summary)
    except UnicodeEncodeError:
        print(github_summary.encode('cp1252', errors='replace').decode('cp1252'))
    print("="*50 + "\n")
    
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
    sys_prompt = (
        "You are an expert HR evaluation engine. Assess the candidate against the job requirements based on their profile and CV. "
        "Provide your assessment strictly following the requested structure.\n\n"
        f"HEAD CHEF RUBRIC/INSTRUCTIONS:\n{evaluation_rubric}"
    )
    prompt = ChatPromptTemplate.from_messages([
        ("system", sys_prompt),
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

    # 6. Chain and Invoke synchronously
    chain = prompt | structured_llm
    
    result = chain.invoke({
        "job_data": json.dumps(job_data, cls=CustomEncoder),
        "student_data": json.dumps(student_data, cls=CustomEncoder),
        "github_summary": github_summary,
        "cv_text": cv_text
    })
    
    # 7. Return dictionary via model_dump()
    return result.model_dump()
