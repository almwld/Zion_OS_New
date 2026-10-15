---
name: cloud-estate-manager
description: Inventory, reconcile, and record provenance for the HUMMBL cloud-estate against the closed-world Cloudflare ledger; tiers cover Tailscale mesh + Cloudflare, other owned surfaces, per-agent identity surfaces, prospective and retrospective estate. Use for "what do we own in the cloud", "does the ledger match live", "which agents have which identity surfaces", "what is expiring or proposed", "how did we get here", or before any DNS, tunnel, ACL, zone, host, mailbox, or credential change.
version: 0.1.0
execution-mode: advisory
argument-hint: "<inventory|reconcile|identities|prospect|history> [--tier primary|secondary|identities|prospective|retrospective|all] [--live] [--json] [--out PATH] [--ledger PATH] [--ledger-ref REF] [--lot KEY]"
category: fleet-ops
status: candidate
providers:
  required: [pytest, python]
---

# Cloud Estate Manager

Owner: operator. Users: claude-code, codex, devin. Linux/macOS shell examples; on Windows run the Python script directly (no PowerShell branch yet). Default `reconcile` runs all tiers including identities; pass `--tier primary` to avoid GPG/1Password/GitHub enumeration.

Read-only estate ledger workflow. Answers five questions per lot, building, deed, and street, in the `hummbl-house` vocabulary: **title** (who owns), **occupancy** (what runs there), **access** (who can reach it and how), **yield** (what it produces or costs), **refuse-to-sell** (what must never be transferred or exposed). Never mutates DNS, zones, tunnels, ACLs, hosts, or deeds. Route mutations to `cloudflare`, `wrangler`, `hummbl-edge-mesh`, or the operator.

## Trigger

- Operator or agent asks what the estate contains, whether the snapshot is stale, what is proposed or expiring, or for the history of a lot or building.
- Preflight before a change to any Cloudflare zone, Pages/Workers/D1/R2/KV/Vectorize resource, Tailscale ACL or node, VPS, CI runner, Git org, or domain registration.
- Weekly estate drift check (timer-driven; `--json --out`).

Not this skill: Tailscale peer diagnostics (`tailscale-status`), tunnel/SSH plumbing (`tunnel-check`), per-machine hardware/software inventory (`machine-inventory`), building/debugging Cloudflare apps (`cloudflare`, `wrangler`), edge-node provisioning (`hummbl-edge-mesh`), fleet health (`fleet-status`, `machine-health`).

## Tiers

| Tier | Scope | Live sources (read-only) | Snapshot sources |
|---|---|---|---|
| primary | Tailscale mesh; Cloudflare zones and improvements | `tailscale status --json`; `wrangler whoami/pages/d1/r2/kv/vectorize list`; `cloudflared tunnel list`; `dig` per zone; chain `hummbl-production/scripts/compare_live_cloudflare_config.py` for Pages/Workers drift | **`hummbl-production/cloudflare/operations.json`** (closed-world ledger, canonical for Cloudflare objects); `docs/cloud-estate.md` Lots; `docs/domain-register-*.csv` |
| secondary | VPS and outbuildings (Hetzner, UpCloud), Git deeds (`hummbl-io` org, `hummbl-dev` user), Slack interior, Gitea, secret vaults (names only), registrars | `gh org list`; register CSV (no host pings: spec 06 forbids them) | `docs/cloud-estate.md` Buildings, Off-roster, Interior, Deeds, Street |
| identities | Per rostered agent (`devin`, `codex`, `claude-code`, `opencode`, `gemini`, `hermes`): candidate mailbox `<agent>@agents.hummbl.io` (reported as `email_candidate`, `mailbox_observed=false` until a routing rule for that local part is in the ledger), GPG key (roster uids only; other uids are never enumerated), GitHub org membership (only when an agent→login map exists), 1Password service account names, bus sender activity (senders validated against `[a-z0-9][a-z0-9._-]{1,31}`) | `gh api orgs/hummbl-io/members`; `gpg --list-keys`; `op service-account list` (names only); bus mirror senders (7 d) | `operations.json` workers (gateway present?), `agent-commit-identity.md` roster |
| prospective | Proposed lot roles, renewal calendar, planned surfaces, prior-art name collisions | none (documents only) | register rows `role_status=proposed`; `cloudflare-domain-portfolio-*.md` §Proposed roles, §Renewal calendar; `cloud-estate-prior-art.md` |
| retrospective | Retired/dormant buildings, transferred deeds, decommissioned lots, AARs, receipts, others' history that constrains naming or claims | `git log` on estate docs | `cloud-estate.md` RETIRED/DORMANT rows; `docs/aar/*`; `_receipts/`; `cloud-estate-prior-art.md` |

Estate doc root: `$PROJECTS_DIR/hummbl-house-cloudflare-portfolio-docs/docs` (override `--estate-root`). Ledger: `$PROJECTS_DIR/hummbl-production/cloudflare/operations.json` (override `--ledger`; read `origin/main` when the local checkout is on a feature branch). Ledger `observed_at` is reported on every run; a ledger older than 7 days is itself a P3 finding.

Three Cloudflare files are source of truth (`operations.json`, `surfaces.json`, `README.md` in `hummbl-production/cloudflare/`). This skill never creates a fourth ledger. Source: grok-build bus STATUS 2026-09-08T01:42:54Z (host=agent-node) naming policies P-ESTATE and P-CLOSED-WORLD in proposal packet 6de4c912; the packet file lives uncommitted on agent-node (`.agents/docs/research/2026-09-08_cf-estate-governance-proposal.md`) and is Tier B until landed. A session GET dump is an observation, not source of truth.

## Workflow

1. **CRAB.** Confirm estate-doc repo path resolves and is a git worktree; record its HEAD. Confirm `tailscale`, `wrangler`, `cloudflared`, `dig`, `gh` presence (absence degrades a tier to snapshot-only, never fails the run). Check secret presence by name only: `[ -n "$CLOUDFLARE_API_TOKEN" ] && echo set`. Never print, echo, or log a value.
2. **Load snapshot.** Load `operations.json` (Pages, Workers, D1, KV, Vectorize names; email routing and DMARC state). Parse `cloud-estate.md` tables (Lots, Improvements, Buildings, Off-roster, Interior, Deeds, Street) and the newest `domain-register-*.csv` into one estate model. Off-roster rows stay off-roster. `hummbl-dev` is a user, not an org. `remote-node` is DORMANT: no probe, no routing. Hub line counts are snapshot text, never live metrics.
3. **Probe (only with `--live`).** Per tier, run the read-only live sources above. Default is offline. Every probe has a timeout. Live results carry `observed_at` and `source`; snapshot results carry `live: false`.
4. **Reconcile.** Join live to snapshot by lot name, zone, node hostname, or holder. Classify each row: `match`, `drift` (normalized field differs; evidence is a set diff), `unlisted` (live but not in snapshot; downgraded to `schema-gap` P3 when the ledger has no schema for that kind, e.g. R2, tunnels), `stale` (snapshot but not observed by a probe that actually ran for that kind), `unprobed` (no probe ran for it), `expected-absent` (snapshot status RETIRED/DORMANT/TRANSFER), `excluded-dormant` (never probed by policy). Drift never triggers a fix; it produces a finding with evidence.
5. **Identities.** For each rostered agent, join bus-sender activity (mirror, 7 d), GPG uids, GitHub org members, and 1Password service-account names into one matrix. Confirm `hummbl-email-gateway` is in the ledger before treating `<agent>@agents.hummbl.io` as live. Findings: bus-active agent with no GPG key (P2), no org membership (P3), non-roster bus senders (P3), gateway missing from ledger (P2).
6. **Prospect.** Emit proposed roles, renewals inside 90 days, lots with no web or MX destination, and prior-art collisions that constrain a proposed name.
7. **History.** Emit retired/dormant/transferred entries with dates and the document or receipt that records them; include `git log --follow` on the estate docs for provenance.
8. **Report.** Write Markdown (default) or JSON to stdout or `--out`. Default report path: `~/.agents/audit-reports/cloud-estate/estate-<UTC>.md`. Post a bus `STATUS` with `host=`, `estate_head=`, `tiers=`, `drift=<n>`, `unlisted=<n>`, `stale=<n>`, `report=<path> proof_source=<commands> next_owner=<operator|agent>` only when the operator or the invoking lane asked for a bus receipt.

```
python scripts/estate_probe.py inventory --tier primary
python scripts/estate_probe.py reconcile --tier all --live --json --out ~/.agents/audit-reports/cloud-estate/estate-$(date -u +%Y%m%dT%H%M%SZ).json
python scripts/estate_probe.py identities --live
python scripts/estate_probe.py prospect
python scripts/estate_probe.py history --lot hummbl.dev
```

## Output contract

```json
{
  "schema_version": 1,
  "ok": true,
  "mode": "offline|live",
  "estate_head": "<git short sha of estate docs>",
  "tiers": ["primary"],
  "authority": "observation-not-source-of-truth",
  "lots": [{"kind": "lot", "key": "hummbl.io", "fields": {"role": "Product catalog", "dns": "...", "a": "1.1.1.1"}, "live": false, "status": "match|drift|unlisted|stale|unprobed|expected-absent|excluded-dormant", "evidence": {}}],
  "improvements": [], "buildings": [], "offroster": [], "deeds": [], "interior": ["#eng"],
  "street": {"url": "https://bus.hummbl-dev.com", "live": false},
  "identities": [{"agent": "claude-code", "email_candidate": "claude-code@agents.hummbl.io", "mailbox_observed": false, "mailbox_evidence": null, "email_gateway_in_ledger": true, "surfaces": ["bus-sender", "gpg-key"]}],
  "ledger_observed_at": "2026-09-06T03:03:09Z",
  "prospective": [],
  "retrospective": [],
  "findings": [{"sev": "P1|P2|P3", "kind": "drift|stale|unlisted|schema-gap|expiring|expired|identity-gap|malformed|truncated|unprobed", "subject": "", "evidence": ""}],
  "code": null, "reason": null,
  "secrets_checked": ["CLOUDFLARE_API_TOKEN: set"],
  "provenance": {"sources": [], "observed_at": ""}
}
```

## Boundaries

- Advisory. The only intentional write is the report file under the audit-reports path or `--out`. Probed CLIs may write their own caches (wrangler writes `.wrangler/` in the working directory); the script runs probes from a scratch working directory so no cache lands in the skill or estate repos. No DNS, zone, tunnel, ACL, host, registrar, vault, mailbox, or git mutation. `operations.json` is read-only here; drift findings become PRs against `hummbl-production`, never in-place edits.
- Secrets: name-only presence checks. KV, R2, D1, vault contents are never listed beyond names. There is no verbose or value-printing flag.
- Report writes are contained under `~/.agents/audit-reports/cloud-estate/` (override only with `--allow-out-outside-root`), never through a symlink, never to a file named `operations.json`/`surfaces.json` or under a `cloudflare/` directory. Every report carries `authority: observation-not-source-of-truth`.
- Every untrusted string (table cells, register fields, bus senders, CLI output) is clipped, control-char stripped, and pipe-escaped before it reaches the markdown report. `dig` only receives validated hostnames (max 200 per run). `--ledger-ref` is validated and passed after `--`.
- Exit codes: 0 ok; 2 `fail_closed` (missing/oversized/symlinked estate doc, bad register header, no probe could run with `--live`) or refused report write. `inventory` ignores `--live`.
- Do not flatten the two estates: real-estate lots from the same repo are out of scope; `deal1_deed` is personal and never appears here as company estate.
- Do not post as `grok-bot` or any identity other than the invoking agent's canonical bus identity.
- remote-node: no active probe unless the operator explicitly approves re-entry.
- Stop and report `fail_closed` when the estate doc root does not resolve, when the register CSV has no header, or when `--live` is requested and a required CLI refuses auth. Never invent lots, hosts, zones, or repos to fill a table.

## Verification

- Offline: `python -m pytest tests/` (51 tests, incl. wargame regressions: markdown/section forgery, dig argv injection, `--out` containment, ReDoS-free parsing, dormant/retired classification, JSON-only wrangler parsing, ledger-ref validation) parses the bundled fixture doc, register, ledger, and bus mirror; and asserts `hummbl.house` and `Workstation` are present, `street.live` is false, off-roster rows are excluded from `buildings`, and `--live` without CLIs fail-closes without a bus post.
- Live (operator-approved only; first approved run 2026-09-08 by operator chat instruction to stress test the skill): run `reconcile --tier primary --live` on agent-node; expected `unlisted` includes Tailscale peers absent from the Buildings table (`ai`, `remote-node`, `galaxy-a16-5g`, `hummbl-runner-isolated`, phones) which is the intended drift finding, not an error.
- Wargame 2026-09-08 (red/purple/yellow/silver subagents on agent-node): 13 red findings (2 P1), 18 yellow defects, 19 purple vectors (4 P0), 40 silver control rows. All P0/P1 closed in v0.1.0 before PR review; residuals listed in CANDIDATE.md.

## Related

- `tailscale-status`, `tunnel-check`, `machine-inventory`, `fleet-status`, `cloudflare`, `wrangler`, `hummbl-edge-mesh`, `dns-check`, `ssl-check`, `1password`, `git-identity-check`
- `hummbl-production/scripts/{compare_live_cloudflare_config.py, validate_cloudflare_operations.py, sync_cloudflare_surfaces.py}` (existing drift guard and ledger validator; chain, do not duplicate)
- grok-build closed-world diff figures (zones 11/11, workers 15/15, pages 11/11; live-not-ledger kv+10 d1+2 r2 4 queues 2 access 3 tunnel_dns 3) as reported in bus STATUS 2026-09-08T01:42:54Z; unverified from agent-node until the proposal packet lands
- `hummbl-house-cloudflare-portfolio-docs/docs/specs/06-estate-probe.md` (offline v1 this skill extends), `07-title-map.md`
- Rules: `protected-surfaces.md`, `secret-enumeration-leakage-prevention.md`, `no-destructive-commands.md`, `claim-honesty-protocol.md`

## Origin

Candidate `cloud-estate-manager` created 2026-09-08 via `skills-factory` (operator-directed, isolated draft; canonical `.agents` worktree dirty). Evidence: `cloud-estate.md` snapshot dated 2026-08-31, domain register 2026-09-05 (12 rows), portfolio doc 2026-09-05, Tailscale mesh 10 peers with 5 not in the Buildings table, AARs 2026-09-05 on Cloudflare portfolio recovery; grok-build closed-world diff 2026-09-08 showing ledger gaps (R2, queues, Access, tunnels absent from schema); operator chat direction 2026-09-08 (delta session, ~05:10Z) to give every agent `<agent>@agents.hummbl.io`.
