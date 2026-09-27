from dataclasses import dataclass

@dataclass(frozen=True)
class ValidationResult:
    valid: bool
    confidence: float
    supported_terms: list[str]
    unsupported_terms: list[str]
    warnings: list[str]
    decision: str = "WAITING_FOR_ADMIN_APPROVAL"
