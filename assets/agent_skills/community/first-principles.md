---
name: first-principles
description: Propose first principles from primitives, invariants, purpose, constraints, and authority. Proposal-only; does not canonize doctrine.
version: 0.1.0
execution-mode: advisory
argument-hint: "<domain/system/artifact> [scope]"
category: fleet-ops
status: candidate
---
# First Principles Proposal

Use this skill when the operator asks to derive, propose, review, or stress-test
first principles for a system, product, organization, protocol, agent, or doctrine.

This skill is **proposal-only**. It may draft doctrine packets, but it must not
declare principles adopted, edit canonical guardrails, or treat its own output as
authoritative without Principal AI Agent, Engineer, or operator review.

## Core Distinctions

Keep these layers separate:

| Layer | Definition | Failure mode |
|---|---|---|
| Primitive | Irreducible component the system is made from | Over-abstract slogan |
| Invariant | Property that must remain true across variants | Brittle implementation detail |
| First principle | Governing norm derived from primitives and invariants | Policy disguised as axiom |
| Policy | Adopted rule under an authority | Unreviewed doctrine |
| Procedure | Operational way to execute a policy | Confused with principle |
| Mechanism | Concrete implementation that executes a procedure | Tool mistaken for doctrine |
| Outcome | Direct observed result of a mechanism or action | Effect mistaken for principle |
| Effect | Downstream consequence of an outcome | Speculation treated as evidence |
| Heuristic | Useful shortcut that can fail | Treated as law |

## Workflow

1. **Scope** - identify the target system, audience, adoption boundary, and authority source.
2. **Extract primitives** - list actors, objects, operations, boundaries, evidence types, authorities, and actions.
3. **Extract invariants** - list what must stay true across variants, versions, deployments, or contexts.
4. **Derive candidates** - propose governing norms that follow from the primitives and invariants.
5. **Classify** - mark each candidate by derivation depth and type: first principle, derived principle, policy, procedure, mechanism, outcome, effect, heuristic, or reject.
6. **Red-team** - test circularity, falsifiability, scope creep, contradiction, ungrounded moralizing, and adoption risk.
7. **Score** - grade retained candidates against the first-principle test below.
8. **Emit packet** - produce a traceable proposal with gates and review requirements.

## Required Checks

- If the task names a repo, file, product, PR, policy, or current state, verify that state from source before stating it as fact.
- If a canonical primitive or invariant document exists, cite it and preserve its terms.
- If a proposed principle cannot be traced back to at least one primitive and one invariant, demote it or reject it.
- If a proposed principle cannot be operationally tested, demote it to value statement or heuristic.
- If a candidate is merely "how to do work," classify it as procedure.
- If a candidate depends on a chosen authority, classify it as policy unless it is still necessary without that authority.
- If a candidate names a concrete script, protocol, API, runtime, or tool, classify it as mechanism.
- If a candidate describes what happened, classify it as outcome or effect, not principle.
- If all candidates survive as first principles, pause and run the demotion rubric again before final output.
- Every retained first-principle candidate must include at least one operational whether-test.

## Output Format

Start with a compact scope line:

```text
Scope: <target> | Authority: <source or proposed reviewer> | Status: PROPOSAL
```

Then produce:

1. Source evidence
2. Primitive inventory
3. Invariant inventory
4. Derivation-depth map
5. Candidate principles
6. Classification table
7. Scorecard
8. Whether-tests
9. Stress tests
10. Rejected or demoted candidates
11. Adoption gate
12. Open questions

Use this schema for each retained principle:

```yaml
id: FP-001
name: <short name>
status: proposed
maturity_state: PROPOSED
classification: first-principle
derivation_depth: D1
score: <0-10>
score_breakdown:
  primitive_grounding: <0-2>
  invariant_grounding: <0-2>
  necessity: <0-2>
  operational_test: <0-2>
  non_derivation: <0-2>
source_evidence:
  - path_or_url: <source>
    claim_supported: <short claim>
    tier: <source hierarchy tier>
argument_quality:
  grounds: <evidence supporting the principle>
  warrant: <why the evidence supports the principle>
  backing: <support for the warrant>
  qualifier: <where the principle applies or does not apply>
  rebuttal: <strongest objection or exception>
derived_from:
  primitives: [<primitive>, <primitive>]
  invariants: [<invariant>]
statement: >
  <one sentence governing norm>
why_first_principle: >
  <why this is not merely policy, procedure, or preference>
whether_test: >
  <the operational question that decides whether the principle is honored>
verification_method: >
  <evidence, review, test, or trace that answers the whether-test>
failure_mode: >
  <what breaks when this principle is violated>
review_gate: <operator | principal_ai_agent | engineer | principal_ai_agent_and_engineer | other>
```

## Derivation Depth

Use derivation depth instead of an endless ordinal chain of "first, second, third
principles." "Second principle" is allowed only as a plain-language synonym for
derived principle.

| Depth | Name | Meaning | Test |
|---|---|---|---|
| D0 | Grounds | Purpose, context, primitives, invariants, constraints, observations, assumptions, and authority | Does this help discover the principle? |
| D1 | First principle | Root governing norm or truth | Does system identity fail without it? |
| D2 | Derived principle | General principle downstream from one or more first principles | Can it be derived from D1? |
| D3 | Policy | Adopted rule under an authority | Does it depend on a decision-maker or governance body? |
| D4 | Procedure | Operational steps for executing a policy | Does it tell someone how to act? |
| D5 | Mechanism | Concrete tool, script, protocol, schema, or runtime implementation | Is it an implementation surface? |
| D6 | Outcome | Direct observed result | Did this happen directly? |
| D7 | Effect | Downstream consequence | Is this a consequence of a consequence? |

Key distinction:

- Before first principles = grounds of discovery.
- First principles = grounds of justification.

Recommended HUMMBL chain:

```text
Primitives / Invariants / Purpose / Authority
-> First Principles
-> Derived Principles
-> Governance Policies
-> Operating Procedures
-> Runtime Mechanisms
-> Receipts
-> Effects
```

Use "whether" as the adjudication operator at every level: whether grounded,
whether first-order or derived, whether policy or principle, whether procedure or
mechanism, and whether the effect is direct or downstream.

## Source Hierarchy

Rank evidence in this order unless the operator supplies a stricter hierarchy:

1. Canonical repo docs, contracts, schemas, and guardrails.
2. Current implementation and tests.
3. Bus receipts, audit logs, governance ledgers, and signed artifacts.
4. Current operator instruction.
5. External primary sources.
6. Prior memory or summaries, explicitly marked as memory-derived.
7. Inference or synthesis, explicitly marked as inference.

If sources conflict, surface the conflict instead of smoothing it over. If a claim
depends on prior memory or inference, do not present it as confirmed-current.

## Methodology Anchors

Use these as methodological anchors, not as canned conclusions:

- **Aristotelian first-principle test**: a first principle should stop circularity
  and infinite regress; it is a starting point for explanation, not a conclusion
  smuggled in as an axiom. Check whether the candidate is needed before derived
  reasoning can begin.
- **NASA verification/validation discipline**: trace each "shall" to a source,
  verification method, and validation purpose. Translate this for principles as:
  source, whether-test, and stakeholder/function validation.
- **Requirements engineering discipline**: define the information items the
  proposal must produce, preserve source traceability, and avoid requirements
  that cannot be verified or validated.
- **Assurance-case discipline**: structure important proposals as claims,
  arguments, and evidence. A principle packet should make clear what is claimed,
  what evidence supports it, and what argument connects the evidence to the claim.
- **Toulmin argument discipline**: separate claim, grounds, warrant, backing,
  qualifier, and rebuttal. A weak first-principles packet often has evidence
  without a warrant, or a warrant without backing.
- **Value-sensitive design discipline**: identify direct and indirect
  stakeholders, value sources, value conflicts, and technical design implications.
  A principle that ignores stakeholder value conflict is probably under-specified.
- **NIST AI RMF discipline**: separate governance, mapping, measuring, and managing.
  A principle is not mature until it is mapped to risks, measurable evidence, and
  management consequences.
- **AI constitution/model-spec discipline**: principles need authority order,
  conflict handling, interpretive aids, and examples for gray areas.
- **Verifiable credential discipline**: evidence should identify issuer/source,
  verifier/reviewer, subject/claim, schema/semantics, and supporting evidence.

## Maturity States

Every principles packet and every principle should carry a maturity state:

| State | Meaning | Allowed use |
|---|---|---|
| DRAFT | Generated but not self-reviewed | Discussion only |
| PROPOSED | Traceable and self-reviewed | Review queue |
| REVIEWED | Reviewed by Principal AI Agent, Engineer, or named reviewer | Candidate for adoption |
| ADOPTED | Approved by operator or canonical authority | Canonical use |
| RETIRED | Superseded, invalidated, or intentionally removed | Historical reference |

Never imply ADOPTED status from this skill alone.

## First-Principle Test

Score each retained candidate 0-2 on each dimension:

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Primitive grounding | No primitive named | Primitive named but weakly tied | Depends on a real primitive |
| Invariant grounding | No invariant named | Invariant named but weakly tied | Protects a real invariant |
| Necessity | Optional preference | Useful default | System identity fails without it |
| Operational test | No test | Subjective test | Evidence-based whether-test |
| Non-derivation | Depends on prior policy | Partly derived | Reasoning starts here |

Classification guidance:

- **9-10**: first-principle candidate.
- **7-8**: likely derived principle; promote only with strong rationale.
- **5-6**: policy or heuristic.
- **0-4**: procedure, slogan, or reject.

## Anti-Slogan Filter

Reject or demote language that is:

- Inspirational but not testable.
- Circular: it assumes the thing it claims to prove.
- So broad that it cannot govern action.
- Merely brand language or positioning.
- A procedure, policy, or preference dressed as an axiom.
- Detached from source evidence, primitives, or invariants.

Examples:

```text
"Be excellent" -> reject: no primitive, no invariant, no whether-test.
"Move fast" -> heuristic or policy: useful only under conditions.
"Trust but verify" -> derived principle unless tied to evidence, authority, and review primitives.
```

## Demotion Rubric

Demote aggressively:

- **First principle -> derived principle** when it depends on another proposed norm.
- **First principle -> policy** when it depends on an adopted authority or organizational choice.
- **First principle -> procedure** when it describes implementation steps.
- **First principle -> heuristic** when it is useful but defeasible.
- **Any category -> reject** when it is circular, unfalsifiable, ornamental, or unsupported.

Quality signal: a good run rejects or demotes some candidates. A packet where every
candidate becomes a first principle is usually too credulous.

## Minimal Example

Input candidate:

```text
Agents should post bus receipts after consequential work.
```

Classification:

```yaml
classification: policy
reason: >
  This is an adopted operating rule. It is grounded in evidence and auditability,
  but it is not itself a first principle.
promote_underlying_candidate: >
  Consequential action must emit reviewable evidence.
```

Underlying first-principle candidate:

```yaml
id: FP-EXAMPLE
name: Evidence before trust
status: proposed
maturity_state: PROPOSED
classification: first-principle
score: 10
score_breakdown:
  primitive_grounding: 2
  invariant_grounding: 2
  necessity: 2
  operational_test: 2
  non_derivation: 2
source_evidence:
  - path_or_url: <current governance rule or bus protocol>
    claim_supported: Consequential action needs reviewable evidence.
    tier: canonical repo docs or guardrails
argument_quality:
  grounds: Receipt systems expose who acted, under which authority, and with what result.
  warrant: Reviewable evidence is what lets a verifier distinguish governed action from assertion.
  backing: Governance and assurance practices rely on traceability from claim to source and verification.
  qualifier: Applies to consequential action, not every low-risk thought or scratch note.
  rebuttal: Over-receipting can create noise, cost, or privacy exposure if scope is not bounded.
derived_from:
  primitives: [action, evidence, reviewer]
  invariants: [governance must be auditable]
statement: >
  A system cannot legitimately trust consequential action unless it can inspect
  evidence that the action occurred under valid authority.
whether_test: >
  Can a reviewer determine whether the action happened, who authorized it, and
  what evidence supports the claim?
verification_method: >
  Review the receipt, source artifact, and authority record.
failure_mode: >
  Governance becomes unverifiable assertion.
review_gate: principal_ai_agent_and_engineer
```

## Red-Team Prompts

Ask:

- What primitive would disappear if this principle were false?
- What invariant would fail if this principle were false?
- Is the principle necessary across variants, or only useful in this version?
- Does it create an operational whether-question?
- Can a reviewer tell whether it was honored from evidence?
- Does it conflict with a higher authority, existing contract, or safety invariant?
- Does it preserve distinction between belief, reasoning, authority, evidence, and action?
- Which source in the source hierarchy supports it, and which source could falsify it?
- What maturity state is justified by current evidence?
- What is the strongest rebuttal or exception?
- Which stakeholder or value conflict could make this principle harmful if applied mechanically?

## HUMMBL Defaults

When the target is HUMMBL or a HUMMBL-adjacent system, check the current canonical
primitive/invariant sources before proposing doctrine. Common anchors include:

- Base120: governed mental-model layer over partial world models.
- Krineia: append-only governance receipt chain; receipts prove governance happened and do not feed reward, gradient, training, or optimization paths.
- BKI: belonging as infrastructure for governance adoption.
- TUPLES: signed trace of governed decision across contract, delegation/capability, and evidence.

Treat this section as a pointer, not as live proof. Verify from current source files
when the proposal depends on exact HUMMBL doctrine.

Start with these local paths when present:

- `$env:USERPROFILE\PROJECTS\hummbl-governance\.claude\rules\hummbl-primitives.md`
- `$env:USERPROFILE\PROJECTS\hummbl-governance\PRIMITIVES.md`
- `$env:USERPROFILE\PROJECTS\hummbl-governance\hummbl_governance\playbooks\EXECUTION_PRIMITIVES.md`
- `$env:USERPROFILE\PROJECTS\hummbl-governance\hummbl_governance\docs\design\krineia\`
- `$env:USERPROFILE\PROJECTS\hummbl-governance\hummbl_governance\docs\publications\BKI_GOVERNANCE_DRAFT.md`

## Bus / Review

If the proposal is consequential, post a bus `PROPOSAL`. The skill invocation
runtime injects the caller's canonical identity as `from_id`. Mark the output
`PROPOSAL`. Do not post `DECISION` or `DIRECTIVE`. Do not self-approve the proposal.
