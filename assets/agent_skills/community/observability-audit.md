---
name: observability-audit
description: Audit logging, metrics, and alerting coverage across services.
version: 0.1.0
execution-mode: advisory
argument-hint: "<module or \"all\">"
category: dev-tools
status: candidate
---
# Observability Audit

Check that services are properly instrumented for monitoring, debugging, and alerting.

## Execution

### 1. Logging coverage
```bash
python3 -c "
from pathlib import Path
import ast

target = '${TARGET:-services}'
for f in sorted(Path(target).rglob('*.py')):
    if '.venv' in str(f) or '__pycache__' in str(f): continue
    try:
        source = f.read_text()
        tree = ast.parse(source)
        has_logger = 'logger' in source or 'logging' in source
        func_count = sum(1 for n in ast.walk(tree) if isinstance(n, ast.FunctionDef))
        log_calls = source.count('logger.') + source.count('logging.')
        if func_count > 3 and not has_logger:
            print(f'  NO LOGGING: {f} ({func_count} functions)')
        elif func_count > 0 and log_calls / max(func_count, 1) < 0.3:
            print(f'  LOW LOGGING: {f} ({log_calls} calls / {func_count} functions)')
    except: pass
"
```

### 2. Health probe coverage
Which services have health probes? Which don't?
```bash
source .venv/bin/activate
python -m your_project.services.health 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
for probe, result in d.get('probes', {}).items():
    status = result.get('status', '?')
    print(f'  {status:10s} {probe}')
" 2>/dev/null || echo "(health endpoint unavailable)"
```

### 3. Error handling audit
Cross-reference with `[try-except-audit]`:
- Which errors are logged but never alerted?
- Which errors silently return None?
- Which critical paths have no error handling?

### 4. Metric gaps
What should be measured but isn't?
- Request latency per adapter
- Bus write latency
- Ledger query performance
- OAuth token freshness
- Agent response time

### 5. Alert gaps
What failure conditions have no notification?
- Service goes down
- Bus file corruption
- Disk > 90%
- OAuth token expiry < 5 min
- Agent posts unauthorized message type

## Output Format
```
Observability Audit | <target>
═══════════════════════════════

## Logging Coverage
- Services with logging: N/M
- Services without logging: <list>
- Low-logging services: <list>

## Health Probes
- Active probes: N
- Missing probes: <list of services without probes>

## Metric Gaps
- <what should be measured but isn't>

## Alert Gaps
- <what failure has no notification>

## Recommendations
1. <highest priority instrumentation to add>
```

## Base120 Context
- Primary: **SY18** (Measurement & Telemetry)
- Related: **IN5** (Negative Space -- what's NOT being measured), **DE13** (FMEA)
