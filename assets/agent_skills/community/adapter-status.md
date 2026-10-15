---
name: adapter-status
description: Check which service adapters are wired and operational.
version: 0.1.0
execution-mode: advisory
category: fleet-ops
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **gh auth**: Run `gh auth status 2>&1 | head -3 || echo "not authenticated"`
- **Signal**: Run `curl -s -m 2 http://127.0.0.1:8080/api/v1/about 2>/dev/null | head -c 100 || echo "not running"`

# Adapter Status Command

Probe and report the status of your project's service adapters.

## Usage

```bash
[adapter-status]        # Check all adapters
```

## Adapters

Identify your project's service adapters (e.g., GitHub, Calendar, Issue Tracker, Cost Tracker, Messaging, etc.) by scanning the `integrations/` and `services/` directories.

## Probe Steps

### 1. Code Wiring Check
Read the project's scheduler or main entry point and verify each adapter has:
- An import or function definition
- A try/except wiring block
- Fallback to None/mock on failure

### 2. Runtime Dependency Check
For each adapter, check whether its runtime dependencies are available:
- **CLI tools**: Are required CLIs authenticated? (e.g., `gh auth status`)
- **Config files**: Are required config values set? (e.g., calendar_id, API keys)
- **Databases**: Do required DB files exist?
- **Services**: Are required services running? (e.g., `curl` health endpoints)

### 3. Smoke Test (optional)
Run the project's main entry point with a `--force` flag if available to exercise all adapters end-to-end.

## Output Format

```
Adapter Status | <YYYYMMDD-HHMMZ>
═════════════════════════════════

| # | Adapter | Wired | Deps OK | Status |
|---|---------|-------|---------|--------|
| 1 | GitHub Events | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 2 | Google Calendar | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 3 | Linear | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 4 | Cost Tracker | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 5 | Priorities | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 6 | Agent Health | Y/N | Y/N | LIVE/DEGRADED/DOWN |
| 7 | Signal Delivery | Y/N | Y/N | LIVE/DEGRADED/DOWN |

Summary: X/7 LIVE, Y/7 DEGRADED, Z/7 DOWN
```

Status definitions:
- **LIVE**: Wired in code AND runtime deps available
- **DEGRADED**: Wired in code BUT runtime deps missing/failing
- **DOWN**: Not wired in code

## Constraints

- This is a READ-ONLY diagnostic. Do not modify any files.
- Do not fabricate adapter status -- check the actual code and deps.
- If smoke test is run, report its output verbatim.
