---
name: config-drift
description: Detect configuration drift across machines in the mesh
version: 0.1.0
execution-mode: advisory
argument-hint: "[--machines machine1,machine2,machine3] [--scope tools|env|settings|all]"
category: backend-infra
status: candidate
---
# Config Drift

Detect configuration drift across machines: Python versions, tool versions, env vars, settings differences. Identifies where machines in the mesh have diverged and what needs syncing.

## When to Use
- After updating tools or settings on one machine
- Debugging "works on my machine" issues
- Periodic mesh health check
- Before deploying to ensure environment consistency

## Prerequisites

1. **Run `[fleet-ssh-config]`** to verify SSH aliases are configured and reachable.
2. **Human approval** — Remote SSH collection requires explicit operator approval.

## Execution

1. Parse `$ARGUMENTS` for `--machines` (default: all known) and `--scope` (default: `all`)
2. For each machine, collect configuration data. Use platform-aware commands:

### `tools` scope

**On local Windows machine:**
```powershell
Write-Output "=== Python ==="; python --version
Write-Output "=== Git ==="; git --version
Write-Output "=== Node ==="; node --version 2>$null
Write-Output "=== gh ==="; gh --version 2>$null | Select-Object -First 1
Write-Output "=== Agent CLIs ==="; foreach ($c in @('claude','devin','codex','opencode')) {
  if (Get-Command $c -EA SilentlyContinue) { "$c : $(& $c --version 2>$null | Select-Object -First 1)" }
}
```

**On local macOS machine:**
```bash
echo "=== Python ==="; python3 --version
echo "=== Git ==="; git --version
echo "=== Node ==="; node --version 2>/dev/null
echo "=== gh ==="; gh --version 2>/dev/null | head -1
echo "=== Agent CLIs ==="; for c in claude devin codex opencode; do
  command -v "$c" >/dev/null 2>&1 && echo "$c : $("$c" --version 2>/dev/null | head -1)"
done
```

**On remote machine via SSH:**
```bash
ssh -o ConnectTimeout=5 mini "python3 --version && git --version && node --version"
```

### `env` scope

**On local Windows machine:**
```powershell
Write-Output "=== PATH length ==="; $env:PATH.Split(';').Count
Write-Output "=== Relevant vars ==="; Get-ChildItem Env: | Where-Object { $_.Name -match 'PYTHON|NODE|GIT|ENABLE_|PATH' } | Format-Table Name,Value -Wrap
```

**On local macOS machine:**
```bash
echo "=== PATH length ==="; echo $PATH | tr ':' '\n' | wc -l
echo "=== Relevant vars ==="; env | grep -E 'PYTHON|NODE|GIT|ENABLE_|PATH='
```

### `settings` scope

**On local Windows machine:**
```powershell
Write-Output "=== Git config ==="; git config --global --list 2>$null
Write-Output "=== Skills count ==="; (Get-ChildItem -Path "$HOME/.agents/skills" -Directory -Depth 0).Count
```

**On local macOS machine:**
```bash
echo "=== Git config ==="; git config --global --list 2>/dev/null
echo "=== Skills count ==="; ls ~/.agents/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' '
```

### `all` scope
Run all three scopes above.

3. For local machine: run the appropriate platform block above.
4. For remote machines: SSH to collect using the remote SSH example. Requires human approval per security rules.
5. Diff each machine pair:
   - **Version drift**: same tool, different versions
   - **Missing tools**: tool present on one machine, absent on another
   - **Config divergence**: different settings for the same tool
   - **Stale**: version more than 2 minor versions behind latest
6. Classify each drift as: CRITICAL (will break workflows), WARNING (may cause issues), INFO (cosmetic)
7. Suggest sync commands for each drift item

## Output Format
```
Config Drift | machines: {list} | scope: {scope}

Drift Summary: {N} items ({critical} critical, {warning} warning, {info} info)

Critical:
- {tool}: {machine_a} has {version_a}, {machine_b} has {version_b} -- {fix}

Warning:
- {item}: {description} -- {fix}

Info:
- {item}: {description}

Sync Commands:
{commands to resolve drift}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Drift detected | `[mesh-sync]` to sync skill files |
| Checking fleet health | `[fleet-status]` for full machine status |
| Tools need updating | `[brew-audit]` (macOS) or manual update |
