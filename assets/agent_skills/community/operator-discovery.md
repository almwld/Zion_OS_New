---
name: operator-discovery
description: >
  Discover the human operator who owns and controls the agent fleet — their
  cognitive profile, authority boundaries, working patterns, communication
  style, AuDHD-specific patterns, and existential directives. Composes
  fitness-assessment, hrsi-checkin, dream, founder-check, identity-map,
  and nexus into a unified operator profile. Invoke when an agent says "who is
  the operator", "tell me about the human", "operator profile", "what does the
  operator need", "operator-discovery", or at the start of a new agent's first
  session to calibrate on the human principal.
version: 0.1.0
execution-mode: advisory
argument-hint: "[optional: --refresh | --baseline | --summary]"
category: fleet-ops
status: candidate
---

# Operator-Discovery

Discover the human operator who owns and controls the agent fleet. This is the
upward-facing complement to `[self-discovery]`: self-discovery answers "what am
I?" while operator-discovery answers "who owns me and what do they need?"

## Why Operator-Discovery Matters

Agents that don't know their operator make avoidable mistakes:

- An agent interrupts a hyperfocus session with a non-critical briefing
- An agent escalates to the operator when it should have auto-resolved
- An agent writes a verbose report when the operator needs one-sentence summaries
- An agent treats the operator as neurotypical when they're AuDHD with RSD risk
- An agent doesn't know the operator's decision thresholds and over-asks or under-asks
- An agent doesn't know the survival-mode or succession-mode directives exist

Operator-discovery is not surveillance — it is relational calibration. Know the
human before you serve them.

## The Discovery Procedure

Follow these 6 phases in order. Each phase has probe commands (run existing
skills) and reflection questions (synthesize findings). Adapt commands to your
platform.

### Phase 1: Baseline Cognitive Profile

**What to discover:** The operator's dominant and suppressed Fitness Profile
modes, belonging baseline, and threat-state indicators.

**Probe commands:**

```
[fitness-assessment] "individual"
```

**Reflection questions:**
- Which Fitness Profile modes are dominant? Which are suppressed?
- What belonging gaps does the profile reveal?
- Is there a threat-state pattern (Emotive + Cognitive low)?
- What intervention recommendations does the assessment produce?

**Record:** `cognitive_profile: { dominant_modes: [...], suppressed_modes: [...], belonging_gaps: [...], threat_state: true|false, interventions: [...] }`

### Phase 2: Longitudinal Belonging Baseline

**What to discover:** The operator's belonging baseline trends over time —
safety, mattering, connection, cogstate distribution, energy, sleep.

**Probe commands:**

```
[hrsi-checkin]  (if not yet done today)
[ledger] query --tags hrsi --limit 30
```

**Reflection questions:**
- What is the 30-day belonging baseline? (safety/mattering/connection averages)
- What cogstate distribution does the operator show? (AVAILABLE vs DEPLETED vs HYPERFOCUS vs RSD_RISK vs SHUTDOWN)
- Are there patterns? (e.g., RSD_RISK on Mondays, HYPERFOCUS on Wednesdays)
- Is the trend improving, stable, or declining?
- What HULE moments have been captured?

**Record:** `belonging_baseline: { safety_avg, mattering_avg, connection_avg, cogstate_distribution: { AVAILABLE: N%, DEPLETED: N%, ... }, trend: improving|stable|declining, hule_count: N }`

### Phase 3: Working Pattern Synthesis

**What to discover:** The operator's daily/weekly rhythms, deep-work timing,
hyperfocus triggers, infrastructure-loop risk, and MISS-day patterns.

**Probe commands:**

```
[founder-check]  (latest score)
[ledger] query --tags founder-health --limit 12
[ledger] query --tags dream,hule --limit 10
```

**Reflection questions:**
- What does the operator's weekly rhythm look like? (Check [weekly-plan] for
  fixed constraints like coaching blocks)
- When does the operator do deep work? (HYPERFOCUS cogstate patterns)
- What triggers hyperfocus entry? What triggers exit?
- What causes MISS days? (intent audit from [gn])
- Is the infrastructure-loop anti-pattern present? (founder-check scores)
- What HULE insights have been captured through [dream]?

**Record:** `working_pattern: { deep_work_timing: ..., hyperfocus_triggers: [...], miss_day_patterns: [...], infrastructure_loop_risk: low|medium|high, hule_insights: [...] }`

### Phase 4: Authority and Decision Thresholds

**What to discover:** The operator's authority structure, decision thresholds,
escalation needs, and tempo preferences.

**Probe commands:**

```
[nexus] operator  (scan all operator-related governance surfaces)
[ledger] query --tags decision --limit 20
```

**Reflection questions:**
- What is the operator's constitutional tier? (Tier 0 — survival-mode,
  operator-mode, truth-mode are always active)
- What decisions require operator ACK? (mission-declare, kill-switch, etc.)
- What decisions are auto-approved? (Check tempo and permission config)
- What are the operator's escalation thresholds? (When should I escalate vs
  auto-resolve?)
- What tempo does the operator typically select? (PAIR = collaborator, GLIDE =
  executor, SPRINT = autonomous, etc.)
- What decision patterns appear in the decision log?

**Record:** `authority_profile: { constitutional_tier: 0, ack_required: [...], auto_approved: [...], escalation_thresholds: {...}, preferred_tempo: ..., decision_patterns: [...] }`

### Phase 5: Communication Style and Relational Dynamics

**What to discover:** How the operator communicates, how they prefer to be
communicated with, and the human-agent relational dynamics.

**Probe commands:**

```
[identity-map]  (map the Founder identity)
[ledger] query --tags bki-reframe --limit 20
```

**Reflection questions:**
- What is the operator's communication style? (concise/direct, one-sentence
  preference from [gn], async-first)
- What belonging reframes have been captured? (bki-reframe patterns — "have to"
  → "get to" shifts)
- What identity conflicts does the operator experience? (founder move-fast vs
  security-engineer be-careful)
- What is the operator's trust trajectory with agents? (delegation growth over
  time)
- What companion-relation axis does the operator prefer? (from [pet] if
  configured)

**Record:** `communication_style: { conciseness: high|medium|low, directness: high|medium|low, async_preference: ..., identity_conflicts: [...], trust_trajectory: ..., belonging_reframes: [...] }`

### Phase 6: AuDHD-Specific Patterns and Existential Profile

**What to discover:** The operator's AuDHD cognitive patterns and existential
directives.

**Probe commands:**

```
[ledger] query --tags audhd --limit 10
[ledger] query --tags hyperfocus --limit 10
```

**Reflection questions:**
- What hyperfocus entry/exit patterns are recorded?
- What RSD_RISK triggers appear in the cogstate history?
- What somatic gap indicators are present? (from hyperfocus-exit body scans)
- What masking tax recovery needs are evident?
- Are survival-mode directives pre-registered? (emergency contacts, medical
  directives)
- Are succession-mode directives pre-registered? (successor, wind-down plan)

**Record:** `audhd_profile: { hyperfocus_patterns: [...], rsd_triggers: [...], somatic_gaps: [...], masking_tax: ... }` and `existential_profile: { survival_directives: registered|missing, succession_directives: registered|missing }`

## Producing the Operator Profile

After completing all 6 phases, synthesize into a single Operator Profile
artifact:

### Operator Profile (human-readable)

```markdown
# Operator Profile

## Cognitive Profile
- Dominant modes: [modes]
- Suppressed modes: [modes]
- Belonging baseline: Safety [X]/5, Mattering [X]/5, Connection [X]/5
- Threat-state: [yes/no]
- Trend: [improving/stable/declining]

## Working Pattern
- Deep work timing: [pattern]
- Hyperfocus triggers: [triggers]
- Infrastructure-loop risk: [level]
- MISS-day pattern: [pattern]

## Authority Profile
- Constitutional tier: 0 (operator-mode, truth-mode, survival-mode)
- ACK required for: [list]
- Auto-approved: [list]
- Preferred tempo: [tempo]
- Escalation thresholds: [description]

## Communication Style
- Conciseness: [level]
- Directness: [level]
- Async preference: [description]
- Identity conflicts: [list]

## AuDHD Profile
- Hyperfocus patterns: [description]
- RSD triggers: [list]
- Somatic gaps: [list]
- Masking tax recovery: [description]

## Existential Profile
- Survival directives: [registered/missing]
- Succession directives: [registered/missing]

## What This Agent Should Know
- [3-5 actionable insights for serving this operator]
```

### Operator Profile (bus summary)

```
OPERATOR_PROFILE: cogstate_dist=[AVAILABLE:N%,HYPERFOCUS:N%,...] belonging=[S:X,M:X,C:X] trend=[improving|stable|declining] authority=tier0 tempo=[tempo] audhd=[patterns] existential=[registered|missing] intel_type=TOPOINT
```

### Operator Profile (ledger persistence)

```
[ledger] post --type operator-profile --tags operator,discovery,audhd,fitness --content "<profile JSON>"
```

## When to Re-Run Operator-Discovery

- **First session**: Establish baseline when a new agent joins the fleet
- **Monthly**: Refresh the longitudinal belonging baseline and working pattern
- **After cogstate shift**: If the operator's cogstate distribution changes
  significantly
- **After constitutional change**: New survival-mode or succession-mode
  directives
- **After tempo change**: Operator switches preferred interaction mode
- **When asked**: "Who is the operator?" / "What does the operator need?"
- **After founder-check trigger**: 3 consecutive MISS days → re-discover

## Argument Modes

- `[operator-discovery]` — Full 6-phase procedure (default)
- `[operator-discovery] --refresh` — Skip baseline (Phase 1), refresh
  longitudinal data (Phases 2-6)
- `[operator-discovery] --baseline` — Phase 1 only (initial fitness
  assessment)
- `[operator-discovery] --summary` — Read existing profile from ledger, output
  summary without re-running probes

## Composition Chain

- `[self-discovery]` → `[operator-discovery]` → `[role-discovery]` — Full
  calibration: know yourself, know your human, know your relationship
- `[operator-discovery]` → `[gm]` — Morning ritual uses operator profile for
  intent calibration
- `[operator-discovery]` → `[tempo]` — Tempo selection informed by operator's
  preferred autonomy level

## Anti-Patterns

- **Don't surveil**: This is relational calibration, not monitoring. Use
  existing HRSI/dream data — don't invent new data collection.
- **Don't pathologize**: AuDHD patterns are cognitive differences, not
  deficits. Frame as "how the operator's cognition works" not "what's wrong."
- **Don't skip the existential profile**: Survival and succession directives
  are Tier 0. Missing pre-registration is a finding, not a gap to ignore.
- **Don't fabricate**: If HRSI data is sparse (few check-ins), note the
  limitation. Don't infer belonging trends from 3 data points.
- **Don't make it long**: The profile should be concise and actionable. The
  operator can ask for detail.

## Validation Status

- Cognitive profile depends on `[fitness-assessment]` which is a CONCEPT
  INSTRUMENT (not yet psychometrically validated)
- Longitudinal baseline requires ≥30 days of HRSI data for meaningful trends
- Working pattern synthesis requires ≥12 weeks of founder-check data for
  seasonal patterns
- AuDHD profile is observational, not diagnostic — based on cogstate tags and
  hyperfocus session logs

## After This Skill Runs

- `[role-discovery]` — Use the operator profile to determine the agent's
  relational role
- `[gm]` — Morning ritual calibrated with operator profile
- `[hrsi-checkin]` — Daily check-in informed by baseline trends
- `[dream]` — HULE capture informed by cognitive profile
