---
name: governance-audit
description: Audit governance bus integrity -- format, fields, timeline, retention.
version: 0.1.0
execution-mode: advisory
argument-hint: "[full | recent N | integrity]"
category: governance-compliance
status: candidate
---
## Context Gathering

Before executing this skill, gather the following context:
- **Governance files**: Run `ls $PROJECT_ROOT/_state/governance/governance-*.jsonl 2>/dev/null | wc -l || echo "0"`

# Governance Audit Command

Validate the integrity of the governance JSONL audit log.

## Usage

```bash
[governance-audit]     # Full audit of all governance files
```

## Execution

### 1. List governance files
```bash
ls -lt $PROJECT_ROOT/_state/governance/governance-*.jsonl
```

### 2. JSONL format validation
For each file, verify every line is valid JSON:
```bash
python3 -c "
import json, sys
errors = 0
for i, line in enumerate(open(sys.argv[1]), 1):
    try:
        json.loads(line)
    except json.JSONDecodeError as e:
        print(f'Line {i}: {e}')
        errors += 1
print(f'Total lines: {i}, Errors: {errors}')
" <file>
```

### 3. Required fields check
Each entry should have: `timestamp`, `tuple_type`, `agent_id` (at minimum).
```bash
python3 -c "
import json, sys
missing = []
for i, line in enumerate(open(sys.argv[1]), 1):
    d = json.loads(line)
    for field in ['timestamp', 'tuple_type']:
        if field not in d:
            missing.append(f'Line {i}: missing {field}')
for m in missing[:20]:
    print(m)
print(f'Missing fields: {len(missing)}')
" <file>
```

### 4. Tuple type distribution
Count entries by tuple_type.

### 5. Timeline analysis
Check for:
- Chronological ordering (timestamps should be monotonically increasing)
- Gaps > 4 hours during business hours
- Entries with future timestamps

### 6. Retention check
- Files older than 30 days should be archived
- Total size should be reasonable

## Output Format

```
Governance Audit | <YYYY-MM-DD HH:MMZ>
═══════════════════════════════════════

## Files
| File | Lines | Size | Date Range |
|------|-------|------|------------|
| governance-2026-02-24.jsonl | 150 | 45K | 00:00Z - 18:30Z |
| ... | ... | ... | ... |

## Integrity Checks
| Check | Result |
|-------|--------|
| JSONL format valid | PASS (0 errors) |
| Required fields present | PASS |
| Chronological ordering | PASS |
| No future timestamps | PASS |
| No gaps > 4h (business hours) | WARN (1 gap) |

## Tuple Type Distribution
| Type | Count | % |
|------|-------|---|
| DCTX | 45 | 30% |
| ... | ... | ... |

## Issues Found
<numbered list of any integrity issues>

## Retention
- Total files: N
- Total size: XMB
- Oldest file: YYYY-MM-DD
- Recommendation: <archive/retain/ok>
```

## Constraints

- READ-ONLY. Do not modify governance files.
- Governance logs are append-only -- never suggest editing existing entries.
- Report actual data only -- do not fabricate audit results.

## Skill Chains

### Mandatory

- None — governance-audit is `advisory` mode (read-only integrity check).

### Advisory

- **After audit**: `[governance-report]` (if issues found, include in periodic report)
- **For remediation**: `[remediation-plan]` (if integrity issues detected)
- **For compliance**: `[soc2-check]`, `[nist-map]` (map findings to frameworks)

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction (read-only audit)
- **T3 (Medium)**: May run without restriction (read-only audit)
- **T4 (Probationary)**: May run (read-only — no side effects)
- **Operator**: Override any restriction
