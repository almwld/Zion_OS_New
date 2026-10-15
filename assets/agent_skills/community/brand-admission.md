---
name: brand-admission
description: Brand-specific admission gate overlay that adds palette-token, visual-asset, and brand-guideline contracts to the generic capability lifecycle for any skill touching HUMMBL brand surfaces.
version: 0.1.0
execution-mode: advisory
argument-hint: '[skill-name] [--contracts] [--verify]'
triggers:
  - admit brand skill
  - brand-specific admission gate
  - verify brand skill contracts
  - palette-token compliance check
  - brand-guideline reference gate
chains:
  - hummbl-capability-lifecycle
  - skill-creator
  - skill-audit
  - admission-gate
  - brand
  - brand-guidelines
  - hummbl-branded-artifacts
base120:
  - base120-structure-005
  - base120-evidence-002
contracts: [{"id": "ba-001", "type": "CNT", "text": "MUST NOT admit a brand-touching skill whose color tokens deviate from the canonical palette defined in brand-guidelines (Grove #12633C, Verderer #1B7A3D, Verderer Light #34C26A) without an explicit brand-risk clearance receipt", "requirement_level": "MUST NOT", "tags": ["palette-token", "brand-compliance", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "canonical palette|Grove.*Verderer.*Verderer Light|brand-risk clearance", "target": "SKILL.md"}}, "line_ref": 38}, {"id": "ba-002", "type": "CNT", "text": "MUST NOT admit a brand-touching skill that generates or extends logos, bird-only marks, or identity systems without a current brand-risk clearance receipt referenced in the skill", "requirement_level": "MUST NOT", "tags": ["visual-asset", "logo-hold", "bird-mark", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "logos.*bird-only marks.*identity systems|brand-risk clearance receipt", "target": "SKILL.md"}}, "line_ref": 42}, {"id": "ba-003", "type": "CNT", "text": "MUST NOT admit a brand-touching skill that does not reference brand-guidelines as its canonical source of truth for palette, wordmark treatment, and asset conventions", "requirement_level": "MUST NOT", "tags": ["brand-guideline-reference", "canonical-source", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "brand-guidelines as its canonical source|canonical source of truth", "target": "SKILL.md"}}, "line_ref": 46}, {"id": "ba-004", "type": "BEH", "text": "SHOULD verify that any visual asset file referenced by the skill exists, is valid SVG or PNG, and matches canonical dimensions before admitting the skill", "requirement_level": "SHOULD", "tags": ["visual-asset-verification", "file-existence"], "machine_check": {"kind": "regex", "spec": {"pattern": "valid SVG or PNG|canonical dimensions", "target": "SKILL.md"}}, "line_ref": 50}, {"id": "ba-005", "type": "BEH", "text": "SHOULD run the brand audit mode against any sample output the skill produces before admission, to confirm zero unauthorised hex literals and font-family compliance", "requirement_level": "SHOULD", "tags": ["audit-mode", "hex-literal-check", "font-compliance"], "machine_check": {"kind": "regex", "spec": {"pattern": "brand audit mode|unauthorised hex literals|font-family compliance", "target": "SKILL.md"}}, "line_ref": 54}]
category: dev-tools
status: candidate
---

# Brand Admission

Brand-specific admission gate overlay. Adds machine-checkable brand contracts on top of the generic capability lifecycle so any skill that touches HUMMBL brand surfaces (palette, wordmark, logos, bird mark, brand assets, brand guidelines) is admitted only when it respects the canonical brand system.

This is an **overlay**, not a duplicate factory. The generic pipeline (discovery, authoring, governance, collision, redaction) is owned by `skills-factory`, `skill-creator`, `hummbl-capability-lifecycle`, `skill-collision-detect`, `admission-gate`, and `skill-audit`. This skill adds the brand-specific admission criteria that those generic skills do not encode.

## When to Use

- A new skill touches brand surfaces (palette tokens, wordmark, logos, bird mark, brand assets, brand guidelines, email signatures, one-pager, sales collateral).
- A skill-creator or skills-factory run produces a candidate skill whose scope intersects `hummbl-brand` or `hummbl-production/web` brand surfaces.
- A skill-audit run on a brand-touching skill needs the brand-specific contract checklist.
- The operator asks "does this skill respect the brand system?" before admitting it.

## Scope Boundary

This skill admits **skills**, not artifacts. Producing brand artifacts (rendering logos, generating one-pagers, exporting favicons) is owned by `hummbl-branded-artifacts` and `brand`. This skill gates whether a *new skill* may enter the registry when its scope intersects brand surfaces.

## Canonical Brand System (Source of Truth)

The canonical palette, wordmark treatment, and asset conventions live in `brand-guidelines`. This skill references them; it does not redefine them. As of this writing the canonical palette is:

| Token | Hex | Role |
|-------|-----|------|
| Grove | `#12633C` | Mark |
| Verderer | `#1B7A3D` | Accent |
| Verderer Light | `#34C26A` | Dark-mode accent |

If `brand-guidelines` updates these values, this skill's contracts still hold — they reference the canonical source, not hardcoded values. The hex values above are documented for the contract regex match only; the live source of truth is `brand-guidelines`.

## Workflow

1. **Determine brand-touch.** Read the candidate skill's `description`, `triggers`, `chains`, and any referenced surfaces. If none intersect brand surfaces (palette, wordmark, logos, bird mark, brand assets, brand guidelines, email signatures, one-pager, sales collateral), this skill does not apply — return control to the generic lifecycle.
2. **Run the generic lifecycle first.** Invoke `hummbl-capability-lifecycle` for trust verification, collision check, least privilege, no-credentials, and authority gate. This overlay assumes those have passed.
3. **Check palette-token contract (ba-001).** Scan the candidate skill for any hardcoded color tokens. If present, they MUST match the canonical palette in `brand-guidelines`. Any deviation requires an explicit brand-risk clearance receipt referenced in the skill body.
4. **Check visual-asset hold (ba-002).** If the skill generates or extends logos, bird-only marks, or identity systems, it MUST reference a current brand-risk clearance receipt. The bird-mark hold is non-negotiable; without clearance, the skill is not admitted.
5. **Check brand-guideline reference (ba-003).** The skill MUST reference `brand-guidelines` as its canonical source for palette, wordmark treatment, and asset conventions. A brand-touching skill that does not point at the source of truth is not admitted.
6. **Verify visual assets (ba-004, SHOULD).** If the skill references visual asset files, verify each exists, is valid SVG or PNG, and matches the canonical dimensions recorded in `hummbl-brand/exports/`.
7. **Run brand audit on sample output (ba-005, SHOULD).** If the skill produces sample output, run the `brand` audit mode against it. Confirm zero unauthorised hex literals and font-family compliance before admitting.
8. **Record the verdict.** Post a receipt to the bus with the contract checklist results. If any MUST NOT contract fails, the skill is not admitted — return to `skill-creator` for revision. If only SHOULD contracts fail, flag for follow-up but admit.

### Edge cases

- **Skill touches brand surfaces indirectly** (e.g., a CI workflow skill that runs `validate_brand_assets.py`): apply ba-003 (must reference brand-guidelines as canonical source) but skip ba-001, ba-002, ba-004, ba-005 unless the skill itself emits colors or assets.
- **Skill is a pointer stub** (like `hummbl-capability-lifecycle` itself): apply only ba-003 if the stub references brand surfaces; otherwise skip.
- **Brand-guidelines is updated mid-admission**: re-run ba-001 against the new canonical palette before admitting.
- **Operator overrides a failed MUST NOT**: record the override in the receipt with operator identity and timestamp. The override does not change the contract; it documents an exception.

## Constraints

- Do not redefine the canonical palette, wordmark treatment, or asset conventions — `brand-guidelines` owns those. This skill references them.
- Do not generate or extend logos, bird-only marks, or identity systems — that is `hummbl-branded-artifacts` scope. This skill only gates admission.
- Do not admit a brand-touching skill that fails ba-001, ba-002, or ba-003 without an explicit operator override recorded in the receipt.
- Do not duplicate the generic lifecycle — run it first, then layer these contracts on top.
- Do not invent new brand tokens. Any new color must come through `brand-guidelines` first, then through this gate.

## Examples

**Example 1: A new "brand-palette-lint" skill**

> Candidate skill lints consumer repos for unauthorised hex literals against the canonical palette. It references `brand-guidelines` as canonical source (ba-003 pass), does not generate logos (ba-002 n/a), does not hardcode colors outside the canonical palette (ba-001 pass), references no visual asset files (ba-004 n/a), and its sample output is a lint report with no colors (ba-005 pass). Admit.

**Example 2: A "logo-variant-generator" skill without clearance**

> Candidate skill proposes generating logo variants for dark-mode backgrounds. It touches logos (ba-002 applies) but references no brand-risk clearance receipt. ba-002 fails. Not admitted. Return to `skill-creator` with the requirement to obtain brand-risk clearance first.

**Example 3: A brand-touching skill with an invented color**

> Candidate skill hardcodes `#0A5C30` as a "darker Grove" for contrast adjustments. `#0A5C30` is not in the canonical palette and no brand-risk clearance receipt is referenced. ba-001 fails. Not admitted. The color must either come through `brand-guidelines` first or carry an explicit clearance receipt.

## Evidence

- [ ] Brand-touch determination recorded (which surfaces the candidate intersects)
- [ ] Generic lifecycle contracts (hcl-001 through hcl-005) passed first
- [ ] Palette-token contract (ba-001) result recorded with any hardcoded tokens listed
- [ ] Visual-asset hold (ba-002) result recorded with clearance receipt reference if applicable
- [ ] Brand-guideline reference (ba-003) confirmed in skill body
- [ ] Visual-asset verification (ba-004) result recorded if applicable
- [ ] Brand audit on sample output (ba-005) result recorded if applicable
- [ ] Admission verdict and any operator overrides posted to bus

## Contracts

5 load-bearing contracts declared in frontmatter. Summary:

| ID | Type | Level | What it protects |
|----|------|-------|------------------|
| ba-001 | CNT | MUST NOT | Palette-token deviation from canonical brand-guidelines palette without clearance |
| ba-002 | CNT | MUST NOT | Logo/bird-mark/identity generation without current brand-risk clearance |
| ba-003 | CNT | MUST NOT | Brand-touching skill without brand-guidelines as canonical source reference |
| ba-004 | BEH | SHOULD | Visual asset file existence, format, and dimension verification |
| ba-005 | BEH | SHOULD | Brand audit mode run on sample output before admission |

All 5 are machine-checked via regex against this SKILL.md — drift detection fires if the load-bearing prose is removed.

## Related Skills

- `hummbl-capability-lifecycle` — generic governance contracts; run first
- `skill-creator` — authoring pipeline
- `skill-audit` — security and epistemic audit
- `admission-gate` — redaction gate for external publishing
- `brand` — brand guidelines reference and file audit mode
- `brand-guidelines` — canonical palette, wordmark treatment, asset conventions
- `hummbl-branded-artifacts` — artifact production with brand-risk clearance constraints
