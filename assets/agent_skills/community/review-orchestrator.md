---
name: review-orchestrator
description: Govern a remediation or merge-readiness review through explicit stages, proof bundles, and reviewer gates. Use this whenever the user asks for a review pipeline, pre-merge gate, merge authorization, proof bundle, remediation review campaign, or wants to know whether an artifact is actually ready to promote.
version: 0.1.0
execution-mode: advisory
argument-hint: "\"<artifact, PR, branch, or remediation item>\" [target gate]"
category: dev-tools
status: candidate
---

# Review Orchestrator

## Purpose

Use this skill to turn a review request into an explicit gate sequence instead
of an improvised opinion.

The orchestrator does not replace existing review skills. It routes work
through them in order:

1. remediation candidate
2. self-review
3. poly-agent review
4. adversarial review
5. merge readiness

The output is a governed recommendation with a proof bundle, not a vague
"looks good."

## Context Gathering

Before executing this skill, gather the following context:

- Detect current platform: `python -c "import platform; print(platform.system())"`
- Identify the reviewed artifact: PR URL, branch, commit range, file path, or
  document path.
- Pin the reviewed state: current branch, exact head SHA, and intended base ref.
- Determine whether the target is advisory-only or promotion-sensitive.
- Determine whether non-author review is required by local repo rules.

If the task includes merge-state claims, remote parity claims, or "already on
main" claims, gather remote-backed proof first:

- `git fetch origin`
- `git log <base-ref>..HEAD`
- `git log HEAD..<base-ref>`

Use the correct remote base ref for the repo. Do not assume `origin/main` if
the default branch is different.

## Required Inputs

Collect or reconstruct these inputs before moving past remediation:

- artifact identifier
- artifact state under review
- target repo or surface
- scope in / scope out
- current gate or requested end state
- validation intent
- review route already satisfied, if any
- target class or authorization posture when applicable

Mark missing inputs as `MISSING`. Do not invent them.

## Stage Model

| Stage | Primary question | Minimum bar to advance |
|---|---|---|
| Remediation | What changed, and what is being claimed? | scoped artifact, pinned state, validation intent |
| Self-Review | Is the change locally coherent? | `[self-review]` complete, no blocking HIGH finding |
| Poly-Agent | Does the change hold across multiple technical lenses? | independent lane outputs reconciled through `[cross-agent]` |
| Adversarial | Can a hostile reviewer break the claim? | blocking findings fixed or explicitly held |
| Merge Readiness | Do we have enough verified proof to promote? | reviewed SHA current, proof bundle complete, review gate satisfied |

## Workflow

### 1. Remediation Candidate

Start by pinning exactly what is under review.

Required facts:

- artifact identifier
- exact reviewed state
- defect, claim, or target behavior
- validation surface
- current owner

If the artifact state is stale, ambiguous, or not pinned, stop and return
`BLOCKED`.

### 2. Self-Review

Route to `[self-review]` when the author needs to check local coherence before
asking for promotion.

Carry forward:

- score and letter grade
- findings with severities
- explicit residual risks
- whether the artifact should return to remediation immediately

Same-session self-review is useful evidence. It is not independent non-author
review.

### 3. Poly-Agent Review

Use `[poly-agent]` when the user requests multiple lenses, dialectical review,
or multi-agent validation, or when the artifact is consequential enough that a
single review lane is too thin.

Rules:

- preserve lane independence before synthesis
- keep prompts and outputs durable
- route lane synthesis through `[cross-agent]`
- do not collapse unresolved disagreements into false consensus

If the review topology is specifically thesis -> antithesis -> synthesis, use
`[dialectical-analysis]` inside the poly-agent stage, then route the outputs to
`[cross-agent]`.

### 4. Adversarial Review

Adversarial review asks "what breaks?" not "what did we mean?"

Use the lightest adversarial posture that matches the risk:

- narrow code or docs claim: explicit hostile-use review by a non-author lane
- security, governance, or protected-surface claim: `[wargame]`, `[red-team-mode]`,
  or another repo-approved adversarial review mode

For high-stakes cyber claims, do not treat red-only output as actionable. The
review packet must capture:

- red artifact
- blue remediation / detection artifact
- purple reconciliation

#### Credential-leak vector hunt (required when PR touches credential access patterns)

If the PR touches credential access patterns — any CLI example, code
snippet, or documentation showing how secrets are retrieved, stored,
piped, or suppressed — perform an **active adversarial credential-leak
vector hunt**. Exec-level verification ("the examples work as written")
is not a substitute for this hunt: a working example can still leak.

Examine every CLI example and code snippet for:

1. **Fields that could echo secrets**: `notesPlain`, `credential`,
   `private_key`, `password`, `totp`, `username`, and any field
   containing a secret value. Check whether the example prints,
   echoes, or previews any of these to stdout/transcript.
2. **Truncation as false safety**: `head -c N`, `Substring(0, N)`,
   `[:N]`, or any "preview first N chars" pattern on a Tier 2 field.
   Most secrets (API keys, tokens) fit in 200 chars, so truncation
   does not protect against leakage. Flag any preview that prints
   secret-bearing fields to stdout.
3. **Stderr handling**: verify `2>/dev/null` (bash) or `2>$null`
   (PowerShell) is present on every `op item get` / credential
   retrieval, since `op` may write item titles or vault names to
   stderr. Check for missing or inconsistent stderr suppression.
4. **Variable capture patterns**: verify credentials are captured in
   variables or env vars, never printed directly. Check for `echo`,
   `Write-Output`, `print()`, or bare evaluation of a credential
   variable.
5. **Fix-introduced vectors**: if the PR is a revision of an earlier
   review, check whether a fix for one vector introduced a new one
   (e.g., fixing `--fields notes` to `--fields notesPlain` is correct,
   but if the same example previews notesPlain to stdout, the fix
   introduced a new leak).

For each vector found, report: the exact line, the field involved, the
leak mechanism (stdout print, truncation, stderr), and the corrected
pattern. Do not mark the adversarial stage PASS if any credential-leak
vector is unfixed in a credential-access PR.

### 5. Merge Readiness

Only declare merge readiness when the current artifact state still matches the
reviewed state and the promotion evidence is current.

Verify:

- current branch and head SHA
- reviewed SHA still current
- check status snapshot
- review route snapshot
- unresolved findings snapshot
- metrics verification snapshot when counts or aggregates are cited
- authorization state snapshot when required by the target class

Do not substitute agent-reported claims for verified proof at the final gate.

## Proof Bundle Contract

Every closeout must include, at minimum:

- `artifact`
- `artifact_state`
- `target`
- `target_class`
- `scope_in`
- `scope_out`
- `authorization_manifest_path` or `not-required`
- `proof_source`
- `proof`
- `validation_results`
- `evidence_artifacts`
- `residual_risks`
- `promotion_recommendation`
- `next_owner`

Review closeout must also include:

- `verdict`
- `findings`
- `review_scope`
- `reviewer_type`

Mark each important claim as one of:

- `VERIFIED`
- `AGENT_REPORTED`
- `MISSING`

`AGENT_REPORTED` can inform routing. It does not satisfy final promotion by
itself.

## Required Git Proof For Branch-State Claims

When the review conclusion depends on whether a fix is already on the remote
base branch, include all of these in the proof bundle:

- current branch
- current head SHA
- remote base ref used
- result of `git fetch origin`
- result summary for `git log <base-ref>..HEAD`
- result summary for `git log HEAD..<base-ref>`

Claims such as "already merged" or "unique to this branch" are invalid without
this proof.

## Output Format

Use this structure unless the user requested a stricter local template:

```markdown
Review Orchestrator | <artifact or topic>

Scope
- Artifact:
- Reviewed state:
- Base ref:
- Target gate:
- Scope in:
- Scope out:

Stage Status
| Stage | Status | Key evidence | Blocking items |
|---|---|---|---|
| Remediation | PASS / HOLD / BLOCKED | <proof> | <items> |
| Self-Review | PASS / HOLD / BLOCKED | <proof> | <items> |
| Poly-Agent | PASS / HOLD / BLOCKED / N/A | <proof> | <items> |
| Adversarial | PASS / HOLD / BLOCKED / N/A | <proof> | <items> |
| Merge Readiness | PASS / HOLD / BLOCKED | <proof> | <items> |

Findings
- P1/P2/P3: <issue, impact, correction>

Proof Bundle
- artifact:
- artifact_state:
- target:
- target_class:
- scope_in:
- scope_out:
- authorization_manifest_path:
- proof_source:
- proof:
- validation_results:
- evidence_artifacts:
- residual_risks:
- verdict:
- findings:
- promotion_recommendation:
- next_owner:

Gate Decision
- Recommendation:
- Human approval required:
- Non-author review satisfied:
- Remaining blocker:
```

## Quality Rules

- Do not declare merge readiness on stale artifact state.
- Do not silently downgrade unresolved HIGH findings.
- Do not treat same-session synthesis as independent non-author review unless
  the Human explicitly waives that gate.
- Do not cite test totals, check counts, or campaign aggregates as verified
  without the command or artifact that produced them.
- Do not widen scope from the reviewed artifact into unrelated dirty-tree work.
- Prefer a durable hold or blocked recommendation over a weak approval.

## Skill Chains

| After completing... | Consider... |
|---------------------|-------------|
| `[review-orchestrator]` remediation stage only | `[self-review]` for the local coherence gate |
| `[review-orchestrator]` with multi-lens or dialectical needs | `[poly-agent]`, then `[cross-agent]` for synthesis |
| `[review-orchestrator]` on security, governance, or protected-surface claims | `[wargame]` if adversarial stress testing is required |
| `[review-orchestrator]` after a complex remediation campaign | `[aar]` for durable process corrections |
