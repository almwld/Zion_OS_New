---
name: git-archaeology
description: Deep history exploration -- find when and why something changed, trace the evolution of code.
version: 0.1.0
execution-mode: advisory
argument-hint: "<query> [--file PATH] [--function NAME] [--since DATE]"
category: dev-tools
status: candidate
---
# Git Archaeology

Dig through git history to answer "when did this change?", "why was this added?", and "how did this evolve?". Goes beyond simple blame to trace the full history of a piece of code.

## When to Use
- Understanding why code is written a certain way
- Tracing the history of a function, class, or pattern
- Finding the PR/issue that introduced a change
- When user says "when did this change", "git archaeology", "history of"

## Techniques

| Technique | Command | Use Case |
|-----------|---------|----------|
| Line history | `git log -L :funcname:file` | Trace a function's evolution |
| String search | `git log -S "string" --all` | Find when a string was added/removed |
| Regex search | `git log -G "pattern" --all` | Find when a pattern appeared |
| File history | `git log --follow -- file` | Full history including renames |
| Diff search | `git log --all --source --remotes -p \| grep pattern` | Find in any branch |

## Execution

1. **Clarify query**: What are we looking for? (function, string, pattern, file)
2. **Select technique**: Match query to the right git command
3. **Run search**: Execute and collect results
4. **Build timeline**: Chronological list of relevant changes
5. **Analyze context**: Read commit messages, linked PRs/issues
6. **Report**: Timeline with context and insights

## Output Format

```
Git Archaeology | {query}
=========================

## Timeline
| Date | Commit | Author | Change | Context |
|------|--------|--------|--------|---------|
| 2026-03-01 | abc1234 | reuben | Created | Initial implementation |
| 2026-03-15 | def5678 | claude | Modified | Added error handling (PR #200) |
| 2026-03-28 | ghi9012 | gemini | Attempted | Rewrote (REVERTED in 956ede6) |

## Key Insights
- {Why it was written this way}
- {Notable decision points}
- {Related changes in other files}

## Related
- PRs: {list}
- Issues: {list}
- ADRs: {list if any}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Found the reason | `[decision-log]` (record if not already an ADR) |
| Code evolved badly | `[tech-debt]` (flag for refactoring) |
| Lost context | `[retrospective]` (process improvement) |
| Multiple authors | `[git-blame-analysis]` (ownership analysis) |
