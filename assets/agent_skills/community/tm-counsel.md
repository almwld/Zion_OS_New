---
name: tm-counsel
description: "Internal trademark strategy review for clearance artifacts or mark questions: section 2(d), confusion risk, coexistence options, risk grades, and counsel-escalation questions."
version: 0.1.0
execution-mode: advisory
category: finance-legal
status: candidate
---
# [tm-counsel]

**NOT LEGAL ADVICE.** For HUMMBL internal strategic reasoning only. Paid-counsel review required before any public-facing trademark filing, opposition response, or coexistence-agreement action.

## When to invoke

- A trademark clearance artifact (Lane A-class) has surfaced YELLOW or RED marks and you need structured analysis of risk + options
- A new mark is being proposed and you want a pre-clearance sanity check
- A specific §2(d) likelihood-of-confusion question needs structured reasoning
- An incumbent registration is partially in the way and coexistence-agreement options need mapping
- Brand-architecture decision is gated on TM analysis (e.g., R4 flagship-name decision)

## Usage

```
[tm-counsel] <substrate-ref-or-query>
```

Substrate-refs:
- `lane-A` → reads `$HOME/_internal/research/intel-surge-2026-05-19/lane-A-trademark.md`
- `<absolute-path-to-clearance-doc>` → reads operator-provided artifact
- `<bare-mark-query>` → e.g., `HUMMBL Receipts in IC042` → builds analysis from substrate + memory pins

## Substrate (lazy-load)

Read these at invocation when relevant:

| Surface | Path | When to load |
|---|---|---|
| Lane A intel-surge | `$HOME/_internal/research/intel-surge-2026-05-19/lane-A-trademark.md` | Default for flagship-name analysis |
| Lane C counsel-packet | `$HOME/_internal/research/intel-surge-2026-05-19/lane-C-entity-counsel-packet.md` | When entity-structure constraints affect TM strategy |
| Brand architecture memory | `$RUNTIME_MEM/project_hummbl_brand_architecture.md` (resolve via `~/.agents/scripts/resolve-memory.sh`) | When TM analysis intersects flagship/sub-mark decisions |
| Krineia prior-art memory | `$RUNTIME_MEM/project_krineia_prior_art.md` | When Krineia mark is in scope |
| HUMMBL primitives | `~/.agents/rules/hummbl-primitives.md` | When understanding the TM's strategic role matters |

DO NOT auto-load all substrate. Read only what's needed for the specific query.

## Reasoning framework — §2(d) likelihood of confusion (8 DuPont factors, abbreviated)

For each YELLOW or RED finding, walk these factors:

1. **Similarity of marks** — sight, sound, meaning, commercial impression. Phonetic identity (HUMMBL vs HUMBL) gets explicit treatment.
2. **Similarity of goods/services** — same class (e.g., both IC042)? Narrower channels possible?
3. **Trade channels** — overlapping buyer surfaces or differentiated?
4. **Conditions of purchase** — sophisticated buyers reduce confusion likelihood; consumer marks higher risk
5. **Strength of senior mark** — registration alone vs use-in-commerce evidence; descriptive vs coined
6. **Actual confusion** — any evidence of marketplace confusion? (Usually none pre-launch.)
7. **Concurrent use** — has incumbent acquiesced to similar marks before?
8. **Variety of marks on similar goods** — crowded field reduces likelihood of confusion per any single mark

Score each factor briefly (favors junior / favors senior / neutral). Aggregate into risk grade.

## Output structure

```
# [tm-counsel] — <mark or scope> | <YYYY-MM-DD>

**NOT LEGAL ADVICE.** Internal strategic reasoning only. Paid-counsel review required before any TM action.

## 1. Marks in scope
<list>

## 2. Senior-mark landscape
<incumbent registrations, status, owner, classes, use evidence>

## 3. §2(d) likelihood-of-confusion analysis (DuPont factors abbreviated)
<per-factor brief, with verdict per factor>

## 4. Risk grade
- 🔴 RED / 🟡 YELLOW / 🟢 GREEN
- Confidence: HIGH/MEDIUM/LOW (based on substrate completeness — flag [SEC] reliance vs [PRIM] reliance)
- Open data gaps: <list — what would change the grade>

## 5. Strategic options
| Option | Approach | Pros | Cons | Optionality preserved? |
|---|---|---|---|---|
<3-5 options with TM-strategic framing — coexistence, narrowing, pivot, defensive sub-brand, etc.>

## 6. Recommendation
<one option + rationale; explicit note where paid counsel must validate>

## 7. Counsel-escalation questions
<numbered list — what to actually ask paid counsel; mapped to which option(s) each Q gates>

## 8. Substrate consulted
<file paths + memory pins read this invocation>
```

## Discipline

- **Every output starts with the NOT LEGAL ADVICE header.** No exceptions.
- **No filing recommendations.** Surface options + their trade-offs; never tell the operator "file this on date X."
- **No fabricated Trademark Search/EUIPO serial numbers.** If a fact isn't in substrate or can't be web-fetched, mark `[UNVERIFIED]` and ask via counsel-escalation question.
- **Confidence calibration.** If substrate is mostly [SEC] aggregator-sourced (per Lane A grading discipline), risk grade carries LOW confidence; flag explicitly.
- **Apply `claim-honesty-protocol.md` §1 4-field provenance** to every specific claim about a registration (claim / source / source_quote / verified_date).
- **Defer to paid counsel on**: actual filing decisions, opposition-response strategy, coexistence-agreement drafting, cease-and-desist responses, settlement terms.
- **Candidate-rule discipline ON**: if this skill generates a recommendation that would create a new fleet-wide rule, land it at `~/.agents/rules/_candidates/` per `_candidates/README.md` C2/M0 triage, NOT direct to canonical.

## What this skill is NOT

- Not a substitute for paid trademark counsel
- Not a TM filing tool
- Not an opposition-response drafter
- Not authoritative on jurisdiction-specific procedure (EUIPO, UKIPO, etc. — flag for paid counsel)
- Not a general legal-counsel skill (see `legal-counsel` agent for contract drafting)

## Smoke test (first invocation)

Operator should invoke as:
```
[tm-counsel] lane-A
```

Expected output: structured analysis of the 16-mark Lane A artifact, with primary focus on HUMMBL Receipts YELLOW phonetic-identity finding vs HUMBL Reg 5812286 IC042. Should produce 3-5 strategic options + 8-12 counsel-escalation questions ready for the eventual paid-counsel conversation.

## Companion skills

- `[brand-architect]` — invoke when TM analysis surfaces a brand-architecture revision option (Option G class)
- `[legal-counsel]` (agent) — invoke for any contract-drafting follow-up
- `[apex]` — invoke for option-sequencing when TM analysis surfaces ≥3 decision points
- `[brainstorm]` — invoke when TM analysis surfaces a pivot question that needs option-space mapping

## Origin

Built 2026-05-19 per apex department-build sequencing decision. SHIP-1 of 3 (TM-counsel → Brand-architect → [name-test] deferred). Substrate: R4 flagship-name decision from intel-surge AAR. Operator-approved D1+D2+D3 gate.
