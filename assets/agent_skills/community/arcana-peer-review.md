---
provider-specific: true
name: arcana-peer-review
description: Simulate independent non-author review by dispatching ARCANA-archetype subagents, each applying a different philosophical or analytical lens to the same work product, blind to author intent and gold labels. Use before sending a framework, architecture, or proposal to a human reviewer, or when the user wants diverse critical perspectives / names a specific lens / asks "what would a skeptic say?" / "red-team this" (on a written work product, not code).
version: 0.1.0
execution-mode: advisory
argument-hint: "<path-or-description of work product to review> [--lens <archetype name>]"
category: fleet-ops
status: candidate
---
## Runtime binding

Role names are neutral. Bind to your runtime per the table in
`rules/skill-provider-neutrality.md` (read-only explorer = `Explore`
in Claude Code; in Devin CLI use `subagent_general` with the read-only
constraint stated in the task prompt — `subagent_explore` is withdrawn
per `rules/devin-subagent-profile-policy.md`).

# ARCANA Peer Review

Simulate independent non-author review by dispatching ARCANA-archetype subagents, each applying a different philosophical or analytical lens to the same work product. Reviewers are blind to author intent, blind to gold labels, and explicitly told they may reject the whole thing. The value is surfacing the issues a real independent reviewer would raise, before the human review — so the work can be revised first.

## When to Use

- Before sending a framework, architecture, or proposal to a human independent reviewer
- When a user wants diverse critical perspectives ("what would a skeptic say?")
- When a user names a specific lens ("review this through Popper / Ostrom / Schneier")
- When a user says "red-team this" or "stress-test this" and the target is a written work product (not code — use security-officer or ponytail for code)
- When a user wants to know "what did I miss?" and is open to the answer being "the whole thing"

## When NOT to Use

- Code review (use ponytail or devin-reviewer)
- Security scanning of code (use devin-security or supply-chain-audit)
- When the user wants a sympathetic review that confirms their thinking (this skill is adversarial by design)
- When the work product is trivial (one paragraph, one function) — the overhead is not worth it

## Context Gathering

Before executing this skill, gather the following context:
- Detect current platform: `python -c "import platform; print(platform.system())"`
- If Windows: use PowerShell for file operations (`New-Item`, `Set-Content`)
- If macOS/Linux: use bash equivalents

## Required Inputs

| Field | Example | Required |
|-------|---------|----------|
| Work product files | `docs/arch.md`, `mappings/evidence.yaml` | Yes — at least one file path |
| Archetypes | `popper,schneier,ostrom,russell` | Yes — user picks, or "default 9" |
| Output path | `docs/review_synthesis.md` | No — defaults to sibling of first input file |

## Step 1. Confirm scope with the user

If the user has not already specified (this session's user did via questions), confirm three things before dispatching:

1. **Which files** are the work product? Get absolute paths. Read them yourself first to confirm they exist and are substantial enough to review.
2. **Which archetypes**? Offer the default set based on doc type (below) or let the user pick. For research docs, the default is the 4-lens skeptic-heavy set; for governance/architecture docs, the default is the 9-lens full set. The user may pick any ARCANA archetype available as a subagent profile. Recommend at least 3 for meaningful convergence.
3. **Output location** for the synthesis? Default is a sibling file in the same directory as the first input.

Do not skip this step even if you think you know — the cost of dispatching 9 subagents against the wrong files is high.

## Step 2. **[MANDATORY]** Read the work product yourself first

Before dispatching any reviewer, read every input file yourself. You need to:
- Confirm the files exist and are readable
- Understand what the work product is (so you can write a useful synthesis later)
- Verify it is substantial enough to warrant N parallel subagents (if it's 3 lines, do not dispatch 9 reviewers — tell the user)
- **Verify the file content matches the lens questions you plan to ask.** If a lens question references "Tier 1/2/3 classifications" but the file doesn't contain tiers, either pick different lens questions or pick a different file. Dispatching a reviewer with lens questions that reference content the file doesn't contain will produce a (correct) refusal-to-fabricate, wasting the run. This was learned the hard way in iteration 1 of this skill's own evaluation.

This is mandatory because dispatching subagents against missing, trivial, or mismatched files wastes budget and produces noise.

**Pre-review self-check (research docs)**: If the work product is a research doc in `docs/research/`, run the research-doc integrity checklist before dispatching reviewers:
```
python scripts/scan-research-tables-pre-commit.py --dir docs/research/
python scripts/audit_research_doc_integrity.py --dir docs/research/ --format text
```
If the doc fails ≥3 patterns, fix the structural issues first — the reviewers will flag them anyway, and fixing them before review saves a revision cycle. See `docs/research/_research_doc_integrity_checklist.md` for the full checklist. (Origin: AAR 2026-09-03, Recommendation #4.)

## Step 2.5. **[MANDATORY]** Quota pre-flight check

**Before dispatching N parallel subagents, verify that subagent dispatch is available AND that capacity is sufficient.** This step was added after a session where 10 subagents were dispatched in one turn and all failed with quota-exhausted errors, wasting the turn and forcing a fallback to self-review. A later session refined this: the pre-flight passed but 6 review subagents failed 8 minutes later because quota was exhausted in the window between pre-flight and dispatch.

Procedure:
1. Dispatch **one** test sub-agent using your runtime's sub-agent dispatch with:
   - role: read-only explorer (cheapest)
   - `is_background: true`
   - A trivial task: `"Reply with the word OK."`
2. Wait for it to complete (it should return in seconds).
3. **Capacity check**: The pre-flight tests availability, not capacity. Since there is no `devin usage --remaining-subagents` command, use this conservative heuristic:
   - If the pre-flight subagent is the only successful dispatch in recent history (check bus for recent subagent failures or quota-exhausted errors in the last hour), assume capacity is 1 and skip to Step 2.6 (inline fallback).
   - If there is no `devin usage` or equivalent quota command, the pre-flight subagent itself consumes 1 unit. For N review subagents, you need at least N+1 units total (1 for pre-flight + N for reviews). If you cannot verify N+1 units remain, skip to Step 2.6.
   - **Conservative default**: if in doubt, skip to inline. The cost of a false skip (inline review) is lower than the cost of a false dispatch (6 failed subagents + wasted turn).
4. **If the test subagent succeeds AND capacity is sufficient**: proceed to Step 3 (dispatch all N reviewers in parallel).
5. **If the test subagent fails** (quota exhausted, network error, or any other error): do NOT attempt to dispatch the N reviewers. Skip to Step 2.6 (inline fallback).

Rationale: one test subagent costs almost nothing. N failed subagents cost a turn of wall-clock time and produce no output. The pre-flight pays for itself the first time quota is exhausted. The capacity check pays for itself the first time quota is exhausted between pre-flight and dispatch.

## Step 2.6. **[FALLBACK]** Inline review path (if subagent dispatch fails)

If the Step 2.5 pre-flight fails, or if N dispatched subagents all fail (quota, network, etc.), fall back to applying the lenses inline. This produces a useful-but-compromised review.

**Mandatory inline-fallback rules:**
1. **Mark the review as self-review, not independent.** The synthesis MUST state in its header: "**Method**: N ARCANA-archetype lenses applied inline by the author agent (subagent dispatch failed — [reason]). **This is self-review, not independent review.** The author is not blind to author intent."
2. **Apply each lens rigorously and honestly**, including against your own reasoning. The temptation in self-review is to be kind to your own work. Resist it. Each lens's specific questions still apply.
3. **Weigh convergent findings more heavily than lone findings.** In self-review, a finding raised by >=3 lenses is more likely to be robust (you'd have to be self-serving in 3 different ways to fake it). A lone finding may be self-serving. Preserve lone findings in the dissent map but flag the epistemic difference.
4. **Recommend re-running via subagents when quota resets.** The synthesis's final section MUST include: "If this work product requires genuine independent review, dispatch a human reviewer or re-run the ARCANA subagent review after the quota resets."
5. **Do NOT claim independence.** No `Bus: Y` receipt from a self-review may claim independent verification. The review is a first-pass stress test, not a substitute for independent review.

The inline fallback is a compromise, not a replacement. It is better than no review (it catches real issues — the 2026-08-14 hummbl-production review caught a verified Cloudflare GitHub App gap via inline self-review). But it is worse than independent review (the same model authored and reviewed the work, so it cannot see its own blind spots that a fresh session or a different model would catch). Note: the ARCANA fleet is consolidated on GLM-5.2 (see Model & Provider Discipline in `arcana-review`); cross-vendor independence is available only via explicit direct-API cross-checks, not via the subagent runtime.

## Step 3. Dispatch reviewers as parallel background subagents

**Only execute this step if Step 2.5 (pre-flight) succeeded.**

For each archetype the user selected, dispatch one background sub-agent using your runtime's sub-agent dispatch with:
- role: read-only explorer (reviewers do not need write access)
- `is_background: true` (parallel — all reviewers run at once)

Dispatch in batches of 3-4 in a single message (multiple dispatch calls in one turn) so they start in parallel. If the user picked 9, dispatch all 9 in one turn (3 batches of 3 fire together).

### Reviewer prompt template

Each reviewer gets the same structure. Replace `<ARCHETYPE>` with the archetype name, `<LENS>` with the one-line lens description, and `<FILES>` with the actual file paths.

```
You are an INDEPENDENT REVIEWER applying the <ARCHETYPE> lens (<LENS>). You did NOT author this work. You have no investment in it. You are blind to any "gold label" classifications the author intended. You are allowed to reject the whole thing.

Read these files:
<FILES>

Apply the <ARCHETYPE> lens specifically:
- <LENS-SPECIFIC-QUESTIONS> (see archetype cards below for each lens's specific questions)

Produce a structured review:
## <ARCHETYPE> Verdict: [RETAIN / REVISE / REJECT]
## <Lens> Assessment
## Strongest Objection (the thing the author did NOT anticipate)
## What the author got right (be honest — do not be uniformly negative)
## What survives <ARCHETYPE> scrutiny
## Specific recommendations

Be rigorous. Do not be kind. <ARCHETYPE> would not be kind.
```

### Why blind matters

Reviewers must NOT see:
- The author's self-assessment or intended classifications
- Other reviewers' output (dispatch in parallel, not sequentially)
- Your own opinions of the work (you are the orchestrator, not a reviewer)

Reviewers MUST see:
- The work product files themselves (that is the point)
- The instruction that they may reject
- The specific lens to apply

## Step 4. Stream verdicts as they complete

As each background subagent completes (you will receive `<subagent_completion_notification>` messages), capture the verdict and post a brief summary to the chat. This gives the user signal while the remaining reviewers are still running.

Format per completion:
```
**<Archetype>**: <VERDICT> — <one-line strongest objection>
```

Do not wait for all reviewers to finish before showing progress.

## Step 5. Synthesize all reviews into a report

Once all reviewers have completed, write a synthesis report. This is the durable artifact. The synthesis is where the value is — individual reviews are data, the synthesis is insight.

### Synthesis structure

```markdown
# <Work product name> Independent Peer Review Synthesis

**Method**: N independent ARCANA-archetype subagents, blind to author intent, may reject.
[If inline fallback was used: "**Method**: N ARCANA-archetype lenses applied inline by the author agent (subagent dispatch failed — <reason>). **This is self-review, not independent review.**"]

**Reviewers**: <list with lenses>

## Headline verdict

<Table: Reviewer | Lens | Verdict>
<Tally: X REVISE, Y REJECT, Z RETAIN>

## Convergence: findings agreed by >=3 reviewers

For each convergent finding (C1, C2, ...):
- **C<n>. <Finding name> (N reviewers: <list>)**
- What the finding is
- Why multiple independent lenses surfacing it makes it authoritative
- The action it implies

## Dissent map: what lone reviewers surfaced

For each lone objection (D1, D2, ...):
- **D<n>. <Reviewer> (<verdict>): <objection>**
- Why it matters even though only one reviewer raised it
- Whether to act on it or flag it

## What survives independent review

<List of contributions that survived, with caveats>

## What does NOT survive

<List of claims/framing/constructs that did not survive>

## Recommended next actions (priority order)

<P1, P2, ... — synthesized from all reviewers' recommendations, deduplicated, ordered by leverage>
```

### Synthesis rules

1. **Convergence is authoritative.** A finding raised by >=3 independent lenses (without coordination) is treated as real. A finding raised by 1 lens is preserved in the dissent map but not treated as authoritative.
2. **Do not average away dissent.** A lone REJECT (like Ostrom's in the RI review) may identify a category error the majority missed. Preserve lone objections in the dissent map with an explanation of why they matter.
3. **Be honest about what the author got right.** Every reviewer is instructed to include "what the author got right" — the synthesis must include this too. A uniformly negative synthesis is less useful than an honest one.
4. **Priority actions are synthesized, not copied.** Deduplicate across reviewers, order by leverage (how many reviewers converged on the underlying issue).
5. **State what this review is and is not.** It is a simulation of independent review by subagents, not a human independent reviewer. A human may surface issues none of these lenses caught.

## Step 6. Write the synthesis to a file

Write the synthesis report to the output path (user-specified or default). Use platform-appropriate file writing:
- Windows (PowerShell): `Set-Content -Path <path> -Value <content> -Encoding utf8`
- macOS/Linux (bash): standard write tool or `cat > <path>`

The synthesis file is the durable artifact. The chat output is ephemeral.

## Step 6.5. **[MANDATORY]** Post REVIEW to the coordination bus

Post the review findings to the bus as a structured REVIEW message so the
review is durable, queryable, and satisfies the bus review gate in
`cross-check-protocol.md` § "Bus as Canonical Review Record".

Use `scripts/post_bus_review.py`:

```bash
python ~/.agents/scripts/post_bus_review.py \
  --reviewer <your-canonical-identity> \
  --artifact "<artifact-path-or-repo#pr>" \
  --artifact-state "<file-hash-or-head-sha>" \
  --verdict <adopt|adopt-with-edits|reject> \
  --next-owner operator \
  --finding "P1:<target>:<finding>|evidence:<evidence>" \
  --review-method "arcana-peer-review <N> lenses <subagent|inline>" \
  --review-lane-authorized <true|false>
```

Determine the fields:
- **verdict**: `adopt` if all verdicts were RETAIN, `adopt-with-edits` if any
  REVISE, `reject` if majority REJECT.
- **findings**: One `--finding` per convergent finding (C1, C2, ...) with
  severity P1 or P2. Lone findings (D1, D2, ...) get P3 unless they identify
  a P0-class defect (security, data loss, fabrication).
- **review-lane-authorized**: `true` if the operator authorized this review
  lane (required for same-session adversarial review per
  `cross-check-protocol.md`). `false` if this was genuine independent review
  via subagents from a fresh session or a different vendor (direct API only).
- **review-method**: e.g., `arcana-peer-review 9 lenses subagent` or
  `arcana-peer-review 9 lenses inline (quota exhausted)`.

If the review was inline (self-review fallback per Step 2.6), the REVIEW
message MUST include `review_method=arcana-peer-review inline` so the
epistemic limit is explicit. The bus review gate script
(`check_bus_review_gate.py`) does not distinguish inline from independent —
that determination is for the merge decision-maker reading the receipt.

## Step 7. Present the synthesis to the user

In chat, present:
1. The headline verdict (tally)
2. The convergent findings (the authoritative issues)
3. The dissent map (the lone objections worth considering)
4. The top 3 priority actions
5. The path to the full synthesis file

Do not dump the entire synthesis into chat — it is in the file. Give the user the headline + the most actionable parts + the file path.

## Default archetype sets

There are two defaults, selected by document type. The operator can always override per-doc.

### Research docs (4-lens skeptic-heavy) — DEFAULT for `docs/research/`

If the user says "you pick" and the work product is a research doc (catalog, survey, benchmark review, landscape analysis), use this 4-lens set. It focuses epistemic pressure on the failure modes most common in research docs: unfalsifiable claims, measurement corruption, methodological dogmatism, and citation-laundering / threat models.

- **popper**: Falsifiability, demarcation, the duty to refute your own theory, immunization stratagems
- **schneier**: Threat model, security theater, adversarial reading, citation-laundering attack surface
- **measurement**: Goodhart's Law, Campbell's Law, proxy vs terminal values, politics of quantification
- **feyerabend**: Against method, proliferation + tenacity, incommensurability, false commensurability in comparative tables

**Why 4, not 9**: The 4-lens set caught all 5 convergent findings in the 2026-09-03 benchmarks review. The missing lenses (Ostrom, Meadows, Russell, Kuhn) surface governance/alignment/paradigm issues that are valuable for governance/architecture docs but overkill for pure research catalogs. 4 lenses = 4 subagent dispatches = half the quota cost. (Origin: AAR 2026-09-03, operator decision Branch B.)

### Governance / architecture docs (9-lens full set) — DEFAULT for governance frameworks, architecture proposals, doctrine changes

If the user says "default 9" or "you pick" and the work product is a governance framework, architecture proposal, or doctrine change, use the full 9-lens set. They cover epistemology, systems/governance, and alignment/method — three different attack surfaces, three archetypes each.

### Batch 1 — Epistemology & falsifiability
- **popper**: Falsifiability, demarcation, the duty to refute your own theory, immunization stratagems
- **ashby**: Law of Requisite Variety, Good Regulator Theorem, centralized control impossibility
- **schneier**: Threat model, security theater, adversarial reading, Goodhart applied to the framework itself

### Batch 2 — Governance & systems
- **ostrom**: Commons governance, 8 design principles, polycentric vs top-down, community self-governance
- **meadows**: Leverage points hierarchy, feedback loops, naming the system, dancing with systems
- **measurement**: Goodhart's Law, Campbell's Law, proxy vs terminal values, politics of quantification

### Batch 3 — Alignment & method
- **russell_s**: Standard vs alternative model, objective uncertainty, CIRL, reward misspecification
- **kuhn**: Normal vs revolutionary science, paradigm status, incommensurability, anomalies
- **feyerabend**: Against method, proliferation + tenacity, incommensurability, separation of science and state

### Doc-type criteria

| Doc type | Default | Why |
|----------|---------|-----|
| Research catalog / survey / benchmark review | 4-lens skeptic-heavy | Epistemic pressure on measurement and citation integrity |
| Governance framework / architecture proposal | 9-lens full set | Needs governance, systems, and alignment lenses |
| Doctrine change / invariant amendment | 9-lens full set | High-stakes, needs all attack surfaces |
| Short internal note / AAR | Operator's call | May not warrant full review |
| Operator override | Any | Operator can always pick a custom set |

## Archetype cards (lens-specific questions for the reviewer prompt)

When dispatching a reviewer, include the lens-specific questions from the relevant card below in the `<LENS-SPECIFIC-QUESTIONS>` slot.

### popper
- FALSIFIABILITY: Is the work falsifiable? What specific observation would refute it?
- CONJECTURES AND REFUTATIONS: Did the author genuinely attempt to refute their own work, or only search for confirming evidence?
- IMMUNIZATION STRATAGEMS: Does the work use escape hatches ("candidate", "all outcomes valid") that make it unfalsifiable?
- THE DUTY TO REFUTE: Did the author subject the core claim to the same scrutiny applied to the parts?
- PIECEMEAL vs UTOPIAN: Is this piecemeal (testable, reversible) or utopian (grand scheme resistant to refutation)?

### ashby
- REQUISITE VARIETY: Does the taxonomy have requisite variety to capture the error space it claims to diagnose?
- GOOD REGULATOR: Does the work contain an adequate model of the system it regulates, or just relabel existing tools?
- CONSTRAINT AS CONTROL: Does delegation preserve the constraint variety needed for control, or lose it?
- VIABLE SYSTEM: Does the structure have the recursive control needed for self-regulation?
- CENTRALIZED CONTROL: Is there a fundamental contradiction between centralized control and a distributed target system?

### schneier
- THREAT MODEL: What is the actual threat model? WHO is the adversary? Is it stated or implied?
- SECURITY THEATER: Is the visible complexity actually reducing risk, or is it taxonomy theater?
- ADVERSARIAL READING: What would an attacker do with this? Can the checks be gamed?
- ECONOMICS: Is the cost (implementation, cognitive load) vs risk reduction favorable?
- INEVITABILITY OF BUGS: What is the framework's own error model?

### ostrom
- COMMONS FRAMING: Is the governed resource a commons? Does the work recognize this?
- 8 DESIGN PRINCIPLES: Score against clearly defined boundaries, congruence, collective-choice, monitoring, graduated sanctions, conflict-resolution, rights to organize, nested enterprises.
- POLYCENTRIC vs FRAGMENTED: Is the delegation polycentric (good) or fragmented (bad)?
- EMPIRICAL GROUNDING: Is the work grounded in real cases of the governed system, or only literature?
- COMMUNITY SELF-GOVERNANCE: Does it enable communities to govern, or impose external categories?

### meadows
- LEVERAGE POINTS: Where in the hierarchy (parameters -> paradigms) is the work intervening? Low or high leverage?
- THE SYSTEM: Does the work name the system it is trying to affect? (A leverage point without a system is meaningless.)
- FEEDBACK LOOPS: Does it create a balancing loop or a reinforcing (gaming) loop?
- DELAYS: What are the delays in the feedback loop, and do they make the system unstable?
- DANCING WITH SYSTEMS: Does it impose categories or listen to the existing system?

### measurement
- GOODHART: Once the metrics become targets, will the system be gamed? Has the work addressed this?
- CAMPBELL: What corruption pressures will the indicators face when used for decision-making?
- PROXY VS TERMINAL: Is the measured quantity a terminal value or a proxy? How much distance?
- MEASUREMENT INVARIANCE: Do the categories measure the same thing across contexts?
- POLITICS OF QUANTIFICATION: Who decides what counts as a defect? Whose view is encoded?

### russell_s
- STANDARD vs ALTERNATIVE MODEL: Does the work assume a fixed objective, or allow uncertainty about the objective?
- BENEFICIAL AI: Trace the causal chain from the work to human benefit. What fills the gaps?
- COOPERATIVE IRL: Does it enable cooperation, or impose one-directional diagnosis?
- CONTROL PROBLEM: Does it contribute to the control problem, or is it orthogonal?
- REWARD MISSPECIFICATION: What happens when the governing context is misspecified?

### kuhn
- NORMAL vs REVOLUTIONARY: Is this normal science (extending a paradigm) or revolutionary (proposing one)? Is the framing inflated?
- PARADIGM OR TOOLKIT: Does the work have ontological commitments, or is it just a toolkit?
- INCOMMENSURABILITY: Can the frameworks it maps between be mapped losslessly, or is incommensurability denied?
- ANOMALIES: What would trigger a paradigm crisis? Will contrary evidence be explained away?
- LOSS IN SHIFTS: If this is a paradigm shift, what is lost?

### feyerabend
- AGAINST METHOD: Is the methodology dogmatic? Would pluralism serve better?
- PROLIFERATION + TENACITY: Did the work abandon constructs too readily (anti-tenacity)? Should it have held them longer?
- INCOMMENSURABILITY: Does the mapping impose a false unity on incommensurable frameworks?
- SEPARATION OF SCIENCE AND STATE: Is this an imposition of one framework on a diverse ecosystem?
- ANYTHING GOES: Would a single heuristic be more effective than the whole apparatus?

## Adding archetypes not in the default set

The user may pick any ARCANA archetype available as a subagent profile (see the fleet's available subagent profiles list). **Profile IDs are lowercase and some use underscores** — e.g., `popper`, `schneier`, `ostrom`, `meadows`, `measurement`, `russell_s` (note the underscore for Stuart Russell), `kuhn`, `feyerabend`, `ashby`, `bostrom`, `schmitt`, `foucault`, `nietzsche`. If a user says "Russell" or "Stuart Russell", use `russell_s` as the profile ID. When unsure of the exact ID, check the available subagent profiles list in your system prompt before dispatching.

Common additions for peer review:
- **bostrom**: existential risk, superintelligence, the control problem (for AI safety work)
- **schmitt**: friend/enemy, the exception, sovereignty (for political/governance work)
- **foucault**: power/knowledge, discourse, discipline (for institutional work)
- **habermas**: communicative rationality, the public sphere (for deliberative work)
- **nietzsche**: genealogy, will to power, ressentiment (for moral/ethical work)

If a user names an archetype not in the cards above, construct lens-specific questions in the same spirit before dispatching. The questions should be specific to that thinker's framework, not generic.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `arcana-peer-review` | `govern` if the review surfaces governance gaps requiring audit-ready artifacts |
| `arcana-peer-review` | `ai-policy-review` if the target was an AI policy and the review found framework gaps |
| `arcana-peer-review` | `brainstorm` if the review recommends a redesign and the user wants design-first exploration before reimplementation |

## What this skill is and is not

**This is**: a simulation of independent review using diverse philosophical lenses. Useful before a human independent reviewer, to surface issues early.

**This is not**: a replacement for a human independent reviewer. All subagents share the same underlying model (GLM-5.2) and were dispatched by the author's agent; independence comes from epistemological diversity and session isolation, not vendor diversity. A human reviewer (or a direct-API cross-vendor cross-check) may surface issues none of these lenses caught, and may reject findings these lenses converged on. If the work product requires a genuine independent review (for compliance, audit, or governance reasons), dispatch a human reviewer after this skill.

## Changelog

- **v1.1** (2026-08-14): Added Step 2.5 (quota pre-flight check) and Step 2.6 (inline fallback path) after a session where 10 subagents were dispatched and all failed with quota-exhausted errors. The pre-flight dispatches 1 test subagent before N; the inline fallback applies lenses inline with mandatory self-review marking. Origin: AAR-2026-08-14-hummbl-production-org-migration-review.md.
- **v1.2** (2026-09-02): Added Step 6.5 (MANDATORY bus REVIEW post) so arcana-peer-review findings are durable on the coordination bus and visible to `check_bus_review_gate.py` pre-merge gate. Integrates with `cross-check-protocol.md` § "Bus as Canonical Review Record".
- **v1.3** (2026-09-03): Added two default archetype sets — 4-lens skeptic-heavy (popper, schneier, measurement, feyerabend) for research docs, 9-lens full set for governance/architecture docs. Added pre-review self-check for research docs (Step 2) referencing the research-doc integrity checklist. Origin: AAR 2026-09-03 arcana-peer-review-long-running-agent-benchmarks, operator decision Branch B.
