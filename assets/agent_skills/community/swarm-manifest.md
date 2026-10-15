---
provider-specific: true
name: swarm-manifest
description: Generate and validate swarm dispatch manifests — lane allocation, budget estimation, pre-flight checks
version: 1.1.0
execution-mode: side_effecting
argument-hint: "[target-count] [--machines mbp,$REMOTE_HOST,windows]"
category: fleet-ops
status: candidate
---
# Swarm Manifest

Generate a structured manifest for multi-agent swarm dispatch. Validates machine capacity, allocates lanes by capability, estimates token budget, and outputs an executable plan.

This skill routes lanes across providers and emits runtime-specific dispatch
commands. It declares `provider-specific: true` under criterion 3 of
`rules/skill-provider-neutrality.md`; its runtime bindings are part of the
subject, not a requirement that the invoking agent use one provider.

## Arguments
- `<target-count>` — Number of lanes to allocate (default: 6)
- `--machines <list>` — Comma-separated machines to include (default: mbp,$REMOTE_HOST)
- `--model <name>` — Optional model override, subject to the current roster and runtime policy. Otherwise inherit the approved parent or named-profile model; verify availability, reasoning effort, quota, and rates before allocation.
- `--runtime <vendor>` — Default lane runtime: claude-code, devin, codex, vibe, gemini, opencode (default: claude-code). Per-lane overrides allowed in manifest.
- `--budget <dollars>` — Max budget in USD (default: $5.00)

## Procedure

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=swarm-manifest] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Pre-Flight: Machine Reachability

```bash
# Local (local machine)
df -h / | tail -1
sysctl -n hw.memsize | awk '{print $1/1073741824 " GB"}'

# $REMOTE_HOST
ssh -o ConnectTimeout=10 $REMOTE_HOST "df -h / | tail -1 && sysctl -n hw.memsize | awk '{print \$1/1073741824 \" GB\"}'"

# Windows (if requested)
ssh -o ConnectTimeout=10 $WINDOWS_HOST "powershell -c 'Get-PSDrive C | Select-Object Used,Free'"
```

Mark each machine as REACHABLE or UNREACHABLE. Only allocate to reachable machines.

### 2. Capacity Assessment

| Machine | Max Lanes | Model Tier | Notes |
|---------|-----------|------------|-------|
| local machine (Intel i7, 16GB) | 2 | policy-approved | CPU-bound, no Ollama |
| $REMOTE_HOST (configured specs) | 8 | any | Primary dispatch target |
| Windows (Ryzen 7, 32GB, RTX 3080 Ti) | 4 | any | GPU for local models |

Check disk space: WARN if <10GB free, BLOCK if <5GB free.
Check for existing worktrees: `git worktree list | wc -l`.

### 3. Lane Allocation

Distribute `<target-count>` lanes across machines respecting capacity limits.
Priority order: $REMOTE_HOST (most capable) > windows > mbp.

For each lane, assign:
- Machine target
- Runtime (see 3a)
- Model and reasoning effort permitted by the current roster and runtime policy
- Estimated calls (default: 50 per lane)
- Worktree branch name following `swarm/<lane-id>/<short-desc>`
- Absolute target-host worktree path verified in `git worktree list --porcelain`
- Absolute target-host prompt path, saved and readable before dispatch

Resolve paths from the actual checkout and host. A branch name does not create a
worktree. Block lanes whose paths are missing; create worktrees only with dispatch
authorization. Never emit unresolved placeholders as runnable commands.

### 3a. Runtime Selection (per docs/multi-vendor-lane-orchestration.md §7)

Every lane MUST declare a runtime. Every dispatch MUST wrap the runtime pattern
below in `(cd -- "<absolute-worktree>" && ...)`, with shell-quoted paths resolved
from the manifest. These are Bash patterns (including Git Bash on Windows), run
on the named target host. Read prompts using their absolute paths. The table
lists only the runtime portion, never a standalone dispatch command.

| Runtime | Spawn pattern | Lane-guard mechanism |
|---|---|---|
| claude-code | `claude --bare -p "<prompt>" --permission-mode <mode> --allowedTools <list> --output-format stream-json` | permission-mode + allowedTools |
| devin | `LANE_GUARD_ALLOW_ROOTS="<absolute-worktree>" devin --permission-mode auto -p "<prompt>"` | verified installed worktree guard + org deny rules (mandatory pre-flight below) |
| codex | `codex exec --sandbox workspace-write --json "<prompt>"` | read-only or workspace-write sandbox (exec default is read-only; `--full-auto` is DEPRECATED — do not emit) |
| vibe | `vibe -p "<prompt>" --agent <lane-toml>` or `--enabled-tools <allowlist>` + `--max-turns N --max-price $` | **allow-list only** — programmatic mode auto-approves if `--agent` omitted; `--enabled-tools` disables everything not listed |
| gemini | `gemini -p "<prompt>" --output-format json` | quota-constrained → research/read lanes only |
| opencode | `opencode run --agent <lane> -m provider/model --format json "<prompt>"` | omit `--auto`; executor only — never DECISION/DIRECTIVE/VETO/COMMAND lanes |

Devin pre-flight is mandatory: inspect the target host's installed runtime hook
configuration and guard implementation, verify it consumes `LANE_GUARD_ALLOW_ROOTS`,
and record its absolute path plus passing allowed-in-worktree / denied-outside-root
and denied commit/push/install/delete/secret-access probes. Verify shell-mediated
writes and path traversal are covered. An environment variable does not install or
enforce a guard; `--permission-mode auto` is not a filesystem boundary. If guard
installation or enforcement cannot be verified, mark the lane BLOCKED and emit no
runnable Devin command. Require equivalent verified restrictions for other write
lanes; a sandbox alone does not enforce the full L2 deny-list.

Codex emits no output-schema flag by default. Add `--output-schema` only when the
manifest records an existing, validated schema at an absolute target-host path.

Rules:
- Mixed-runtime swarms are allowed — set `runtime:` per lane; default = `--runtime` arg.
- Audit/research lanes → currently approved read-scoped runtime/profile, respecting roster invocation and quota limits. Devin subagents use only `subagent_general`, inheriting the approved parent model per `rules/devin-subagent-profile-policy.md`; consult that policy at dispatch time.
- Fix lanes → codex/devin/claude-code with write-scoped guards.
- Review lane runtime MUST differ from authoring lane runtime (no self-review).

### 4. Budget Estimation

Use current approved model rates and quota evidence; do not assume a model or
reasoning tier is free. Record the source and verification time with each estimate.

| Lane | Approved model/profile | Input/output token estimate | Verified rates | Estimated lane cost |
|---|---|---|---|---|
| <lane-id> | <current roster-approved selection> | <input> / <output> | <current rate evidence> | <computed cost> |

Reasoning effort follows the current runtime/profile policy and explicit operator
constraints. If price or quota cannot be verified, mark the estimate unknown and
block paid dispatch until the budget constraint can be checked.

Total = sum of per-lane estimates. If total exceeds `--budget`, reduce lane count or downgrade models and report the adjustment.

### 5. Ledger Pre-Check (NEW)

Before finalizing the manifest, verify any dependent research exists in the ledger:

```bash
# Check if dependent ledger entries exist
grep -l "clp-<research-id>" _state/cognition/ledger.jsonl || echo "MISSING: clp-<research-id>"

# List recent ledger entries to verify
tail -5 _state/cognition/ledger.jsonl | jq -r '.id'
```

If dependent research is MISSING:
- Abort manifest generation
- First persist the missing research to ledger
- Re-run manifest after dependent data exists

This prevents the "spec constraint update without source data" failure mode.

### 6. Generate Manifest

## Output Format

````text
Swarm Manifest | <date> | <goal>

Pre-Flight:
  local machine:      REACHABLE  disk=45GB  mem=16GB
  $REMOTE_HOST: REACHABLE  disk=120GB mem=48GB
  Windows:  UNREACHABLE (skipped)

Lane Allocation (<N> lanes):
  Lane  Machine    Runtime      Model    Branch                        Est. Cost
  L01   $REMOTE_HOST   codex        approved swarm/L01/task-description    $0.60
  L02   $REMOTE_HOST   devin        approved swarm/L02/task-description    $0.60
  L03   $REMOTE_HOST   vibe         approved swarm/L03/task-description    $0.15
  L04   mbp        claude-code  approved swarm/L04/task-description    $0.15

Budget:
  Estimated total: $1.50 / $5.00 budget
  Model mix: current approved selections recorded per lane
  Headroom: $3.50 (70%)

Pre-Flight Checklist:
  [x] All target machines reachable
  [x] Disk space adequate (>10GB each)
  [x] No stale worktrees to clean
  [x] Main branch up to date
  [ ] Every target-host worktree and absolute prompt path verified
  [ ] Installed runtime guards and allow/deny probe evidence verified
  [ ] Target-host terminals ready (one terminal per lane)

Lane Paths (illustrative; substitute verified absolute target-host paths):
  L01: worktree=/srv/worktrees/L01  prompt=/srv/swarm/prompts/L01.md
  L02: worktree=/srv/worktrees/L02  prompt=/srv/swarm/prompts/L02.md
  L03: worktree=/srv/worktrees/L03  prompt=/srv/swarm/prompts/L03.md
  L04: worktree=/Users/operator/worktrees/L04  prompt=/Users/operator/swarm/prompts/L04.md

Dispatch Commands (Bash on each named host; emit only after pre-flight passes):
  L01: (cd -- "/srv/worktrees/L01" && codex exec --sandbox workspace-write --json "$(cat -- "/srv/swarm/prompts/L01.md")")
  L02: (cd -- "/srv/worktrees/L02" && LANE_GUARD_ALLOW_ROOTS="/srv/worktrees/L02" devin --permission-mode auto -p "$(cat -- "/srv/swarm/prompts/L02.md")")
  L03: (cd -- "/srv/worktrees/L03" && vibe -p "$(cat -- "/srv/swarm/prompts/L03.md")" --enabled-tools read_file grep glob --max-turns 20 --max-price 0.50)
  L04: (cd -- "/Users/operator/worktrees/L04" && claude --bare -p "$(cat -- "/Users/operator/swarm/prompts/L04.md")" --permission-mode plan --output-format stream-json)
  # One verified command per target-host terminal; no tmux helper is assumed.
  # Save and verify every absolute prompt path before dispatch (quota fallback).

## Auto-Persistence Hook

After swarm completes, always persist findings to ledger before claiming dependent actions complete. Include this in the manifest output:

```
## Post-Swarm Persistence
# IMMEDIATELY after swarm-collect, run:
python -c "
import json
entry = {
    'agent': 'codex',
    'assurance_level': 'SWARM',
    'confidence': 0.X,
    'content': '<findings summary>',
    'content_hash': '<unique-hash>',
    'evidence': '<files touched>',
    'id': 'clp-<research-id>',
    'model': '<model>',
    'scope': 'project',
    'tags': ['<tag1>', '<tag2>'],
    'timestamp': '2026-XX-XXTZ',
    'type': 'discovery',
    'vendor': 'local'
}
with open('_state/cognition/ledger.jsonl', 'a', encoding='utf-8') as f:
    f.write(json.dumps(entry) + '\n')
print('Research persisted')
"
```

Failure to persist blocks dependent actions (see step 5 ledger pre-check).

Next action: Review manifest, then `[swarm]` to execute
````

## Safety Rules

- Never allocate more lanes than a machine can handle
- Never dispatch to unreachable machines
- Abort manifest if total budget exceeds limit with no downgrade path
- Always include pre-flight checklist with actionable items
- Warn if main branch has uncommitted changes
- **Verify dependent ledger entries exist before generating manifest** — see step 5
- **Never emit a bare `vibe -p`** — programmatic mode auto-approves without `--agent`/`--enabled-tools` (see §3a)
- **Never emit `codex exec --full-auto`** — deprecated; use `--sandbox workspace-write`
- **No commit/push/deploy/install/delete/secrets in lane commands** — lanes write diffs and receipts; only the coronal commits (lane contract L2)
- Save every lane prompt to its absolute target-host manifest path before dispatch (quota pre-flight + manual fallback)

## Lexicon

This skill uses the canonical swarm lexicon (`~/.agents/rules/swarm-lexicon.md`).
Key terms: swarm, wave, batch, lane, manifest, orchestrator, pre-flight,
lane allocation. Conflicts between this skill's local vernacular and the lexicon
resolve in favor of the lexicon.

## Skill Chains

### Mandatory

None — manifest generation; read-only analysis plus file write.

### Advisory

- → `[swarm]` (execute dispatch after manifest generated)
- → `[swarm-subagent]` (if SSH unavailable, use subagent-based dispatch)
- → `[tailscale-status]` (if machine unreachable)
- → `[swarm-collect]` (gather results post-swarm)

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: May run
- **T4 (Probationary)**: May run (file generation only)
- **Operator**: Override any restriction
