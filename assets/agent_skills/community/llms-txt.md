---
name: llms-txt
description: Generate or update llms.txt and llms-full.txt for LLM-optimized site discovery
version: 0.1.0
execution-mode: advisory
argument-hint: "[repo-path] [--full]"
category: sales-marketing
status: candidate
---
# [llms-txt]

## When to Use
- Publishing a repo or site that should be discoverable by LLMs
- After major documentation changes to keep LLM context current
- Setting up a new public-facing project
- Improving AI search discoverability (AEO/GEO strategy)

## Execution

### Background
The llms.txt specification (llmstxt.org) defines a `[llms].txt` file that helps LLMs understand a site or project. It provides structured context for AI assistants answering questions about the project. Reference: `PROJECTS/$GITHUB_ORG-profile/promotion/LLMS_TXT.md`

### Inputs
- **repo-path** (optional): Path to repo, default current directory
- **--full**: Also generate `llms-full.txt` with comprehensive documentation

### Steps
1. Analyze the project:
   - Read README.md, CLAUDE.md, and `docs/` directory
   - Identify: project name, description, key features, license
   - Detect: language, framework, package manager
   - Find: install commands, API surface, CLI usage, key concepts
2. Generate `llms.txt` (concise, <500 lines):
   - H1: Project name
   - Blockquote: One-line description
   - `## Docs` section with links to key documentation files
   - `## Optional` section with secondary links
3. If `--full`, generate `llms-full.txt` (<2000 lines):
   - Everything from llms.txt
   - Full API reference / public interface
   - Architecture overview
   - Configuration options
   - Common patterns and usage examples
   - FAQ
4. Validate format against llms.txt spec
5. Write to repo root

### llms.txt Format (per spec)
```
# Project Name

> One-line description of the project.

## Docs

- [README](url): Project overview and quick start
- [API Reference](url): Complete API documentation
- [Getting Started](url): Installation and first steps

## Optional

- [Changelog](url): Version history
- [Contributing](url): Contribution guidelines
```

## Output Format

```
llms.txt | hummbl-governance
============================================================
Analyzed: README.md, docs/, 20 modules, pyproject.toml

Generated:
  llms.txt       45 lines (concise overview)
  llms-full.txt  380 lines (complete reference)

Preview (llms.txt):
  # hummbl-governance
  > Python stdlib-only AI governance primitives: circuit breakers,
  > kill switches, delegation tokens, audit logging.
  ## Docs
  - [README](https://github.com/$GITHUB_ORG/hummbl-governance/...)
  - [API Reference](https://github.com/$GITHUB_ORG/hummbl-governance/...)

Validation: PASS (conforms to llmstxt.org spec)

Deploy: copy to site root or serve at [llms].txt
------------------------------------------------------------
Next: [readme-gen] --refresh (link to llms.txt from README)
```

## Skill Chains
- After `[repo-scaffold]` -> suggest `[llms-txt]` for public repos
- After `[readme-gen]` -> suggest `[llms-txt]` to complement README
- After major docs update -> `[llms-txt] --full` to refresh
