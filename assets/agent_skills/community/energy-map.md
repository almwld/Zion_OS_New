---
name: energy-map
description: Track energy levels across the day to optimize task scheduling and identify peak hours
version: 0.1.0
execution-mode: advisory
argument-hint: "[--action log|analyze|recommend] [--level 1-5]"
category: data-science
status: candidate
---
# Energy Map

Track personal energy levels throughout the day to identify peak productivity windows and optimize task scheduling. Logs energy at intervals, analyzes patterns over time, and recommends when to schedule different types of work (deep focus, meetings, admin).

## When to Use
- When logging current energy level during a work session
- When analyzing energy patterns to find optimal work windows
- When planning the next day or week and want to match tasks to energy levels
- When feeling consistently low energy and want to identify contributing factors

## Execution
1. Parse `$ARGUMENTS` for action (log, analyze, recommend) and optional energy level (1-5)
2. For `log`: record timestamp, energy level, current activity, and optional notes to `_state/energy_log.jsonl`
3. For `analyze`: aggregate energy data over the last 7-30 days, identify patterns by time of day, day of week
4. For `recommend`: based on energy patterns, suggest optimal time slots for different task types
5. Categorize tasks: deep work (needs 4-5 energy), meetings (needs 3-4), admin/email (needs 2-3), breaks (needs 1-2)
6. Flag anomalies: consistently low energy at certain times, energy crashes after specific activities

## Output Format
```
Energy Map | <action>
======================

## Current Log (log)
- Time: <timestamp>
- Energy: <level>/5 <visual bar>
- Activity: <current task>
- Streak: <N> logs today

## Energy Pattern (analyze)
| Time Block | Avg Energy | Best For |
|------------|-----------|----------|
| 6-9 AM | 4.2 | Deep work |
| 9-12 PM | 3.8 | Meetings, coding |
| 12-2 PM | 2.5 | Admin, breaks |
| 2-5 PM | 3.3 | Collaboration |
| 5-8 PM | 2.8 | Light tasks |

## Weekly Pattern
| Day | Avg Energy | Peak Hour |
|-----|-----------|-----------|
| Mon | 3.4 | 8 AM |
| ... | ... | ... |

## Recommendations (recommend)
- Schedule deep work: <optimal windows>
- Schedule meetings: <optimal windows>
- Take breaks at: <low energy windows>
- Avoid scheduling focus work at: <consistently low periods>

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Know peak hours, need to plan work | `[find-work]` to match tasks to energy windows |
| Morning planning with energy data | `[gm]` to schedule the day optimally |
