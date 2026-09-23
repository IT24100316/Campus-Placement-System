import os
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Tuple, List, Dict, Any

def get_db_connection():
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        raise ValueError("DATABASE_URL environment variable is not set")
    return psycopg2.connect(db_url, cursor_factory=RealDictCursor)

def canonicalize_pair(term_a: str, term_b: str) -> Tuple[str, str]:
    """
    Normalizes and orders the terms alphabetically to ensure cache hit rates.
    E.g., ("React", "ReactJS") and ("ReactJS", "React") both become ("react", "reactjs").
    """
    a = term_a.strip().lower()
    b = term_b.strip().lower()
    
    # Sort alphabetically
    if a < b:
        return a, b
    return b, a

def check_skill_cache(pairs: List[Tuple[str, str]]) -> Dict[Tuple[str, str], Dict[str, Any]]:
    """
    Queries the database for existing skill equivalences.
    Input: List of raw (term_a, term_b) pairs.
    Returns: A dictionary mapping the canonicalized (term_a, term_b) to the database row.
    """
    if not pairs:
        return {}
        
    canonical_pairs = [canonicalize_pair(a, b) for a, b in pairs]
    results = {}
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # We can optimize by batching, but a simple IN clause with tuples is easiest in psycopg2.
                # E.g., WHERE ("TermA", "TermB") IN (('react', 'reactjs'), ...)
                
                # Build the query string dynamically
                placeholders = ', '.join(['(%s, %s)'] * len(canonical_pairs))
                query = f'''
                    SELECT "TermA", "TermB", "IsMatch", "Reason", "Source"
                    FROM "SkillEquivalences"
                    WHERE ("TermA", "TermB") IN ({placeholders})
                '''
                
                # Flatten the pairs for execute
                flat_params = [item for pair in canonical_pairs for item in pair]
                
                cur.execute(query, flat_params)
                rows = cur.fetchall()
                
                for row in rows:
                    key = (row["TermA"], row["TermB"])
                    results[key] = row
                    
    except Exception as e:
        print(f"Database error during skill cache lookup: {str(e)}")
        # In case of DB error, we treat as cache miss (return empty/partial dict)
        
    return results

def save_skill_equivalence(term_a: str, term_b: str, is_match: bool, reason: str, source: str = "llm") -> None:
    """
    Saves a fresh LLM verdict to the cache.
    Uses UPSERT (ON CONFLICT) to safely handle concurrent identical requests.
    """
    ca, cb = canonicalize_pair(term_a, term_b)
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('''
                    INSERT INTO "SkillEquivalences" ("Id", "TermA", "TermB", "IsMatch", "Reason", "Source", "CreatedAt")
                    VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT ("TermA", "TermB") 
                    DO UPDATE SET 
                        "IsMatch" = EXCLUDED."IsMatch",
                        "Reason" = EXCLUDED."Reason",
                        "Source" = EXCLUDED."Source",
                        "CreatedAt" = EXCLUDED."CreatedAt"
                ''', (ca, cb, is_match, reason, source))
            conn.commit()
    except Exception as e:
        print(f"Database error during skill equivalence save: {str(e)}")
