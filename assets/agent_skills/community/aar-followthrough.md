---
name: aar-followthrough
description: "Run AFTER [aar] completes to elaborate and plan every §7 recommendation into an owned, verifiable goal that feeds into [goal-selection]. Use whenever the operator says 'elaborate on and plan for all recommendations', 'plan the recommendations', 'follow through on the AAR', 'turn the AAR recommendations into plans', 'what do we do with these recommendations', or 'make the AAR recommendations actionable'. This is the bridge between AAR (what we learned) and goal-selection (what we do next) — it closes the retrospective→prospective loop so recommendations do not rot."
version: 0.4.1
execution-mode: side_effecting
argument-hint: "[<aar-name-or-path>] [--no-seed] [--no-bus]"
category: fleet-ops
status: candidate
---

> **Finalize shortcut**: After the skill produces a seed file, run
> `aar-followthrough-finalize <seed-file.json>` to post the SITREP and
> ingest the seed in one command. Add `--dry-run` to review without
> posting. The wrapper guards against re-ingesting already-processed
> seed files (status=ingested/superseded/declined).

# AAR Follow-Through

Turn the §7 Recommendations of a completed AAR into owned, verifiable, executable plans — then hand them to `[goal-selection]` as a seed file so the fleet can actually do them.

## Why this skill exists

An AAR ends with a prioritized one-liner list:

```
1. [HIGH] <action> -- addresses: <which improve>
2. [MED]  <action> -- addresses: <which improve>
```

Each line is an **intention**, not an action. Intentions rot. Without a follow-through step, §7 becomes a graveyard of good ideas: no owner, no deadline, no verification, no path into the work-selection system. This skill is the anti-rot step. It does two things to every recommendation:

- **Elaborate** — expand the one-liner into real understanding: what it means, the mechanism, the scope, and *why* it matters traced back through §6 (the Improve it addresses) to §4 (the root cause). Elaboration frequently surfaces recommendations that are vague once expanded, that conflict with each other, or that have hidden ordering dependencies — all invisible at one-line resolution.
- **Plan** — convert the elaborated intention into a goal-shaped, owned, verifiable plan that `[goal-selection]` can ingest as a candidate goal.

The output is prospective, so the bus vehicle is a **SITREP** (forward-looking), not another AAR. See the AAR-vs-SITREP table in `[aar]`: AAR is "what did we learn", SITREP is "what do we do next". This skill lives on the SITREP side.

## When to run

- Immediately after `[aar]` completes, when the operator says "elaborate on and plan for all recommendations" or any variant.
- Any time the operator points at an existing AAR and asks to make its recommendations actionable.
- Do NOT run without an AAR in hand (this session's output, or a path). If no AAR can be located, stop and say so — there is nothing to follow through on.

## Inputs

- **Primary**: the AAR's §7 Recommendations (the one-liner list).
- **Trace context**: §6 Improves (what each recommendation addresses) and §4 Root Causes (the why behind the Improve). The elaboration is only as good as this trace — a recommendation detached from its root cause becomes a surface fix.
- **Optional**: §1 Mission & Intent (keeps plans aligned with what the operation was originally trying to do).

Locate the AAR from, in order: (1) an explicit path/name argument, (2) the most recent AAR produced in the current session, (3) a path the operator provides when asked. Do not fabricate an AAR's contents — if you can only see part of it, say so and ask.

## Workflow

### 0. **[MANDATORY]** Emit SKILL_INVOKE

Post SKILL_INVOKE to the bus before any stateful action (writing the seed file, posting the SITREP). Use the canonical sender identity for the current runtime; do not invent one.

```
Type: SKILL_INVOKE
To: all
Message: [skill=aar-followthrough] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```

Delegate the actual bus write to `[bus]` rather than appending to `messages.tsv` directly — this keeps the skill portable across platforms and avoids re-implementing the host-tag-first validation that `[aar]` and `[bus]` already enforce.

### 1. Locate and parse the AAR

Read the AAR. **Before extracting numbered sections**, scan the top of the document (above §1) for any corrective addendum, supersession note, or reclassification block — typically blockquoted or bold-labeled "Corrective disposition" text that reclassifies the original outcome (e.g., PASS → PARTIAL / NONCONFORMING), changes which artifacts are canonical, holds implementation pending, corrects eligibility/alias facts, or supersedes the AAR's own §3 claims. If present:

- Record its binding assertions (disposition change, held items, canonical-path corrections, eligibility corrections, alias resolutions).
- Treat the addendum as the governing reality for every recommendation — the original §3/§7 text is historical; the addendum supersedes it.
- In each per-recommendation block (step 3), note whether the addendum affects that recommendation's scope, urgency, or whether it should be held pending. A recommendation the addendum leaves untouched still gets a "addendum does not address this" note so the check is explicit, not silent.

Then extract:
- §7 Recommendations → the work list (each item has a priority tag `[HIGH]|[MED]|[LOW]`, an action, and an "addresses:" pointer to an Improve).
- §6 Improves → the failure each recommendation is supposed to fix.
- §4 Root Causes → the why behind each Improve.
- The AAR's `operation` name and timestamp → used in the SITREP and the seed filename.

### 2. Cross-check for orphan Improves

Compare §6 Improves against the "addresses:" pointers in §7. If any Improve has **no** recommendation targeting it, surface it explicitly as an orphan:

```
ORPHAN IMPROVES (no recommendation addresses these — consider adding one):
- <improve text> -- evidence: <receipt>
```

This matters because an Improve with no recommendation is a known failure mode the AAR explicitly named but did not act on. Surfacing it forces a decision: add a recommendation, or consciously accept the gap. Either is fine; silence is not.

### 3. Elaborate + plan each recommendation

**Zero-recommendation case**: if §7 has 0 recommendations (empty, "(none)", or absent), skip steps 3-4's per-item loop. Still run the orphan-Improve check (step 2) — an AAR with 0 recs but ≥1 §6 Improve is itself a finding. Write a seed file with `goals: []` and `escalated: []` (empty but present, with lifecycle metadata). Draft the SITREP with `0 plans from 0 recommendations` and **omit the `top:` field** — there is no top goal line when there are 0 plans. Declare PASS only if orphan Improves were flagged; declare PARTIAL if orphans exist and were not surfaced. Do not crash or emit an undefined `top:` field.

For each §7 item, produce one block using the template below. The block is the unit of work — every recommendation gets one, no skipping. If a recommendation is too vague to plan, say so in the elaboration and propose either a sharpened version or a split into smaller plans. Vagueness is a finding, not a reason to skip.

If a §7 recommendation does not trace to any §6 Improve (e.g. a bonus finding, a runbook open item resolved as a side effect), plan it anyway — it is still a stated intention that will rot without an owner. In the "Addresses" field, write `N/A — no §6 Improve trace` and explain what the recommendation actually addresses (e.g. "runbook open item #2, resolved as a bonus output of the validation run"). Flag the count in the run header as `NON-IMPROVE RECOMMENDATIONS: <N>` so the operator can route these separately from the retro→prospect loop at ingest time. Do not exclude non-improve recs from the seed file — exclusion is silent loss, which is the failure mode this skill exists to prevent.

If a recommendation is **self-contradictory where the contradiction reverses intent** (e.g. a headline says "do X" and a note says "consider not-X"), do NOT pick a side. Surface both readings in the elaboration, produce a candidate goal line for each, mark each `DEVIATION-FROM-ORIGINAL-INTENT: operator-decision-required`, and escalate to the operator before writing either into the seed file. Reversing a recommendation's intent is a decision that belongs to the operator or AAR author, not to this skill.

If a recommendation is a **"consider whether …" question rather than an action**, do NOT answer the question by planning one branch. Surface the question, enumerate the candidate actions that would resolve it either way, and escalate to the operator to pick. A question is not a recommendation; planning it as if it were silently closes a decision the AAR author left open.

### 4. Build the goal-harness seed file

Collect every plan's goal line + details + priority into a JSON file in the exact schema `goal-harness.py seed` expects (verified against `$HOME/.agents/scripts/goal-harness.py`). Include lifecycle metadata so the seed file is a traceable trail artifact, not orphan cruft:

```json
{
  "created_at": "<ISO 8601 UTC timestamp>",
  "source_aar": "<path or identifier of the AAR>",
  "status": "pending-ingest",
  "goals": [
    {
      "title": "<goal line — goal-selection shape>",
      "details": "<elaboration summary + plan steps + success criteria + receipt path>",
      "priority": 10,
      "command": "",
      "completed": false
    }
  ],
  "escalated": []
}
```

**`completed` field** (optional, default `false`): set to `true` for goals that were already executed before this seed file was written (e.g. a recommendation that was addressed during the same session as the AAR). The goal-harness reads this field at seed time and marks the goal as `status: "done"` so `[goal-selection]` skips it. This prevents re-picking work that is already complete. Use this instead of relying on prose markers like "ALREADY EXECUTED" in the `details` field — the structured boolean is machine-readable and filters reliably.

Priority mapping (verified: harness sorts ascending, "lower is higher"):
- `[HIGH]` → `10`
- `[MED]`  → `50`
- `[LOW]`  → `100`

**Priority on sharpened recommendations**: keep the original §7 priority tag as the default — the AAR author assigned it based on their judgment of the recommendation in context, and re-prioritizing is outside this skill's scope (elaborate + plan, not re-prioritize). When sharpening changes the *nature* of the work in a way that would change the priority (e.g., a [HIGH] protocol gate sharpened into a [MED] template edit, or a [LOW] "consider whether" sharpened into a doctrine amendment), surface the discrepancy in the elaboration field and the Priority note field — do NOT silently change the priority int. The original priority stands unless the operator overrides.

Default output path: `~/.agents/goal-harness/seeds/<aar-slug>-followthrough.json`. The slug is derived from the AAR's operation name (lowercase, hyphenated). This co-locates seed files with goal-harness state so they are discoverable by `goal-harness.py seed` and do not clutter the home directory or get committed to unrelated git repos. The operator can move or rename the file.

**Existing-file check (re-run handling)**: before writing, check whether a seed file already exists at the output path (or shares the same `source_aar`). If it does, this is a re-run — do NOT overwrite in place. Mark the prior file `status: "superseded"` in place (edit its `status` field), then write the new file. If the prior file is at the same path, write the new file to `<aar-slug>-followthrough.json` and rename the prior to `<aar-slug>-followthrough.superseded-<prior-created_at>.json` so both coexist as audit records. If the prior file was already `ingested` or `declined`, still mark it `superseded` — the operator's prior decision stands on the record, but the new run replaces it as the current plan set. Log the supersession in the SITREP (`| SUPERCEDS: <prior path> (<prior status>)`). This is the one lifecycle transition the skill performs itself (see "Who updates status" below); `ingested` and `declined` remain operator-gated.

To actually load the plans into the goal harness so `[goal-selection]` can pick them up:

```
python $HOME/.agents/scripts/goal-harness.py seed --agent <owner-tag> --seed <path-to-seed.json>
```

This step is **optional and operator-gated** — do not run it unless the operator confirms. Producing the seed file is the skill's job; ingesting it into the live goal queue is a fleet action the operator should authorize. (Probe `python` vs `python3` per platform; on Windows Workstation it is `python`.)

**Two ingestion paths** (Fix #6, documented 2026-08-25):

1. **`goal-harness.py seed`** (canonical) — the standard path. Preserves `seed_source`, `seed_index`, `source_aar` provenance; honors the `completed` field; updates the seed file's `status` to `ingested` after successful ingestion. **Use this for all normal AAR followthrough ingestions.**

2. **`goal_harness_repair.py reconcile`** (repair-only) — the reconciliation path. Handles duplicate-ID repair, seed inventory building, and bulk re-ingestion of all `status: "ingested"` seed files in the seeds directory. **Use this only for state repair, dedup, or fleet-wide re-ingestion.** It writes a `reconciliation` metadata block and `seed_inventory` to `state.json`; `cmd_seed` does not (it updates `state_goal_count` instead).

Both paths now honor the `completed` field and preserve provenance. The difference is scope: `seed` is per-file, `reconcile` is per-directory.

### 5. Self-check (PASS / PARTIAL / NONCONFORMING)

Mirror the AAR's protocol-conformance self-check. For a run to be PASS, every recommendation must be elaborated AND planned, the seed file must be written, and orphan Improves must be addressed (flagged or planned). If any recommendation was skipped or the seed file was not written, declare PARTIAL or NONCONFORMING and list the deviations — do not declare PASS. This is the internal adversarial review; do not wait for someone else to catch a self-serving "all done."

### 6. Draft SITREP, present, post on approval

Draft a SITREP (host-tag-first, per `[aar]` and project `AGENTS.md`):

```
<timestamp_utc>	<canonical-identity>	all	SITREP	host=<machine> FOLLOWTHROUGH: <aar-operation> -- <N> plans from <M> recommendations; top: <top goal line>
```

`<machine>` MUST be one of `workstation`, `delta`, `remote-node`, `remote-node`, `hummbl-vps`, `huxley`, `remote-node`, `unknown`. Validate the message body begins with `host=(workstation|delta|remote-node|remote-node|hummbl-vps|huxley|remote-node|unknown)` before posting.

Present the draft SITREP to the operator. **Post only after explicit approval.** If the operator declines, leave `Bus: N (declined)` in the footer — do not post unsolicited. If the bus is unreachable from this host, report `Bus: N (unreachable: <reason>)` and surface it as a gap, exactly as `[aar]` does — never claim `Bus: Y` without a real post.

**Bus reachability verification (do not assume)**: before declaring `Bus: Y` or `Bus: N`, run an actual reachability probe — not a dry-run alone. `bus-global.py post --dry-run` only checks the offline-marker file, not network reachability, and can report `hub_reachable: true` when the bridge is actually down (confirmed: stale `BUS_CANONICAL_BRIDGE_URL` env var pointing at a dead Cloudflare quick tunnel produced a false-positive dry-run while real posts failed with DNS errors). Verify with: (1) `bus-global.py post --dry-run` for the offline-marker check, AND (2) an actual `bus-global.py post` of the SITREP (the real write is the verification — if it fails, the failure IS the `Bus: N` evidence). If you want to probe without posting the SITREP, post a PROBE message first and confirm it appears. Do not infer reachability from a mirror file being updated — another host may be writing it. The only reliable verification is a successful post from this host.

---

## Per-recommendation block template

Use this exact shape for each §7 item. The fields with a Base120 tag apply that transformation; include the code only when the field was actually filled in (per `[aar]`'s no-fabrication rule — do not decorate with codes you didn't use).

```
### [HIGH|MED|LOW] <recommendation, verbatim from §7>

- **Addresses**: <§6 Improve it targets> → <§4 Root Cause>  (trace the why) — OR `N/A — no §6 Improve trace: <what it actually addresses>` if the rec does not trace to an Improve
- **Elaboration**: <what this actually means; mechanism; scope; why it fixes the root cause and not just the symptom>
- **Goal line** (P6: POV anchoring — owner; IN17: counterfactual — verifiable done-state; IN20: antigoal — explicit non-actions):
  <verb> <artifact/system> so that <fleet/operator outcome>, verified by <specific evidence>, without <explicit non-actions>.
- **Plan**:
  1. <concrete step>
  2. <concrete step>
  ...
- **Owner**: <agent tag or operator>
- **Effort**: S | M | L
- **Success criteria**: <how we know it's done — must be checkable, not "improved">
- **Receipt path**: <where the completion evidence will live: commit, PR, bus receipt, file>
- **Risk if skipped** (IN20): <what keeps failing if we don't do this>
- **Bus closeout** (when the plan is executed later): REVIEW | WIP_END | RECEIPT | BLOCKED
- **Priority int**: 10 | 50 | 100
- **Priority note** (only when sharpening changed the work's nature): original [<tag>]=<int>; sharpened version arguably [<tag>]=<int>; operator to confirm
```

The goal line is the most important field — it is what `[goal-selection]` reads. It must be one sentence in the goal-selection shape, with a verifiable `verified by` clause and an explicit `without` clause. A goal line without a verifiable done-state is not a goal; it is still an intention.

---

## Seed file schema (reference)

```json
{
  "created_at": "<ISO 8601 UTC timestamp>",
  "source_aar": "<path or identifier of the AAR>",
  "status": "pending-ingest",
  "goals": [
    {
      "title": "<verb> <artifact> so that <outcome>, verified by <evidence>, without <non-actions>",
      "details": "<elaboration + plan steps + success criteria + receipt path>",
      "priority": 10,
      "command": "",
      "completed": false
    }
  ],
  "escalated": [
    {
      "recommendation": "<§7 rec text>",
      "reason": "<why escalated — self-contradictory or question-shaped>",
      "candidate_branches": [],
      "operator_decision_required": "<what the operator needs to pick>"
    }
  ]
}
```

- `created_at`: ISO 8601 UTC timestamp when the seed file was written (required — enables staleness sweeps).
- `source_aar`: path or identifier of the AAR these plans were derived from (required — provenance for audit).
- `status`: lifecycle state of the seed file (required). One of:
  - `pending-ingest` — seed file written, operator has not yet ingested or declined. **Default on creation.**
  - `ingested` — operator ran `goal-harness.py seed` and the goals are in the live queue. Update to this when ingest is confirmed.
  - `declined` — operator reviewed and chose not to ingest. Update to this when the operator declines.
  - `superseded` — a newer followthrough run for the same AAR replaced this one. Update to this if you re-run the skill against the same AAR.
  - `stale` — seed file is older than the staleness threshold (default 90d) and still `pending-ingest`. Set by a staleness sweep, not by this skill.
- `goals`: array of planned goals (see per-goal fields below).
- `escalated`: array of recommendations that were NOT planned because they require operator decision (self-contradictory or question-shaped). `goal-harness.py seed` ignores this field — it only reads `goals[]`. Escalated branches enter the live queue only after the operator picks one and it is moved into `goals[]`.

Per-goal fields:
- `title`: the goal line (required).
- `details`: elaboration + plan + success criteria + receipt path (required — this is what makes the goal actionable rather than a title alone).
- `priority`: int, lower = higher priority. HIGH=10, MED=50, LOW=100.
- `command`: optional shell command the harness can run for this goal. Leave empty unless the plan reduces to a single command.
- `completed`: optional boolean (default `false`). If `true`, the goal is seeded with `status: "done"` and `completed: true` — `goal-harness.py select` skips it. Use this to mark goals that were already executed before the seed file was created, so they are not re-picked.

## Seed file lifecycle

Seed files are trail artifacts. Without lifecycle metadata they become cruft — unowned files in the working directory with no indication of whether they were ingested, declined, or forgotten. The `status` field makes the trail auditable and sweepable.

**On creation**: set `status: "pending-ingest"` and `created_at: <now>`.

**On ingest**: when the operator confirms `goal-harness.py seed` ingestion, update `status` to `ingested`. Do not assume ingest from the command running — confirm the harness accepted the goals.

**On decline**: if the operator reviews the plans and chooses not to ingest, update `status` to `declined`. A declined seed file is not deleted — it is the audit record of a conscious decision not to act.

**On re-run**: if the skill is run again against the same AAR (e.g., after the AAR was revised or a corrective addendum was added), mark the prior seed file `superseded` and write a new one. Do not overwrite in place — the prior file is the audit record of what was planned before the revision.

**Staleness sweep**: a seed file with `status: "pending-ingest"` older than 90 days is `stale`. A staleness sweep (via `stale-cleanup` or a future `trail-audit` mode) surfaces stale seed files as "decide or retire" — the operator either ingests, declines, or deletes them. The 90d threshold matches `skill-archive`'s dormancy window; adjust if the fleet adopts a different trail-lifecycle doctrine.

**Who updates status**: the skill sets `pending-ingest` on creation and `superseded` on re-run (the skill detects the re-run itself — see the existing-file check in step 4). The operator (or an agent on operator confirmation) updates to `ingested` or `declined` — these require operator judgment about whether to act on the plans. A staleness sweep sets `stale`. The skill does not transition its own seed file to `ingested` or `declined` — those are operator-gated lifecycle transitions, consistent with the operator-gated ingest step.

---

## SITREP draft template

```
<timestamp_utc>	<canonical-identity>	all	SITREP	host=<machine> FOLLOWTHROUGH: <aar-operation> -- <N> plans from <M> recommendations; top: <top goal line>
```

**Zero-plan variant** (when §7 had 0 recommendations): omit the `top:` field entirely — there is no top goal line when there are 0 plans. Use:

```
<timestamp_utc>	<canonical-identity>	all	SITREP	host=<machine> FOLLOWTHROUGH: <aar-operation> -- 0 plans from 0 recommendations
```

Append `| WARN: <K> orphan improves` if the orphan check surfaced anything (an AAR with 0 recs but ≥1 Improve is itself a finding).

If any edge cases are present, append `| WARN: <counts by category>`. List only the categories present, count + category name, no narrative — the *why* lives in the seed file, not the bus line:

- `<K> orphan improves` — §6 Improves with no recommendation addressing them
- `<K> sharpened recs` — §7 recommendations that were vague but intent-preserving and rewritten before planning
- `<K> escalated recs` — §7 recommendations that were self-contradictory (intent-reversing) or question-shaped, and escalated to the operator instead of planned
- `<K> non-improve recs` — §7 recommendations that do not trace to any §6 Improve (bonus findings or scope anomalies)

Example: `| WARN: 1 orphan improve, 2 sharpened recs, 1 non-improve rec`

If no edge cases are present, omit the WARN clause entirely — clean 1:1 runs produce a bare SITREP line.

If a corrective addendum was found in step 1, append: `| ADDENDUM: plans built against corrected disposition (<brief>)`.

---

## Self-check template

```
## Self-check
| Step                                  | Status   | Receipt                              |
|---------------------------------------|----------|--------------------------------------|
| AAR located & §7 parsed               | YES/NO   | <count> recommendations found       |
| Corrective addendum checked           | YES/NO/NA| <addendum summary or "none found">  |
| Each recommendation elaborated        | YES/NO   | <count>/<total> blocks              |
| Each recommendation planned           | YES/NO   | <count>/<total> goal lines          |
| Escalated recs (intent-reversing/question-shaped) | YES/NO | <count> escalated to operator |
| Intent preservation verified (no sharpened rec reversed direction) | YES/NO/NA | <count> sharpened, <count> intent-reversals caught> |
| Escalated recs not silently planned  | YES/NO/NA | <count> escalated, <count> silently planned (should be 0)> |
| Orphan Improves flagged               | YES/NO   | <count> orphans                     |
| Seed file written                     | YES/NO   | <path>                              |
| SITREP drafted                        | YES/NO   | <text>                              |
| SITREP posted                         | YES/PENDING/NO | <timestamp> / pending approval / declined |

Status: PASS | PARTIAL | NONCONFORMING
```

PASS only if: every recommendation elaborated AND either planned or explicitly escalated, seed file written, orphans flagged, addendum checked, **intent preservation verified** (no sharpened rec reversed the original recommendation's direction), AND **escalated recs not silently planned** (every intent-reversing or question-shaped rec was escalated, not planned as if it were a normal rec). Escalated recommendations do not block PASS — escalation IS the correct handling for intent-reversing or question-shaped recs. SITREP posted may be PENDING (awaiting approval) without blocking PASS — the planning work is complete; the bus post is a separate operator-gated action.

The two intent-preservation rows are the internal adversarial review for self-serving sharpening. Without them, a run that silently reverses a recommendation's direction (e.g., sharpening "no tool use" into "permit tool use") would pass the self-check because "each recommendation planned" only verifies a goal line exists, not that the goal line preserves intent. The 5-reviewer review caught the v0.1.0 overreach; these rows catch it without reviewers. (Origin: v0.1.0 overreach on adr-gov-008 recs #2 and #5, caught by devin-reviewer Q2, not by the v0.1.0 self-check.)

---

## Output footer

End the run with this footer (mirrors `[aar]`):

```
---
Base120 Applied: <codes actually used — typically P6, IN17, IN20, RE16, DE7; only list ones you applied>
Evidence: <seed file path; AAR path; any receipts>
Bus: Y (<timestamp>) | N (declined) | N (unreachable: <reason>)
Plans seeded to goal-harness: Y (<count>) | N (seed file written at <path>, not ingested — operator-gated)
```

---

## Guardrails

- Do not fabricate AAR contents, recommendation text, or receipt paths. If you cannot see a field, say so.
- Do not skip a recommendation because it is vague — vagueness is a finding; surface it in the elaboration and propose a sharpened version. But distinguish three cases:
  - **Vague but intent-preserving**: sharpen it — make the existing intention concrete and verifiable without changing its direction. This is the default.
  - **Self-contradictory where the contradiction reverses intent** (e.g. a headline says "do X" and a note says "consider not-X"): do NOT pick a side. Surface both readings in the elaboration, produce a candidate goal line for each, mark each `DEVIATION-FROM-ORIGINAL-INTENT: operator-decision-required`, and escalate to the operator before writing either into the seed file. Reversing a recommendation's intent is a decision that belongs to the operator or AAR author, not to this skill.
  - **"Consider whether …" question, not an action**: do NOT answer the question by planning one branch. Surface the question, enumerate the candidate actions that would resolve it either way, and escalate to the operator to pick. A question is not a recommendation; planning it as if it were silently closes a decision the AAR author left open.
- Do not run `goal-harness.py seed` without operator approval. Producing the file is the skill's job; ingesting into the live queue is a fleet action.
- Do not post the SITREP without operator approval. Draft, present, post on confirmation.
- Do not claim `Bus: Y` without a real, host-tag-valid post. `Bus: N (unreachable)` is honest; `Bus: Y` without a post is fabrication.
- One block per recommendation, no merging. If two recommendations collapse into one plan, say so explicitly and note the merge — do not silently drop one.
- Keep the goal line to one sentence in the goal-selection shape. The `verified by` clause is non-negotiable — it is what makes a plan a goal instead of an intention.

## Skill Chains

### Mandatory

- None — this skill is self-contained.


| After completing... | Consider... |
|---------------------|-------------|
| `[aar-followthrough]` | `[goal-selection]` — to pick the top plan and start executing |
| `[aar-followthrough]` | `[find-work]` — to confirm no higher-priority live work supersedes the plans |
| `[aar]` | `[aar-followthrough]` — this skill, to close the loop |

## Authority

- **T1 (TRUSTED)**: Full access — elaborate, plan, write seed file, post SITREP on approval, seed goal-harness on approval
- **T2 (Active/High)**: Full access — same as T1
- **T3 (Medium)**: May run — elaborate + plan + write seed file; operator confirms before any bus post or goal-harness ingest
- **T4 (Probationary)**: May run — advisory only; produces the plan set in-chat, writes nothing, posts nothing
- **Operator**: Override any restriction
