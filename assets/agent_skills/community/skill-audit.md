---
name: skill-audit
description: Security + epistemic rigor audit of SKILL.md files. Checks secrets, unsafe shell, privacy gates, eval suites, promotion gates, schema versioning, expert review boundaries, and receipt completeness across the skill fleet.
version: 0.3.0
status: tested
execution-mode: advisory
argument-hint: "[all | SKILL_NAME_OR_ID | --security-only | --epistemic-only | --json | --summary]"
category: fleet-ops
providers:
  required: [python]
---
# Skill Audit

Two-dimensional audit of skills: **security** (can this skill cause harm?) and **epistemic rigor** (does this skill know what it claims to know?).

> **Status: TESTED** — v0.3.0 adds recursive discovery, qualified skill IDs, and complete lifecycle reporting.
> The epistemic dimension was derived from the claim-verify eval suite standard (v0.2.0).

## When to Use

- Before syncing skills to other machines (`mesh-sync`)
- After creating or significantly modifying skills
- Periodic fleet health audit (monthly)
- Before promoting a skill (candidate → tested → stable)
- After accepting skills from another agent or session
- When evaluating fleet-wide epistemic posture

## Two Audit Dimensions

### Security Audit (v0.1.0 — retained)

Checks whether a skill can cause active harm:

| Check | What it detects |
|-------|----------------|
| Secret Scan | Hardcoded API keys, tokens, passwords in SKILL.md |
| Unsafe Shell Patterns | eval, rm -rf with variables, pipe-to-shell, sandbox disable |
| Credential Leakage | env dumps, printing secret vars, verbose curl with auth |
| Cross-Machine Safety | Hardcoded IPs, OS-specific paths, macOS-only commands |
| Privilege Escalation | Unnecessary sudo, chown root, writes to system paths |

### Epistemic Rigor Audit (v0.2.0 — new)

Checks whether a skill has the infrastructure to back its claims:

| Check | What it detects |
|-------|----------------|
| Status Declaration | Does the skill declare candidate/tested/stable/canonical? |
| Schema Versioning | Does the skill version its output schema? |
| Eval Suite Presence | Does the skill have an eval/ directory with corpus + scorer? |
| Promotion Gates | Does the skill define pass/fail gates for promotion? |
| Privacy Gate | Does the skill document privacy boundaries for sensitive data? |
| Expert Review Boundaries | Does the skill route legal/medical/financial to expert review? |
| Receipt Completeness | Does the skill have version history + promotion receipt? |
| Output Schema | Does the skill document its output format? |
| Ground Truth Freshness | Are volatile/time-sensitive fixtures flagged for revalidation? |
| Confusion Matrix | Does the eval suite produce directional error analysis? |
| Regression Tracking | Does the eval suite detect drift across runs? |

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **CRIT** | Active security risk or missing critical safety boundary | Must fix before sync or use |
| **WARN** | Potential risk or missing epistemic infrastructure | Should fix |
| **INFO** | Awareness item for cross-machine sync or lifecycle | Note for operator |
| **PASS** | Check passed | No action |

## Prerequisites

Python 3.10 or newer is required; the audit itself uses only the standard
library. The examples below use a Unix shell path. On Windows, invoke the same
script with `python` and the corresponding `%USERPROFILE%\.agents\...` path.

## Execution

### Full audit (security + epistemic)

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py
```

### Single skill

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --skill claim-verify
```

### Security only

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --security-only
```

### Epistemic only

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --epistemic-only
```

### JSON output (for programmatic consumption)

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --json
```

### Fleet summary only

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --summary
```

## Audit Script

The audit is implemented in `skill_audit.py` (stdlib-only, in this skill directory).

The script:
1. Recursively discovers all SKILL.md files across known skill roots
2. Parses YAML frontmatter for metadata
3. Runs security checks (grep-based pattern matching)
4. Runs epistemic checks (frontmatter + filesystem analysis)
5. Produces per-skill findings and fleet-wide summary
6. Exits with code 1 if any CRIT findings, 0 otherwise

Skills are identified by their directory path relative to a root (for example,
`skill-creator`, `.system/skill-creator`, or `_archived/gameboard-ops`). When the
same relative ID appears in multiple mirror roots, the first configured root
wins; divergent mirror content emits a warning on stderr. `--skill` accepts a
qualified ID or an unambiguous declared name. JSON output retains `skill` for
compatibility and adds `id` and `path`.

## Output Format

```
Skill Audit | <scope: all | SKILL_NAME> | <date>
══════════════════════════════════════════════════════════════

## Fleet Summary
  Skills scanned: N
  Security: C critical, W warnings, I info
  Epistemic: C critical, W warnings, I info

  Status distribution:
    candidate:   N
    tested:      N
    stable:      N
    canonical:   N
    undeclared:  N
    <other observed lifecycle states>: N

  Eval suites: N/N skills (X%)
  Schema versioning: N/N skills (X%)
  Privacy gates: N/N skills (X%)

## Per-Skill Findings

### skill-name (status: tested, version: 0.2.0)
  SECURITY:
    [PASS] Secret scan — no hardcoded secrets
    [WARN] Unsafe shell: line 42 — eval with variable input
    [PASS] Credential leakage — none detected
    [PASS] Cross-machine safety — no hardcoded IPs
    [PASS] Privilege escalation — no sudo

  EPISTEMIC:
    [PASS] Status declared: tested
    [PASS] Schema versioning: claim_verify_eval.v0.2.0
    [PASS] Eval suite present (11 cases, 92 claims)
    [PASS] Promotion gates: 10/10 PASS
    [PASS] Privacy gate documented
    [PASS] Expert review boundaries documented
    [PASS] Receipt complete (version history + promotion receipt)
    [PASS] Output schema documented
    [PASS] Ground truth freshness: 3 volatile cases flagged
    [PASS] Confusion matrix available
    [PASS] Regression tracking available

### skill-name (status: undeclared, version: 0.1.0)
  SECURITY:
    ...

  EPISTEMIC:
    [WARN] Status not declared (defaulting to candidate)
    [WARN] No schema versioning
    [CRIT] No eval suite — skill makes factual claims without verification infrastructure
    [WARN] No promotion gates defined
    [WARN] No privacy gate documentation
    [INFO] No expert review boundaries (may not be needed for this domain)
    [WARN] No version history
    [PASS] Output schema documented
    [INFO] No volatile fixtures (skill domain is stable)
    [INFO] No confusion matrix (no eval suite)
    [INFO] No regression tracking (no eval suite)

## Recommendations
  CRIT: N skills need immediate fixes before sync
  WARN: N skills should add epistemic infrastructure
  PROMOTE: N skills are ready for promotion evaluation
  RETIRE: N skills are dormant and lack eval coverage
```

## Epistemic Check Details

### Status Declaration
Every skill should declare its lifecycle status in frontmatter:
```yaml
status: candidate | tested | stable | canonical | superseded | deprecated | retired
```
- `candidate`: New, untested, not yet validated
- `tested`: Has passed eval suite gates
- `stable`: Has survived cross-agent or live-session regression
- `canonical`: Fleet-wide standard, other skills reference it
- `superseded`, `deprecated`, `retired`: Terminal lifecycle states

Unrecognized lifecycle states are reported as **WARN** and still appear in the
fleet status distribution. Missing status is **WARN** for primary verification
skills and **INFO** otherwise.

### Schema Versioning
Skills that produce structured output should version their schema:
```yaml
schema_version: my_skill_output.v0.1.0
```
This prevents silent drift when the output format changes.

**WARN** if skill produces structured output but has no schema_version. **INFO** if skill produces only free text.

### Eval Suite Presence
Skills that make factual claims, verify claims, or produce structured analysis should have an eval suite:
```
skill-name/eval/
  corpus/          # Ground truth cases
  scorer.py        # Scoring engine
  run_eval.py      # Eval runner
  report.py        # Report generator
```

**CRIT** if skill verifies claims or makes safety-critical decisions and has no eval suite. **WARN** if skill produces structured output without eval. **INFO** if skill is purely operational (no factual claims).

### Promotion Gates
Eval suites should define multi-gate promotion criteria:
```python
PROMOTION_GATES = {
    "verdict_accuracy": {"threshold": 0.90, "direction": "gte"},
    "false_positive_rate": {"threshold": 0.05, "direction": "lte", "hard_gate": True},
    ...
}
```

**WARN** if eval suite exists but has no promotion gates. **INFO** if no eval suite.

### Privacy Gate
Skills that handle user data, internal business info, or sensitive claims should document privacy boundaries:
- What is restricted vs. public
- When external lookup is allowed
- What happens to restricted claims by default

**CRIT** if skill handles sensitive data with no privacy documentation. **WARN** if skill might encounter sensitive data incidentally.

### Expert Review Boundaries
Skills touching legal, medical, financial, or safety domains should route to expert review when sources are insufficient:
```
For legal/medical/financial/public-safety claims: route to REQUIRES_EXPERT_REVIEW
if sources are insufficient. Do not overstate confidence.
```

**WARN** if skill touches high-risk domains without expert review routing. **INFO** if skill domain is purely technical.

### Receipt Completeness
Skills should maintain:
- Version history (changelog in SKILL.md or PLAYBOOK.md)
- Promotion receipt (if promoted past candidate)
- Ground truth corrections (if eval process found corpus errors)

**WARN** if skill is tested/stable but has no promotion receipt. **INFO** if candidate with no receipt needed yet.

### Output Schema
Skills should document their output format so consumers know what to expect.

**WARN** if skill produces structured output with no documented format. **PASS** if output format is documented.

### Ground Truth Freshness
Eval suites with volatile/time-sensitive fixtures should flag them:
```json
{
  "fixture_freshness": {
    "type": "volatile",
    "revalidation_required": true,
    "revalidate_every_days": 30
  }
}
```

**WARN** if eval suite has time-sensitive cases without freshness metadata. **INFO** if no eval suite or all fixtures are stable.

### Confusion Matrix
Eval suites for classification/verification skills should produce a confusion matrix for directional error analysis.

**INFO** if eval suite exists but lacks confusion matrix. **PASS** if confusion matrix is generated.

### Regression Tracking
Eval suites should detect drift across runs by comparing to historical baselines.

**WARN** if eval suite exists but has no regression tracking. **INFO** if no eval suite.

## Skill Chains

| After completing... | Consider... |
|--------------------|-------------|
| `skill-audit` (clean) | `mesh-sync` (if clean), `skill-test` (format validation) |
| `skill-audit` (CRIT findings) | Fix criticals before any sync or promotion |
| `skill-audit` (epistemic WARN) | `skill-create` (add eval suite), `skill-evolve` (score health) |
| `skill-create` | `skill-audit` (verify new skill is safe + has epistemic infrastructure) |
| `skill-evolve` | `skill-audit` (drill into low-scoring skills) |
| `mesh-sync push` | `skill-audit` (pre-sync check) |

## Authority

Any agent tier may run this audit. It is read-only — no modifications to skills.

## Changelog

- **0.3.0 (2026-08-31):** Added deterministic recursive discovery, root-relative IDs, mirror-drift warnings, complete status reporting, qualified selection, JSON paths, and stdlib regression tests; corrected all execution paths.
- **0.2.0:** Added epistemic rigor checks.
- **0.1.0:** Initial security audit.

## Companion

See `skill_audit.py` in this skill directory for the programmatic implementation.
