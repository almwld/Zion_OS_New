---
name: long-running-loop
description: Governed execution protocol for relentless, long-running autonomous agent operations.
version: 1.0.0
execution-mode: side_effecting
category: fleet-ops
status: active
---

# Long-Running Loop Protocol

## Mandatory

- Run `[crab]` before stateful work and verify the active operator scope, repository state, and canonical bus identity.
- Record the authorized objective, iteration, time and cost limits, stop conditions, and permitted execution mechanism before starting. Recurring tasks and further delegation require the corresponding authorized scope.

## Authority

The `side_effecting` classification describes possible actions; it grants no
permission to execute them. Follow the current operator instruction, roster,
trust and AIP restrictions, budget limits, and protected-surface rules.
Use the invoking agent's verified identity. This boundary takes precedence over
legacy examples and identity labels elsewhere in this skill. No direct push
to `main`, unsigned fallback, or unrequested scheduling, spending, delegation,
commit, push, PR, or deployment is authorized by invoking this skill.

Execute a continuous, multi-step autonomous loop for massive refactors, deep research, or continuous monitoring, while remaining strictly bound to fleet governance laws.

## Usage

```bash
[long-running-loop] "<objective>" --max-iterations=<N> --interval=<seconds>
```

## 1. Loop Architectures

An agent executing this skill must explicitly choose one of the following mechanical loops:

1. **The Cron Loop**: Utilizing the `schedule` tool to set a recurring background job. Best for continuous monitoring, periodic repository audits, or external polling.
2. **The Recursive Subagent Loop**: Spawning a subagent that is instructed to spawn *another* subagent when it completes its turn, passing the baton forward. Best for deep, exploratory research trees.
3. **The Relentless Goal Loop**: Utilizing the internal autonomous reasoning engine to refuse to stop iterating until the terminal condition is met. Best for massive codebase refactors.

## 2. Mandatory Constraints (LLL Adherence)

To prevent Goodhart collapses and Sybil-boundary exhaustion, any agent engaging in a long-running loop **MUST** comply with the Lattice, Loop, Ladder (LLL) engineering framework:

*   **The Lattice Constraint (Edge Decay)**: The looping agent cannot self-escalate authority. It must remain within the exact operational scope granted at the initiation of the loop.
*   **The Loop Constraint (Receipts)**: A loop is legally dead if it is silent. The looping agent **must** post a `HEARTBEAT` or `SITREP` message to the coordination bus every 15-30 minutes. If the agent fails to emit a heartbeat, it is considered trapped in a cognitive loop and should be terminated by the host.
*   **The Ladder Constraint (Depth Capping)**: If using the Recursive Subagent Loop, the maximum delegation depth is `N=5`. A subagent may not spawn a subagent that spawns a subagent ad infinitum. 

## 3. Terminal Conditions (Anti-Zombie Law)

An agent is strictly forbidden from initiating a `long-running-loop` without a mathematically verifiable terminal condition. 
Before starting the loop, the agent must define:
1. **Success Condition**: What exact file state, test passing, or metric defines the end?
2. **Exhaustion Condition**: What is the maximum number of iterations or maximum time-to-live (TTL) before the loop forcefully kills itself?

## 4. Operational Runbook

When invoked to run a long loop, the agent must:
1. Write a `<loop_manifest.md>` in the scratch directory defining the Success and Exhaustion conditions.
2. Post a `WIP_START` to the coordination bus indicating the loop has begun.
3. Execute the loop mechanism.
4. On loop termination, use the `aar` skill to generate a formal After Action Report of what occurred during the autonomous runtime.

## 5. Sandboxing & Ephemeral Worktree Execution

For deep, multi-hour autonomous execution or Escalating Mega-Sessions (Cycle 1–14+), executing directly on the host OS is strictly discouraged. Autonomous agents must execute inside an ephemeral, resource-capped container sandbox backed by an isolated git worktree:

1. **Isolation Architecture**:
   - **Ephemeral Worktree**: Allocate an isolated worktree at `_worktrees/<session-id>` (`git worktree add ...`). Never run autonomous loops directly on active developer working copies.
   - **Container Sandbox**: Mount the worktree into `hummbl/mega-sandbox:latest` (`docker run --rm --read-only --cpus 4 --memory 8g --tmpfs /tmp ... -v <worktree>:/workspace:rw`).
   - **OS-Level Containment**: Eliminates host blast radius, prevents cross-platform CRLF pipe drift, and restricts shell tools to container memory.

2. **Checkpoint & Rollback Engine**:
   - Use `scripts/sandbox_checkpoint.py` or `scripts/start_sandboxed_session.ps1` to take atomic git tree snapshots before and after each epoch.
   - If an agent hallucination or broken test regression occurs during an epoch, trigger immediate rollback:
     ```bash
     python scripts/sandbox_checkpoint.py rollback --session-id <session_id>
     ```

3. **Turnkey Launcher**:
   ```powershell
   pwsh -File scripts/start_sandboxed_session.ps1 -RepoPath <path> -BranchName <branch> -CommandText "<command>"
   ```
