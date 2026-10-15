---
name: cross-repo-grep
description: Search pattern across all PROJECTS/ repos with repo-level grouping
version: 0.1.0
execution-mode: advisory
argument-hint: "<pattern> [--type py|ts|md] [--repo filter]"
category: fleet-ops
status: candidate
---
# [cross-repo-grep]

## When to Use
- Searching for a function, class, or pattern across the entire repo fleet
- Finding which repos use a specific import, API, or convention
- Auditing a pattern (e.g., all uses of `subprocess.run`, all TODOs)
- Checking for secret patterns or security issues across repos

## Execution

### Inputs
- **pattern** (required): Regex pattern to search for
- **--type**: File type filter (py, ts, md, json, yaml, etc.)
- **--repo**: Only search specific repo(s), comma-separated
- **--exclude**: Skip specific repos

### Steps
1. Enumerate all directories under `~/PROJECTS/` that contain `.git/`
2. Include root repo (`~/`) if relevant
3. For each repo, use the Grep tool with the pattern
4. Group results by repo name
5. Within each repo, show `file:line:match`
6. Cap at 50 matches per repo (note if truncated)
7. Summarize: total matches, repos with hits, repos clean

### Exclusions (automatic)
- `.git/`, `node_modules/`, `.venv/`, `__pycache__/`, `dist/`, `build/`
- Repos with `archived` marker

## Output Format

```
Cross-Repo Grep | "circuit_breaker" --type py
============================================================
Searched: 15 repos | Pattern: circuit_breaker

## hummbl-governance (12 matches)
  services/circuit_breaker.py:15: class CircuitBreaker:
  services/circuit_breaker.py:42:     def trip(self):
  services/resilient_briefing.py:8: from .circuit_breaker import CircuitBreaker
  tests/test_circuit_breaker.py:1: """Circuit breaker tests"""
  ...

## hummbl-governance (3 matches)
  src/hummbl_governance/circuit_breaker.py:1: """Circuit breaker module"""
  tests/test_circuit_breaker.py:5: from hummbl_governance import circuit_breaker
  ...

## foundermode-app (0 matches)

Summary: 15 matches across 2/15 repos
------------------------------------------------------------
Next: [mono-diff] (see recent changes to matched files)
```

## Skill Chains
- After finding duplicated code -> suggest extracting to shared package
- After finding security patterns -> suggest `[security-scan]`
- Use before `[mono-diff]` to see where a pattern lives
