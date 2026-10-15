---
name: tree-synthesis
description: Centralized Asynchronous Isolated Delegation (CAID) 10:1 recursive fan-in tree synthesis
version: 1.0.0
execution-mode: side_effecting
argument-hint: "[--fan-in <N>] [--tier <T>] [--manifest <PATH>] [--output <PATH>]"
category: swarm
status: candidate
---
# Tree Synthesis (CAID 10:1 Recursive Fan-in)

Recursive hierarchical synthesis for 10,000+ agent swarms. Condenses large volumes of asynchronous worker task receipts, diffs, and findings into bounded, high-density executive intelligence without overflowing context windows.

## Problem

A single orchestrator agent reading raw task outputs from 10,000 subagents would require >50 million tokens of context, resulting in instant context window exhaustion, latency failure, and hallucination. 

Linear collection (`swarm-collect`) works up to ~50 agents. Above 50 agents, synthesis must be structured as a **recursive fan-in reduction tree**.

## Architecture & Reduction Hierarchy

The Centralized Asynchronous Isolated Delegation (CAID) pattern enforces a strict 10:1 fan-in ratio across 4 tiers:

```
[ Tier 0: Root Orchestrator ]              Context: ~15,000 tokens
             ^
             | (10:1 Fan-in)
[ Tier 1: 10 Sector Synthesizers ]         Context: ~12,000 tokens each
             ^
             | (10:1 Fan-in)
[ Tier 2: 100 Domain Synthesizers ]        Context: ~10,000 tokens each
             ^
             | (10:1 Fan-in)
[ Tier 3: 1,000 Cluster Synthesizers ]     Context: ~8,000 tokens each
             ^
             | (10:1 Fan-in)
[ Tier 4: 10,000 Leaf Workers ]            Bounded isolated execution
```

### Tier Responsibilities

1. **Tier 4 — Leaf Workers (N=10,000)**:
   - Run in pre-warmed worker pools or ephemeral serverless actors.
   - Execute bounded tasks (research lookup, test execution, file linting, micro-benchmark).
   - Write structured JSON receipts (`{ task_id, status, metrics, findings, artifact_refs }`).
2. **Tier 3 — Cluster Synthesizers (N=1,000)**:
   - Ingest 10 leaf worker receipts.
   - Deduplicate repetitive observations, compute aggregate statistics (pass/fail rate, mean latency).
   - Emit a 1-page Cluster Summary JSON object.
3. **Tier 2 — Domain Synthesizers (N=100)**:
   - Ingest 10 cluster summaries.
   - Group findings by subsystem/domain, isolate blockers, cross-validate claims.
   - Emit a Domain Intelligence Brief.
4. **Tier 1 — Sector Synthesizers (N=10)**:
   - Ingest 10 domain briefs.
   - Synthesize architectural tradeoffs, fleet health indicators, and high-priority risks.
   - Emit a Sector Synthesis Packet.
5. **Tier 0 — Root Orchestrator (N=1)**:
   - Ingests the 10 sector packets.
   - Formulates final decisions, posts MILESTONE to coordination bus, and presents executive findings to the human operator.

---

## Procedure

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the coordination bus before initiating synthesis:
```
Type: SKILL_INVOKE
To: all
Message: [skill=tree-synthesis] [fan_in=10] [tier=<T>] [manifest=<PATH>]
```

### 1. Partition Input Manifest
Partition the input JSONL manifest of N items into chunks of `fan-in` size (default: 10 items per chunk):
```python
chunks = [items[i:i + fan_in] for i in range(0, len(items), fan_in)]
```

### 2. Dispatch Level Synthesizers
For each chunk, assign a synthesizer agent with a bounded synthesis prompt:
- Extract common themes.
- Identify contradictions or anomalies.
- Compress numerical metrics into distribution summaries (min, max, median, p95).
- Filter out noise and redundant logging.

### 3. Worktree & Artifact Isolation
For file modifications and diff synthesis:
- Subagents never commit directly to shared branches.
- Diffs are exported as patch files (`git diff > task_<id>.patch`).
- Automated Arbiter tests patch application against a clean worktree from the 50-slot recycling pool.
- Conflicting patches are quarantined and reported up the tree as `MERGE_CONFLICT`.

### 4. Recurse Until Root
If output chunk count > 1, repeat reduction at the next tier until exactly 1 unified document remains.

---

## Safety & Bounding Rules

1. **Context Ceiling**: No synthesizer at any tier may receive more than 30,000 tokens of prompt context.
2. **Deterministic Schemas**: All intermediate synthesis tiers must produce valid JSON matching the `SynthesisNode` contract.
3. **Worktree Pool Bound**: The local filesystem must never exceed 50 concurrently checked-out worktrees. Worktrees must be recycled or deleted immediately upon artifact collection.
4. **Failure Propagation**: If more than 20% of leaf nodes in a cluster fail (`status: ERROR`), the synthesizer must flag the cluster as `DEGRADED` rather than silently discarding failures.

---

## Authority

- **T1 (TRUSTED)**: Full invocation of full 4-tier tree synthesis and merge resolution.
- **T2 (Active/High)**: May run Tier 3 and Tier 2 synthesizers; Root execution requires T1 or operator approval.
- **T3/T4**: BLOCKED.
