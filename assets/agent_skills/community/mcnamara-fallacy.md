---
name: mcnamara-fallacy
description: Audit decisions and metric systems for the McNamara fallacy — the four-step collapse where only what is measurable counts, the unmeasurable gets an arbitrary value or is presumed irrelevant, then denied to exist. Detects metric-only reasoning and KPI-as-goal corruption before it ships. Chains to metric-define and kaizen. [Maps to IN18.]
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<decision or metric under review> [--strict]"
category: analytical
status: candidate
---

## Live Context

!`echo "Skills: $(ls ~/.agents/skills/ | wc -l) | Related: metric-define kaizen incentive-design assumption-audit"`

# McNamara Fallacy

Named for Robert McNamara's Vietnam-era body-count metrics (attributed by Daniel Yankelovich, 1972): decisions collapse into what can be measured, and everything else is disregarded, presumed unimportant, then denied to exist. Use when a decision is being justified by metrics alone, when a KPI has become the goal, or when a benchmark or scorecard is the only evidence in the room.

## When to Use
- A decision rests on quantified metrics alone ("just look at the numbers")
- A KPI, benchmark, or scorecard has become the goal instead of the outcome it proxies
- Reviewing dashboards, OKRs, or agent-performance metrics for measurement-driven blindness
- Someone assigns an arbitrary number to an unmeasurable factor (Step 2 warning sign)
- Before shipping a metric system, alert rule, or incentive tied to a metric

## Execution

### 1. Emit SKILL_INVOKE (side_effecting gate)
Before any stateful action (bus post, ledger write, file edit), emit:
```
Type: SKILL_INVOKE
To: all
Message: [skill=mcnamara-fallacy] [mode=side_effecting] [args_hash=<sha256 of args>] [session=<session_id>]
```

### 2. Parse Arguments
- `$ARGUMENTS`: decision, metric, KPI, or scorecard under review
- `--strict`: also flag borderline Step 2 cases (arbitrary quantification)

### 3. Map the Metric Chain
For the decision under review, identify:
1. What is measured (the metric)
2. What it proxies for (the intended outcome)
3. The outcome that actually matters
4. What is consequential but NOT measured

### 4. Test the Four Steps
Ask each against the decision:
- Step 1 (measure): is the easy-to-measure treated as the relevant measure?
- Step 2 (disregard): is the unmeasurable disregarded, or given an arbitrary number that then gets treated as real?
- Step 3 (presume): is there an implicit claim that unmeasurable factors are not important?
- Step 4 (deny): is the unmeasurable treated as if it does not exist?

### 5. Check Co-Corruption
- Goodhart (SY14): has the metric become a target and lost meaning?
- Cobra Effect (SY13): does pursuing the metric worsen the outcome?
- Disconfirmation (IN15): seek evidence the metric is misleading before trusting it

### 6. Verdict + Remediation
- Verdict: PASS / FALLACY_DETECTED / PARTIAL
- For each detected step: name the unmeasured factor, its likely direction of bias, and a qualitative signal that would bound it
- Chain: `[metric-define]` to redesign the metric system, `[kaizen]` if a fix ships

## Output Format
```
mcnamara-fallacy | <decision under review>
═════════════════════════
Measured:              <metric>
Proxies for:           <intended outcome>
Actually matters:      <outcome>
Unmeasured but consequential: <factor list>

Step 1 (measure):   PASS/FAIL — <note>
Step 2 (disregard): PASS/FAIL — <note>
Step 3 (presume):   PASS/FAIL — <note>
Step 4 (deny):      PASS/FAIL — <note>

Goodhart:   <flag>
Cobra:      <flag>
Verdict:    PASS | FALLACY_DETECTED | PARTIAL
Remediation: <unmeasured factors to weight, qualitative signals to add>
```

## Base120 Context
- Primary: **IN18** (Assumption Surfacing / Negative Indicators — the unmeasured is the signal)
- Related: **SY14** (Goodhart's Law), **SY13** (Cobra Effect), **IN15** (Disconfirmation)

## Skill Chains
- After audit -> `[metric-define]` to redesign the metric system
- After audit -> `[kaizen]` if a remediation ships
- After audit -> `[incentive-design]` if the metric corrupted behavior
