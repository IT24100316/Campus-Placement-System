from pydantic import BaseModel, Field

class AdminEvaluationSummary(BaseModel):
    technical_alignment: str = Field(
        description="Write a detailed paragraph (3-4 sentences) deeply analyzing how the candidate's technical skills (extracted from the Student Form and CV) align with the exact requirements of the Job Post. Provide concrete examples of matched technologies."
    )
    
    identified_gaps: str = Field(
        description="Write a detailed paragraph explicitly identifying any critical skill gaps. Compare the Job Post requirements against the candidate's CV and Form data, and highlight any required technologies or experience levels that are missing."
    )
    
    project_relevance: str = Field(
        description="Write a detailed paragraph analyzing the practical relevance of the candidate's projects (from both the CV and GitHub) to the Job Role. Explain how the complexity and tech stack of their past work prepares them for this specific company."
    )
    
    cv_strategic_insights: str = Field(
        description="""Act as a Talent Acquisition Director extracting strategic insights from the CV to understand the candidate's true potential and engineering persona. Focus on strengths and overarching capabilities, not flaws. 
        Analyze the CV to determine:
        1. Core Persona & Domain: What is their primary identity? (e.g., 'A product-focused Full-Stack Engineer', 'A data-driven AI Specialist with a focus on predictive modeling').
        2. Business Impact & Problem Solving: Do they highlight the real-world outcome of their projects (e.g., solving specific user problems, architecting end-to-end platforms, or building explainable systems) rather than just listing technologies?
        3. Career Trajectory: Does the CV show a progression in project complexity, moving from basic academic assignments to mature, multi-faceted architectures?
        Write a compelling executive summary highlighting the candidate's unique value proposition, core strengths, and the specific type of engineering challenges they are best equipped to solve."""
    )
    
    github_comprehensive_analysis: str = Field(
        description="""Conduct a comprehensive evaluation of the candidate's GitHub profile against their CV. Analyze the repositories to determine:
        1. Hidden Strengths: Identify advanced skills, tools, or frameworks present in their repositories that were omitted or understated in the CV (e.g., complex full-stack implementations, mobile app development, advanced database architectures).
        2. Documentation & Professionalism: Evaluate the quality of their repositories. Do they include well-written README.md files, setup instructions, and architecture diagrams, or are they just raw code dumps?
        3. Git Workflow & Best Practices: Check for meaningful commit messages, branching strategies, or usage of CI/CD (e.g., GitHub Actions) which indicate readiness for a professional team environment.
        4. Code Authenticity & Flags: Check for developer red flags like heavy forking without original contributions, or massive single-commit project uploads.
        Write a detailed paragraph highlighting any unlisted technical advantages, their level of software engineering professionalism, and any authenticity flags. If the profile simply matches the CV without adding new info or flags, state 'Consistent with CV; no additional skills or flags detected'."""
    )
    
    approval_recommendation: str = Field(
        description="Provide a comprehensive final verdict paragraph recommending whether to 'Approve' or 'Reject' the candidate for the human Admin. Justify this exact decision by synthesizing the technical alignment, project relevance, and any verification flags discovered."
    )