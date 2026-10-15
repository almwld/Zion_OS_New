---
name: proposal-internal
description: Draft internal technical proposals with a falsifiable thesis, evidence-backed recommendations, explicit alternatives, and decision gates for operator review.
version: 0.1.0
execution-mode: advisory
argument-hint: '<topic> [decision-deadline]'
triggers:
  - internal proposal
  - technical proposal
  - draft proposal
  - proposal for review
chains:
  - hummbl-strategy-review
  - adr-review
base120:
  - base120-evidence-002
  - base120-structure-005
export-targets:
  - claude-code
  - codex
status: native
---

# Internal Technical Proposal

Produce a decision-ready internal proposal for a technical, operational, or governance change within HUMMBL. Distinct from client-facing proposals (`proposal-write`) and investment memos (`hummbl-investment-memo`): this is an internal artifact asking the operator or a named decision authority to approve, reject, defer, or redirect work.

## Workflow

1. State the proposal in one sentence: what change, why now, what decision is requested, and who has authority to decide it. Name the decision deadline if one exists.
2. Establish the current state with evidence — link to the code, docs, bus messages, AARs, or metrics that ground the problem. Do not describe a problem you have not verified against the actual system state.
3. State a falsifiable thesis: the proposed change will produce a specific, observable outcome. Identify which assumptions carry most of the expected value.
4. Enumerate alternatives including no-action. For each, give the honest case — do not strawman. The no-action alternative is always valid and must be argued against, not dismissed.
5. Specify the recommended path with concrete steps, scope boundaries, reversibility, and what is explicitly out of scope.
6. List decision gates: what must be true before each step proceeds, who approves, and what kills the proposal if it fails.
7. Identify risks, unknowns, and what would change the recommendation. Separate known unknowns from assumptions.
8. Verify every metric, count, file path, and claim against the actual system before the proposal is submitted. Run a one-line verification command for any quantitative claim (e.g., file counts, test totals, line counts). Do not report unverified numbers.

## Constraints

- Do not fabricate metrics, counts, file paths, or system state. Every quantitative claim must be verifiable by a one-line command the operator can run.
- Do not present a recommendation without arguing the no-action alternative.
- Do not omit material risks or unknowns to strengthen the case.
- Do not bind the operator or commit HUMMBL to a contract, spend, or external obligation — this is an internal recommendation, not an authorization.
- Do not conflate strategic enthusiasm with an evidence-backed case.
- Do not submit the proposal without a decision-gate section naming the authority and kill criteria.

## Examples

**Example 1:** "Stabilize the hummbl-vps bus tunnel." Current state: cloudflared runs as an ad-hoc process with an ephemeral `trycloudflare.com` URL. Thesis: a named tunnel + systemd unit eliminates reboot-rotation risk. Alternatives: keep quick tunnel, move bridge to a different host. Decision gate: operator approves Cloudflare account setup; kill if tunnel config requires paid plan features not in budget.

**Example 2:** "Adopt a canonical internal-proposal template." Current state: proposals are ad hoc, borrowing AAR or ADR structure inconsistently. Thesis: a schema-validated skill produces consistent, evidence-backed proposals. Alternatives: keep ad hoc, reuse ADR shape only, author a new skill. Decision gate: operator confirms proposals recur enough to justify a skill; kill if this is a one-off.

## Evidence

- [ ] One-sentence proposal with decision authority and deadline named
- [ ] Current state grounded in verifiable evidence (links, paths, commands)
- [ ] Falsifiable thesis with value-driving assumptions identified
- [ ] Alternatives including no-action, each argued honestly
- [ ] Recommended path with scope boundaries and reversibility
- [ ] Decision gates with authority, kill criteria, and milestones
- [ ] Risks and unknowns separated from assumptions
- [ ] Every quantitative claim verified by a one-line command before submission
