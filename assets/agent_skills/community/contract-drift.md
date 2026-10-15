---
name: contract-drift
description: Detect drift in structured contracts from SKILL.md frontmatter against a frozen baseline; validate machine_check contracts
version: 1.0.0
status: approved
execution-mode: advisory
argument-hint: "{freeze|check|validate|diff|report} [--root DIR] [--baseline FILE] [--skill NAME] [--json]"
triggers:
  - contract drift
  - skill contracts changed
  - baseline freeze
  - contract validation
  - machine check
chains:
  - to: skill-audit
    type: advisory
    note: contract-drift check output feeds skill-audit's contract coverage check
  - to: fleet-skill-health
    type: advisory
    note: monthly fleet health audit uses contract-drift report summary
  - from: skill-evolve
    type: advisory
    note: skill-evolve triggers contract-drift after skill modifications
schema_version: contract_drift_output.v1.0.0
category: skills-meta
providers:
  required: [python]
---
# Contract Drift Detector v1.0.0

> **status: approved (v1.0.0, 2026-08-10).** Path 4 successor to the deprecated
> v0.1.x regex extractor. Uses deterministic diff-based drift detection on
> structured `contracts` blocks in SKILL.md frontmatter (see
> `spec/schema.json` in hummbl-skills). No regex extraction, no LLM, no ambiguity.

## What This Tool Does

1. **freeze** — Snapshot all skills' contracts with content hashes as a baseline
2. **check** — Detect drift (added, removed, modified contracts) vs a frozen baseline
3. **validate** — Run `machine_check` validators (file_exists, regex, exit_code) against live state
4. **diff** — Diff two baseline JSON files (for comparing snapshots)
5. **report** — Fleet-wide contract summary (counts by type, level, machine_check coverage)

## Execution

### Freeze a baseline
```bash
python ~/.agents/skills/contract-drift/contract_drift_v1.py freeze
```

### Check for drift
```bash
python ~/.agents/skills/contract-drift/contract_drift_v1.py check
```

### Validate machine_check contracts
```bash
python ~/.agents/skills/contract-drift/contract_drift_v1.py validate
python ~/.agents/skills/contract-drift/contract_drift_v1.py validate --skill novelty-surge
```

### Diff two baseline files
```bash
python ~/.agents/skills/contract-drift/contract_drift_v1.py diff --baseline old.json --current new.json
```

### Fleet report
```bash
python ~/.agents/skills/contract-drift/contract_drift_v1.py report
```

## Drift Severity Model

| Severity | When | Exit code |
|----------|------|-----------|
| BLOCK | MUST/MUST NOT contract removed, or machine_check removed from a MUST/MUST NOT contract | 1 |
| WARN | Contract text, type, requirement_level, or machine_check modified | 0 |
| INFO | Contract added, line_ref changed, machine_check added | 0 |

Only BLOCK events cause a non-zero exit code, making this suitable as a CI gate
that fails on enforcement regressions but passes on additive changes.

## Contract Types (from spec/schema.json)

| Code | Type | Description |
|------|------|-------------|
| FMT | Format | Timestamp format, date format, ID pattern |
| FEX | File Existence | File/directory must exist at path |
| BEH | Behavior | Append-only, never delete, no pipes |
| CNT | Constraint | No secrets, no fabrication, redact values |
| SCH | Schema | Schema validation requirements |
| THR | Threshold | Timeout, size, age, version thresholds |
| EXT | External | External dependency requirements |
| DEP | Dependency | Stdlib-only, specific library requirements |

## Machine_check Validators (v1.0.0 implements)

| Kind | Implemented | Description |
|------|-------------|-------------|
| file_exists | Yes | Verifies file/directory exists at path |
| regex | Yes | Verifies pattern matches in target file |
| exit_code | Yes | Runs command and checks exit code |
| enum | Runtime | Requires runtime context (skipped) |
| threshold | Runtime | Requires runtime metric values (skipped) |
| custom | User-defined | Skipped (user provides validator) |

## Exit Codes

- 0: No BLOCK events (check/report), no validation failures (validate)
- 1: BLOCK events detected (check), validation failures (validate)
- 2: Baseline file not found (check), required args missing (diff)

## Constraints

- Stdlib-only (no third-party dependencies)
- Offline (no network calls, no API keys)
- Deterministic (same input produces same output; no clock in output)
- Single file (contract_drift_v1.py)
- Read-only: reads SKILL.md files and runs machine_check validators; no modifications

## Authority

Any agent tier may run this tool. It is read-only — reads contracts from
SKILL.md frontmatter and runs validators. Advisory-only (T1-T2).

## Skill Chains

| Direction | Skill | Type | Notes |
|-----------|-------|------|-------|
| Chains to | skill-audit | advisory | contract-drift output feeds skill-audit's contract coverage check |
| Chains to | fleet-skill-health | advisory | monthly fleet health audit uses contract-drift summary |
| Chains from | skill-evolve | advisory | skill-evolve triggers contract-drift after skill modifications |

## Evidence

- [x] Deterministic: identical output across repeated runs (verified)
- [x] Freeze → modify → check cycle tested: correctly detects added, removed, requirement_level-changed, type-changed, text-modified, machine_check-removed events
- [x] file_exists validator tested: correctly verifies file presence
- [x] exit_code validator tested: runs commands and checks exit codes
- [x] regex validator tested: checks patterns in target files
- [x] Severity model: BLOCK (MUST/MUST NOT removal, machine_check regression), WARN (modifications), INFO (additions)
- [x] Single-file, stdlib-only, offline, deterministic
- [x] UTF-8 output on Windows consoles (sys.stdout.reconfigure)
- [ ] Baseline frozen and committed (pending Step 4 bootstrap migration)
- [ ] CI integration (pending Step 5 phased enforcement)

## Version History

- 1.0.0 (2026-08-10): Path 4 successor. Deterministic diff-based drift detection on structured `contracts` blocks in SKILL.md frontmatter. Five subcommands: freeze, check, validate, diff, report. Implements file_exists, regex, exit_code validators. Severity model: BLOCK/WARN/INFO. Stdlib-only, offline, deterministic, single file. Replaces deprecated v0.1.x regex extractor.
- 0.1.3 (2026-08-10): DEPRECATED. Regex-based extraction approach does not generalize. Held-out recall 0.008-0.033 vs 0.70 target. Preserved as documented negative result. See v0.1.3 history in git log and `contract_drift.py` (legacy file preserved).
- 0.1.2 (2026-08-10): Held-out test on 15 unseen skills. Severe overfitting confirmed — 99% recall collapse.
- 0.1.1 (2026-08-10): Fixed eval methodology per auditor review. Honest metrics: P=0.721, R=0.845, F1=0.778.
- 0.1.0 (2026-08-10): Initial MVP — extractor + eval runner against H16 ground truth.

## Companion

- `contract_drift_v1.py` — v1.0.0 implementation (active)
- `contract_drift.py` — v0.1.x legacy implementation (preserved as negative result)
- `eval/` — eval framework and ground truth corpus (reusable assets from v0.1.x)

## Legacy v0.1.x Documentation

The v0.1.x regex extractor is preserved as a documented negative result. Key
findings from the multi-agent review (4 reviewers: planner, auditor, governance,
adversarial):

- **H16 held-in eval**: P=0.721, R=0.845, F1=0.778 (30 samples, 58 GT)
- **Held-out eval**: P=0.125, R=0.008-0.033 (auditor-corrected), F1=0.016-0.052 (15 samples, ~105-120 consensus GT)
- **Overfitting confirmed**: 96-99% recall collapse from held-in to held-out
- **Root cause**: Regex patterns tuned against H16 corpus do not generalize
- **Operator decision**: Path 3 (close as negative result) + Path 4 (structured contract authoring)
- **Methodology**: Jaccard 0.60, per-sample matching, no substring bypass (audited)
- **Kappa**: 0.630 (binned-count, n=21 due to annotator row-shift defect); item-level intersection/union = 56/120 = 0.467

The eval framework (`eval/`) and ground truth corpus are reusable assets. The
legacy `contract_drift.py` file is preserved but should not be invoked as a
working detector. Use `contract_drift_v1.py` instead.
