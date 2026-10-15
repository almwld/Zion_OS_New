---
name: brew-audit
description: Audit Homebrew packages for outdated, unused, and security issues
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--cleanup] [--security]"
category: fleet-ops
status: candidate
---
# brew-audit | Homebrew Package Audit

## When to Use
- Periodic maintenance (monthly or before major work)
- After macOS updates that may break packages
- Investigating disk usage from Homebrew
- Security review of installed packages

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=brew-audit] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Homebrew Health
```bash
brew doctor 2>&1 | head -20
```
Note any warnings or errors.

### 2. Outdated Packages
```bash
brew outdated --verbose
```
Categorize by severity:
- **Critical**: security-relevant packages (openssl, curl, git, python)
- **Recommended**: development tools
- **Optional**: utilities and nice-to-haves

### 3. Installed Package Inventory
```bash
brew list --formula | wc -l
brew list --cask | wc -l
brew list --formula
```

### 4. Disk Usage
```bash
brew info --installed | grep -E "^[0-9]+ formulae" 
du -sh $(brew --prefix)/Cellar 2>/dev/null
du -sh $(brew --prefix)/Caskroom 2>/dev/null
```

### 5. Unused Detection
Check for packages not depended on by others:
```bash
brew autoremove --dry-run
brew cleanup --dry-run | tail -20
```

### 6. Security Check (if --security)
For security-critical packages, check versions against known CVEs:
- openssl, curl, git, python, node (if installed)
- Compare installed version vs latest available

### 7. Cleanup (if --cleanup)
```bash
brew cleanup --prune=30
brew autoremove
```
Report space reclaimed.

## Output Format

```
brew-audit | <hostname>

## Health
- brew doctor: OK / N warnings

## Inventory
- Formulae: 45 | Casks: 12 | Total disk: 3.2 GB

## Outdated (N packages)
| Package   | Installed | Available | Severity    |
|-----------|-----------|-----------|-------------|
| openssl   | 3.2.0     | 3.2.1     | CRITICAL    |
| python    | 3.11.7    | 3.11.8    | RECOMMENDED |
| jq        | 1.7       | 1.7.1     | OPTIONAL    |

## Cleanup Available
- Stale downloads: 450 MB
- Old versions: 280 MB
- Autoremove candidates: 3 packages

## Commands
brew upgrade openssl python
brew cleanup --prune=30
brew autoremove
```

## Skill Chains

### Mandatory

None — read-only audit; package inventory and version checks do not modify the system.

### Advisory

- After audit → `[disk-check]` for broader disk health
- After finding outdated Python → `[venv-manage]` to rebuild venvs
- Security findings → `[security-scan]` for broader review

## Authority

- **T1 (TRUSTED)**: May run freely
- **T2 (Active/High)**: May run freely
- **T3 (Medium)**: May run freely
- **T4 (Probationary)**: May run (read-only audit — no packages modified)
- **Operator**: Override any restriction
