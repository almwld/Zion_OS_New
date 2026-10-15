---
name: usability-test
description: Plan, run, or synthesize task-based usability tests for products, prototypes, flows, docs, APIs, or tools. Use when the user asks whether users can complete tasks or wants test scripts/findings.
version: 0.1.0
execution-mode: advisory
argument-hint: "<flow-or-product> [tasks]"
category: fleet-ops
status: candidate
---
# Usability Test

## Purpose

Answer: "Can representative users complete real tasks, and where do they fail?"

## Workflow

1. Define target users and tasks.
2. Write scenario prompts that avoid leading the participant.
3. Define success criteria, failure criteria, and observation notes.
4. Run or simulate walkthroughs only when real participants are unavailable; label simulations clearly.
5. Synthesize findings by severity:
   - `P1`: task failure or unsafe misunderstanding.
   - `P2`: major friction or repeated confusion.
   - `P3`: minor friction or preference.
6. Recommend changes and retest tasks.

## Output

```markdown
Usability Verdict: <validated | needs-test | failed-tasks | inconclusive>
Participants/Mode: <real/simulated/unknown>
Tasks: <list>
Findings:
- P1/P2/P3: <evidence, impact, fix>
Retest Plan:
- <tasks>
```

## Rules

- Do not present simulated tests as user research.
- Separate observed behavior from inference.
- Use task success over opinions as the primary signal.
