---
name: habit-track
description: Track daily habits and routines with streak counting, trends, and consistency scores
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action log|status|trends] [--habit NAME]"
category: data-science
status: candidate
---
# Habit Track

Track daily habits and routines with streak counting, consistency scores, and trend analysis. Stores entries in `_state/habits.jsonl` for cross-session persistence. Designed for solo founders tracking personal productivity habits alongside engineering work.

## When to Use
- Logging completion of a daily habit (exercise, journaling, deep work block, etc.)
- Checking current streaks and consistency across all tracked habits
- Reviewing weekly or monthly trends to identify patterns
- Setting up a new habit to track

## Execution
1. Parse `$ARGUMENTS` for `--action` (default: status) and `--habit` name filter.
2. For `log`: record today's completion for the specified habit in `_state/habits.jsonl` with timestamp.
3. For `status`: load all habit entries, calculate current streak (consecutive days), longest streak, and consistency score (completions / total days since start).
4. For `trends`: analyze weekly completion rates, identify best/worst days of week, show month-over-month trend.
5. If a habit has not been logged in >2 days, flag it as AT RISK.
6. Calculate overall consistency score across all habits.

## Output Format
```
Habit Track | status

| Habit | Current Streak | Best Streak | Consistency | Last Logged | Status |
|-------|---------------|-------------|-------------|-------------|--------|
| deep-work | 5 days | 12 days | 78% | today | ACTIVE |
| exercise | 0 days | 8 days | 45% | 3 days ago | AT RISK |
| journal | 2 days | 15 days | 62% | today | ACTIVE |
| research-read | 1 day | 5 days | 33% | today | ACTIVE |

Overall Consistency: 55% (target: 70%)

Trends:
- Best day: Tuesday (82% completion across all habits)
- Worst day: Saturday (18% completion)
- This week: 11/20 completions (55%) -- flat vs last week

Next action: Log exercise today to restart the streak.
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Weekly trends reviewed | `[weekly-review]` for broader productivity context |
| Energy patterns visible | `[energy-map]` to correlate habits with energy levels |
| Consistency improving | `[retrospective]` to capture what is working |
