---
name: context-budget
description: Monitor and optimize context window usage -- suggest compaction, trim bloat, manage token budget.
version: 0.1.0
execution-mode: advisory
argument-hint: "[status | trim | suggest]"
category: hummbl-research
status: candidate
---
# Context Budget

Monitor context window consumption and suggest optimizations to prevent hitting limits.

## When to Use
- Long sessions approaching context limits
- Before launching parallel subagents (each gets its own context)
- When autocompact triggers frequently
- When responses start losing earlier conversation details

## Execution

### status
Assess current context health:
- How many messages in this conversation?
- How many tool calls have been made?
- Are we in a compacted state? (check for "[earlier context was summarized]" markers)
- What's the largest single tool result in context?

### trim
Identify what's consuming the most context:
- Large file reads that could be narrowed with offset/limit
- Tool results that returned more data than needed
- Repeated information (same file read multiple times)
- Verbose agent outputs that should have been summarized

### suggest
Recommend context-saving strategies:
1. **Use dispatch** for independent research (each subagent gets fresh context)
2. **Use background agents** for long-running tasks
3. **Read with offset/limit** instead of full files
4. **Grep before Read** to find the right section first
5. **Summarize before storing** -- don't paste raw data into conversation
6. **Commit and start fresh** when a logical milestone is reached

## Signs of Context Pressure
- Autocompact has triggered (conversation was compressed)
- Claude starts "forgetting" earlier decisions
- Responses become less specific about earlier work
- Tool calls get slower (more context to process)

## Output Format
```
Context Budget | <status>
═══════════════════════════

## Usage Estimate
- Messages: ~N
- Tool calls: ~N
- Compactions: N
- Largest result: ~N tokens (<source>)

## Recommendations
1. <highest-impact optimization>
2. <second>

## When to Start Fresh
<criteria for ending session and starting new one>
```

## Tips
- The `[end-session]` skill creates a clean handoff for the next session
- The `[handoff]` skill persists context for cross-session continuity
- The `[ledger]` skill persists key decisions to CLP (survives context death)
- Dispatch subagents don't share parent context -- use this to your advantage

## Skill Chains
- For token budget impacts Neuron consumption on Cloudflare models -> `[usage-monitor]` (`python ~/bin/usage_monitor.py status`)
