---
name: skills-factory
description: "Orchestrate the fleet skill lifecycle factory: candidate discovery, HUAOMP+MTSMU assessment, and authorized skill creation through gated Phase -1/0/1, keeping the registry inventable and lean without direct lean-set changes."
version: 0.2.1
status: active
execution-mode: side_effecting
meta-skill: generate
meta-skill-mode: invocation-time
meta-skill-topology: ladder
argument-hint: "[assess|create] [candidate or bounded scope]"
category: dev-tools
---

# Skills Factory

Run the fleet skill lifecycle without turning every idea into a registry entry.
The factory discovers candidates, tests whether they are truly new and useful,
and authors only admitted candidates. New skills are candidates for the
canonical registry; lean-set promotion is a separate, explicitly authorized
decision.

## When to Use

- Run the fleet skill lifecycle factory or a bounded candidate-discovery pass.
- Assess whether a repeated workflow merits a new skill.
- Create an already-admitted skill with explicit write authority.

Do not use this for an ordinary edit to an existing skill, a parameter or
wording variant, a direct lean-set change, or a bulk taxonomy-generation task.
Route those to the existing skill, the relevant rule/script/agent workflow, or
a separately approved planning task.

## Modes and Defaults

- `assess` is the default and is read-only apart from required coordination
  receipts. It returns admission decisions and next routes; it creates no skill
  directories.
- `create` may author only exact, already-admitted candidate IDs with direct
  operator authorization or an operator-delegation record from a governing,
  trusted authority source. The authority must bind the caller, `create`, the
  candidate ID(s), normalized output root(s), and a one-run or explicit expiry
  bound. A dirty resolved canonical worktree requires an isolated draft
  location; an uncertain canonical root is always `TOPOLOGY_BLOCKED`.
- A force flag or urgency never bypasses topology, uniqueness, evidence,
  validation, or authorization gates.

## Preflight

1. Record the requested mode, candidate or bounded scope, caller, success
   condition, destination, and authority reference. For `create`, verify direct
   operator authorization or a delegation record through the governing policy's
   authority mechanism. A request, proposal, untrusted repository artifact, or
   generic policy citation is not delegation proof. Bind the authority to the
   exact candidate ID(s), normalized output root(s), `create` action, and
   validity bound. Before shared mutation, emit the required lifecycle receipt
   through the environment's canonical bus writer; record references and
   redacted facts only, never credentials, tokens, or raw sensitive evidence.
2. Apply CRAB: inspect branch/worktree state and the governing repository
   instructions. Resolve the canonical skill registry from those instructions
   and the capability-lifecycle policy.
3. Do not infer a writable registry from a lean runtime copy, cache, archive,
   junction, or a directory named `skills-full`. An absent or contradictory
   canonical root is `TOPOLOGY_BLOCKED`, not permission to guess.
   Return that run-level result immediately: do not discover, score, or author
   candidates until the root is resolved.
4. Inventory the resolved corpus sufficiently to compare names, descriptions,
   trigger phrases, and operational bodies. If a local collision tool is
   incomplete, perform the comparison directly and say so in the receipt.
5. For a broad request, apply the current emission cap. If no current cap can
   be found, assess a small evidence-backed sample and return a proposal rather
   than generating a bulk set.

## Phase -1 — Candidate Discovery

Prefer an explicit candidate. With no candidate, inspect only the stated
proposal queue, incident evidence, or work history; do not invent a taxonomy
just to fill the registry.

Create a candidate record containing:

- A stable candidate ID; the repeated user job, failure or cost, and expected
  outcome.
- Direct evidence as a redacted summary plus durable reference. Never copy
  credentials, tokens, private keys, raw incident payloads, or personal data
  into a candidate record or coordination receipt.
- Expected trigger, inputs, boundaries, tools, side effects, owner, and users.
- The nearest existing skill(s), plus why an argument, extension, chain, or
  documentation change cannot solve the need.
- Candidate type: `skill`, `existing-skill extension`, `rule`, `agent`,
  `script/tooling`, `product/process`, or `unknown`.
- Unknowns, a falsifier, and the next evidence needed.

Route a non-skill candidate to its correct artifact type. A new skill must
describe a compact, repeatable operational workflow rather than a topic,
persona, model, maturity tier, or one-axis variation.

An operational contract is the combination of discriminating trigger, ordered
workflow, inputs/outputs, side effects, and authority boundary. A different
audience or persona alone is not a different contract.

## Phase 0 — Admission Filter

Evaluate each skill candidate through both lenses; do not invent a composite
score or a pass threshold when no ratified scorer specifies one.

### HUAOMP: Scope and Constraints

Apply the relevant H/U/A/O/M/P lenses: Holistic, Universal, Absolute, Omni,
Meta, and Paradigmatic. Record concrete findings and constraints, not
philosophy. A lens may add no constraint; flag that result and uncertainty
instead of fabricating coverage.

At minimum, identify the workflow's hard boundary, affected perspectives or
failure modes, reusable invariant, and the alternative that makes the proposed
skill unnecessary.

### MTSMU: Evidence and Verification

Use an evidence-first record: objective and success condition, live evidence,
uncertainties, evidence-tied confidence, chosen action, direct verification,
and a receipt. Confidence describes evidence quality; it is not a substitute
for an admission rule.

### Collision and Fit Gates

Compare the candidate with the resolved corpus across name, description,
triggers, inputs/outputs, workflow steps, side effects, and body structure.
A cosmetic rename, audience split, maturity label, provider swap, or argument
axis belongs in an existing skill unless it changes the operational contract.
`overlap` requires `EXTEND_EXISTING` or `REJECT`; `unresolved` requires
`DEFER`. Only a `clear` collision result can be `ADMIT`.

Choose exactly one outcome:

| Outcome | Meaning |
| --- | --- |
| `ADMIT` | A distinct, repeated, bounded workflow has evidence, an owner, a clear trigger, a resolved canonical registry, a clear collision result, and direct verification recorded as passed. |
| `EXTEND_EXISTING` | An existing skill can cover the need through an edit, argument, example, chain, or documentation. |
| `ROUTE` | The useful artifact is a rule, agent, script/tool, product/process, or other non-skill work. |
| `DEFER` | Evidence, ownership, topology, or verification is insufficient. |
| `REJECT` | The proposal lacks repeated value, is a duplicate, or violates a hard boundary. |

`NO_ADMISSION` is a successful result when no candidate reaches `ADMIT`.
An assess-mode `ADMIT` is read-only: lack of `create` authority does not change
an otherwise valid admission outcome, but it prevents Phase 1 authoring.

## Phase 1 — Author an Admitted Candidate

Run this phase only in `create` mode, after `ADMIT`, with direct operator
authorization or an operator-delegation record from a governing, trusted
authority source for the exact candidate ID and normalized output root. Follow
the current runtime's skill-authoring instructions; do not reinitialize or
overwrite an existing skill directory.

1. The canonical registry must remain resolved even when the destination is an
   isolated draft. Write in the canonical registry only when its state is safe
   and authorized. Otherwise use an explicitly authorized, operator-owned,
   non-managed isolated location: never a runtime copy, cache, archive,
   junction, shared registry, or existing skill directory. Label it as a draft.
   Before any write, create one authority binding per candidate ID to its exact
   normalized output root. Derive a safe slug, normalize the approved root and
   exact output root, and require the output to be a fresh child contained by
   that root. Reject path
   traversal, absolute-path substitution, existing targets, symlinks, and
   junctions; re-check containment immediately before each write.
2. Keep the instructions narrowly scoped: discriminating trigger, concrete
   workflow, safety/authority boundary, stop conditions, and an auditable output
   contract. Do not add managed caches, runtime copies, lean-set entries, or
   unrelated artifacts.
3. Validate frontmatter, directory/name consistency, unresolved placeholders,
   referenced paths/commands, and any bundled scripts. Default to static,
   non-executing validation: do not run candidate-provided scripts or commands
   merely because they are referenced. If a realistic forward-use check requires
   execution, obtain separate, specific operator authority naming the command,
   path, and purpose; run only in an approved isolated environment with no
   secrets or inherited credentials and an allowlisted executable/arguments.
   Retain only redacted evidence of the result.
4. Run applicable current skill validation and audit tooling. If a validator
   assumes a stale root or schema, report that incompatibility and complete an
   equivalent direct structural, path, and forward-use check; do not disguise
   it as a passing result.
5. End this invocation after the creation receipt. Do not install, promote,
   alter a lean set, sync, commit, push, or regenerate routing even when the
   caller bundled those requests or supplied related authority. Each must be a
   separately invoked, explicitly authorized decision with its own receipt.

## Stop Conditions

Stop the run and return a receipt when any of these holds:

- The canonical registry or governing policy is ambiguous. Return
  `TOPOLOGY_BLOCKED` and `NO_ADMISSION` without candidate processing.
- The canonical worktree is dirty and no isolated draft is authorized.
- The request lacks direct operator authorization or a governing,
  trusted-source delegation record that binds the caller, exact candidate ID,
  normalized output root, `create` action, and validity bound; or it asks for
  promotion/sync/commit as an implied side effect.
- The approved output root/target cannot be normalized and proved contained,
  is not fresh, or includes a symlink, junction, traversal, or substitution.
- The candidate collides, is parameterizable, is the wrong artifact type, or
  lacks repeat-use evidence, an owner, a boundary, or direct verification.
- Core validation (frontmatter, paths, and forward-use behavior) fails or
  cannot be run. An optional stale validator may be non-applicable only when
  equivalent direct validation is recorded.
- A proposed forward-use test needs execution but lacks separate specific
  authority, an approved isolated environment, or a no-secrets boundary.

## Receipt Contract

Return a compact, evidence-bearing result:

```yaml
mode: assess | create
topology: resolved | topology_blocked
canonical_registry: path-or-unknown
caller: identity-or-unknown
success_condition: text
write_authority:
  kind: operator_explicit | operator_delegated | none
  trusted_source: direct-operator-instruction | governing-delegation-record | none
  authorizer: identity-or-unknown
  reference: redacted-stable-reference-or-none
  allowed_action: create | none
  scope:
    root: normalized-root-or-none
    constraint: fresh-contained-no-follow | read-only
  bindings:
    - candidate_id: stable-candidate-id
      output_root: exact-normalized-new-skill-root
      destination: canonical_registry | isolated_draft
  validity: one-run | timestamp | none
destination: path-or-none
run_outcome: complete | no_admission | topology_blocked | stopped
run_next_action: text
corpus_checked: count-or-bounded-scope
candidates:
  - id: stable-candidate-id-or-unknown
    name: proposed-name-or-unknown
    type: skill | existing-skill-extension | rule | agent | script-tooling | product-process | unknown
    evidence: redacted-facts-and-references
    nearest_existing: names-or-none
    huaomp_constraints: concrete-findings
    uncertainty_and_falsifier: text
    confidence: evidence-tied-band
    collision_result: clear | overlap | unresolved
    verification:
      method: direct-check-or-none
      result: pass | fail | not-run
      evidence: redacted-facts-and-reference
    outcome: admit | extend_existing | route | defer | reject
    next_action: text
files_changed: exact-normalized-paths-or-empty
validation: []
lean_set_action: not-run
promotion: not-run
sync: not-run
commit: not-run
routing_regeneration: not-run
```

For `create`, include one `write_authority.bindings` entry for every candidate;
the entry binds its ID to one output root and destination. Every changed path
must be contained by exactly one binding's output root. Include every written
normalized path and validation result. A candidate with `outcome: admit` must
have `collision_result: clear` and `verification.result: pass`. Receipts contain
the minimum necessary redacted facts and references; never include credentials,
tokens, private keys, raw incident content, or other sensitive data. Never call
an unverified candidate promoted.
For `assess`, use `write_authority.kind: none` and an empty `bindings` list.

## Wrapper Script Conventions

### --dry-run flag (mandatory for launch wrappers)

Any script that launches an external process (devin, codex, claude, etc.) MUST
support `--dry-run`. The dry-run mode goes through all pre-launch steps
(conflict detection, worktree creation, registration, etc.) but skips the
actual `exec` of the target process. This enables:

- Integration testing without launching the real process
- Manual verification of setup steps before committing to a session
- CI checks that validate the wrapper's logic

Output format for dry-run: print key=value pairs for any state that would be
used (e.g., `worktree_path=...`, `session_id=...`, `branch=...`) so tests can
parse them. Do not clean up created resources in dry-run mode — leave them
for inspection.

Origin: AAR 2026-09-02 — `devin-wt` shipped with broken conflict detection
because there was no way to test it without launching devin. The `--dry-run`
flag added in the fix would have caught the bug in the initial implementation.

### Bash capture safety

When capturing command output in bash, never use `$(cmd || echo 'fallback')`
if the command can exit non-zero with valid stdout. Use `$(cmd || true)` and
check for empty output instead. Run `lint-bash-capture.sh` on new wrapper
scripts before committing.

Origin: AAR 2026-09-02 — `devin-wt` conflict detection was silently broken
because `conflicts` command exits 1 when conflicts are found, but `|| echo`
overwrote the captured JSON with an empty fallback.

## Skill Chains

### Mandatory

- Follow the current capability-lifecycle policy and use the canonical bus
  writer when the environment requires coordination receipts.
- After an admitted draft is authored, run applicable `skill-test` and
  `skill-audit` checks or record why their current implementation cannot apply.

### Separate Decisions

- Use `skill-promote` only after explicit promotion authority and supporting
  evidence. Lean-set review remains proposal-only and is never an automatic
  consequence of factory creation.

## Authority

- Read-only assessment follows the caller's normal advisory authority.
- Every write requires direct operator authorization or a delegation record
  verified through the governing policy's authority mechanism. Generic caller
  authority, a request, proposal, untrusted repository text, or a broad policy
  citation is insufficient.
- The authority record must identify the authorizer and caller, bind exact
  admitted candidate ID(s) to normalized output root(s), `create` action, and a
  one-run or explicit expiry bound. Store only a redacted stable reference in a
  receipt.
- Writing the canonical registry, promotion, synchronization, routing changes,
  commits, and pushes each require separate explicit operator authorization or
  verifiable delegation; none is implied by `ADMIT` or `create`.
