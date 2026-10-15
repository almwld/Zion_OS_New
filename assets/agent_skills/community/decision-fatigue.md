---
name: decision-fatigue
description: Identify and reduce decision points in workflows to combat decision fatigue
version: 0.1.0
execution-mode: advisory
argument-hint: "[--scope workflow|daily|code] [--action audit|reduce]"
category: data-science
status: candidate
---
# Decision Fatigue

Identify and reduce decision points in workflows. Batch, automate, or eliminate unnecessary decisions. Analyzes daily routines, code review patterns, and operational workflows to find where cognitive load accumulates from repeated low-value choices.

## When to Use
- Feeling overwhelmed by the number of small decisions in a workflow
- Auditing a process for automation opportunities
- Designing a new workflow and want to minimize decision points
- After a session where progress was slow despite high effort

## Execution
1. Parse `$ARGUMENTS` for `--scope` (default: `workflow`) and `--action` (default: `audit`)
2. If `--scope workflow`: enumerate decision points in the current active workflow (git, CI, deploy, review)
3. If `--scope daily`: review daily routine decisions (tool choice, task ordering, communication channels)
4. If `--scope code`: scan for decision-heavy code patterns (complex conditionals, config without defaults, manual steps in scripts)
5. Classify each decision as: ELIMINATE (automate/remove), BATCH (group with similar), DELEGATE (assign to agent/tool), or KEEP (genuinely requires judgment)
6. If `--action reduce`: propose concrete changes (defaults, automation, policies) for each non-KEEP decision
7. Estimate cognitive savings: count of decisions removed or batched

## Output Format
```
Decision Fatigue | scope: {scope} | action: {action}

Decisions Found: {N}
- ELIMINATE: {count} (can be automated or removed)
- BATCH: {count} (can be grouped)
- DELEGATE: {count} (can be assigned to tool/agent)
- KEEP: {count} (requires human judgment)

Top Reduction Opportunities:
1. {decision} -- {classification} -- {proposed change}
2. {decision} -- {classification} -- {proposed change}
3. {decision} -- {classification} -- {proposed change}

Estimated Cognitive Savings: {N} fewer decisions per {period}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Found automatable decisions | `[automation-roi]` to quantify value |
| Too many variables in scope | `[dimension-reduce]` to simplify |
| Identified workflow bottlenecks | `[velocity-tune]` to optimize |
