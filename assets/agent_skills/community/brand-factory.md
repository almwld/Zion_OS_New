---
name: brand-factory
description: Generate novel brand name candidates from etymological roots, verify domain availability via RDAP, screen trademarks, and rank by ownability. Domain-first, not word-first.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[--brief <path>] [--use-case <text>] [--archetype <type>] [--max-candidates N]"
category: dev-tools
status: candidate
providers:
  required: [python]
  pip: [metaphone]
---

# Brand Factory

A production micro-unit that repeatably generates, verifies, and ranks novel
brand name candidates. Novel words are constructed from etymological root
combinations (Greek, Latin, PIE) using Base120 cognitive operators — not
scanned from dictionaries. Domain availability is checked first via RDAP,
because every dictionary word's .com is squatted.

## When to Use

- Need a brand name for a new product, project, or subsidiary
- Want candidates with .com actually available (not just "probably available")
- Building a portfolio of ownable names across archetypes
- The dictionary-scanning approach has failed (it will — 0% .com hit rate)

## When NOT to Use

- You already have a name and just need domain registration → register directly
- You need a name in a non-classical language family (this skill targets Greek/Latin/PIE roots)
- You need immediate results (a full run takes 8-15 minutes due to RDAP rate limiting)

## Contracts

These are machine-checkable invariants. Violations are bugs.

| ID | Contract | Enforcement |
|----|----------|-------------|
| bf-001 | RDAP only, never whois | Script uses `curl rdap.org`, never `whois` |
| bf-002 | Sequential checks with 2s delay | `sleep 2` between every RDAP call |
| bf-003 | UNCERTAIN ≠ AVAILABLE | Failed checks after 3 retries marked UNCERTAIN, never AVAILABLE |
| bf-004 | Etymological provenance per root | Every candidate carries source language, root, meaning, source URL |
| bf-005 | Dictionary filter | Reject any candidate that exists in Wiktionary or local dictionary |
| bf-006 | TESS gate | Factory TM CLEAR is preliminary — operator must verify on TESS before filing |

## Pipeline

```
Input (brand brief)
    │
    ▼
Phase 1: Etymological Gathering
    │  Query Wiktionary/Perseus for roots matching use-case semantics
    │  Tag each root with provenance (source, URL, language, meaning)
    │
    ▼
Phase 2: Combinatorial Generation
    │  Apply Base120 operators to combine roots into novel words
    │  CO4: cross-language synthesis (Greek root + Latin suffix)
    │  DE2: morpheme factorization (stem + affix recombination)
    │  IN5: negative-space framing (which valid combinations don't exist?)
    │  RE5: fractal reasoning (apply productive suffix patterns across stems)
    │  SY5: systems archetypes (recognize morphological patterns across languages)
    │  P1: first-principles (reduce to phonotactic constraints, fill valid gaps)
    │
    ▼
Filter: Novelty (dictionary check)
    │  Reject if word exists in any dictionary (Wiktionary, /usr/share/dict/words)
    │  This is the opposite of the old approach — we want words that DON'T exist
    │
    ▼
Filter: Radio Test
    │  PASS: unambiguous spelling after hearing
    │  SOFT: most people could spell it, some hesitation
    │  FAIL: significant misspelling risk (excluded)
    │
    ▼
Filter: Semantic/Cultural Check
    │  Reject words with negative secondary meanings
    │  Reject profanity/false friends in modern languages
    │  Flag sacred/religious terms for manual review
    │
    ▼
Phase 3: Domain Verification (RDAP, sequential, 2s delay)
    │  Check .com first (hardest constraint — if taken, demote)
    │  Then .io, .ai, .dev, .org, .net
    │  404 = AVAILABLE, 200 = TAKEN, failed = UNCERTAIN
    │  Log every check to verification-log.jsonl
    │
    ▼
Phase 4: Trademark Screening
    │  Web search USPTO aggregators for Cl.9 + Cl.42
    │  CLEAR / CAUTION / BLOCKED
    │  Not a substitute for TESS verification (contract bf-006)
    │
    ▼
Phase 5: Scoring & Ranking
    │  score = (domain × 0.35) + (tm × 0.25) + (radio × 0.15)
    │        + (etymology × 0.15) + (phonetic × 0.10)
    │  .com available adds bonus; .com taken caps score at 30
    │
    ▼
Output: ranked markdown table + verification log + provenance per candidate
```

## Input

### Brand Brief (YAML or CLI args)

```yaml
use_case: "Append-only audit layer for AI agent receipts"
archetype: intellectual  # operational | intellectual | premium | mysterious | systems | niche
target_tlds: [com, io, ai, dev, org, net]
tm_classes: [9, 42]
source_languages: [greek, latin, proto_indo_european]
max_syllables: 4
min_syllables: 2
avoid_semantics: ["death", "poison", "war"]
generation_count: 50
verify_count: 20
output_count: 10
```

### Archetypes

| Archetype | Sonic Profile | Use Cases | Primary Operators |
|-----------|--------------|-----------|-------------------|
| operational | 1-2 syllables, punchy | dev tools, CLIs, runtimes | CO15, DE2, RE9 |
| intellectual | 2-4 syllables, classical | research, governance, consulting | CO4, DE10, P17 |
| premium | smooth, elegant | design tools, creative platforms | CO13, SY5, P1 |
| mysterious | unusual, enigmatic | media, publishing, content | IN5, IN3, DE6 |
| systems | structural, connective | platforms, frameworks, backbones | CO11, DE17, SY1 |
| niche | context-dependent | security, privacy, defense | IN10, IN12, P17 |

## Execution

### Quick run (CLI args)

```bash
# Generate candidates for a governance product
python scripts/brand-factory.py \
  --use-case "AI agent governance enforcement layer" \
  --archetype intellectual \
  --source-languages greek,latin \
  --generation-count 30 \
  --verify-count 15 \
  --output-count 5

# Full run from brief file
python scripts/brand-factory.py --brief brand-brief.yaml
```

### What the scripts do

1. `scripts/rdap-check.py` — Standalone RDAP domain checker. Takes a word list, checks .com/.io/.ai/.dev/.org/.net sequentially with 2s delays. Outputs JSONL verification log + summary table. Can be used independently.

2. `scripts/brand-factory.py` — Main orchestrator. Runs the full pipeline from generation through ranking. Calls rdap-check.py for domain verification.

### Output Files

All output goes to the current working directory (or `--output-dir`):

- `brand-candidates.md` — ranked markdown table with all verified candidates
- `verification-log.jsonl` — append-only log of every RDAP check
- `etymology-roots.json` — gathered roots with provenance (for audit)
- `rejected-candidates.md` — candidates that failed filters, with reasons

## Key Findings from Validation Run (2026-09-03)

- 71 novel root-combination words checked via RDAP
- 19 had .com available (27% hit rate vs 0% for dictionary words)
- All 19 .com-available candidates also had .io and .ai available
- Greek roots + novel suffixes (-tia, -mia, -asis, -eth, -neia) = highest availability
- Greek root + -ion = 100% squatted; Latin root + -ia = 100% squatted; hybrids (-ova, -via) = 100% squatted
- The escape hatch: use suffixes that are valid Greek morphology but not commonly used in English

## Failure Modes (learned from the whois disaster)

1. **Whois false positives** → prevented by bf-001 (RDAP only)
2. **Rate-limit false positives** → prevented by bf-002 (sequential, 2s delay)
3. **Uncertainty treated as availability** → prevented by bf-003 (UNCERTAIN ≠ AVAILABLE)
4. **Semantic traps** → prevented by semantic/cultural filter + IN10 red-team check
5. **Etymological fabrication** → prevented by bf-004 (provenance per root)
6. **Accidental dictionary words** → prevented by bf-005 (dictionary filter)
7. **TM false negatives** → mitigated by bf-006 (TESS gate — factory CLEAR ≠ filing decision)

## Cost

- ~50K-100K tokens per run (generation + analysis)
- ~8-15 minutes (dominated by RDAP rate limiting — 120 checks × 2s = 4 min minimum)
- $0 API cost (Wiktionary, Perseus, RDAP are all free)
- ~$1,045-1,260 per brand first year (domains + DBA + TM filing)

## Composition

- **Before**: `seed-search` to identify gaps in current brand portfolio
- **After**: Operator reviews candidates, verifies on TESS, registers domains
- **Standalone**: `scripts/rdap-check.py` can be used independently to check any word list

## Version History

### v0.1.0 — 2026-09-03
- Initial implementation
- RDAP-based domain verification (replaces whois)
- Base120 operator-driven generation (P/IN/CO/DE/RE/SY families)
- 6 machine-checkable contracts (bf-001 through bf-006)
- Validated by Lane A canary: 19/71 candidates with .com available
- Design doc: ~/work/brand-factory-design-lane-b.md (1429 lines)
- Discovery results: ~/work/brand-discovery-lane-a.md (205 lines)
