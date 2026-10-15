---
name: blueteam
description: Defensive analysis — for a given asset, system, change, or red-team report, identify existing controls, surface missed mitigations, validate or push back on red-team findings, and recommend defense-in-depth. Companion to /redteam (offense) and /purpleteam (synthesis).
version: 0.1.0
execution-mode: advisory
argument-hint: <target or path-to-redteam-report>
category: security
status: candidate
---
# Blue Team | `$ARGUMENTS`

Defensive analysis of an asset, change, or red-team report. The blue team's job is NOT to dismiss attacks — it is to inventory the defenses that already exist, find gaps a defender would catch that the attacker missed, validate or correct the attacker's claims, and recommend layered countermeasures.

## When to use this skill

- Right after `[redteam]` — defender's response to the offense report (validate findings, surface counter-evidence, propose mitigations)
- Before a sensitive change — what defenses must be in place before this ships?
- During incident review — what existing defenses worked? what didn't?
- For governance audits — what controls are demonstrably present vs. claimed?

## Stance — what makes a good blue team pass

- **Validate, don't capitulate**: a red-team finding can be wrong, overstated, or already-mitigated. Saying "yes that's a real risk" when it isn't is theater. Saying "no it's not" when it is, is denial. Calibrate.
- **Existing controls first**: most defenses already exist as hooks, guardrails, doctrine, peer-review gates, append-only logs. Inventory before recommending new controls.
- **Defense-in-depth**: a single control is a single point of failure. For each high-severity attack, list 2-3 layered defenses (preventive, detective, corrective).
- **Cost-aware**: a recommendation that doubles operational overhead to prevent a once-a-quarter incident is worse than the incident. Propose mitigations proportional to risk.
- **Receipts oriented**: defenses you can't verify with an artifact (config check, log line, hook fire, bus post) don't count.

## Context Gathering

Before executing this skill, gather the following context:
- Run `ls -1 ~/.agents/rules/*-guardrails.md 2>/dev/null | head -5`
- Run `ls -1 ~/.agents/hooks/ 2>/dev/null | head -10`
- Run `grep -l "guard-\|deny\|reject\|block" ~/.agents/hooks/*.sh 2>/dev/null | head -5`

## Procedure

### Step 1 — Identify the target

If `$ARGUMENTS` is a path to a red-team report, read it and enumerate findings by severity. If it's a system name or asset, identify the protected surface and current controls.

```bash
# If target is a red-team report
TARGET="${ARGUMENTS:-_internal/redteam/latest.md}"
if [ -f "$TARGET" ]; then
    grep -n "^### \|\*\*[A-Z][0-9]\*\* \|severity\|HIGH\|MED\|LOW\|CRITICAL" "$TARGET" | head -30
fi
```

### Step 2 — Inventory existing controls

For each finding (or for the target system overall), list existing defenses by layer:

| Layer | Examples in this fleet |
|---|---|
| **Preventive** | Guardrail files, scope rules, identity registration, branch protection, hook deny-lists, bus-writer policy, agent trust tiers |
| **Detective** | Bus REVIEW posts, codex observability-loop, post-tool hooks, daily audits, CI gates, AAR-on-bus rule |
| **Corrective** | Rollback scripts, revert-PR pattern, force-with-lease, kill-switch, retraction memory pins |
| **Compensating** | Cross-machine mirror, append-only bus, peer-review obligation, operator-final-merge |
| **Cultural / doctrinal** | Claim-honesty protocol, cross-check protocol, claim-honesty tiering, evidence-class marks |

### Step 3 — Validate red-team findings (if input was a redteam report)

For each finding the redteam called out, produce a verdict:

| Verdict | Meaning |
|---|---|
| **VALID** | Finding is real, severity is right, mitigation needed |
| **VALID-but-OVERSTATED** | Real but severity should be lower; existing controls partially address |
| **VALID-but-ALREADY-MITIGATED** | Real attack but defense already in place; document the defense |
| **INVALID** | Red-team mis-identified; not a real attack on this fleet |
| **INVALID-but-RELATED** | The named finding is wrong but a real adjacent issue exists |

Every verdict needs evidence — file path, hook body, config grep, bus post, log line.

### Step 4 — Find what the red team missed

Defenders see what attackers don't:

- **Operational controls** the attacker treated as "trust this works" but actually need verification
- **Documentation gaps** that block effective response when the attack fires
- **Combination attacks** the red team enumerated individually but didn't chain
- **Recovery rehearsal gaps** — controls exist but have never been exercised
- **Doctrine vs implementation drift** that the attacker noticed but didn't fully trace

### Step 5 — Recommend layered defenses

For each VALID/VALID-but-OVERSTATED finding, propose 2-3 layered controls:
- Preventive (stop the attack before it lands)
- Detective (notice the attack as it lands or shortly after)
- Corrective (limit blast radius and recover)

Cost each control roughly: minutes to implement / hours / days. Operator approves what's worth the spend.

### Step 6 — Report

```
Blue Team Report | <target> | <date>
======================================

Findings reviewed: <N from redteam>
Verdicts:
  VALID: X        (mitigation needed)
  VALID-but-OVERSTATED: Y
  VALID-but-ALREADY-MITIGATED: Z
  INVALID: W
  INVALID-but-RELATED: V

Missed by red team: A
  M1 — <missed finding> — severity: <H/M/L> — evidence: <…>
  M2 — …

Existing controls inventory:
  Preventive: <list>
  Detective: <list>
  Corrective: <list>
  Compensating: <list>

Layered defense recommendations:
  R1 [HIGH] addresses redteam.A1:
    Preventive: <action> (effort: <time>)
    Detective: <action>
    Corrective: <action>
  R2 [MED] addresses redteam.A2:
    …

Accept-as-residual-risk (cost > benefit):
  - <finding> — rationale

Defense rehearsal gaps:
  - <control X never tested>
  - <runbook Y never exercised>

Grade: A/B/C  per intel-surge-quality.md R1-R4
```

## Output discipline

- **Class-mark every claim**: [OBS] direct verify, [INF] inference, [SEC] secondary, [GAP] unable-to-verify-this-pass
- **Date-stamp counts**: control coverage figures, alert latency, etc.
- **No fabricated defenses**: if a control isn't actually wired, don't claim it is
- **Push back on red team** where evidence supports it — this is the value of blue, not rubber-stamping
- **Recommend acceptance** where defense cost > attack expected value; don't fix everything

## Cross-references

- `[redteam]` — offense side; this skill responds to it
- `[purpleteam]` — synthesis of red + blue in one pass
- `[threat-model]` — STRIDE structure (preventive only)
- `[security-scan]` — automated tool layer
- `[governance-audit]` — bus + receipt integrity check
- `~/.agents/rules/claim-honesty-protocol.md` — evidence tiering (apply to defender claims too)
- `~/.agents/rules/intel-surge-quality.md` — R1-R4 quality bar

## Skill Chains

- After `[redteam]` → `[blueteam] <report>` → `[purpleteam]` if iteration needed
- After `[incident]` → `[blueteam]` (post-incident: what defenses worked?)
- After major change → `[blueteam] <change>` before `[ship]`
