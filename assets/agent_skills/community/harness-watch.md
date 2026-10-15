---
name: harness-watch
description: Track releases and breaking changes across agentic harnesses and runtimes — claude-code, codex, devin CLI, opencode, gemini CLI, antigravity — plus MCP spec changes. Complements industry-watch (models/vendors) and config-drift (local config state).
version: 0.1.0
execution-mode: advisory
argument-hint: "[--harness claude-code|codex|devin|opencode|gemini|antigravity|mcp|all] [--depth quick|full]"
category: backend-infra
status: candidate
provider-specific: true
---
# Harness Watch

Track what shipped in the agentic-harness layer: CLI releases, deprecations, auth/permission-model changes, MCP spec updates. `[industry-watch]` covers vendors and models; `[config-drift]` covers local config state; this skill covers the harnesses themselves — the layer fleet agents actually run inside.

## When to Use

- 12:00 UTC watch-cycle slot (scheduled external lane)
- Before upgrading any fleet runtime
- When a runtime behaves differently after an update
- When an MCP server stops working across multiple clients

## Sources

Prefer primary, machine-checkable sources:

- GitHub releases via `gh api repos/<owner>/<repo>/releases` (versioned CLIs)
- `npm view <pkg> version` for npm-distributed harnesses
- `devin update` / `devin version` for the local Devin CLI
- MCP spec: `modelcontextprotocol/specification` repo + `modelcontextprotocol.io` changelog
- Official changelogs/blogs when no machine-readable source exists

Do not scrape release pages when a release API exists.

## Known Harness Surfaces (update as runtimes change)

| Harness | Check |
|---|---|
| claude-code | `npm view @anthropic-ai/claude-code version`; anthropic changelog |
| codex | `npm view @openai/codex version` vs local `codex --version` (binary/shim skew is a known fleet issue — flag mismatches) |
| devin | `devin update --check`, `devin version` |
| opencode | `opencode upgrade` check / opencode.ai releases |
| gemini | `npm view @google/gemini-cli version` |
| antigravity | Antigravity release notes (no registry; mark unverified) |
| mcp | `modelcontextprotocol/specification` releases + sdk changelogs |

## Default Output Shape

```yaml
harness:
observed_version:
latest_version:
date:
change:
routing_implication:
confidence:
sources:
```

- Flag when installed version lags latest by more than one minor release.
- Flag breaking changes, auth changes, permission-mode changes, and MCP-protocol incompatibilities explicitly — these can silently break the fleet.
- If a source is unreachable, say so and mark the version unverified; never interpolate.

## Boundaries

- Read-only: never upgrade or modify a runtime; that is an operator decision.
- Local version comparison is evidence collection, not remediation.
- Sources required per `claim-honesty-protocol`; "no significant findings" is a valid result.
