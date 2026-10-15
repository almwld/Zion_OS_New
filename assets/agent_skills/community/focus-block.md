---
name: focus-block
description: Start a timed deep work block with goal, distraction logging, and end-of-block review
version: 0.1.0
execution-mode: advisory
argument-hint: "<goal> [--duration 25|50|90] [--action start|review]"
category: data-science
status: candidate
---
# Focus Block

Start a structured deep work block with a clear goal, timed duration, distraction logging, and end-of-block review. Based on the Pomodoro technique and Cal Newport's deep work principles. Helps maintain focus and measure productive output.

## When to Use
- When starting focused work on a specific task that requires concentration
- When you need to minimize context switching and track interruptions
- When reviewing how a focus session went and what was accomplished
- When establishing a rhythm of focused work blocks during the day

## Execution
1. Parse `$ARGUMENTS` for goal description, duration (default: 50 minutes), and action (default: start)
2. For `start`: record the goal, start time, and duration in `_state/focus_blocks.jsonl`
3. Display the goal prominently and set expectations for the block
4. During the block: log any interruptions or distractions as they occur
5. For `review`: calculate time spent, assess goal completion (fully, partially, not met)
6. Record outcome, interruption count, and learnings
7. Suggest optimal next action based on energy and goal completion

## Output Format
```
Focus Block | <action>
========================

## Block Details
- Goal: <goal>
- Duration: <N> minutes
- Started: <time>
- Status: IN_PROGRESS / COMPLETED / REVIEWED

## During Block (start)
Focus on: <goal>
Duration: <N> minutes
Avoid: context switches, notifications, unrelated tasks

## Review (review)
- Goal completion: FULL / PARTIAL / NOT_MET
- Actual duration: <N> minutes
- Interruptions: <count>
- Output produced: <summary>

## Interruption Log
| Time | Type | Description | Resolved |
|------|------|-------------|----------|
| ... | EXTERNAL/SELF | ... | YES/DEFERRED |

## Next Action
- ...
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Tempo was just set | `[tempo]` established the work mode, focus block executes it |
| Block complete, reflect on session | `[retrospective]` for broader pattern analysis |
