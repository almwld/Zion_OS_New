---
name: config-matrix
description: Systematically test configuration combinations -- env vars, feature flags, provider settings. Maps to CO15.
version: 0.1.0
execution-mode: advisory
argument-hint: <module or feature to test across configs>
category: backend-infra
status: candidate
---
# Config Matrix (CO15: Combinatorial Design)

Systematically explore configuration combinations to find broken states.

## When to Use
- Testing across Python versions (3.11, 3.12, 3.13, 3.14)
- Testing with/without BUS_SIGNING_SECRET
- Testing with/without ENABLE_IDP
- Testing different FOUNDER_PROFILE settings
- Testing with different OAuth states (valid, expired, missing)
- Testing bus policy modes (PERMISSIVE, WARN, STRICT)

## Execution

### 1. Identify the config dimensions
```
Dimension A: BUS_SIGNING_SECRET [set, unset]
Dimension B: BUS_SECURITY_POLICY [permissive, warn, strict]
Dimension C: ENABLE_IDP [true, false]
```

### 2. Generate the matrix
Full combinatorial: 2 x 3 x 2 = 12 combinations.
If too many, use pairwise coverage (every pair of values tested at least once).

### 3. Run tests per combination
```bash
for signing in "" "test-secret-32-bytes-minimum-length"; do
  for policy in "permissive" "warn" "strict"; do
    for idp in "" "true"; do
      echo "=== signing=${signing:+SET} policy=$policy idp=${idp:-unset} ==="
      BUS_SIGNING_SECRET="$signing" BUS_SECURITY_POLICY="$policy" ENABLE_IDP="$idp" \
        python -m pytest tests/unit/test_bus_writer.py -q --tb=line 2>&1 | tail -1
    done
  done
done
```

### 4. Report failures
| Config | Result | Notes |
|--------|--------|-------|
| signing=SET, policy=strict, idp=true | PASS | All features active |
| signing=UNSET, policy=strict, idp=false | FAIL | Strict requires signing |

## Output Format
```
Config Matrix | <target>
═══════════════════════════

## Dimensions
<list of config variables and their values>

## Matrix (N combinations)
| # | Dim A | Dim B | Dim C | Result |
|---|-------|-------|-------|--------|

## Failures
<details on which combinations fail and why>

## Recommendations
<config combinations that should be added to CI>
```

## Base120 Context
- Primary: **CO15** (Combinatorial Design)
- Related: **DE14** (Variable Control), **IN7** (Boundary Testing), **CO16** (Integration Testing)
