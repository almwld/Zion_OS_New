---
name: knowledge-map
description: "Map who-knows-what across teams, agents, docs, and code ownership. Use for silos, gaps, documentation coverage, knowledge transfer, and bus-factor risk."
version: 0.2.0
execution-mode: advisory
argument-hint: "[--scope team|agents|codebase]"
category: dev-tools
status: candidate
---
# Knowledge Map

Visualize how knowledge is distributed across team members and agents. Identifies knowledge silos (single points of failure), coverage gaps, and bus factor risks. Analyzes git blame, bus activity, commit history, and documentation ownership to build the map.

This skill maps **knowledge ownership and distribution**. For epistemic state and blind-spot mapping
using known knowns / known unknowns / unknown knowns / unknown unknowns, use `uncertainty-map`.

## When to Use
- When assessing team resilience and knowledge concentration risks
- Before onboarding new team members to identify training priorities
- When planning knowledge transfer or cross-training sessions
- When evaluating whether a team member or agent departure would create critical gaps

## Execution
1. Parse `$ARGUMENTS` for scope (team, agents, or codebase)
2. For `codebase`: analyze git blame across key directories to map file ownership
3. For `agents`: scan bus messages and commit history to map agent expertise areas
4. For `team`: combine git, bus, and documentation authorship data
5. Calculate bus factor per module (how many people understand each area)
6. Identify knowledge silos (modules with bus factor = 1)
7. Identify coverage gaps (modules with no recent commits or documentation)
8. Generate a knowledge distribution matrix

## Output Format
```
Knowledge Map | <scope>
========================

## Knowledge Distribution Matrix
| Area | Primary | Secondary | Bus Factor | Risk |
|------|---------|-----------|------------|------|
| services/ | ... | ... | 2 | MEDIUM |
| integrations/ | ... | ... | 1 | HIGH |
| cognition/ | ... | ... | 3 | LOW |

## Knowledge Silos (Bus Factor = 1)
- <area>: Only <person/agent> has committed here in last 90 days

## Coverage Gaps
- <area>: No commits in <N> days, no documentation found

## Recommendations
1. Cross-train <person> on <area> to reduce bus factor risk
2. Document <area> which has no written docs

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Identified training needs | `[onboard-human]` to plan knowledge transfer |
| Knowledge gaps in specific tech | `[study-plan]` to create learning path |
| Need detailed ownership analysis | `[git-blame-analysis]` for deeper file-level view |
| Need knowns/unknowns/blind spots | `[uncertainty-map]` for epistemic-state mapping |
