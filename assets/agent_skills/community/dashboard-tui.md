---
name: dashboard-tui
description: Launch the HUMMBL fleet TUI dashboard — Textual-based terminal interface showing agents, bus stream, tasks, topology, governance, and validation.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--bus PATH | --post-sitrep [--dry-run] | --refresh N]"
category: governance-compliance
status: candidate
---
# HUMMBL Fleet TUI Dashboard

Terminal dashboard for the HUMMBL fleet. Built with Textual. Shows all agents with heraldic shields, live bus stream, task queue, topology map, session lifecycle, governance trail, and validation bar.

## When to Use

- Monitoring fleet status from a terminal
- Viewing live bus messages with type-colored icons
- Checking agent health, trust tiers, and heraldic identity
- Posting SITREPs from the command line
- Any terminal-based fleet overview

## Usage

```bash
# Launch interactive dashboard
python -m hummbl_dashboard.tui

# Use a specific bus file
COORDINATION_BUS=~/.cache/bus/messages.tsv python -m hummbl_dashboard.tui

# Post a SITREP (dry run first)
python -m hummbl_dashboard.tui --post-sitrep --dry-run
python -m hummbl_dashboard.tui --post-sitrep

# Set refresh interval
python -m hummbl_dashboard.tui --refresh 15
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| `1` | Focus agent grid |
| `2` | Focus bus stream |
| `3` | Focus task queue |
| `4` | Focus topology |
| `q` | Quit |
| `r` | Refresh data |
| `enter` | Open agent detail (when agent grid focused) |
| `escape` | Close agent detail |

## Widgets

1. **StatusBar** — fleet summary (agent count, message count, verdict)
2. **AgentGrid** — all agents with heraldic Unicode shields, status dots, sparklines
3. **BusStream** — live bus messages with type-colored icons (●◆✓→★✕?♦)
4. **TaskQueue** — BLOCKED/QUESTION/PROPOSAL/MILESTONE sorted by priority
5. **TopologyMap** — agents grouped by status, message type distribution
6. **ValidationBar** — fleet health verdict + falsifiability indicator
7. **AgentDetail** — full agent info modal (heraldry, watch, API gauge)

## Data Sources

Tries three sources in order:
1. FastAPI (`http://127.0.0.1:8000/api/identity`)
2. Bus TSV (`~/.cache/bus/messages.tsv`)
3. Placeholder fallback (static fleet data)

## Install

```bash
cd /work/active/hummbl-dashboard
pip install -e ".[tui]"
```

## Package

- **Repo**: `hummbl-io/hummbl-dashboard`
- **Path**: `src/hummbl_dashboard/tui/`
- **Dependencies**: textual, rich

## Mandatory

This skill launches a TUI application that reads bus data. It does not modify the bus or any fleet state unless `--post-sitrep` is used (which posts a SITREP to the bus).

## Authority

- **Read-only mode** (default): No authority required. Any agent can launch the dashboard.
- **SITREP posting** (`--post-sitrep`): Requires bus post authority. Posts as `devin` by default. Use `--dry-run` first to preview.
