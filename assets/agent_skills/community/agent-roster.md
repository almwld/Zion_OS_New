---
provider-specific: true
name: agent-roster
description: Live probe of all known agents and models -- registry, bus activity, process status, model tiers.
version: 0.2.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Recent bus agents**: Run `tail -20 _state/coordination/messages.tsv 2>/dev/null | cut -f2 | sort -u | tr '\n' ', ' || echo "none"`

# Agent Roster Command

Cross-reference all known agents and models from the registry, bus, and
running processes. Includes the OpenCode multi-model inventory.

## Usage

```bash
[agent-roster]              # Show all agents and models with status
[agent-roster] --agents     # Agents only
[agent-roster] --models     # Model inventory only
```

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=agent-roster] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Read unified roster
```bash
# Primary source of truth
cat ~/.agents/ROSTER.md
```
Extract agent names, trust tiers, statuses, and model inventory.

### 2. Read model tiers (if --models or default)
```bash
cat ~/.agents/MODEL_TIERS.md
```
Extract model IDs, tiers, and privacy caveats.

### 3. Scan bus for agent activity
```bash
# Cross-platform: works on both macOS and Windows (git-bash)
cut -f2 _state/coordination/messages.tsv 2>/dev/null | sort | uniq -c | sort -rn
```
Get message count and last message timestamp per agent.

### 4. Extract model usage from bus metadata
```bash
# Find model tags in bus messages
grep -oP '\[model=[^\]]+\]' _state/coordination/messages.tsv 2>/dev/null | sort | uniq -c | sort -rn
```
Get usage count per model from bus metadata tags.

### 5. Check running processes
```bash
# macOS/Linux
pgrep -la "claude\|codex\|gemini\|opencode\|python.*hummbl_governance" 2>/dev/null
# Windows (PowerShell fallback)
Get-Process -Name "*claude*","*codex*","*gemini*","*opencode*" -ErrorAction SilentlyContinue 2>$null
```

### 6. Check service ports
```bash
# macOS/Linux
lsof -i :11434 -P -n 2>/dev/null | grep LISTEN
# Windows (PowerShell fallback)
Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue 2>$null
```

## Output Format

```
Agent & Model Roster | <YYYY-MM-DD HH:MMZ>
════════════════════════════════════════════

## Agent Identities
| Agent | Trust | Bus Msgs | Last Active | Process | Status |
|-------|-------|----------|-------------|---------|--------|
| human | OWNER | n/a | current | n/a | ACTIVE |
| claude-code | TRUSTED | 145 | 2m ago | running | ACTIVE |
| codex | TRUSTED | 12 | 1d ago | — | INACTIVE |
| opencode | PILOT | 8 | 5m ago | running | ACTIVE |
| gemini | AIP | 5 | 2d ago | — | INACTIVE |

## OpenCode Model Usage
| Model | Tier | Bus Mentions | Last Used | Privacy |
|-------|------|-------------|-----------|---------|
| claude-opus-4-6 | T1-BYOK | 6 | 5m ago | Your key |
| ring-2.6-1t-free | T3-FREE | 2 | 1h ago | Training-eligible |

## Services
| Service | Port | Status |
|---------|------|--------|
| Ollama | 11434 | UP |
| Gitea | 3030 | UP |

## Summary
- Active agents: N
- Active models: N (T1: X, T2: Y, T3: Z)
- Idle agents (>1h): N
- Total bus messages: N
```

## Constraints

- READ-ONLY. Do not start, stop, or signal any agents.
- An agent is "ACTIVE" if last bus message < 1h, "IDLE" if 1h-24h, "INACTIVE" if > 24h.
- Do not fabricate agent data -- cross-reference actual sources.
- Model tier data comes from `~/.agents/MODEL_TIERS.md` -- do not infer tiers.

## Skill Chains
- For bridge tracks opencode session activity for the roster -> `[cross-runtime-bridge]` (`python ~/bin/cross_runtime_bridge.py sessions`)

### Mandatory

None — read-only probe; no state is modified and no downstream skill is required to ensure safety.

### Advisory

- After `[agent-roster]` → `[health]` to check current adapter health status
- After `[agent-roster]` shows inactive agents → `[agent] <name> status` to investigate a specific agent
- After `[agent-roster]` shows stale models → review `~/.agents/rules/model-tier-policy.md` for current tier assignments

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (read-only probe — no state modified)
- **Operator**: Override any restriction
