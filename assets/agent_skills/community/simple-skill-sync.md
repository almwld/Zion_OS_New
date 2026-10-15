---
name: simple-skill-sync
description: Plan and safely run registered simple advisory skill adapters with deterministic parsing, metadata-based safety gates, strict mode, dry-run planning, and JSON receipts. Use when an operator requests a short chain of known skills.
version: 0.1.0
execution-mode: advisory
status: candidate
argument-hint: "[--mode=serial|parallel] [--strict] [--dry-run] [--max-steps=8] [--allow-side-effects] \"[skill_a args] ; [skill_b args] ; ...\""
category: fleet-ops
providers:
  required: [pytest, python]
---
# Simple Skill Sync Command

Use `scripts/simple_skill_sync.py` to resolve and validate a short chain of
known skills. The runtime fails closed: a skill without explicit metadata or a
registered adapter cannot execute.

This remains `candidate` until real adapters are registered by the host skill
runtime. Planning and validation are available now; arbitrary execution is not
inferred from a Markdown skill definition.

## Contract

- Parse semicolon-delimited input while preserving quoted semicolons.
- Resolve each step to a known skill under the configured skill roots.
- Require explicit `execution-mode` metadata for every step.
- Allow parallel mode only when every step declares `parallel-safe: true`.
- `--strict` stops on the first failure; non-strict mode reports `degraded`.
- `--dry-run` emits a plan and never calls an adapter.
- Side-effecting steps require `--allow-side-effects`.
- Emit versioned JSON receipts with per-step status and failure context.

## Safety

- Unknown skills and malformed quoting are rejected.
- Missing metadata is rejected rather than inferred.
- Ambiguous parallel plans are rejected rather than downgraded to serial.
- The runtime does not emit unsupported `SKILL_INVOKE` bus messages.
- Host integrations may post supported `STATUS` and `MILESTONE` receipts.

## Usage

```text
python scripts/simple_skill_sync.py --dry-run "skill-a --brief ; skill-b"
python scripts/simple_skill_sync.py --strict "skill-a ; skill-b"
```

## Non-goals

This is not a general workflow engine. It does not infer adapters, execute
arbitrary shell commands, retry unknown operations, or run side effects without
explicit authorization.

## Acceptance criteria

- Resolves a 3-step serial chain and executes it when adapters exist.
- Strict mode halts immediately on an adapter failure.
- Dry-run only prints the resolved JSON plan.
- Parallel mode rejects steps without explicit parallel-safe metadata.
- Output includes schema version, counts, stop state, first failure, and steps.
