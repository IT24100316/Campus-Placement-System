from pydantic import BaseModel, Field

class EvaluationRubric(BaseModel):
    summary_rubric: str = Field(description="Instructions for the Summary agent (Agent 3) on what to focus on based on the job posting.")
