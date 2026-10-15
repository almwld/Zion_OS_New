---
name: daily-grade
description: Grade the operator's day on a 100-point rubric that scores meaningful state change, not activity. Declares day mode (Sell/Build/Operate/Recover), scores six dimensions, applies anti-gaming caps, separates mood from performance, and logs the entry to the Cognitive Ledger. Use when the user asks to grade today, review the day, score performance, or run end-of-day accountability.
argument-hint: "[today | <date> | trend]"
version: 0.1.0
execution-mode: advisory
triggers:
  - daily grade
status: imported
provenance:
  source_surface: project
  original_version: 0.1.0
  import_date: 2026-08-10
---
# [daily-grade]

> Did I advance the mission, protect continuity, and leave the operating system stronger than I found it?

Daily performance rubric for the operator. Grades **meaningful state change**, not activity, hours, mood, or raw output volume. The full rubric, anti-gaming rules, caps, and trial protocol live in `~/.agents/playbooks/daily-grade.md` — that file is the canonical source of truth. This skill is the agent-invokable wrapper.

**Run:** end of day (after `/gn` or before `/end-session`); any time the user asks "how did today go?", "grade today", "score the day"; weekly trend review with `trend`.

## Workflow

1. **Declare (or confirm) the day mode.**
   - Sell / Build / Operate / Recover
   - If the user did not declare at start of day, ask what mode the day was actually operated in. Do not retroactively relabel an avoidant day as "Recover."

2. **Gather evidence before scoring.**
   - Pull today's bus messages from the operator (`human` posts + agent receipts addressed to `human` or `all`).
   - Pull today's git commits across active repos.
   - Pull today's ledger entries.
   - Pull calendar / outreach / pipeline movement if available.
   - Separate confirmed facts from inferred judgments. Do not score intention when execution evidence exists.

3. **Score the six dimensions.** Use the per-dimension guidance (0/25/50/75/100% of weight):
   - Primary mission result: / 30
   - Economic continuity: / 20
   - Shipped proof: / 15
   - Leverage and closure: / 15
   - Human performance: / 15
   - Evidence and calibration: / 5

4. **Apply anti-gaming rules.** See playbook §4. In particular:
   - No receipt → reduced credit
   - No double-counting one artifact across three categories
   - Volume ≠ value
   - Blocked work can still score well if surfaced early with evidence and a next move

5. **Apply caps.** See playbook §5. The numerical total must not hide foundational failures:
   - No meaningful verified state change → max C+
   - Avoided declared primary commitment without legitimate change → max C
   - Significant preventable operational damage → max D
   - Misrepresented completion/evidence/outcomes → automatic F
   - Cash-flow-constrained phase, no direct economic action on an ordinary weekday → max B (unless declared recovery or overriding critical incident)

6. **Convert to letter grade.** See playbook §3.
   - 95–100 A+, 90–94 A, 85–89 B+, 80–84 B, 75–79 C+, 70–74 C, 60–69 D, <60 F
   - A B is a genuinely good day. An A requires consequential movement, not effort.

7. **Record mood separately.** Do not blend into the grade.
   - Energy 1–5, Mood 1–5, Load 1–5
   - Surface the pattern read (high perf + low energy = unsustainable, etc.)

8. **Write the entry.**
   - Emit the filled template (below) to chat.
   - Persist to the Cognitive Ledger via `[ledger]` with tag `daily-grade` (only with operator approval — ledger writes are operator-gated).
   - If operator declines ledger write, still emit the entry to chat.

9. **Surface tomorrow's first admissible move.** This is the most important field. It must be a concrete, evidence-supported action that would be admissible under tomorrow's likely constraints — not a wish.

## Trend Mode (`trend`)

When invoked with `trend` (or when the user asks about the seven-day pattern):

1. Query the ledger for the last 7–14 `daily-grade` entries.
2. Compute: average score, grade distribution, energy trend, repeated drift causes, shipped-proof count, economic-move count.
3. Compare against the trial targets (playbook §8): weekly avg ≥ 82, no dishonest F days, ≥ 1 economic move per weekday, ≥ 3 shipped proofs/week, no 3-day energy decline without intervention.
4. Report gaps and the single highest-leverage adjustment for the coming week.

If fewer than 3 entries exist, report "insufficient data — continue trial" and do not fabricate a trend.

## Output Format

```text
DAILY GRADE | <date>
═══════════════════════════════
DAY MODE: <Sell / Build / Operate / Recover>

PRIMARY OUTCOME: <one line>
ECONOMIC MOVE: <one line, or "none — cap applies">
CAPACITY FLOOR: <one line>

PRIMARY MISSION RESULT:   __ / 30  — <rationale>
ECONOMIC CONTINUITY:      __ / 20  — <rationale>
SHIPPED PROOF:            __ / 15  — <rationale>
LEVERAGE AND CLOSURE:     __ / 15  — <rationale>
HUMAN PERFORMANCE:        __ / 15  — <rationale>
EVIDENCE AND CALIBRATION: __ / 5   — <rationale>

RAW SCORE:        __ / 100
CAP OR PENALTY:   <none / which cap, why>
FINAL GRADE:      <letter> (__ / 100)

ENERGY: __ / 5
MOOD:   __ / 5
LOAD:   __ / 5
Pattern read: <sustainable / avoidance / recovery / repeatable>

RECEIPTS:
- <bus msg ref / commit sha / ledger entry / artifact path>
- <...>

WHAT ACTUALLY CHANGED? <one honest sentence>
WHERE DID I DRIFT?     <one honest sentence, or "nowhere">
TOMORROW'S FIRST ADMISSIBLE MOVE: <one concrete action>
```

## Honesty Floor

- A truthful C is more valuable than a fabricated A.
- If the operator pushes for a higher grade than evidence supports, state the gap explicitly and hold the cap. Do not capitulate.
- If evidence is thin, say so and score down on Evidence and Calibration — do not backfill with inferred credit.
- This skill is governed by `[truth-mode]` (Constitutional Tier 0 epistemic honesty floor). No mode overrides it.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[daily-grade]` end of day | `[gn]` for the personal close ritual, then `[end-session]` for ops closeout |
| `[daily-grade]` score < 70 | `[reframe]` on tomorrow's primary commitment before sleep |
| `[daily-grade]` 3-day energy decline | flag to operator; do not auto-intervene |
| `[daily-grade]` trend | `[weekly-review]` or `[weekly-plan]` for forward allocation |
| `[daily-grade]` recovery day scored A | `[hrsi-checkin]` to confirm capacity was actually restored |
| `[daily-grade]` economic cap applied | `[pipeline-review]` or `[follow-up]` to surface next economic move |
