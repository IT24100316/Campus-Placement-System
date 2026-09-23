import json
from typing import List, Tuple, Dict
from pydantic import BaseModel, Field
from langchain_groq import ChatGroq
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser

class EquivalenceResult(BaseModel):
    pair_index: int = Field(description="The index of the pair in the batch")
    is_match: bool = Field(description="True if the two terms refer to the exact same skill/technology")
    reason: str = Field(description="Brief justification for the verdict")

def check_llm_equivalence_batch(pairs: List[Tuple[str, str]]) -> Dict[Tuple[str, str], EquivalenceResult]:
    """
    Takes a list of unmatched skill pairs and queries the LLM in one single batch.
    Returns a dictionary mapping the pair to the EquivalenceResult.
    """
    if not pairs:
        return {}
        
    llm = ChatGroq(model="openai/gpt-oss-20b", temperature=0)
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are an expert technical recruiter analyzing software engineering skills. "
                   "Determine if the pairs of skills represent the EXACT SAME technology/skill. "
                   "Return a JSON object with a single key 'results' which contains a list of objects. "
                   "Each object must have: 'pair_index' (integer), 'is_match' (boolean), and 'reason' (string). "
                   "DO NOT wrap the output in markdown blocks. Output raw JSON only."),
        ("human", "Here are the pairs to analyze:\n\n{pairs_text}\n\nRespond with strict JSON.")
    ])
    
    chain = prompt | llm | JsonOutputParser()
    
    pairs_text = "\n".join([f"[{i}] Required: '{req}', Candidate: '{cand}'" for i, (req, cand) in enumerate(pairs)])
    
    try:
        response = chain.invoke({"pairs_text": pairs_text})
        results_dict = {}
        for r in response.get("results", []):
            idx = r.get("pair_index")
            if idx is not None and 0 <= idx < len(pairs):
                results_dict[pairs[idx]] = EquivalenceResult(
                    pair_index=idx,
                    is_match=bool(r.get("is_match", False)),
                    reason=str(r.get("reason", ""))
                )
        return results_dict
    except Exception as e:
        print(f"LLM batch call failed: {e}")
        return {}
