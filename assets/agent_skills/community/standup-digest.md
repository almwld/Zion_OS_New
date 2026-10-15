---
name: standup-digest
description: Aggregate standups from multiple agents and humans into a single team digest with highlights and blockers
version: 0.1.0
execution-mode: advisory
argument-hint: "[--sources bus|git|manual] [--period today|yesterday|week]"
category: fleet-ops
status: candidate
---
# Standup Digest

Aggregate standup updates from all agents and humans into a unified team digest. Pulls from the coordination bus, git commit history, and manual inputs to produce a single view of what happened, what is planned, and what is blocked across the team.

## When to Use
- Daily team sync to see all agent and human activity in one place
- Morning review to understand overnight agent work
- Weekly rollup for stakeholder communication
- Before a planning session to understand current state across all contributors

## Execution
1. Parse `$ARGUMENTS` for sources (default: `bus,git`) and period (default: `today`).
2. Gather data from each source:
   - **bus**: Read `$PROJECT_ROOT/_state/coordination/messages.tsv` for STATUS, SITREP, COMPLETE, BLOCKED, and WIP messages in the period.
   - **git**: Run `git log --since` for the period, group by author/agent.
   - **manual**: Check for manual standup entries in `_state/standups/` if they exist.
3. Group updates by contributor (agent identity or human name).
4. For each contributor, extract:
   - **Done**: Completed work (COMPLETE bus messages, merged commits).
   - **In Progress**: Active work (WIP messages, open branches).
   - **Blocked**: Blockers and dependencies (BLOCKED messages).
5. Identify cross-cutting themes: features worked on by multiple contributors, shared blockers.
6. Highlight standout items: large commits, critical blockers, milestone completions.

## Output Format
```
Standup Digest | period | sources

## Team Summary
- Contributors active: N
- Items completed: N
- Active blockers: N

## By Contributor
### {contributor_name}
- Done: {list of completed items}
- In Progress: {list of active items}
- Blocked: {list of blockers or "None"}

## Cross-Cutting Themes
- {theme}: {contributors involved, status}

## Blockers Requiring Attention
- {blocker}: {who is blocked, dependency, suggested resolution}

## Highlights
- {notable accomplishment or milestone}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Reviewing daily digest | `[daily-standup]` for individual async standup |
| Analyzing patterns over time | `[bus-analytics]` for message frequency trends |
| Rolling up for stakeholders | `[weekly-digest]` for broader operational summary |
