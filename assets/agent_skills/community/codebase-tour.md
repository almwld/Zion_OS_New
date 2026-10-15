---
name: codebase-tour
description: Generate a guided tour of a codebase with entry points, key modules, data flow, and start-here guidance
version: 0.1.0
execution-mode: advisory
argument-hint: "[PATH] [--audience new-dev|ai-agent|reviewer] [--depth quick|comprehensive]"
category: dev-tools
status: candidate
---
# Codebase Tour

Generate a structured walkthrough of a codebase or subdirectory. Identifies entry points, key modules, data flow patterns, conventions, and provides "start here" guidance tailored to the audience. Useful for onboarding humans, briefing AI agents, or giving reviewers a map before a deep dive.

## When to Use
- Onboarding a new developer or AI agent to a repo or subsystem
- Preparing context before a code review of an unfamiliar area
- Creating orientation material for a handoff or delegation
- Understanding a new codebase or directory you have not worked in before

## Execution
1. Parse `$ARGUMENTS` for target path (default: repo root), audience (default: `new-dev`), and depth (default: `quick`).
2. Scan directory structure: list top-level directories, count files by type, identify config files (pyproject.toml, package.json, Makefile, etc.).
3. Identify entry points: main scripts, CLI commands, `__main__.py`, `if __name__`, server start files, test runners.
4. Map key modules: find the largest files, most-imported modules, and public API surfaces.
5. Trace data flow: follow imports from entry points to understand how data moves through the system.
6. Extract conventions: naming patterns, test organization, commit style (check CONTRIBUTING.md, CLAUDE.md, hooks).
7. For `comprehensive` depth, also analyze: dependency graph, test coverage distribution, CI pipeline, and config patterns.
8. Tailor output to audience:
   - **new-dev**: Emphasize setup, conventions, "change X to see Y" examples.
   - **ai-agent**: Emphasize module boundaries, import paths, approved scope, and constraints.
   - **reviewer**: Emphasize architecture decisions, risk areas, and test gaps.

## Output Format
```
Codebase Tour | PATH | audience | depth

## Overview
{2-3 sentence description of what this codebase does}

## Directory Map
{Tree with annotations for each major directory}

## Entry Points
- {file}: {what it does, how to run it}

## Key Modules
- {module}: {responsibility, key classes/functions}

## Data Flow
{How data moves from input to output, 3-5 steps}

## Conventions
- {convention}: {example}

## Start Here
1. {First thing to read or run}
2. {Second thing}
3. {Third thing}

Next action: {suggestion or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Tour for a new developer | `[onboard-dev]` for full environment setup |
| Tour revealing complex architecture | `[arch-diagram]` for visual representation |
| Tour for documentation purposes | `[readme-gen]` to update the README |
