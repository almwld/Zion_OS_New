---
name: tournament
description: Governed multi-agent cooperative tournament runner. Dispatches competing agents in dialectical sparring, Pareto brackets, or spectrum wargames, then extracts winners to code and losers' failure traces into permanent test fixtures.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<topic> [--topology dialectical|pareto|spectrum] [--contenders <agents>] [--judge <agent|auto>]"
category: fleet-ops
status: candidate
providers:
  required: [python, git]
---

# tournament — Governed Multi-Agent Cooperative Tournament Runner

**Cooperative Competition Engine:** Orchestrates competitive agent tournaments where multiple agents spar, benchmark, or cross-redline, while enforcing the coopetition invariants: **the winner ships, the loser teaches**, open playbooks, and mutual trust accretion.

Canonical specification: `rules/_candidates/cooperative-tournament-protocol.md`.

---

## When to Use

- Resolving high-stakes architectural or algorithm choices where a single agent's solution might have hidden blind spots.
- Stress-testing critical governance proposals or security boundaries before PR merge.
- Running dialectical `PIN-CODE-RESY` sparring matches to refine concepts.
- Benchmarking competing model families or agent frameworks on identical tasks.

## When to Skip

- Routine, single-lane tasks with low ambiguity.
- Reversible trivial changes where multi-agent overhead exceeds the benefit.

---

## Topologies

1. **`dialectical` (Default for conceptual / architectural work):**
   - 1 Instigator (Thesis: `[P]` Perspective / `[CO]` Composition)
   - 1 Adversary (Antithesis: `[IN]` Inversion / `[DE]` Decomposition)
   - 1 Judge/Synthesizer (Synthesis: `[RE]` Recursion / `[SY]` Systems)

2. **`pareto` (For code, performance & algorithmic optimization):**
   - $N$ parallel contenders implement solutions in isolated worktrees.
   - Evaluated across Correctness, Token Cost, Latency, and Cleanliness.

3. **`spectrum` (For security, robustness & edge cases):**
   - Red Team (Offense/Breakers) vs. Blue Team (Defense/Hardening) vs. Purple Team (Reconciliation).

---

## Execution Protocol

### Step 0: Context Gathering & Bus Assertion
```powershell
python $HOME\bin\bus-global.py post agy all WIP_START "host=agent-node [skill=tournament] [task=<tournament-id>] [topology=<topology>]"
```

### Step 1: Manifest Generation
Create a tournament manifest `_state/tournaments/<tournament-id>/manifest.yaml` specifying topic, contenders, evaluation suite, and cooperative sinks.

### Step 2: Dispatch Contenders
Run contenders with isolated worktree bounds. Contenders receive the identical task specification and must commit to a position without hedging.

### Step 3: Automated Benchmark & Cross-Critique
1. Execute unit test harness against all submitted patches.
2. Contenders read competitor submissions and file one structured critique highlighting unhandled edge cases or vulnerabilities.

### Step 4: Judging & Synthesis (Invariant Enforcement)
The Judge (or automated harness):
- Names the winning implementation based on objective Pareto criteria.
- **Enforces Invariant 1 (The Loser Teaches):** Extracts the valid edge cases found in the runner-up's critique into golden regression fixtures in `tests/golden/`.
- Records full receipts to the bus and Cognitive Ledger.

### Step 5: Bus Receipt
```powershell
python $HOME\bin\bus-global.py post agy all RECEIPT "host=agent-node [skill=tournament] [task=<tournament-id>] [winner=<agent>] [fixtures_extracted=<count>]"
```

---

## Authority & Trust

- **T1 / T2 Agents**: Authorized to initiate and judge tournaments.
- **T3 Agents**: Authorized to participate as contenders.
- **T4 (Probationary)**: May participate as contenders in sandboxed worktrees only.
