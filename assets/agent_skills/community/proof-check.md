---
name: proof-check
description: Verify claims by contradiction or contrapositive -- stress-test assertions in code, docs, and proposals. Maps to IN6/IN8.
version: 0.2.0
status: tested
canonical_status: not_yet_global_canon
execution-mode: advisory
argument-hint: "\"CLAIM to verify\" (e.g., \"our bus never loses messages\", \"stdlib-only means no CVEs\")"
category: governance-compliance
providers:
  required: [bash, python]
---
# Proof Check (IN6: Proof by Contradiction + IN8: Contrapositive Reasoning)

Rigorously verify a claim by trying to disprove it. If you can't construct a counterexample, the claim is stronger. If you can, it's false.

## When to Use
- Verifying security claims ("no secrets in code")
- Validating architecture invariants ("all bus writes go through bus_writer")
- Checking documentation claims ("5,600+ tests" -- is it actually true?)
- Stress-testing proposals ("this migration has no downtime")

## Execution

### 1. State the claim precisely
Vague claims can't be verified. Transform into a testable statement:
- Vague: "Our system is secure"
- Precise: "No API key appears in any committed file in the git history"

### 2. Attempt contradiction
Try to find a counterexample that disproves the claim:

```bash
# Claim: "No API keys in git history"
git log --all -p | grep -E "sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}" | head -5

# Claim: "All bus writes go through bus_writer.py"
grep -rn "messages.tsv" services/ integrations/ --include="*.py" | grep -v bus_writer | grep -v test

# Claim: "Zero third-party runtime imports"
python3 -c "..." # (use [dep-check])

# Claim: "Every adapter has a circuit breaker"
grep -L "circuit_breaker\|CircuitBreaker" integrations/*.py
```

### 3. Apply contrapositive
If claim is "If A then B", verify "If not B then not A":
- Claim: "If an agent is TRUSTED, it can write to any file"
- Contrapositive: "If an agent cannot write to a file, it is not TRUSTED"
- Test: Find a file-write failure and check the agent's trust level

### 4. Grade the result

| Result | Meaning |
|--------|---------|
| **No counterexample found** | Claim holds (confidence proportional to search effort) |
| **Counterexample found** | Claim is FALSE -- document the counterexample |
| **Edge case found** | Claim is MOSTLY true but has exceptions -- document them |

## Output Format
```
Proof Check | "<claim>"
═══════════════════════════

## Claim (precise form)
<testable statement>

## Contradiction Attempt
<what was searched, what commands were run>

## Result: [HOLDS | FALSE | EDGE CASE]
<evidence>

## Confidence: <high/medium/low>
<what would increase confidence>
```

## Base120 Context
- Primary: **IN6** (Proof by Contradiction), **IN8** (Contrapositive Reasoning)
- Related: **IN10** (Red Teaming), **P15** (Assumption Surfacing)

## Promotion Receipt (v0.2.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (8 cases)
**Schema version**: `proof_check_eval.v0.1.0`

### Self-test results (perfect run)
- result_accuracy: 1.0 (gate: ≥0.85) PASS
- false_positive_rate: 0.0 (gate: ≤0.10) PASS
- false_negative_rate: 0.0 (gate: ≤0.10) PASS
- counterexample_quality: 1.0 (gate: ≥0.75) PASS
- confidence_calibration: 1.0 (gate: ≥0.70) PASS
- schema_validity: 1.0 (gate: =1.0, HARD) PASS

### Residual issues
- Self-test uses ground-truth-as-actual; real LLM run needed for true accuracy baseline
- Search command execution not tested (commands are specified but not run)
- Edge case boundary conditions need more granular testing

## Skill Chains
- For independent proof verification via different free-tier provider -> `[reasoning-router]` (`route`)
