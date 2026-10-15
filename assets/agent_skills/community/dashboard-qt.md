---
name: dashboard-qt
description: Summon the HUMMBL fleet Qt/QML dashboard — Quickshell panel with agent grid, bus stream, tasks, topology, governance, and agent detail modal.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[summon | install | uninstall | keybind]"
category: governance-compliance
status: candidate
---
# HUMMBL Fleet Qt Dashboard

Native QML panel for the HUMMBL fleet. Built with Quickshell. Shows all agents with heraldic SVG shields, live bus stream, task queue, topology map, session lifecycle, governance trail, validation bar, and click-to-open agent detail modal.

## When to Use

- Monitoring fleet status from the Hyprland desktop
- Viewing agents with full heraldic SVG shields (not Unicode)
- Clicking agents for detailed identity (watch face, API gauge, blazon)
- Any native-panel fleet overview

## Usage

```bash
# Summon the panel
omarchy-shell shell summon hummbl.fleet-dashboard

# Enable the plugin (first time only)
omarchy-shell shell enablePlugin hummbl.fleet-dashboard '{}'

# Hyprland keybinding (already configured):
# SUPER + SHIFT + ALT + CTRL + F3

# Install from source
cd /work/active/hummbl-omarchy/packages/hummbl.fleet-dashboard
./install.sh

# Uninstall
./install.sh --uninstall
```

## Widgets

1. **AgentGrid** — all agents with heraldic SVG shields, status dots, trust tiers
2. **BusStream** — live bus messages with type-colored icons, auto-scroll
3. **TaskQueue** — BLOCKED/QUESTION/PROPOSAL/MILESTONE sorted by priority
4. **TopologyMap** — agents grouped by status, message type distribution bars
5. **SessionLifecycle** — INIT → PLANNING → EXECUTING → VERIFYING → CLOSED stepper
6. **GovernanceTrail** — DECISION/MILESTONE/BLOCKED events with status badges
7. **ValidationBar** — fleet health verdict + falsifiability indicator
8. **AgentDetail** — click any agent for full heraldic arms, watch face SVG, API gauge SVG

## Data Sources

Tries three sources in order:
1. FastAPI (`http://127.0.0.1:8000/api/identity`)
2. Bus TSV (`~/.cache/bus/messages.tsv`)
3. Placeholder fallback (static fleet data)

## Settings

| Key | Default | Description |
|-----|---------|-------------|
| `apiUrl` | `http://127.0.0.1:8000/api/identity` | FastAPI dashboard URL |
| `busTsvPath` | `~/.cache/bus/messages.tsv` | Bus TSV path |
| `refreshIntervalSec` | `30` | Auto-refresh interval |

## Install Location

- **Source**: `/work/active/hummbl-omarchy/packages/hummbl.fleet-dashboard/`
- **Installed**: `~/.config/omarchy/plugins/hummbl.fleet-dashboard/`
- **Keybinding**: `~/.config/hypr/bindings.lua` (SUPER+SHIFT+ALT+CTRL+F3)

## Package

- **Repo**: `hummbl-io/hummbl-omarchy`
- **Path**: `packages/hummbl.fleet-dashboard/`
- **License**: MIT
- **Dependencies**: Quickshell, Qt 6

## Mandatory

This skill summons a Quickshell panel that reads bus data and API endpoints. It does not modify fleet state. The panel is display-only.

## Authority

- **Summon/display**: No authority required. Any agent can summon the panel.
- **Install/uninstall**: Requires file system write to `~/.config/omarchy/plugins/`. Not a bus-affecting action.
