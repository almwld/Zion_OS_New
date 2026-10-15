---
name: repo-scaffold
description: Initialize new repo with your conventions and standard tooling
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<repo-name> [language] [--private]"
category: dev-tools
status: candidate
---
# [repo-scaffold]

## When to Use
- Creating a new repo for your-org or your-org org
- Setting up a project with consistent conventions across the fleet
- Bootstrapping a new Python package, tool, or service

## Execution

### Inputs
- **repo-name** (required): Name for the new repo
- **language** (optional): `python` (default), `typescript`, `rust`, `go`
- **--private**: Create as private repo (default: public)

### Steps
### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=repo-scaffold] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

1. Verify `$PROJECTS_DIR/<repo-name>` does not already exist
2. Create directory and `git init`
3. Generate files based on language:

**Python (default):**
- `pyproject.toml` -- stdlib-only runtime, Python 3.11+, pytest in `[test]` extras
- `README.md` -- your organization template with badges, install, usage, contributing
- `CLAUDE.md` -- Project instructions for Claude Code
- `.github/workflows/ci.yml` -- pytest on 3.11/3.12, self-hosted runner ($REMOTE_HOST-m4)
- `.github/workflows/security.yml` -- bandit + semgrep
- `.gitignore` -- Python standard (must include `__pycache__/`, `*.pyc`, `*.pyo`, `.pytest_cache/`, `*.egg-info/`, `.venv/`). Origin: 2026-09-14 — `__pycache__` was committed to 4 MCP repos via `git add -A` because no `.gitignore` existed.
- `src/<package>/` -- source package with `__init__.py`
- `tests/conftest.py` -- test scaffold
- `scripts/git-hooks/commit-msg` -- conventional commits hook
- `LICENSE` -- Apache 2.0

**TypeScript:**
- `package.json`, `tsconfig.json`, `.eslintrc.json`
- `src/index.ts`, `tests/`
- `.github/workflows/ci.yml` -- Node 20

4. Create initial commit
5. Optionally create GitHub remote: `gh repo create <org>/<name> --source .`

### your organization Conventions Applied
- Zero third-party runtime deps (Python projects)
- Conventional commits via hook
- Self-hosted CI runners ($REMOTE_HOST-m4)
- Security scanning in CI
- CLAUDE.md for AI agent context

## Output Format

```
Repo Scaffold | my-project (python)
============================================================
Created: $PROJECTS_DIR/my-project/

Files generated:
  pyproject.toml              Python 3.11+, stdlib-only
  README.md                   your organization template
  CLAUDE.md                   Claude Code instructions
  .github/workflows/ci.yml    Self-hosted CI
  .github/workflows/security.yml
  .gitignore
  src/my_project/__init__.py
  tests/conftest.py
  scripts/git-hooks/commit-msg
  LICENSE                     Apache 2.0

Git: initialized, initial commit created
GitHub: run `gh repo create your-org/my-project --public --source .`

Ready to develop:
  cd $PROJECTS_DIR/my-project
  python -m venv .venv && source .venv/bin/activate
------------------------------------------------------------
Next: [readme-gen] (flesh out README) or start coding
```

## Skill Chains

### Mandatory

None — repo creation; local file generation.

### Advisory

- After `[repo-scaffold]` → suggest `[readme-gen]` to flesh out README
- After first feature → suggest `[ci-monitor]` to verify CI passes
- For public repos → suggest `[llms-txt]` for LLM discoverability

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator approval (new repo creation)
- **T4 (Probationary)**: BLOCKED (repo creation authority)
- **Operator**: Override any restriction
