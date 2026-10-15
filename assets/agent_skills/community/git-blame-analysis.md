---
name: git-blame-analysis
description: Analyze code ownership, churn rate, and hotspots by file and function using git blame and log.
version: 0.1.0
execution-mode: advisory
argument-hint: "[PATH] [--metric ownership|churn|hotspots|age] [--since DATE]"
category: dev-tools
status: candidate
---
# Git Blame Analysis

Go beyond `git blame` to understand code ownership patterns, change frequency, and maintenance hotspots. Identifies files that change too often (instability), single-owner files (bus factor risk), and ancient code nobody touches.

## When to Use
- Understanding who owns what in a codebase
- Identifying high-churn files (maintenance burden)
- Assessing bus factor risk
- Prioritizing tech debt work
- When user says "who wrote this", "code ownership", "hotspots", "blame"

## Metrics

| Metric | What It Measures | Command |
|--------|-----------------|---------|
| **ownership** | Who wrote what % of each file | `git blame --line-porcelain` |
| **churn** | How often each file changes | `git log --format='' --name-only` |
| **hotspots** | Files with both high churn AND high complexity | churn * LOC as proxy |
| **age** | Time since last modification per file | `git log -1 --format='%ai'` |

## Execution

1. **Scope**: Target path (file, directory, or whole repo)
2. **Collect**: Run git commands to gather data
3. **Analyze**: Compute metrics, rank files
4. **Report**: Top-N files by selected metric with actionable insights

## Output Format

```
Git Blame Analysis | {path} | {metric}
=======================================

## Ownership Map (top 20 files)
| File | Primary Owner | % | Secondary | % | Contributors |
|------|--------------|---|-----------|---|-------------|

## Churn Hotspots (top 20)
| File | Changes (90d) | LOC | Hotspot Score | Last Changed |
|------|--------------|-----|---------------|-------------|

## Bus Factor Risks
| File | Single Owner | LOC | Risk |
|------|-------------|-----|------|
(Files where one person wrote >80%)

## Ancient Code (untouched >6 months)
| File | Last Modified | LOC | Owner |
|------|-------------|-----|-------|

## Recommendations
- {High-churn files that need refactoring or better tests}
- {Single-owner files that need knowledge transfer}
- {Ancient files that may be dead code}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| High churn found | `[tech-debt]` (prioritize stabilization) |
| Bus factor risk | `[onboard-human]` or `[knowledge-map]` |
| Ancient code | `[dead-code]` (check if still used) |
| Ownership unclear | `[contributor-guide]` (clarify ownership) |
