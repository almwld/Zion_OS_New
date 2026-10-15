---
name: readme-gen
description: Generate or refresh README.md from code structure, imports, and conventions
version: 0.1.0
execution-mode: advisory
argument-hint: "[repo-path] [--refresh]"
category: dev-tools
status: candidate
---
# [readme-gen]

## When to Use
- New repo needs a README
- Existing README is stale or incomplete after major changes
- Ensuring GEO/SEO/AEO optimization for public repos
- Refreshing counts, badges, or structure after a release

## Execution

### Inputs
- **repo-path** (optional): Path to repo, default current working directory
- **--refresh**: Update existing README, preserving sections marked `<!-- custom -->`

### Steps
1. Analyze repo structure:
   - Detect language(s) from file extensions and config files
   - Read `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod` for metadata
   - Scan for test framework (pytest, vitest, cargo test, go test)
   - Check `.github/workflows/` for CI setup
   - Read `CLAUDE.md` if present for context
2. Detect key patterns:
   - Entry points (`__main__.py`, `main.py`, `index.ts`, `main.go`)
   - CLI commands and subcommands
   - Exported modules and public API surface
   - Runtime vs dev dependencies
3. If `--refresh`: read existing README, preserve `<!-- custom -->` blocks
4. Generate sections:
   - Title + one-line description (from metadata)
   - Badges (CI status, PyPI/npm version, license)
   - What it does / Features
   - Installation
   - Quick Start / Usage (with real examples)
   - Architecture (if >5 modules)
   - Testing commands
   - Contributing
   - License
5. Apply GEO optimization:
   - Natural language headings ("What is X?" not just "About")
   - FAQ section for common questions (helps AI search)
   - First paragraph as structured description

### GEO/AEO Checklist
- Descriptive headings with question phrasing
- "What is X?" and "How does X work?" sections
- FAQ with 3-5 questions for public repos
- First paragraph answers "what is this project?"

## Output Format

```
README Gen | your-package
============================================================
Analyzed: 20 modules, 476 tests, Python 3.11+, Apache 2.0

Generated sections:
  [x] Title + badges (CI, PyPI, license)
  [x] Description (GEO-optimized)
  [x] Features (6 bullet points)
  [x] Installation (pip install)
  [x] Quick Start (3 examples)
  [x] Architecture (module map)
  [x] Testing (pytest command)
  [x] Contributing
  [x] FAQ (4 questions)
  [x] License

Written to: README.md (142 lines)
Previous backed up to: README.md.bak

Key changes:
  - Added missing installation section
  - Updated test count (was 400, now 476)
  - Added GEO FAQ section
------------------------------------------------------------
Next: [llms-txt] (generate llms.txt for LLM discovery)
```

## Skill Chains
- After `[readme-gen]` -> suggest `[llms-txt]` for LLM discoverability
- After `[repo-scaffold]` -> run `[readme-gen]` to flesh out template
- Before publishing a release -> `[readme-gen] --refresh` to update counts
