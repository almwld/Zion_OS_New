---
name: fleet-tools
description: Query the HUMMBL fleet tool catalog — discover which Python packages, dashboards, and Omarchy plugins are available, what they do, and how to invoke them.
version: 1.0.0
execution-mode: advisory
argument-hint: "[list | search \"QUERY\" | info PACKAGE_NAME | categories]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---
# Fleet Tool Registry

The HUMMBL fleet has 24 Python packages, 2 dashboards (TUI + Qt), and 38 Omarchy plugins. This skill is the index — use it to discover what's available, then invoke the specific tool's skill for detailed usage.

## Usage

```bash
[fleet-tools] list                    # List all tools by category
[fleet-tools] search "heraldry"       # Search by keyword
[fleet-tools] info hummbl-heraldry    # Detailed info on one package
[fleet-tools] categories              # List categories
[fleet-tools] list --python           # Only Python packages
[fleet-tools] list --dashboards       # Only dashboards
[fleet-tools] list --omarchy          # Only Omarchy plugins
```

## Task

$ARGUMENTS

## Catalog

### Identity & Visual System

| Package | Skill | Description |
|---------|-------|-------------|
| `hummbl-design-tokens` | `design-tokens` | Design token system — colors, typography, spacing, status colors. Single source of truth for fleet visual identity. `generate_tcss()`, `generate_qml_tokens()`, `tincture_to_ansi()`. |
| `hummbl-heraldry` | `heraldry` | Procedural heraldic identity — SHA-256 agent arms generator. Generates SVG shields, Unicode renderings, blazon text from agent name + trust tier. |
| `hummbl-garage` | `garage` | Agent Performance Index — watch faces, API gauges, failure aesthetics, livery presets. Unicode + SVG renderers. |
| `hummbl-identity` | `identity` | Unified identity facade integrating design-tokens + heraldry + garage. One import for full agent identity. |

### Governance & Coordination

| Package | Skill | Description |
|---------|-------|-------------|
| `hummbl-governance` | `hummbl-governance` | Governance primitives — kill switch, circuit breaker, cost governor, delegation tokens, audit log, identity registry, schema validation, coordination bus, compliance mapper. |
| `hummbl-bus` | `bus` | Secure append-only TSV coordination bus for multi-agent systems. Post, read, search messages. |
| `hummbl-contracts` | — | Contract schemas and stdlib-only JSON Schema validator. |
| `hummbl-tuples` | — | Typed Tuples governance model. |
| `idp-spec` | — | Intelligent Delegation Profile — deterministic delegation for multi-agent systems. |
| `hummbl-validation` | — | Invariant & schema validation primitives. |
| `hummbl-validation-framework` | — | External validation tests for the design system. |

### Reasoning & Cognition

| Package | Skill | Description |
|---------|-------|-------------|
| `base120` | `base120` | 120 reasoning operators for structured thinking. 6 transformations × 20 models. MCP server + fallback. |
| `hummbl` | — | Structured reasoning framework — plans, hypotheses, observations, evaluations, decisions, reflections as durable artifacts. |
| `hummbl-lattice` | — | Domain-specific reasoning operator lattices for Domain120. |
| `hummbl-axis` | — | Ladder that selects which Atlas contradiction to act on. |
| `hummbl-cognition` | — | Cognitive Ledger Protocol (CLP) and Open Brain server. |

### Navigation & Routing

| Package | Skill | Description |
|---------|-------|-------------|
| `hummbl-compass` | — | Directional navigation & multi-agent routing algorithms. |
| `hummbl-free-models` | — | Open-weights & free-tier model registry generator. |

### Intelligence & Taxonomy

| Package | Skill | Description |
|---------|-------|-------------|
| `hummbl-intel` | — | INT taxonomy framework for agent intelligence collection. |
| `hummbl-taxonomy` | — | Governed intelligence tier taxonomy & classifier. |
| `hummbl-rubric-templates` | — | Standard evaluation rubric templates & validators. |

### Infrastructure

| Package | Skill | Description |
|---------|-------|-------------|
| `hummbl-kernel` | — | Orchestration kernel — workflow execution with security, compliance, fleet coordination. |
| `hummbl-bif` | — | Batch Ingestion Framework for technical knowledge acquisition. |
| `governed-compression` | — | Compression experiments — quantization and approximation primitives. |
| `hummbl-lint-config` | — | Shared ruff lint configuration for the fleet. |

### Dashboards

| Tool | Type | Skill | Description |
|------|------|-------|-------------|
| `hummbl-dashboard` (TUI) | Textual TUI | `dashboard-tui` | Terminal dashboard — 7 widgets, keyboard nav, SITREP mode. `python -m hummbl_dashboard.tui` |
| `hummbl.fleet-dashboard` (Qt) | Quickshell QML | `dashboard-qt` | Native panel — 7 widgets, AgentDetail modal, heraldic SVGs. `omarchy-shell shell summon hummbl.fleet-dashboard` |

### Omarchy Plugins (38 total)

All installed at `~/.config/omarchy/plugins/`. Summon via `omarchy-shell shell summon <id>`. Key plugins:

| Plugin | Kind | Description |
|--------|------|-------------|
| `hummbl.fleet-dashboard` | panel | Full fleet dashboard (Qt/QML) |
| `hummbl.fleet-health` | bar-widget | Fleet health indicator (green/yellow/red) |
| `hummbl.fleet-connect` | panel | SSH connect to fleet hosts |
| `hummbl.bus-post` | bar-widget | Post to coordination bus |
| `hummbl.bus-ticker` | bar-widget | Scrolling bus message ticker |
| `hummbl.agent-activity` | panel | Agent activity feed |
| `hummbl.cogstate` | bar-widget | Cognitive state indicator |
| `hummbl.cogstate-declare` | panel | Declare cognitive state |
| `hummbl.hrsi-checkin` | panel | HRSI check-in |
| `hummbl.hrsi-status` | bar-widget | HRSI status indicator |

## Install Paths

| Location | Contents |
|----------|----------|
| `/work/active/oss/packages/python/<name>/` | Python packages (dev) |
| `/work/active/hummbl-dashboard/` | TUI + web dashboard |
| `/work/active/hummbl-omarchy/packages/hummbl.<name>/` | Omarchy plugins (dev) |
| `~/.config/omarchy/plugins/hummbl.<name>/` | Omarchy plugins (installed) |
| `~/.agents/skills/<name>/SKILL.md` | Skill definitions |

## Execution

### Mode: list (default)
Print the full catalog grouped by category. Accepts `--python`, `--dashboards`, `--omarchy` filters.

### Mode: search
Case-insensitive keyword search across package names and descriptions.

### Mode: info
Print detailed info for one package: description, install path, key APIs, skill name, examples.

### Mode: categories
List the 7 category names.
