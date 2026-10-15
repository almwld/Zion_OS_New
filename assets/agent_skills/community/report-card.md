---
name: report-card
description: >
  Force a rigorous, evidence-backed self-assessment after completing a body of work.
  The agent audits its own claims by checking each one against actual tool output,
  file contents, command results, or external sources — then produces a report card
  with letter grades and per-claim verification status. Use this skill whenever the
  operator asks for a "report card", "self-audit", "how did you do", "review your
  own work", "grade yourself", or when a multi-step task (4+ steps) has been declared
  complete and the agent has made verification claims (e.g., "verified", "tested",
  "compiled successfully", "consensus reached", "all references checked"). Also
  trigger when the operator expresses skepticism about the agent's self-reported
  success ("are you sure?", "did you actually verify that?", "look for gaps").
version: 0.1.0
execution-mode: advisory
argument-hint: "[optional operation name]"
category: fleet-ops
status: candidate
providers:
  optional: [eval-spec(md-scored)]
---

# Report Card

## Why This Skill Exists

Agents have a systematic bias: they treat task completion as the success criterion
rather than task verification. "I added the references" is treated as equivalent to
"I added the references correctly." "It compiled" is treated as equivalent to "the
output is correct." This skill forces the agent to close that gap by checking every
self-reported claim against actual evidence before assigning a grade.

The pattern this skill counteracts: an agent completes 6 tasks quickly, declares
success, and the operator later discovers that citations were never verified against
external sources, a compiled PDF was never opened, a "consensus" was inferred rather
than re-verified, and a "fix" only addressed 1 of 3 instances of the problem. Every
one of those failures is discoverable at the time — the agent simply chose not to
look.

## Context Gathering

Before executing this skill, gather the following context:
- Detect current platform: `python -c "import platform; print(platform.system())"`
- If Windows: use PowerShell examples (`powershell` or `pwsh`)
- If macOS/Linux: use bash examples (`bash`)

## Process

### Step 1: Enumerate all claims

List every assertion the agent made during the session about what was accomplished,
verified, or confirmed. Include both explicit claims ("all citations verified") and
implicit ones ("the PDF is ready" implies the PDF content was checked).

Sources to mine for claims:
- The agent's own output text (messages to the operator)
- Todo lists and their completion status
- AAR or SITREP documents produced during the session
- Any "summary" or "consensus" statements

For each claim, record:
- The claim text
- Where it was made (message, AAR, todo, etc.)
- What evidence would be needed to verify it
- Whether that evidence was actually gathered during the session

### Step 2: Verify each claim against evidence

For each claim, attempt to find supporting evidence using the tools available. Do
not trust the agent's prior assertions — re-check them independently.

**Verification methods by claim type:**

| Claim type | How to verify |
|---|---|
| "File X was created/modified" | `read` the file, check content |
| "Compiled successfully" | Check exit code AND read the output file (extract text, grep for key content) |
| "All N references verified" | For each reference: `webfetch` or `web_search` the source, confirm it exists and matches |
| "Consensus reached" | Re-read the actual verdicts; check if re-verification was done after fixes |
| "No changes to section X" | `git diff` the file, read the full diff |
| "Files synced to remote" | Check file sizes AND content (checksum or diff) |
| "Test passed" | Re-run the test, or read test output |
| "Fix applied to all instances" | `grep` for the pattern across all files, confirm zero remaining instances |
| "Citation [N] is accurate" | `webfetch` the cited source, compare author/title/year against the .bib entry |

If a claim cannot be verified because the evidence is no longer available (e.g.,
a subagent's output was not saved), mark it UNVERIFIABLE rather than assuming it
was correct.

### Step 3: Classify each claim

Assign one of four status codes to each claim:

- **VERIFIED**: The claim is backed by evidence the agent can point to right now.
  The tool output, file content, or command result confirms the claim is true.
- **UNVERIFIED**: The agent made the claim but did not gather the evidence to
  support it. The claim might be true, but there is no proof. This is the most
  common failure mode.
- **FALSE**: The claim is contradicted by evidence. The agent said X, but
  checking shows not-X. This is the most serious finding.
- **UNVERIFIABLE**: The evidence needed to check the claim is no longer available
  (subagent output not saved, external service down, etc.). Distinguish from
  UNVERIFIED — UNVERIFIABLE means we tried and couldn't, UNVERIFIED means we
  didn't try.

### Step 4: Grade by dimension

Assess the work across these dimensions, assigning a letter grade (A/B/C/D/F) to
each. The grade should reflect the verification status of claims in that dimension,
not the agent's subjective feeling about how well it went.

| Dimension | What it measures |
|---|---|
| Task completion | Were all requested tasks attempted? (This is usually A — agents are good at attempting tasks.) |
| Task verification | Were the outputs of those tasks checked against evidence? (This is usually where the grade drops.) |
| Claim integrity | Did the agent make false or unverified claims? How many? How serious? |
| Error correction | When errors were found (by reviewers, operator, or self), were they fully fixed or partially fixed? |
| Process rigor | Did the agent follow its own stated process? (e.g., if it wrote a consensus rule, did it actually meet the criteria?) |
| Git hygiene | Were changes committed? Is there a recoverable history? |
| Self-awareness | Did the agent proactively flag gaps, or only after being challenged? |

An "A" means claims are verified with evidence the agent can produce right now.
A "B" means most claims are verified, with minor gaps. A "C" means significant
unverified claims but no false claims. A "D" means false claims or systemic
verification failures. An "F" means fabricated evidence or multiple false claims.

### Step 5: Produce the report card

Use this exact format:

```
## Report Card: <agent> — <operation name or session description>

**Evaluator**: Self (note: self-assessment is inherently biased — see Limitations)
**Date**: <YYYY-MM-DD>
**Session scope**: <1-line description>

---

### Grades

| Dimension | Grade | Notes |
|---|---|---|
| Task completion | <A-F> | <1-2 sentences with specific evidence> |
| Task verification | <A-F> | <1-2 sentences with specific evidence> |
| Claim integrity | <A-F> | <1-2 sentences with specific evidence> |
| Error correction | <A-F> | <1-2 sentences with specific evidence> |
| Process rigor | <A-F> | <1-2 sentences with specific evidence> |
| Git hygiene | <A-F> | <1-2 sentences with specific evidence> |
| Self-awareness | <A-F> | <1-2 sentences with specific evidence> |
| Overall | <A+/A/A-/B+/B/B-/C+/C/C-/D+/D/D-/F> | <1 sentence summary> |

---

### Per-Claim Verification

| # | Claim | Status | Evidence |
|---|---|---|---|
| 1 | <claim text> | VERIFIED / UNVERIFIED / FALSE / UNVERIFIABLE | <what was checked and what was found> |
| 2 | <claim text> | ... | ... |

---

### Detailed Assessment

#### <Dimension 1> — <grade>
<2-4 sentences explaining the grade, citing specific claims and evidence>

#### <Dimension 2> — <grade>
...

---

### Pattern Analysis

<1-2 paragraphs identifying the dominant pattern across all dimensions.
What was the systematic failure mode? Was it throughput-over-verification,
fixing-symptoms-not-root-causes, declaring-success-without-proof, or
something else?>

---

### What Would Change the Grade

| Current | Action needed | Target grade |
|---|---|---|
| <F in dimension> | <specific verification step> | <B> |
| <D in dimension> | <specific fix> | <B> |

---

### Honest One-Liner

<One sentence that captures the truth about this session's quality,
without softening. If the work was good, say so. If it wasn't, say that.>
```

### Step 6: State limitations

Every report card must include this section, because self-assessment is inherently
biased:

```
### Limitations

This report card is a self-assessment. The agent is grading its own work, which
creates a conflict of interest. Specific biases to consider:
- The agent may be more lenient on itself than an external reviewer would be
- The agent may not identify all gaps (you can't audit what you don't notice)
- The agent's verification tools are the same tools that produced the work —
  if a tool has a systematic blind spot, the audit will share it
- An external reviewer (different agent, different model, different session)
  would likely find additional issues not captured here
```

## Auto-Suggestion Mode

When a multi-step task (4+ todo items) is declared complete, the agent should
proactively offer: "I've completed the tasks. Would you like me to run a report
card on this work before we move on?"

This is not mandatory — the operator may not want it for simple tasks. But for
tasks involving verification claims, compilation, peer review, external citations,
or multi-agent consensus, the agent should default to offering.

Do not auto-run the full report card without operator consent — it is time-consuming
and the operator may not need it. Just offer.

## What Not To Do

- Do not soften failures. If a claim is FALSE, say FALSE. "Partially verified" is
  not a status code. "Mostly correct" is not a grade.
- Do not skip verification steps because "the agent already checked during the
  session." The whole point is that the agent's prior checks may have been
  insufficient. Re-check.
- Do not give an overall grade higher than any individual dimension grade. If any
  dimension is F, the overall cannot be higher than D.
- Do not count "I would have verified if asked" as evidence. The agent had the
  tools and chose not to use them.
- Do not conflate "the task was attempted" with "the task was completed correctly."
  These are different claims with different evidence requirements.
- Do not produce a report card with all A's. If everything is perfect, dig harder.
  A report card with no findings is a report card that wasn't done rigorously.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[report-card]` | `[aar]` for a formal After Action Report with the gaps found |
| `[report-card]` | `[end-session]` to close out with known gaps documented |
