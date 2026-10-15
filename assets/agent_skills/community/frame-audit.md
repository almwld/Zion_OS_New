---
name: frame-audit
description: "Audit metaphor or framing choices before pitches, positioning, architecture narratives, category definitions, or naming decisions. Surfaces useful and dangerous frames."
version: 1.0.0
execution-mode: advisory
argument-hint: "<subject> (e.g., \"LLMs\", \"AI governance\", \"agents\", \"HUMMBL\", \"trust\")"
category: fleet-ops
status: candidate
---
# Frame Audit

Canonical form: `"<subject> is < >, so < > it."`

## When to invoke

- Before writing a pitch or positioning document
- Before committing to an architecture narrative
- Before defining a new product category
- Before naming anything load-bearing (adapter program, governance primitive, agent role)
- Any time you notice you're leaning on a single metaphor ("X is like Y") to explain a system

## What this skill does

1. **States the frame** — parse `$ARGUMENTS` as the subject. Template = `"<subject> is < >, so < > it."` (or `"<subject> are < >, so < > them."` for plural subjects).
2. **Dispatches a creative agent** with the divergence prompt (see `prompt_template.md`). Required output: 80+ matched pairs across 15+ axes with an explicitly-required **contrarian axis** (no exceptions).
3. **Applies the filter pair** — every pair is scored on: (a) unlocks new design space? (b) does *not* mislead a team that builds on it? Frames that pass both are keepers. Frames that pass only (a) are the most dangerous.
4. **Flags the danger set** — top 5 dangerous pairs with one-line rationale. Check if the user's default/starting frame is in this set.
5. **Surfaces the useful set** — top 5 pairs that unlock new design or product language.
6. **Writes the artifact** — save to `hummbl_governance/docs/research/YYYY-MM-DD_frame_audit_<slug>.md` with full pair corpus preserved.
7. **Returns a structured summary** — top 5 useful, top 5 dangerous, best single reframe, contrarian highlights, and the starting-frame danger check.

## Three permanent patterns (observed across runs)

1. **Starting frames are usually in the danger set.** LLMs→databases (danger), governance→CYA (danger), agents→employees (danger). Check the danger list *first*.
2. **Winning frames import mature vocabularies.** The useful frames borrow from disciplines with centuries of accountability: Bayesian stats (priors/update), principal-agent law (proxies/POA), guild cert (hallmark/strike), control theory (PID/tune), cell biology (membrane/apoptose).
3. **The contrarian axis is always generative, always required, never volunteered.** Demand it explicitly in the agent prompt. Without the demand, the agent tilts toward legitimating frames. With it, the sharpest critique emerges.

## Output format

```markdown
Frame Audit | <subject>

## Top 5 USEFUL
1. <subject> is <noun>, so <verb> it. — <why>
...

## Top 5 DANGEROUS
1. <subject> is <noun>, so <verb> it. — <why>
...

## Starting-frame check
Default frame: <what the user or team was already using>
Verdict: DANGER / SAFE / UNTESTED

## Contrarian highlights
<3-5 premise-undermining pairs>

## Best single reframe
<one pair with one-line rationale>

## Artifact
Written to: hummbl_governance/docs/research/YYYY-MM-DD_frame_audit_<slug>.md
```

## Method reference

Full method documentation and corpus from the v1.0 run:
- `hummbl_governance/docs/research/2026-04-16_frame_auditor.md` (tool + LLM corpus)
- `hummbl_governance/docs/research/2026-04-16_adjacent_framings_audit.md` (v1.1 refinements + cross-run synthesis)

## Invariants

- The contrarian axis is mandatory in every run. If the agent omits it, re-prompt.
- The filter pair (unlock × not-mislead) must be applied to every pair, not just the top ones.
- Flag the user's default/starting frame explicitly — if it's in the danger set, say so.
- Never collapse to a single "best" frame — always triangulate with 2–3 honest frames that illuminate different facets.
- Artifact goes to `hummbl_governance/docs/research/` (not repo root, not a Gemini branch).

## Composition

- **After this skill**: consider `[decision-log]` if a reframe changes a design decision, `[ledger]` if the finding generalizes, `[arcana-to-pitch]` if it unlocks HUMMBL pitch language.
- **Before this skill**: consider `[brainstorm]` if the subject itself needs exploration first.

## Cost

~$0.50 in API-equivalent per run. ~5 minutes wall time for the creative agent.
High ROI for any positioning/naming decision.
