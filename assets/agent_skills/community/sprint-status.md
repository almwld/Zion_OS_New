---
name: sprint-status
description: Sprint health -- focus area, effort, capacity, blocked issues.
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---
# Sprint Status Command

Query the sprint recommender for current sprint health.

## Usage

```bash
[sprint-status]        # Show current sprint status
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=sprint-status] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Import and query sprint recommender
```python
from hummbl_governance.services.sprint_recommender import SprintRecommender
sr = SprintRecommender()
result = sr.recommend_sprint()
```

### 2. Extract key metrics
- Focus area / sprint goal
- Total effort points
- Capacity used (%)
- Items included vs excluded
- Blocked items
- Priority distribution

## Output Format

```
Sprint Status | <YYYY-MM-DD HH:MMZ>
════════════════════════════════════

## Current Sprint
Focus: <sprint goal / focus area>
Capacity: XX% used (N/M effort points)

## Items
| Priority | Count | Effort |
|----------|-------|--------|
| P0 Critical | 2 | 8 |
| P1 High | 5 | 15 |
| P2 Medium | 3 | 6 |

## Blocked Items
<list of blocked items with reason>

## Excluded (Over Capacity)
<items that didn't fit in the sprint>

## Recommendations
<sprint recommender suggestions>
```

## Constraints

- READ-ONLY. Do not modify sprint state.
- If the sprint recommender fails to import, try alternative: check Linear for current sprint items.
- Do not fabricate sprint data -- always query actual recommender or issue tracker.

## Skill Chains

### Mandatory

None — read-only sprint analysis.

### Advisory

- → `[weekly-plan]` (if sprint goals need reallocation to days)
- → `[rice-prioritize]` (if over-capacity items need triage)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (read-only)
- **Operator**: Override any restriction
