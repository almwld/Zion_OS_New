---
name: entropy-catalog
description: Look up public true-RNG, beacon, and clone sites from the HUMMBL entropy catalog. Refuse secrets. Not an RNG client. [Maps to SY18.]
version: 0.1.0
execution-mode: advisory
argument-hint: "[list [--family A|B|C|D|M] [--live] [--core] | get <id>]"
status: candidate
category: security
---

# entropy-catalog

Read-only lookup over `docs/research/entropy-catalog/catalog.v1.json` joined with `_state/entropy-catalog-status.v1.json`. Use when the operator asks which public randomness source to use, whether a beacon is up, or for sites like random.org.

## When to Use

- "which true random / beacon / VRF may I use"
- "sites like random.org"
- "is CURBy / NIST / drand / ANU live"
- public draw vs private sampling vs consumer clone

## When not to use

- Generating a password, API key, wallet seed, or any secret — refuse and stop.
- Fetching random bits from a remote API — this skill does not call entropy endpoints.
- Gyre / Base120 model atlas — different product.

## Execution

From the `agents` repo root:

```bash
python docs/research/entropy-catalog/lookup_v1.py list --core
python docs/research/entropy-catalog/lookup_v1.py list --family B --live
python docs/research/entropy-catalog/lookup_v1.py get drand
```

If `_state/entropy-catalog-status.v1.json` is missing, core records are **unknown**, not live. Refresh with `python docs/research/entropy-catalog/probe_v1.py` only when the operator asked for a probe.

Join rule:

- catalog `retired` → `retired` even if the page returns 200
- `probe: true` and no sidecar → `unknown`
- `probe: true` and sidecar `ok` → `up`
- `probe: true` and sidecar not ok → `down`
- `probe: false` → catalog `status` only (`live`/`unknown`/`retired`)

`--live` means telemetry `up` only.

## Output Format

```
entropy-catalog | status=<probed_at or missing>
REFUSE: never fetch a secret from this catalog. ...
id                       F  role           entropy                state    canonical
...
rows=N
```

For `get`: JSON of the record plus `telemetry_state` and `probe_result`.

## Routing cheat sheet

| Need | Query |
|---|---|
| Public later-provable bits | `list --family B --live` |
| True-random sampling, not a secret | `list --family A --core` then read `quota` |
| On-chain draw | `list --family C` |
| Consumer wheel/clone | `list --family D` (not true random) |

## Constraints

- Advisory. Do not write the catalog. Do not post to the bus.
- Do not call `api.random.org`, `api.quantumnumbers.anu.edu.au`, or any entropy-dispensing URL.
- If the user asks for a secret from a listed site, print the REFUSE line and stop.
- Schema: `docs/research/entropy-catalog/SCHEMA.md`

## Base120 Context

- Primary: **SY18** (Measurement & Telemetry)
- Related: **P15** (Assumption Surfacing)

## Skill Chains

### Mandatory

None — read-only.

### Advisory

- After stale/missing status → `python docs/research/entropy-catalog/probe_v1.py` (operator-requested)
- After a public-draw need → do not invent a raffle product; point at family B only
