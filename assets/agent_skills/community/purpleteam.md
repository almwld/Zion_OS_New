---
name: purpleteam
description: Synthesis of /redteam + /blueteam in one pass. For each attack vector, surface the defense; for each defense, surface the bypass. Produces a single Attack/Defense/Bypass/Residual table per finding. Use when you want offense and defense reconciled in one artifact rather than two passes.
version: 0.1.0
execution-mode: advisory
argument-hint: <target>
category: security
status: candidate
---
# Purple Team | `$ARGUMENTS`

Iterated offense + defense in one pass. The purple team's job is to produce a single reconciled view: for every attack the red team would surface, the corresponding defense the blue team would inventory, and the bypass the red team would attempt next. Stop when residual risk is operator-acceptable or further iteration produces no new information.

## When to use vs. [redteam] vs. [blueteam]

| Pattern | Use |
|---|---|
| Need only offense — "what could break this?" | `[redteam]` |
| Need only defense — "what protects this?" | `[blueteam]` |
| Need both, reconciled, with iteration | **`[purpleteam]`** |
| Have a redteam report already, want defender's response | `[blueteam] <report>` |
| Have a blueteam control list, want adversarial test | `[redteam] <controls>` |

Purple team is the most expensive pass — both perspectives, with iteration. Reserve for: shipping a new agent / runtime / hook / scheduled job, integrating a third-party tool, or post-incident "what should have happened" analysis.

## Stance

- **Iterate until convergence**: each attack → defense → bypass round adds information; stop when bypass attempt produces a residual the operator accepts.
- **Both sides argue in good faith**: red doesn't sandbag; blue doesn't capitulate. The output is more rigorous than either pass alone.
- **Track which side surfaced each item**: useful for calibration over time (does our red team miss the same class of defenses repeatedly? does our blue team miss the same class of attacks?).
- **Acceptable-residual is a valid output**: not every finding needs a fix. Many need an explicit "accepted, here's why" verdict.

## Context Gathering

Before executing this skill, gather the following context:
- Run `ls -1 ~/.agents/skills/redteam/ ~/.agents/skills/blueteam/ 2>/dev/null`
- Run `grep -l "claim-honesty\|cross-check\|guard-" ~/.agents/rules/ 2>/dev/null | head -5`

## Procedure

### Step 1 — Scope the target

Identify what you're purple-teaming: a system, a change, an asset, a code path, an automation. Note current state, expected behavior, and trust boundary.

### Step 2 — Round 1: open red + open blue in parallel

Red team enumerates attack vectors per `[redteam]` categories adapted to the target. Blue team simultaneously inventories existing controls per `[blueteam]` Step 2. Don't let one influence the other in round 1 — independent perspectives.

### Step 3 — Round 2: reconcile

For each red finding, ask blue: "what already defends against this?"
For each blue control, ask red: "how would you bypass this?"

Build the table:

| # | Sev | Attack vector (red) | Defense in place (blue) | Bypass attempt (red round 2) | Residual risk |
|---|---|---|---|---|---|
| P1 | HIGH | <vector> | <control> | <bypass> | <accepted/needs-mitigation> |

### Step 4 — Round 3+: iterate the residuals

For each residual that says "needs mitigation": red proposes the next-level bypass; blue proposes the next-level defense. Continue until either:
- Bypass attempt fails → residual = ACCEPTABLE
- Defense cost exceeds attack cost-times-frequency → residual = ACCEPTED (with explicit rationale)
- 3 rounds of iteration without convergence → ESCALATE (operator decision required)

### Step 5 — Produce the matrix

Single artifact with:
- Target + scope
- Full attack/defense/bypass/residual table
- Per-row verdict: MITIGATE / ACCEPT / ESCALATE
- Cost estimates for MITIGATE rows
- Calibration note: which side won each round?

### Step 6 — Report

```
Purple Team Report | <target> | <date>
======================================

Target: <system/change>
Rounds executed: <N>
Iterations to convergence: <typical 2-3>

| # | Sev | Attack vector | Defense | Bypass | Residual | Verdict |
|---|---|---|---|---|---|---|
| P1 | H  | <…>          | <…>     | <…>   | <…>      | MITIGATE/ACCEPT/ESCALATE |
| P2 | H  | …            | …       | …     | …        | …        |
| …  |    |              |         |       |          |          |

Counts:
  MITIGATE: X (effort: <range>)
  ACCEPT (with rationale): Y
  ESCALATE (operator decision): Z

Calibration this pass:
  - Red surfaced N attacks; blue inventoried M defenses
  - Round 2 converged on K residuals; round 3 on L
  - Asymmetry observed: <if any>

Grade: A/B/C per intel-surge-quality.md R1-R4
```

## Output discipline

- **Class-mark every claim**: [OBS]/[INF]/[SEC]/[GAP] — applies to both red and blue claims
- **Cite controls precisely**: file path + line if possible; "we have guardrails" isn't a control, "guard-bash.sh L17 denies hook-bypass flag" is
- **Bypass attempts must be plausible**: don't invent novel zero-days; use existing fleet patterns
- **Residual acceptance needs operator visibility**: ESCALATE is the right verdict when you're unsure; don't ACCEPT on the operator's behalf
- **No theater**: a 3-round convergence where every round is "yep, mitigated" is not actually purple teaming — both sides need to find something

## Cross-references

- `[redteam]` — offense pass; round-1 input
- `[blueteam]` — defense pass; round-1 input
- `[threat-model]` — STRIDE structure (preventive-focused, less iteration)
- `[governance-audit]` — receipt + bus integrity verification
- `~/.agents/rules/cross-check-protocol.md` — Principal AI Agent ⇄ Engineer pair = continuous purple-team analog
- `~/.agents/rules/claim-honesty-protocol.md` — evidence discipline applies to both sides

## Skill Chains

- Before `[ship]` on agent/automation/hook change → `[purpleteam] <change>`
- After `[incident]` → `[purpleteam] <incident>` (what should have happened, both perspectives)
- After major doctrine change → `[purpleteam] <doctrine>` (does the new rule actually defend what it claims?)
