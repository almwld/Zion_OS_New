---
name: rice-prioritize
description: RICE scoring (Reach, Impact, Confidence, Effort) for feature and task prioritization.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"LIST OF ITEMS TO PRIORITIZE\""
category: data-science
status: candidate
---
# RICE Prioritize

Score and rank items using the RICE framework: Reach x Impact x Confidence / Effort.

## Execution

### 1. List the candidates
Gather items to prioritize (features, tasks, bugs, skills, etc.)

### 2. Score each dimension

| Dimension | Scale | Guidance |
|-----------|-------|---------|
| **Reach** | 1-10 | How many users/agents/sessions does this affect per month? |
| **Impact** | 0.25 / 0.5 / 1 / 2 / 3 | Minimal / Low / Medium / High / Massive |
| **Confidence** | 0.5 / 0.8 / 1.0 | Low / Medium / High (how sure are we about R, I, and E?) |
| **Effort** | Person-sessions | How many focused work sessions to complete? |

### 3. Calculate RICE score
```
RICE = (Reach × Impact × Confidence) / Effort
```

### 4. Rank and decide

## Output Format
```
RICE Prioritization | <context>
═══════════════════════════════

| # | Item | Reach | Impact | Confidence | Effort | RICE | Priority |
|---|------|-------|--------|------------|--------|------|----------|
| 1 | <item> | 8 | 2 | 0.8 | 2 | 6.4 | P0 |
| 2 | <item> | 5 | 1 | 1.0 | 1 | 5.0 | P1 |
| 3 | <item> | 3 | 3 | 0.5 | 4 | 1.1 | P2 |

## Recommendation
Do items 1-2 this sprint. Defer item 3.

## Confidence Notes
- <item>: confidence is low because <reason>
- <item>: reach estimate assumes <assumption>
```

## When to Use
- Sprint planning (which features to build)
- Bug triage (which bugs to fix first)
- Skill creation (which skills to build next)
- Tech debt prioritization
- Any "we have N things, can only do M" situation

## Base120 Context
- Primary: **DE7** (Pareto 80/20)
- Related: **DE15** (Decision Tree), **IN13** (Opportunity Cost), **DE8** (Work Breakdown)
