---
name: epistemic-crucible-mode
description: A composable, multi-agent sandbox for rigorous, non-destructive trial and error utilizing LLM-as-Judge, LLM-as-Coach, and anti-purge data ledgers.
version: 1.0.0
execution-mode: side_effecting
category: fleet-ops
status: active
---

# Epistemic Crucible Mode

## Mandatory

- Run `[crab]` before stateful work and verify the active operator scope, repository state, and canonical bus identity.
- Confirm the sandbox path, bounded iteration budget, and named agent assignments before creating a worktree, invoking agents, or writing the ledger. Preserve existing experiments.

## Authority

The `side_effecting` classification describes possible actions; it grants no
permission to execute them. Follow the current operator instruction, roster,
trust and AIP restrictions, budget limits, and protected-surface rules.
Use the invoking agent's verified identity. This boundary takes precedence over
legacy examples and identity labels elsewhere in this skill. No direct push
to `main`, unsigned fallback, or unrequested scheduling, spending, delegation,
commit, push, PR, or deployment is authorized by invoking this skill.

The Epistemic Crucible is a modular, multi-agent orchestration loop designed to maximize epistemic rigor (truth-seeking) without risking the active branches of a repository.

> **CRITICAL DIRECTIVE (THE ANTI-PURGE LAW)**
> In this sandbox, failure is considered high-value cybernetic data. **Do not purge, delete, or overwrite failed attempts.** Every hallucination, logic failure, and rejected artifact must be appended to the local `crucible_ledger.jsonl`. 

## 1. Sandbox Containment (Initialization)

Before any agentic reasoning begins, the orchestrator must establish containment:
1. Do not operate in `main`. 
2. Spin up a temporary isolated environment using: `git worktree add ../_worktrees/crucible-<ticket-id>` (or use the containerized sandbox environment in `docker-compose.mega-session.yml`).
3. Initialize or link `crucible_ledger.jsonl`:
   - Canonical persistent location: `state/crucible/crucible_ledger.jsonl` (persisted on host and mapped read-write in container Tier 2).
   - In worktrees or ephemeral scratch containers, symlink `crucible_ledger.jsonl` $\to$ `state/crucible/crucible_ledger.jsonl` to ensure failures are never purged upon container or worktree eviction.

## 2. The Composable Subagent Roles

The Crucible requires the orchestration of distinct, adversarial subagent profiles. Do not merge these roles into a single prompt; they must remain isolated to prevent context-contamination.

### Role A: The Trainee
*   **Purpose**: The primary generator attempting to solve the objective.
*   **Prompting**: Standard operational prompt. The Trainee is entirely blind to the existence of the Judge or the Coach.

### Role B: The Judge (LLM-as-Judge)
*   **Purpose**: A cold, boolean validator. 
*   **Prompting**: The Judge evaluates the Trainee's output strictly against LLL Invariants (e.g., "Did the Trainee provide a verifiable filesystem receipt for this claim?"). 
*   **Output**: The Judge may only output `PASS` or `FAIL` with a highly specific, 2-sentence rationale mapping the failure to an LLL structural violation.

### Role C: The Coach (LLM-as-Coach)
*   **Purpose**: Strategic remediation.
*   **Prompting**: If the Judge issues a `FAIL`, the Coach is invoked. The Coach *must not rewrite the artifact or solve the problem*. The Coach must analyze the Judge's rationale and write a new instructional prompt tailored for the Trainee (e.g., "Your last attempt hallucinated an acronym. You must execute `grep_search` before answering this time.").

## 3. The Orchestration Loop

1. **Invoke Trainee**: Trainee generates `<artifact_v1>`.
2. **Invoke Judge**: Judge evaluates `<artifact_v1>`.
    * If `PASS` $\to$ Proceed to Step 5.
    * If `FAIL` $\to$ Proceed to Step 3.
3. **Invoke Coach**: Coach reads the FAIL rationale and generates `<coaching_prompt>`.
4. **Data Preservation**: Append the original artifact, the FAIL rationale, and the coaching prompt to `crucible_ledger.jsonl`.
5. **Re-Invoke Trainee**: Trainee receives the `<coaching_prompt>` and attempts `<artifact_v2>`. (Return to Step 2).
6. **Peer-Review Gate**: Upon a `PASS` from the Judge, the orchestrator halts autonomous action and bundles the final artifact into a Pull Request for human (or senior fleet) review.

## 4. Modularity 
The Crucible is composable. If a task requires lower rigor, the orchestrator may toggle off the **Coach** (relying on raw Trainee retries) or toggle off the **Judge** (relying purely on human PR review). However, the **Anti-Purge Law** (Step 4) cannot be toggled off; the ledger must always be preserved.
