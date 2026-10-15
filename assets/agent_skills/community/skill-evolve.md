---
name: skill-evolve
description: Score and rank installed skills using usage telemetry, epistemic rigor, and security posture; recommend promotion, exploration, retirement, or pruning.
version: 0.2.1
status: tested
execution-mode: advisory
argument-hint: "[detail <skill>] [retire] [--epistemic-only] [--usage-only]"
category: fleet-ops
providers:
  required: [python]
---
## Context Gathering

Before executing this skill, gather the following context:
- **Skill count**: Run `ls -d ~/.agents/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' '`
- **Telemetry lines**: Run `wc -l < ~/.agents/_state/telemetry/skill-usage.tsv 2>/dev/null || echo 0`
- **Audit results**: Run `python3 ~/.agents/skills/skill-audit/skill_audit.py --json` for epistemic + security findings

# Skill Evolution Engine

## When to Use
- Periodic skill library health check (weekly recommended)
- After new skills have usage evidence, assess their lifecycle health and promotion readiness
- When wondering which skills are unused or underperforming
- Before a skill cleanup or retirement pass
- To identify skills that deserve wider trigger patterns
- To identify skills ready for promotion (candidate → tested → stable)
- To identify skills lacking epistemic infrastructure (eval suites, privacy gates, etc.)

Not for `SKILL.md` structure, root coverage, inventory drift, or baseline
snapshots; use `[fleet-skill-health]`. For missing routing triggers or
discoverability gaps, use `[routing-evolve]`.

## Usage

```bash
[skill-evolve]                    # Full report: all skills scored and ranked
[skill-evolve] detail X           # Deep dive on skill X
[skill-evolve] retire             # Generate archival plan for DORMANT skills
[skill-evolve] --epistemic-only   # Score only epistemic rigor (no telemetry needed)
[skill-evolve] --usage-only       # Score only usage telemetry (legacy mode)
```

## Scoring Model (v0.2.0)

The composite health score (0-100) now uses **three dimensions**:

### Dimension 1: Usage Health (0-40 points, from telemetry)

| Component | Max Points | What it measures |
|-----------|------------|------------------|
| Frequency | 12 | Recency-weighted invocation count |
| Success | 8 | Wilson score lower bound for success rate |
| Recency | 8 | Days since last invocation (exponential decay) |
| Chain | 6 | References from/to other skills |
| Exploration | 6 | UCB1 bonus for under-explored skills |

### Dimension 2: Epistemic Rigor (0-40 points, from skill-audit)

| Component | Max Points | What it measures |
|-----------|------------|------------------|
| Status Declaration | 4 | Has lifecycle status (candidate/tested/stable/canonical) |
| Eval Suite | 8 | Has eval/ directory with corpus + scorer |
| Promotion Gates | 4 | Eval suite defines pass/fail gates |
| Privacy Gate | 4 | Documents privacy boundaries for sensitive data |
| Expert Review | 4 | Routes high-risk domains to expert review |
| Schema Versioning | 4 | Versions its output schema |
| Receipt Completeness | 4 | Has version history + promotion receipt |
| Output Schema | 3 | Documents output format |
| Regression Tracking | 3 | Eval suite detects drift across runs |
| Confusion Matrix | 2 | Eval suite produces directional error analysis |

### Dimension 3: Security Posture (0-20 points, from skill-audit)

| Component | Max Points | What it measures |
|-----------|------------|------------------|
| Secret Scan | 5 | No hardcoded secrets |
| Unsafe Shell | 5 | No dangerous shell patterns |
| Credential Leakage | 4 | No credential exposure patterns |
| Cross-Machine Safety | 3 | No hardcoded IPs or OS-specific paths |
| Privilege Escalation | 3 | No unnecessary sudo or system path writes |

### Tier Classification

| Tier | Score Range | Meaning |
|------|-------------|---------|
| THRIVING | 80-100 | High usage + strong epistemic + clean security |
| HEALTHY | 60-79 | Good coverage, minor gaps |
| AT_RISK | 40-59 | Usage declining or epistemic gaps |
| DEFICIENT | 20-39 | Multiple critical gaps in usage or epistemic |
| DORMANT | 0-19 | No usage + no epistemic infrastructure |

## Execution

### 1. Run the usage scorer (if telemetry available)

```bash
cd $HOME && python -c "
from hummbl_governance.services.skill_scorer import SkillScorer
import os

telemetry = os.path.expanduser('~/.agents/_state/telemetry/skill-usage.tsv')
if not os.path.isfile(telemetry):
    telemetry = None

scorer = SkillScorer(telemetry_path=telemetry)
scores = scorer.score_all()
print(scorer.generate_report(scores))
"
```

### 2. Run the epistemic + security audit

```bash
python3 ~/.agents/skills/skill-audit/skill_audit.py --json
```

### 3. Merge scores and classify

Combine usage scores (0-40) + epistemic scores (0-40) + security scores (0-20) into composite health score (0-100).

### 4. Act on recommendations

- **THRIVING** skills: optimize trigger patterns, consider splitting if overloaded
- **HEALTHY** skills: no action needed, monitor
- **AT_RISK** skills with chain participation: widen trigger patterns in skill-routing.md
- **AT_RISK** skills with epistemic gaps: add eval suite, privacy gate, or schema versioning
- **DEFICIENT** skills: prioritize adding eval suite or consider retirement
- **DORMANT** skills with 0 invocations and 0 chain: candidates for retirement

### Promotion Recommendations

Skills are flagged for promotion evaluation when:
- Status is `candidate` or undeclared
- Has eval suite with promotion gates
- Eval gates are passing (from latest baseline)
- Usage is non-zero (skill is being invoked)

Skills are flagged for promotion to `stable` when:
- Status is `tested`
- Has survived 3+ eval runs without regression
- Has been used by 2+ agents or in 5+ sessions

### Retirement Recommendations

Skills are flagged for retirement when:
- Status is `undeclared` or `candidate`
- 0 invocations in 90+ days
- 0 chain references
- No eval suite
- No unique capability not covered by another skill

## Output Format

```
Skill Evolution Engine | N skills | M invocations
====================================================================

TIER SUMMARY
  THRIVING   ( X):  skill-a, skill-b, ...
  HEALTHY    ( Y):  skill-c, skill-d, ...
  AT_RISK    ( Z):  skill-e, skill-f, ...
  DEFICIENT  ( W):  skill-g, skill-h, ...
  DORMANT    ( V):  skill-i, skill-j, ...

TOP 20 (by composite health score)
    #  Skill               Health  Usage  Epist  Secur  Tier
    1  claim-verify          92.3   40.0   40.0   20.0  THRIVING
    2  sitrep                85.1   35.0   32.0   18.0  THRIVING
    ...

EPISTEMIC GAPS (skills needing eval suites)
  CRIT (0 skills):
    (none — the 6 primary-verification skills previously listed here
     — hallucination-check, evidence-grade, proof-check, doc-harden,
     backup-verify, case-study-verify — now ship eval/ suites)

  WARN (N skills):
    - skill-name: missing privacy gate
    - skill-name: missing schema versioning
    ...

PROMOTION CANDIDATES
  READY FOR TESTED:
    - skill-name (has eval suite, gates passing, status=candidate)
  READY FOR STABLE:
    - claim-verify (tested, 3+ eval runs, used by 2+ agents)

RETIREMENT CANDIDATES
  - skill-name (dormant 90+ days, no eval, no chain refs)
  ...

RECOMMENDATIONS
  PROMOTE: ...
  EXPLORE: ...
  RETIRE: ...
  ADD_EVAL: ...
  ADD_PRIVACY: ...
```

## Epistemic Scoring Detail

Each epistemic check from skill-audit contributes to the epistemic score:

| Finding | Points |
|---------|--------|
| PASS | Full points for that component |
| INFO | Half points (not critical, but infrastructure missing) |
| WARN | Quarter points (should fix) |
| CRIT | 0 points (critical gap) |
| (not applicable) | Half points (domain doesn't require this check) |

### Example Scoring

**claim-verify** (status: tested, has eval suite, all gates pass):
- Status Declaration: PASS → 4/4
- Eval Suite: PASS → 8/8
- Promotion Gates: PASS → 4/4
- Privacy Gate: PASS → 4/4
- Expert Review: PASS → 4/4
- Schema Versioning: PASS → 4/4
- Receipt: PASS → 4/4
- Output Schema: PASS → 3/3
- Regression Tracking: PASS → 3/3
- Confusion Matrix: PASS → 2/2
- **Epistemic total: 40/40**

**hallucination-check** (status: undeclared, no eval suite):
- Status Declaration: WARN → 1/4
- Eval Suite: CRIT → 0/8
- Promotion Gates: INFO → 1/4
- Privacy Gate: PASS → 4/4
- Expert Review: PASS → 4/4
- Schema Versioning: WARN → 1/4
- Receipt: WARN → 1/4
- Output Schema: PASS → 3/3
- Regression Tracking: INFO → 1/3
- Confusion Matrix: INFO → 1/2
- **Epistemic total: 17/40**

## Constraints

- This is READ-ONLY. Do not modify skills, routing rules, or telemetry.
- Do not fabricate scores. Always run the actual scorer and audit.
- If the usage scorer fails to import, report the error and suggest `pip install -e ".[test]"`.
- If the audit script is missing, fall back to usage-only scoring and note the gap.
- Usage scores are deterministic given the same telemetry data (no randomness).
- Epistemic scores are deterministic given the same skill files.

## Skill Chains

| After completing... | Consider... |
|--------------------|-------------|
| `skill-evolve` | `skill-audit` (drill into low-scoring skills) |
| `skill-evolve` (promotion candidates) | `skill-test` (format validation before promotion) |
| `skill-evolve` (retirement candidates) | Review with operator before archiving |
| `skill-audit` | `skill-evolve` (rescore after fixes) |

## Version History

- 0.1.0 — 2026-06-23: Initial version. Usage-only scoring (frequency, success, recency, chain, exploration).
- 0.2.0 — 2026-06-24: Added epistemic rigor dimension (10 checks from skill-audit) and security posture dimension (5 checks). Three-dimensional composite scoring. Promotion and retirement recommendations now consider epistemic infrastructure, not just usage.
- 0.2.1 — 2026-08-31: Sharpened the boundary between lifecycle scoring and structural fleet inventory validation.
