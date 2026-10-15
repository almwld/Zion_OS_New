---
name: contributor-guide
description: Generate CONTRIBUTING.md with dev setup, PR process, code style, and testing requirements from repo analysis
version: 0.1.0
execution-mode: advisory
argument-hint: "[--repo PATH] [--style minimal|standard|comprehensive]"
category: dev-tools
status: candidate
---
# Contributor Guide Generator

Analyze a repository's structure, tooling, and conventions to generate a CONTRIBUTING.md file. Extracts dev setup instructions, PR process, code style rules, testing requirements, and commit conventions from existing configuration files and patterns.

## When to Use
- When setting up a new open source project that needs contributor docs
- When existing CONTRIBUTING.md is outdated or missing
- When onboarding external contributors who need clear guidelines
- When standardizing contribution processes across repos

## Execution
1. Parse `$ARGUMENTS` for repo path (default: current) and style level
2. Analyze repo for: package manager (pyproject.toml, package.json), linters, formatters, test framework, CI config
3. Extract dev setup from existing scripts, Makefile, or documented commands
4. Detect commit conventions from git log and hooks (conventional commits, etc.)
5. Identify PR process from GitHub config, templates, and branch protection rules
6. Generate CONTRIBUTING.md at the appropriate detail level
7. For `minimal`: setup + PR process only. For `standard`: add code style + testing. For `comprehensive`: add architecture overview + decision process

## Output Format
```
Contributor Guide | <repo> | <style>
======================================

## Generated CONTRIBUTING.md

<full markdown content ready to write>

## Detected Conventions
- Package manager: <pip/npm/etc>
- Test framework: <pytest/jest/etc>
- Linter: <ruff/eslint/etc>
- Commit style: <conventional/freeform>
- Branch strategy: <trunk/gitflow/etc>
- CI: <GitHub Actions/etc>

## Next Action
- Review and write to CONTRIBUTING.md
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| CONTRIBUTING.md ready | `[readme-gen]` to ensure README references it |
| New contributors joining | `[onboard-human]` for personalized onboarding |
