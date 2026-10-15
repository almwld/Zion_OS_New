---
name: git-identity-check
description: Verify git author identity matches the agent guardrails per repo. Checks that commits are attributed to the correct agent identity (codex/devin/claude-code) per each repo AGENTS.md.
version: 0.1.0
execution-mode: advisory
category: dev-tools
status: candidate
---

# git-identity-check

Verify git author identity matches the agent guardrails per repo. Checks that commits are attributed to the correct agent identity (codex/devin/claude-code) per each repo AGENTS.md.

## When to Use

- Before committing to verify identity compliance
- Auditing commit history for identity mismatches
- Pre-push identity verification

## Notes

- Skill directory populated by junction remediation P5 (2026-07-26)
- Content sourced from fleet skill registry descriptions
