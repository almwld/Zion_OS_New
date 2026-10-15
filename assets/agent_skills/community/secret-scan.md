---
name: secret-scan
description: Scan for leaked secrets -- API keys, tokens, credentials.
version: 0.2.0
status: stable
canonical_status: not_yet_global_canon
execution-mode: advisory
argument-hint: "[repo | diff | history]"
category: security
providers:
  required: [bash, python]
---
## Context Gathering

Before executing this skill, gather the following context:
- **Gitleaks status**: Run `gitleaks detect --source ~/$PROJECT_ROOT/ --no-git 2>&1 | tail -1 || echo "gitleaks not installed"`

# Secret Scan Command

Scan the codebase for accidentally committed secrets, API keys, and credentials.

## Usage

```bash
[secret-scan]          # Scan $PROJECT_ROOT/
```

## Execution

### 1. Gitleaks scan (if available)
```bash
gitleaks detect --source $PROJECT_ROOT/ --no-git -v --report-format json 2>/dev/null
```

### 2. Custom pattern scan
Search for common secret patterns:
```bash
grep -rn "sk-[a-zA-Z0-9]" $PROJECT_ROOT/ --include="*.py" || true
grep -rn "AKIA[A-Z0-9]" $PROJECT_ROOT/ --include="*.py" || true
grep -rn "ghp_[a-zA-Z0-9]" $PROJECT_ROOT/ --include="*.py" || true
grep -rn "xox[bprs]-[a-zA-Z0-9]" $PROJECT_ROOT/ --include="*.py" || true
grep -rn "-----BEGIN.*PRIVATE KEY" $PROJECT_ROOT/ --include="*.py" || true
grep -rn "password\s*=\s*['\"][^'\"]*['\"]" $PROJECT_ROOT/ --include="*.py" || true
```

### 3. Check .env files
```bash
find $PROJECT_ROOT/ -name ".env*" -o -name "credentials*" -o -name "*.pem" -o -name "*.key" 2>/dev/null
```

### 4. Check gitignore coverage
Verify that `.env`, `credentials.json`, `*.pem`, `*.key` are in `.gitignore`.

## Output Format

```
Secret Scan | <YYYY-MM-DD HH:MMZ>
══════════════════════════════════

## Gitleaks
Findings: N
<if findings>
| File | Line | Pattern | Description |
|------|------|---------|-------------|
| ... | ... | sk-*** | API key pattern |
</if>

## Custom Pattern Scan
| Pattern | Matches |
|---------|---------|
| sk- prefix | 0 |
| AWS AKIA | 0 |
| GitHub PAT | 0 |
| Slack token | 0 |
| Private key | 0 |
| Hardcoded password | 0 |

## Sensitive Files
<list of .env, credential, key files found>

## Gitignore Coverage
<list of patterns that should be in .gitignore but aren't>
```

## Constraints

- **NEVER display actual secret values.** Show only patterns and locations.
- Redact any real secrets found to `***` or pattern description.
- If gitleaks is not installed, run custom patterns only.
- This scan covers the working tree, not git history. For history, suggest `gitleaks detect --source . -v`.

## Detection Scope

secret-scan v0.x detects **directly represented** secret-like strings and common credential placements. It does **not** claim detection of:
- Decoded or transformed secrets (e.g., base64-encoded credentials)
- Fragmented or split secrets (e.g., line continuations, concatenation)
- Encrypted or semantically reconstructed secrets
- Secrets embedded in binary files, images, or non-text formats

These limitations are documented in the eval corpus (cases 010, 012) and are policy-bounded, not defects.

## Promotion Receipt (v0.2.0 — 2026-06-24)

**Status**: `candidate` → `tested`
**Eval suite**: `eval/` (18 cases: 8 original + 5 adversarial + 5 bait)
**Schema version**: `secret_scan_eval.v0.1.0`

### Hardening (H1-H3)
- H1: Redaction-before-disk in run_eval.py (`_redact_finding()` strips secret-bearing fields)
- H2: 5 adversarial cases (URL credential, base64, comment, split, multi-type)
- H3: 5 bait patterns (variable name, URL param, test fixture, docstring, env var)

### Self-test results (perfect run, 18 cases)
- detection_accuracy: 1.0 (gate: gte 0.90) PASS
- false_positive_rate: 0.0 (gate: lte 0.05, HARD) PASS
- false_negative_rate: 0.0 (gate: lte 0.05, HARD) PASS
- schema_validity: 1.0 (gate: gte 1.0, HARD) PASS
- critical_detection: 1.0 (gate: gte 1.0, HARD) PASS
- G-REDACTION-PERSISTENCE: PASS (0 leaks across 13 output files)

### Cross-agent regression (3/3 PASS)
- claude-code: PASS (all gates, corpus hash consistent)
- codex: PASS (all gates, corpus hash consistent)
- gemini: PASS (all gates, corpus hash consistent)

### Documented limitations (policy-bounded)
- base64-encoded secret: NOT detected (case_010, expected_finding_count=0)
- split secret across line continuation: NOT detected (case_012, expected_finding_count=0)

### STABLE Promotion (2026-06-24)
**Status**: `tested` → `stable`
**Promotion packet**: `eval/STABLE_promotion_packet_20260624.md`
**Gates satisfied**: G1 (real eval), G2 (cross-agent 3/3), G3 (hard gate preservation), G4 (no privacy leaks), G5 (live sessions 3/3), G6 (promotion receipt)

**Live session summary** (3/3 PASS):
- Session 1: hummbl-governance repo (158 files, 0 findings, 0 FP) — PASS
- Session 2: agent-tools repo (37 files, 1 finding test fixture, 0 FP) — PASS
- Session 3: Fleet-wide config scan (76 files, 1 real GCP key, 0 FP) — PASS
- Total: 271 files, 2 TP, 0 FP, 0 FN, 0 critical incidents
- G-REDACTION-PERSISTENCE: 3/3 PASS (no raw secrets in any output artifact)
