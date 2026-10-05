from dataclasses import dataclass
from dataclasses import field

@dataclass(frozen=True)
class ValidationResult:
    valid: bool
    confidence: float
    supported_terms: list[str]
    unsupported_terms: list[str]
    warnings: list[str]
    decision: str = "WAITING_FOR_ADMIN_APPROVAL"
    unsupported_claims: list[str] = field(default_factory=list)
    evidence: dict[str, str] = field(default_factory=dict)
