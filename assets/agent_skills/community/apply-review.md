---
name: apply-review
description: Review application materials (resume, cover letter, LinkedIn copy, portfolio one-pager, outreach email, any first-person professional artifact) against memory + fabrication checks before they get sent or published in Reuben's name. Catches the v3-style fabricated-employment failure mode at the gate.
version: 0.1.0
execution-mode: advisory
argument-hint: "[file or directory path | empty to scan default locations]"
category: governance-compliance
status: candidate
---
# [apply-review]

**Purpose**: Pre-send integrity check for any document going out in Reuben's name as a job applicant or professional candidate. Built 2026-05-13 after opencode v3 of the resume contained fabricated employment history that nearly went out to 5 Tier-1 targets.

This skill is `advisory` only. It does NOT edit files. It produces a P0/P1/P2/P3 finding list + a SEND / HOLD / FLAGGED verdict. The human (or a follow-up `remedial` skill) does the fixes.

---

## When to invoke

- Before sending any resume, cover letter, LinkedIn copy, portfolio one-pager, dev case study, outreach email, or interview prep doc
- After ANY agent (claude-code, codex, opencode, gemini, devin) generates first-person professional material on Reuben's behalf
- After a multi-version document evolution (v2 → v3 → v4) — verify fabrications didn't accumulate across versions
- Before merging a PR that touches `hummbl-production/web/`, `hummbl-research/docs/`, or any application-bound artifact
- As a chain after `[case-study]`, `[blog-draft]`, `[social-post]`, `[landing-page-copy]`, or any agent-generated first-person professional output

---

## Arguments

```
[apply-review]                              # scan default locations
[apply-review] $HOME/Downloads/    # review every applicable file in dir
[apply-review] output/target.md          # review one file
[apply-review] path/file1.md path/file2.md  # review multiple specific files
```

**Default scan locations** (when no args):
- `$HOME/Downloads/` — recent transferred application artifacts
- `/work/active/hummbl-production/web/` — public web copy
- `/work/active/hummbl-research/docs/` — research docs that may surface in applications
- `/work/active/coaching/` — coaching materials (case studies may apply)

File types reviewed: `.md`, `.txt`, `.docx` (if pandoc available), `.pdf` (if pdftotext available). Skip binary blobs and dirs starting with `_` or `.`.

---

## Memory cross-check sources (authoritative for "is this true")

Read in this order; conflicts resolve to operator-direct chat > most-recent memory > older memory. Resolve the runtime memory dir first: `eval "$("$HOME/.agents/scripts/resolve-memory.sh")"` → `$RUNTIME_MEM` (your runtime's pins) and `$FLEET_MEM` (fleet canonical).

1. `$RUNTIME_MEM/user_background.md` — biographical authoritative pin (school, certs, career arc)
2. `$RUNTIME_MEM/project_pre_hummbl_arc.md` — pre-HUMMBL timeline with Drive file IDs
3. `$RUNTIME_MEM/feedback_hallucinated_employment_history.md` — the rule that no pre-2024 CS/eng roles exist
4. `$RUNTIME_MEM/user_profile.md` — machines, devices, current role context
5. `$RUNTIME_MEM/project_hummbl_legal.md` — HUMMBL LLC GA incorporation
6. `$RUNTIME_MEM/feedback_hummbl_governance_namespace.md` — Founder Mode app vs internal ops platform distinction
7. `$RUNTIME_MEM/feedback_agent_grounding_protocol.md` — operator-state context

> **NOTE:** Several pin files listed above are currently phantom (not found in any memory dir). Verify existence before citing; do not assume content. The fleet canonical `$FLEET_MEM` covers overlapping material.

If a claim in the reviewed doc cannot be matched to any of these, flag it. The doc may still be sendable, but the gap should be visible to the operator before send.

---

## Checks performed

### Tier 0 — Fabrication scan (P0 send-blockers)

- **Bracketed placeholders**: `[Company Name]`, `[N projects]`, `[Date]`, `[School Name]`, etc. Any unfilled bracket = P0 send-blocker.
- **Employment history not in memory**: any job title / company / role period not present in `user_background.md` or `project_pre_hummbl_arc.md`. Per `feedback_hallucinated_employment_history.md`, Reuben has NO pre-2024 CS/engineering roles. Flag any pre-2024 engineering title.
- **Quantitative claims with no source**: any number (test count, module count, year count, customer count, revenue figure) that doesn't trace to a verifiable artifact. Mark as ESTIMATE if it's a defensible rough number; mark as P0 if it's a specific count with no source.
- **Identity drift**: school name, degree, certifications, location, email, links — must match `user_background.md`.

### Tier 1 — Integrity (P1 significant)

- **Timing stretches**: "two years" when actual is <18 months, "over a decade" when actual is ~9, etc. Cross-check every "N years" / "N months" against confirmed dates in memory.
- **Title inflation**: claiming "Senior" / "Lead" / "Principal" / "Founding" where the operator's actual role doesn't carry that title.
- **Capability claims that imply experience he doesn't have**: "Led teams of N" / "Mentored N engineers" / "Owned platform with N users" — flag any team-leadership or scale claim not grounded in actual HUMMBL/BDE/Memscore receipts.
- **Self-attributed credentials he doesn't hold**: any degree, certification, or affiliation not in `user_background.md`.

### Tier 2 — Quality (P2 improvements)

- **Cover-letter litmus**: paragraph 1 must contain at least one sentence specific to the target company (researched fact, recent move, named product). If swapping company name preserves meaning, paragraph 1 is generic. Flag P2.
- **Voice consistency**: resume and cover letter should sound like the same author. Resume language should be keyword-dense / ATS-friendly; cover letter should be narrative. Mixed registers = P2.
- **Headline-to-role alignment**: resume headline should match the exact job title phrase in the posting. Stale headline carried across multiple applications = P2.
- **Founder Mode namespace collision**: per `feedback_hummbl_governance_namespace.md`, "Founder Mode" (consumer app, R2) ≠ `hummbl-governance` (internal ops platform, R1) ≠ HUMMBL governance work. Conflating them in a cover letter or LinkedIn copy = P2.
- **Missing concrete next-step proposal**: cover letter without a "first 90 days I would..." paragraph reads as weaker than one with it.

### Tier 3 — Polish (P3 nits)

- **ATS hygiene** (resume only): tables, multi-column layouts, headers/footers, custom fonts, graphics. Detectable via markdown structure or .docx XML.
- **Typos / formatting**: bracket-style placeholders left in as nits, smart quotes vs straight quotes, em-dash vs hyphen consistency.
- **Length**: resume >2 pages OR cover letter >400 words = consider tightening.
- **Bracketed `[Date]` / `[City]` fields filled but not formatted consistently** across docs.

---

## Execution flow

1. **Resolve targets**: parse arguments OR scan default locations. List the files that will be reviewed in the output header.
2. **Load memory sources**: read the 7 memory files above into context.
3. **Read each target file** in full.
4. **Run all 4 tiers of checks** per file.
5. **Aggregate findings** into a single P0/P1/P2/P3 list per file + overall verdict.
6. **Generate verdict**:
   - **SEND** = zero P0 + zero P1
   - **HOLD** = any P0 (send-blocking; operator must address)
   - **FLAGGED** = zero P0 but at least one P1 (operator decides whether to send anyway)
7. **Output**: structured per the template below. Suggest specific edits where useful. Do NOT edit files.
8. **Chain**: if FLAGGED or HOLD, suggest the next action (`[edit]` the file directly, or invoke a `remedial`-mode skill).

---

## Output template

```
[apply-review] | <ISO timestamp UTC>
══════════════════════════════════════════

## Files reviewed
- <path1> (<file size>, <line count>)
- <path2>
...

## Verdict: SEND | HOLD | FLAGGED

## Findings

### P0 — send-blockers
- [<file>:<line>] <finding> | <evidence: memory file or counter-claim> | <suggested fix>
- (or: "none")

### P1 — significant integrity
- [<file>:<line>] <finding> | <evidence> | <suggested fix>

### P2 — improvements
- [<file>:<line>] <finding> | <suggested fix>

### P3 — nits
- [<file>:<line>] <finding>

## Memory cross-check summary
- user_background.md: <matched | drift detected | gap detected>
- project_pre_hummbl_arc.md: <matched | drift | gap>
- (per-source line)

## Per-document verdict
- <file1>: SEND | HOLD | FLAGGED (N P0, N P1, N P2, N P3)
- <file2>: ...

## Suggested next action
- If SEND: proceed with submission. Optional chain: `[case-study-verify]` for marketing artifacts.
- If FLAGGED: operator review the P1 list, decide accept-or-fix per finding, then re-invoke `[apply-review]` after edits.
- If HOLD: operator must address every P0 before any send. Suggested edits provided above. Re-invoke after edits.

## Bus
- Post STATUS naming the verdict + file list + finding counts so future sessions inherit the review outcome.
```

---

## Bus integration

After review completes, post a STATUS to the bus naming the verdict + file list + finding counts. This makes the review outcome durable across sessions and other agents can defer to it.

Post STATUS to the bus with the review verdict.
```
Type: STATUS
To: all
Message: [lane=ops/<agent>/apply-review-<date>] [apply-review] verdict=<SEND|HOLD|FLAGGED> on <N> files. P0=<n> P1=<n> P2=<n> P3=<n>. Files: <list>.
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

---

## Cross-references

- `feedback_hallucinated_employment_history.md` — the rule this skill enforces
- `user_background.md` — the authoritative biographical pin
- `case-study-verify` skill — adjacent: pre-publish verification for case studies
- `content-review` skill — adjacent: outbound content (blog, social, one-pager) review
- `hallucination-check` skill — adjacent: cross-reference LLM output against source docs

## Origin

2026-05-13: opencode-generated `RESUME_MASTER_v3.md` contained fabricated "Senior Engineer / Tech Lead" + "Additional Role" blocks. A claude-code session asked the operator to retro-fill the bracketed placeholders, treating fabrication as a data gap. Operator pushed back — "I have never had a role related to computer science or engineering ever." Without this skill, the same failure mode could have shipped the resume to 5 Tier-1 targets under his name. This skill is the gate that catches it.
