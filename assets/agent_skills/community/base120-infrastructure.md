---
name: base120-infrastructure
description: Infrastructure for adding --base120 cognitive structuring to skill scripts at fleet scale. Provides a self-contained mixin, a migration script for existing skills, and a code generator for complex skills. Use when adding Base120 to a new skill, migrating existing skills, or generating custom Base120 report functions.
version: 0.1.0
execution-mode: advisory
argument-hint: '[--mixin | --migrate | --generate]'
triggers:
  - base120 infrastructure
  - add base120 to skill
  - base120 mixin
  - base120 migration
  - base120 generator
  - scale base120
  - base120 at scale
chains:
  - skill-creator
  - skill-audit
  - base120
base120:
  - P6: Point-of-View Anchoring
  - CO8: Layered Abstraction
  - DE3: Modularization
  - RE17: Versioning & Diff
  - SY10: Causal Loop Diagrams
export-targets:
  - claude-code
  - codex
status: candidate
category: fleet-ops
providers:
  required: [python]
---

# Base120 Infrastructure

Infrastructure for adding `--base120` cognitive structuring to skill scripts at fleet scale (1000+ skills).

## Why This Exists

The `--base120` flag was first added to 7 skills (bus-forensics, session-forensics, git-forensics, skill-audit, contract-drift, fleet-skill-health/drift, fleet-skill-health/smoke) by hand. That doesn't scale to 1000 skills. This skill provides three tools that make `--base120` a standard capability:

1. **Mixin** — self-contained, copy-pasteable module for new skills
2. **Migration script** — patches existing skills automatically
3. **Code generator** — generates custom Base120 functions for complex skills

## Components

### 1. base120_mixin.py — The Mixin (for new skills)

A self-contained, stdlib-only Python module that provides:
- `Base120Formatter` class — handles headers, sections, findings, footer
- `add_base120_arg(parser)` — adds the `--base120` flag to any argparse parser
- `fix_stdio()` — fixes Windows cp1252 encoding issues
- `BASE120_CODES` — operator code catalog, loaded from the canonical 120-entry registry
- `load_registry()` — runtime registry resolution with fallback chain
- `REGISTRY_SOURCE` / `REGISTRY_COUNT` — provenance metadata for audit

**Registry resolution order** (first available wins):
1. `BASE120_REGISTRY_PATH` env var (explicit override)
2. Bundled `registry/base120_registry.json` in the skill directory (self-contained)
3. `~/Projects/hummbl-governance/.../cognition/data/base120_registry.json` (retired — the hummbl-governance repo is archived and this path does not resolve; verified missing on agent-node 2026-09-20. Left in the chain only so the loader falls through.)
4. `~/Projects/base120/Base120_Canonical_Model_Registry.yaml` (base120 repo YAML; untracked, host-local. Its 120 model ids were verified identical to the bundled JSON on 2026-09-20.)
5. Hardcoded 27-entry fallback subset (never leaves you stranded)

Step 2 is the only source that exists in CI and on a fresh checkout, so it is the
authority for conformance purposes: `tests/test_base120_registry_conformance.py`
binds every Base120 code and model name in this family to it. Steps 3–5 are
host-local or degraded and must never be treated as canonical.

**Design principle**: The mixin is intentionally self-contained (no imports from other skill modules). It is designed to be COPIED into a skill's `scripts/` directory. This preserves the fleet's standalone skill principle.

**Usage** (3 steps):
```python
# 1. Copy into your skill's scripts/ dir
# 2. Import and add the flag
from base120_mixin import Base120Formatter, add_base120_arg, fix_stdio
fix_stdio()

parser = argparse.ArgumentParser(...)
add_base120_arg(parser)

# 3. Use in output
if args.json:
    print_json(...)
elif args.base120:
    fmt = Base120Formatter("Your Skill")
    fmt.header()
    fmt.section("Overview", "P6")
    fmt.metric("Count", 42)
    fmt.finding("Missing eval", "CRIT",
        why="...", reveals="...", action="...", code="DE1")
    fmt.footer()
else:
    print_report(...)
```

### 2. base120_migrate.py — The Migration Script (for existing skills)

Scans skill roots for Python scripts with argparse and human-readable output, then patches them automatically:
- Copies `base120_mixin.py` into the skill's `scripts/` directory
- Adds the import and `fix_stdio()` call
- Adds `add_base120_arg(parser)` to the argparse setup
- Inserts an `elif args.base120:` output branch
- Conservative: skips eval suites, test scripts, and scripts that already have `--base120`

```bash
# Dry-run (report only)
python base120_migrate.py

# Apply changes
python base120_migrate.py --apply

# Target a single skill
python base120_migrate.py --skill stash-audit
```

### 3. base120_generate.py — The Code Generator (for complex skills)

For skills whose output structure is too complex for the simple mixin pattern:
- Analyzes the target script's output functions, sections, metrics, and findings
- Maps section names to appropriate Base120 codes using heuristic matching
- Generates a custom `print_base120_report()` function with cognitive structuring
- Inserts the function and wires it into the output chain

```bash
# Review generated code
python base120_generate.py --script ~/.agents/skills/my-skill/scripts/my_script.py

# Apply to the script
python base120_generate.py --script ~/.agents/skills/my-skill/scripts/my_script.py --apply
```

### 4. base120_recommend.py — The Code Recommender (for skill authors)

A keyword-based heuristic that suggests which Base120 operator codes to use for each section of a skill's output. Not LLM reasoning — just keyword matching against operator definitions.

```bash
# Analyze a skill script's print statements:
python base120_recommend.py --script ~/.agents/skills/skill-audit/skill_audit.py

# Analyze a text snippet directly:
python base120_recommend.py --text "Overview: 5 skills. Findings: 3 missing evals. Recommendations: create evals."

# Output as JSON for programmatic consumption:
python base120_recommend.py --text "..." --json
```

The recommender maps section titles to Base120 families using keyword overlap:
- "overview|summary|status|context" → P-family (Perspective)
- "findings|issues|errors|gaps|missing" → DE-family (Decomposition)
- "recommendations|actions|next steps|fixes" → CO-family (Composition)
- "risks|threats|worst-case|security|vulnerabilities" → IN-family (Inversion)
- "evidence|receipts|audit|provenance|trace" → RE-family (Recursion)
- "trends|patterns|feedback|loops|system|lifecycle" → SY-family (Systems)

Within each family, operators are ranked by keyword overlap with their definitions.

### 5. krineia_mixin.py — The Krineia Receipt Footer (composes with --base120)

A self-contained, stdlib-only module that renders the MTSMU receipt footer defined by the `basen` skill. It standardizes trust-root separation, falsifiability anchors, verify-method tags, and epistemic stance declarations.

**What it renders:**
- `Reasoned-by:` — identity of the agent/session that produced the analysis
- `Observed-agent:` — identity of the system being analyzed (MUST ≠ reasoned_by)
- `Falsifiability anchor:` — ONE observable that would invalidate the primary recommendation
- `Stance:` — epistemic stance (descriptive/prescriptive/strategic/negotiative)
- `Verify-method default:` — default verify-method for findings (verify-after/cross-check/empirical/unverified)
- `Source:` — verification source label

**What it does NOT do:**
- Cryptographic signing (that's the krineia-watcher daemon's job)
- Hash-chain linkage (that's the krineia-watcher daemon's job)
- Epistemic reasoning (that's the `basen` skill's job)

**Trust-root separation enforcement:** The `check_separation()` method raises `KrineiaSeparationError` if `reasoned_by == observed_agent` (Krineia §3.2). The agent who reasons must not be the agent whose state is observed.

**Usage** (composes with `--base120`):
```python
from krineia_mixin import KrineiaReceipt, add_krineia_arg

# In argparse setup:
add_krineia_arg(parser)  # adds --krineia flag

# In output section (after fmt.footer()):
if args.base120 and args.krineia:
    receipt = KrineiaReceipt(
        reasoned_by="devin session=abc123",
        observed_agent="skill-audit (the system being audited)",
        falsifiability_anchor="re-run on clean fleet -> CRIT count = 0",
        stance="descriptive",
        source="verified via canonical registry",
    )
    receipt.render()  # prints the Krineia receipt footer
```

**Composition architecture:**
```
python skill_audit.py --base120 --krineia
                     │         │
                     │         └── prints Krineia receipt footer after Base120 footer
                     └── prints Base120 cognitive structuring (codes, Why/Reveals/Action)
```

The `Base120Formatter.finding()` method also accepts optional `verify_method` and `uncertainty` parameters when `--krineia` is active, adding per-finding rigor tags.

### 6. mtsmu_mixin.py — The MTSMU Rigor Summary (composes with --base120 --krineia)

A self-contained, stdlib-only module that tracks verify-methods and uncertainty levels across findings, then renders a summary footer showing the aggregate rigor profile.

**What it renders:**
- `Findings tracked:` — total number of findings with rigor data
- `Verify-methods:` — count and percentage for each method (verify-after, cross-check, empirical, unverified)
- `Uncertainty levels:` — count and percentage for each level (low, medium, high, unknown)
- `Verifiable: X/N (P%) — RIGOR ASSESSMENT` — overall rigor classification (HIGH/MODERATE/LOW/INSUFFICIENT)

**Rigor thresholds:**
- HIGH RIGOR: >= 75% verifiable
- MODERATE RIGOR: >= 50% verifiable
- LOW RIGOR: >= 25% verifiable
- INSUFFICIENT RIGOR: < 25% verifiable

**Usage** (composes with `--base120 --krineia`):
```python
from mtsmu_mixin import MtsmuSummary, add_mtsmu_arg

add_mtsmu_arg(parser)  # adds --mtsmu flag

# In output section (after fmt.footer(), before Krineia receipt):
if args.base120 and args.mtsmu:
    summary = MtsmuSummary()
    # ... after each fmt.finding() call:
    summary.track("verify-after", "medium -- no baseline")
    # ... after fmt.footer():
    summary.render()  # prints MTSMU rigor summary
```

### 7. aar_mixin.py — The After Action Report Format (canonical 7-section spec)

A self-contained, stdlib-only module that formats output as a structured After Action Report following the canonical 7-section spec with Base120 code mapping, evidence receipts, and bus integration footer.

**Canonical 7 sections (each with Base120 code):**
1. `## 1. Mission & Intent (P6: Point-of-View Anchoring)` -- objective, success criteria, constraints
2. `## 2. Chronology (RE17: Versioning & Diff)` -- timestamped events table
3. `## 3. Outcome vs Plan (IN17: Counterfactual Negation)` -- planned vs actual vs delta
4. `## 4. Root Causes (DE1: Root Cause Analysis)` -- 5-Whys style deviation analysis
5. `## 5. Sustains (RE16: Retrospective -> Prospective Loop)` -- what worked, with evidence
6. `## 6. Improves (IN20: Antigoals & Anti-Patterns Catalog)` -- what failed, with evidence
7. `## 7. Recommendations (DE7: Pareto Decomposition)` -- prioritized HIGH/MED/LOW actions

**Footer:**
- `Base120 Applied:` -- comma-separated codes actually used
- `Evidence:` -- artifact paths, commit ranges, or [none]
- `Bus: Y/N` -- whether a SITREP was posted to the coordination bus

**Bus integration:** AARs with Improves >0 or Recommendations >0 MUST post a SITREP to the bus. The mixin tracks whether posting was done via `set_bus(posted=True/False)` and renders the `Bus: Y/N` footer. Actual bus posting is the caller's responsibility.

**Usage** (standalone or composes with `--krineia`):
```python
from aar_mixin import AarFormatter, add_aar_arg

add_aar_arg(parser)  # adds --aar flag

# In output section:
if args.aar:
    aar = AarFormatter("skill-name", author="devin", classification="INTERNAL")
    aar.set_mission(
        objective="What we set out to do",
        success_criteria="How we would know it worked",
        constraints="Time, scope, resource limits",
    )
    aar.chronology_entry("2026-01-01 00:00Z", "Action", "Result")
    aar.set_outcome(planned="...", actual="...", delta="...")
    aar.root_cause("Deviation", ["Why 1: surface", "Why 2: deeper"])
    aar.sustain("What worked", "evidence: receipt")
    aar.improve("What failed", "evidence: receipt")
    aar.recommendation("HIGH", "Action to take", "addresses: which improve")
    aar.set_evidence(["commit-abc", "test-output.log"])
    aar.set_bus(posted=True)
    aar.render()
```

### 8. hrsi_mixin.py — The HRSI Check-In Format

A self-contained, stdlib-only module that formats output as a standardized HRSI (Human Relational System Index) check-in report, capturing the three belonging dimensions (safety, mattering, connection), cognitive state, somatic data, HULE, and relational notes.

**What it renders:**
- `Cogstate:` — cognitive state (AVAILABLE/DEPLETED/HYPERFOCUS/RECOVERY/RSD_RISK/SHUTDOWN/TRANSITION)
- `Safety: X/5` — safety baseline (1=threatened, 5=secure)
- `Mattering: X/5` — mattering baseline (1=absent, 5=thriving)
- `Connection: X/5` — connection baseline (1=isolated, 5=deeply connected)
- `Energy: X/5 (somatic)` — energy level
- `Sleep: Xh` — hours of sleep
- `HULE: "..."` — Human Unique Lived Experience moment
- `Relational: "..."` — relational connection note
- Optional: days logged, 7-day averages, trend
- Chain recommendation: `[dream]` if RECOVERY/TRANSITION cogstate

**Usage** (standalone or composes with `--krineia`):
```python
from hrsi_mixin import HrsiCheckin, add_hrsi_arg

add_hrsi_arg(parser)  # adds --hrsi flag

# In output section:
if args.hrsi:
    checkin = HrsiCheckin()
    checkin.header()
    checkin.cogstate("AVAILABLE")
    checkin.baseline(safety=4, mattering=3, connection=4)
    checkin.somatic(energy=3, sleep_hours=7.5)
    checkin.hule("Felt calm during review")
    checkin.relational_note("Coffee with Dan")
    checkin.render(days_logged=42, averages={"S": 4.0, "M": 3.5, "C": 4.0, "E": 3.2})
```

## Workflow

### For a NEW skill (use the mixin)
1. Create the skill using `skill-creator`
2. Copy `base120_mixin.py` into the skill's `scripts/` directory
3. Import and use `Base120Formatter` in the script
4. Test with `--base120` flag

### For an EXISTING skill (use migration)
1. Run `base120_migrate.py` in dry-run mode to see candidates
2. Review the candidates list
3. Run `base120_migrate.py --apply` to patch them
4. Test each patched skill with `--base120`
5. Fill in the TODO sections in the generated output branch

### For a COMPLEX skill (use the generator)
1. Run `base120_generate.py --script <path>` to analyze and generate
2. Review the generated `print_base120_report()` function
3. Run `base120_generate.py --script <path> --apply` to insert it
4. Customize the generated function with skill-specific Why/Reveals/Action analysis
5. Test with `--base120` flag

## When to Use Each Tool

| Situation | Tool | Why |
|-----------|------|-----|
| New skill with simple output | Mixin | Copy-paste, 3-step integration |
| Batch-migrating existing skills | Migration script | Automated, conservative, dry-run support |
| Complex skill with many sections | Code generator | Analyzes structure, generates custom function |
| Skill with no script (advisory only) | None | `--base120` only applies to scripted skills |

## Separation from `basen` skill

`--base120` and `basen` are different abstraction layers. Don't merge them.

| Layer | What it does | Where it lives |
|-------|-------------|----------------|
| **Rendering** | Format output as structured text with codes, Why/Reveals/Action, footer | `--base120` flag (this skill) |
| **Recommendation** | Suggest which codes to use based on section keywords | `base120_recommend.py` (this skill) |
| **Reasoning** | Epistemic stance detection, trust-root separation, falsifiability anchoring, verify-method tagging | `basen` skill |

### What `--base120` does (rendering layer)
- Formats output with `Base120Formatter` — headers, sections, findings, footer
- Tracks applied codes and prints `Base120 Applied:` footer
- Loads operator names from the canonical 120-entry registry
- Registry-backed: all 120 codes available, not just a hardcoded subset

### What `base120_recommend.py` does (recommendation layer)
- Keyword heuristic: maps section titles to Base120 families
- Ranks operators within each family by keyword overlap with definitions
- Helps skill authors pick codes without memorizing the full 120-entry catalog
- Does NOT do epistemic reasoning — just keyword matching

### What `basen` skill does (reasoning layer)
- `[basen] apply "problem"` — stance-gated operator application with 6Q pre-flight
- `[basen] recommend "question"` — epistemic operator recommendation
- Trust-root separation (Krineia §3.2): the reasoner must not be the observed agent
- Falsifiability anchoring: every recommendation has ONE observable that would invalidate it
- Verify-method tagging: verify-after / cross-check / empirical / unverified
- Epistemic stance detection: descriptive / prescriptive / strategic / negotiative

### Intended workflow
```
[basen] apply "problem"  →  get stance-gated operator selection
                           ↓
--base120 flag           →  render the analysis as structured text
```

The `basen` skill selects the right operators with epistemic rigor. The `--base120` flag renders the output. `base120_recommend.py` is a quick heuristic for skill authors who don't need the full reasoning layer.

## Constraints

- `--base120` only applies to skills with Python scripts that produce human-readable output
- Advisory-only skills (SKILL.md with no script) do not need `--base120`
- `--json` always takes precedence over `--base120` (the script's output chain controls this)
- The mixin is stdlib-only — no third-party dependencies
- The migration script is conservative — it skips eval suites, test scripts, and scripts that already have `--base120`

## Evidence

- [x] Mixin self-test — `python base120_mixin.py` runs a built-in self-test (120 operators from bundled registry)
- [x] Krineia mixin self-test — `python krineia_mixin.py` runs a built-in self-test (separation check, validation, rendering)
- [x] MTSMU mixin self-test — `python mtsmu_mixin.py` runs a built-in self-test (tracking, rendering, normalization)
- [x] AAR mixin self-test — `python aar_mixin.py` runs a built-in self-test (7-section canonical format, Base120 codes, evidence, bus footer)
- [x] HRSI mixin self-test — `python hrsi_mixin.py` runs a built-in self-test (cogstate, baseline, somatic, validation)
- [x] Migration dry-run — `python base120_migrate.py` reports candidates without changes
- [x] Code generator review — `python base120_generate.py --script <path>` prints for review
- [x] Recommender — `python base120_recommend.py --script <path>` suggests codes for real skill scripts
- [x] 22 recommender tests pass — family matching, section extraction, operator ranking, rendering
- [x] 18 krineia mixin tests pass — construction, separation, rendering, to_dict, argparse
- [x] 7 skills already have `--base120` (forensic triangle + audit/health) — proof of concept
- [x] 70/70 tests passed across all 7 existing `--base120` skills
- [x] hummbl-eval integration — 125 tests pass, 95% coverage, registry-backed with 120 operators
- [x] Full flag composition: `--base120 --mtsmu --krineia` verified (Base120 -> MTSMU -> Krineia order)
- [x] `--aar` and `--hrsi` standalone modes verified (each renders independently, composes with `--krineia`)
