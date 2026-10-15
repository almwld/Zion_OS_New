---
name: mcp-fleet-ops
description: Cross-machine MCP fleet operations — rolling health checks, config drift detection, version reconciliation, and fleet-wide rotate/retire with provenance across all HUMMBL machines and MCP config roots.
version: 0.1.0
execution-mode: side_effecting
argument-hint: '<health|drift|reconcile|rotate|retire|rollup> [--machine <name>] [--config <path>]'
triggers:
  - MCP fleet health check
  - MCP config drift across machines
  - reconcile MCP servers across fleet
  - rotate MCP server fleet-wide
  - retire MCP server with provenance
  - MCP fleet rollup
chains:
  - mcp-fleet-config-12server
  - config-drift
  - hummbl-capability-lifecycle
  - mesh-sync
  - mesh-audit
  - machine-health
  - heartbeat
  - rollback
base120:
  - base120-structure-005
  - base120-feedback-005
  - base120-evidence-002
contracts: [{"id": "mfo-001", "type": "CNT", "text": "MUST NOT write MCP configs to a remote machine without first backing up the existing config to a timestamped .bak file on that machine", "requirement_level": "MUST NOT", "tags": ["backup-before-write", "remote-mutation-safety", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "backing up.*timestamped .bak|backup.*before.*write", "target": "SKILL.md"}}, "line_ref": 60}, {"id": "mfo-002", "type": "CNT", "text": "MUST NOT declare a server healthy based solely on process existence -- a healthy status requires a successful MCP initialize handshake for stdio servers or a 2xx HTTP response for remote servers", "requirement_level": "MUST NOT", "tags": ["health-verification", "handshake-required", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "MCP initialize handshake|2xx HTTP response", "target": "SKILL.md"}}, "line_ref": 64}, {"id": "mfo-003", "type": "CNT", "text": "MUST NOT rotate or retire an MCP server fleet-wide without recording provenance (server name, version, machine list, reason, rollback ref, authority) before the mutation", "requirement_level": "MUST NOT", "tags": ["provenance", "fleet-wide-mutation", "authority-gate", "non-negotiable"], "machine_check": {"kind": "regex", "spec": {"pattern": "recording provenance|server name.*version.*machine list.*reason.*rollback ref.*authority", "target": "SKILL.md"}}, "line_ref": 68}, {"id": "mfo-004", "type": "BEH", "text": "SHOULD reconcile drift toward the declared canonical config rather than toward any single machine's current state, and post the diff to the bus before applying", "requirement_level": "SHOULD", "tags": ["canonical-reconciliation", "diff-before-apply", "bus-receipt"], "machine_check": {"kind": "regex", "spec": {"pattern": "declared canonical config|post the diff to the bus", "target": "SKILL.md"}}, "line_ref": 72}, {"id": "mfo-005", "type": "BEH", "text": "SHOULD detect config drift between all active MCP config roots on each machine (.gemini/config, .gemini/antigravity-cli, .devin, .cursor) and report per-root server set differences, not just a single config", "requirement_level": "SHOULD", "tags": ["multi-root-drift", "per-root-diff", "config-roots"], "machine_check": {"kind": "regex", "spec": {"pattern": "all active MCP config roots|per-root server set differences", "target": "SKILL.md"}}, "line_ref": 76}]
category: fleet-ops
status: candidate
---

# MCP Fleet Ops

Cross-machine MCP fleet operations. Extends the single-machine `mcp-fleet-config-12server` standard to the fleet: rolling health checks across all machines, config drift detection across all MCP config roots, version reconciliation against a declared canonical config, and fleet-wide rotate/retire with provenance.

`mcp-fleet-config-12server` configures and validates one machine. This skill operates the fleet.

## When to Use

- Rolling health check across all MCP servers on all machines.
- MCP config drift detected between machines or between config roots on the same machine.
- Reconcile an MCP server addition/removal across the fleet.
- Rotate or retire an MCP server fleet-wide with provenance and rollback.
- Unified MCP fleet rollup for the bus (replaces ad-hoc per-machine SITREPs).

## Fleet Topology

| Machine | OS | MCP Config Roots | Role |
|---------|----|------------------|------|
| workstation | Windows | `.gemini/config`, `.gemini/antigravity-cli`, `.devin`, `.cursor` | Primary desktop |
| delta | Linux | `.gemini/config`, `.devin` | VPS |

Detect machines dynamically from the bus and `machine-health` rather than hardcoding. remote-node is dormant since 2026-07-01 — do not probe it.

## MCP Config Roots

Each machine may carry multiple active MCP config roots. Detect and diff all of them:

- `$HOME/.gemini/config/mcp_config.json` (Gemini CLI)
- `$HOME/.gemini/antigravity-cli/mcp_config.json` (Antigravity Desktop)
- `$HOME/.devin/mcp_config.local.json` (Devin CLI)
- `$HOME/.cursor/mcp.json` (Cursor)

A machine is not "in sync" unless all its active roots agree. Per-root drift on the same machine is a finding, not just cross-machine drift.

## Workflow

### health — Rolling Fleet Health Check

1. **Enumerate machines** from the bus and `machine-health`. Skip dormant machines (remote-node).
2. **For each machine, for each active config root, for each declared server**, run the appropriate probe:
   - stdio server: send MCP `initialize` handshake, expect a JSON-RPC response with `protocolVersion`.
   - HTTP/SSE server: send `initialize` over HTTP, expect 2xx with JSON-RPC body.
3. **Aggregate per machine, per root, per server.** Record `ready | missing-packages | missing-env | unreachable | handshake-fail | http-5xx | http-4xx`.
4. **Post a fleet rollup to the bus**: `MCP_FLEET_HEALTH host=<machine> root=<root> total=<n> ready=<n> degraded=<n> failed=<n> failed_servers=<list>`.
5. **On any failed server**, post a `BLOCKED` if the server is on the declared canonical set (regression), or a `WARN` if it is an extra non-canonical server (cleanup candidate).

### drift — Config Drift Detection

1. **Read the declared canonical config** (see Canonical Config below).
2. **For each machine, for each active root**, read the config and compute the server set.
3. **Diff per root against canonical**: missing servers, extra servers, URL/command/args/env differences.
4. **Diff roots against each other on the same machine**: per-root server set differences.
5. **Diff machines against each other**: server present on agent-node but missing on agent-node, etc.
6. **Post the diff to the bus** before any reconciliation: `MCP_CONFIG_DRIFT machine=<m> root=<r> missing=<list> extra=<list> changed=<list>`.
7. **Do not auto-reconcile.** Drift detection is read-only. Reconciliation requires the `reconcile` subcommand and operator authority.

### reconcile — Reconcile Toward Canonical

1. **Require operator authority** (T1 or operator). T3/T4 may not reconcile.
2. **Post the drift diff to the bus** (from `drift`) and wait for acknowledgment.
3. **For each machine, for each root with drift**, back up the existing config to a timestamped `.bak` file on that machine before writing.
4. **Write the canonical server set** in the root's native format. Preserve unmanaged entries (servers not in the canonical set but present locally — flag them, do not delete without explicit instruction).
5. **Re-validate** each root after write.
6. **Post a receipt** with machine, root, servers added/removed/changed, backup path, and authority.

### rotate — Fleet-Wide Server Rotation

1. **Require operator authority**. Record provenance before any mutation: server name, current version, new version, machine list, reason, rollback ref, authority.
2. **For each machine**, back up the config, update the server entry to the new version/ref, re-validate.
3. **Run `health`** after rotation to confirm the new version is ready on all machines.
4. **On any machine where the new version fails**, roll back from the `.bak` file and post `BLOCKED`.
5. **Post a rotation receipt** with per-machine results.

### retire — Fleet-Wide Server Retirement

1. **Require operator authority**. Record provenance: server name, version, machine list, reason, rollback ref, authority.
2. **For each machine**, back up the config, remove the server entry, re-validate.
3. **Confirm no agent runtime on any machine still references the retired server** (check `.agents/` skill triggers, `skill-routing.md`).
4. **Post a retirement receipt**. Keep the `.bak` files for the rollback window.

### rollup — Unified Fleet Rollup

1. **Run `health`** across the fleet.
2. **Aggregate with `drift`** results.
3. **Post a single `MCP_FLEET_ROLLUP`** to the bus: total machines, total servers, ready/failed counts, drift count, top failures. This replaces per-machine ad-hoc SITREPs for MCP.

### Edge cases

- **A machine is unreachable**: record `unreachable` for all its servers, post `WARN`, continue with other machines. Do not block the rollup.
- **A config root does not exist on a machine**: skip it, record `root-absent`. Do not create it without explicit instruction.
- **An extra non-canonical server is healthy**: report it as `extra` in drift, not as a failure in health. Cleanup is a separate `reconcile` decision.
- **Canonical config itself is disputed**: post `PROPOSAL` to the bus with the proposed canonical change. Do not reconcile until the proposal is ratified.
- **Cross-machine transport mismatch** (same server is stdio on agent-node, HTTP on agent-node): report as drift only if the canonical declares one transport. If canonical allows both, record but do not flag.

## Canonical Config

The declared canonical MCP config is the server set this skill reconciles toward. It is NOT hardcoded here — it lives in `mcp-fleet-config-12server`'s 12-server standard, extended by any ratified additions. As of this writing the canonical set has drifted from the original 12 (real configs carry 15-16 servers including `onepassword`, `bif`, `governance`, `utf`, `Neon`, `agent-web-reader`). Reconciling the canonical declaration to reality is a `PROPOSAL` to the bus, not a silent update.

## Constraints

- Do not write MCP configs to a remote machine without first backing up the existing config to a timestamped `.bak` file on that machine.
- Do not declare a server healthy based solely on process existence — require a successful MCP initialize handshake (stdio) or 2xx HTTP response (remote).
- Do not rotate or retire an MCP server fleet-wide without recording provenance (server name, version, machine list, reason, rollback ref, authority) before the mutation.
- Do not auto-reconcile drift — `drift` is read-only; `reconcile` requires operator authority.
- Do not delete unmanaged (extra) servers during reconcile without explicit instruction — flag them.
- Do not probe remote-node — it is dormant since 2026-07-01.
- Do not hardcode the canonical server set — read it from the declared canonical and post a `PROPOSAL` if reality has diverged.
- Do not bypass `hummbl-capability-lifecycle` provenance and authority gates for rotate/retire.

## Examples

**Example 1: Rolling health check**

> `mcp-fleet-ops health` enumerates workstation and delta. On agent-node it probes 4 config roots × N servers each. On agent-node it probes 2 roots. It posts `MCP_FLEET_HEALTH` per machine/root and a final `MCP_FLEET_ROLLUP`. Three servers on agent-node fail handshake (missing-env) — posted as `BLOCKED` because they are in the canonical set.

**Example 2: Drift detection reveals per-root divergence**

> `mcp-fleet-ops drift` finds workstation's `.gemini/config` has 16 servers but `.devin` has 15 (missing `linear`, `Neon`, `agent-web-reader`; has `hummbl-graph-mcp` and `basen-mcp` which gemini lacks). It posts `MCP_CONFIG_DRIFT machine=workstation root=.devin missing=linear,Neon,agent-web-reader extra=hummbl-graph-mcp,basen-mcp`. Reconciliation is a separate operator-authorized step.

**Example 3: Fleet-wide rotation with rollback**

> Operator authorizes rotating `github` MCP server from `@modelcontextprotocol/server-github@1.0.0` to `@modelcontextprotocol/server-github@2.0.0`. Provenance recorded. Both machines backed up. After write, `health` finds the new version fails handshake on agent-node (missing-env for `GITHUB_TOKEN`). Rollback from `.bak` on agent-node. `BLOCKED` posted. Workstation keeps the new version; delta stays on old. Receipt records the split state.

## Evidence

- [ ] Machine enumeration recorded (which machines probed, which skipped as dormant)
- [ ] Per-machine, per-root, per-server health results recorded
- [ ] Drift diff posted to bus before any reconciliation
- [ ] Backup files created on each mutated machine (timestamped `.bak`)
- [ ] Provenance recorded before any rotate/retire (server, version, machines, reason, rollback ref, authority)
- [ ] Post-mutation health check run
- [ ] Rollback executed on any failed mutation, with receipt
- [ ] Fleet rollup posted to bus

## Contracts

5 load-bearing contracts declared in frontmatter. Summary:

| ID | Type | Level | What it protects |
|----|------|-------|------------------|
| mfo-001 | CNT | MUST NOT | Remote MCP config write without timestamped backup |
| mfo-002 | CNT | MUST NOT | Healthy declaration without handshake (stdio) or 2xx (HTTP) |
| mfo-003 | CNT | MUST NOT | Fleet-wide rotate/retire without provenance and authority |
| mfo-004 | BEH | SHOULD | Reconcile toward declared canonical, post diff before applying |
| mfo-005 | BEH | SHOULD | Detect drift across all active MCP config roots per machine |

All 5 are machine-checked via regex against this SKILL.md — drift detection fires if the load-bearing prose is removed.

## Mandatory (MUST pass before any mutation subcommand)

- **`reconcile`**: drift diff MUST be posted to the bus and acknowledged before any config write. Operator authority (T1 or operator) MUST be confirmed.
- **`rotate`**: provenance (server name, version, machine list, reason, rollback ref, authority) MUST be recorded before any config write.
- **`retire`**: provenance (server name, version, machine list, reason, rollback ref, authority) MUST be recorded before any config write.
- **All mutation subcommands**: timestamped `.bak` backup MUST exist on each target machine before the config write.

### Advisory

- **Before `reconcile`**: `[mcp-fleet-ops] drift` (read-only diff first)
- **After `reconcile`/`rotate`/`retire`**: `[mcp-fleet-ops] health` (verify fleet state)
- **On failed mutation**: `[rollback]` from `.bak` file, then `[mcp-fleet-ops] health`
- **Closeout**: `[bus]` receipt with machine, root, servers changed, backup path, authority

## Authority

- **T1 (TRUSTED)**: May run `health`, `drift`, `rollup` (read-only) without pre-approval. MAY NOT run `reconcile`, `rotate`, `retire` without operator approval.
- **T2 (Active/High)**: May run read-only subcommands. MUST get operator approval for `reconcile`, `rotate`, `retire`.
- **T3 (Medium)**: MUST get operator approval for all subcommands including read-only if posting to bus.
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill.
- **Operator**: Override any restriction. May authorize fleet-wide mutations directly.

## Related Skills

- `mcp-fleet-config-12server` — single-machine 12-server config standard (canonical source)
- `config-drift` — generic cross-machine config drift pattern
- `hummbl-capability-lifecycle` — provenance, authority, and least-privilege gates
- `mesh-sync` — tar-over-SSH transport for `.agents/` content
- `mesh-audit` — `.agents/` content alignment verification
- `machine-health` — machine-level SSH/Tailscale/Docker health
- `heartbeat` — cross-machine service probe (remote-node-dormant)
- `rollback` — git release rollback (this skill handles MCP config rollback via `.bak` files)
