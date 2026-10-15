---
name: hummbl-edge-mesh
description: Provision, operate, monitor, recover, and deploy HUMMBL edge nodes across meshtastic + Raspberry Pi 5 + Tailscale + Cloudflare. Full edge-node lifecycle.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "[provision|operate|monitor|recover|deploy|tunnel|mesh-status] [node-name]"
category: governance-compliance
status: candidate
---

# HUMMBL Edge Mesh

Full lifecycle management for HUMMBL edge nodes: Raspberry Pi 5 boards running
mesh networking (DemosMesh / Meshtastic), connected via Tailscale, exposed
through Cloudflare tunnels. Covers provisioning, operation, monitoring,
recovery, deployment, and mesh-status.

## Canonical Repos

| Component | Repo | Purpose |
|-----------|------|---------|
| Mesh networking | `hummbl-io/demosmesh` | Rust no_std core + Python governance via PyO3. 5-layer: Transport → Routing → Dex → Governance → Application |
| Edge benchmark | `hummbl-io/edge-agent-bench` | Edge agent compatibility, reliability, security, recovery, workload-economics. Pi/Orange Pi/RPi5 candidates on ARM64 Linux |
| Fleet mesh | `hummbl-io/hummbl-mesh` | Multi-machine agent coordination — swarm dispatch, file transfer, config drift, fleet health |
| Mesh ping | `hummbl-io/hummbl-mesh-ping` | Cross-machine health probe (Go) |
| Cloudflare prod | `hummbl-io/hummbl-production` | Cloudflare Workers (api.hummbl.io) + Cloudflare Pages (hummbl.io) |
| Low-level systems | `hummbl-io/metal` | C/Rust/Zig/asm/go/nim/fortran/odin — close-to-metal projects |
| Engineering monorepo | `hummbl-io/hummbl-engineering` | Includes "Edge & Embedded Engineering" discipline |
| Infrastructure as code | `hummbl-io/infrastructure-as-code` | Cloud, local, network, runtime, deployment infra as versioned code |

## Fleet Context

- Delta (Arch Linux / Omarchy / Hyprland) — development, orchestration
- Workstation (Windows) — GPU inference, fleet bus authority
- Tailscale SSH enabled across fleet — `ssh user@hostname`
- Edge nodes (rpi5) join Tailscale mesh as new peers
- Cloudflare tunnels expose edge services without public IPs

## Commands

### `provision <node-name>`

Provision a new Raspberry Pi 5 edge node from bare metal to fleet member.

1. **Pre-flight**: verify node-name is unique in Tailscale and fleet inventory
2. **OS flash**: write ARM64 Linux image to SD card / NVMe
   - Default: Raspberry Pi OS Lite 64-bit (bookworm) or Ubuntu Server 24.04 ARM64
   - Enable SSH, set hostname to `<node-name>`
3. **First boot config**: SSH in, create `reuben` user, set locale, timezone (America/New_York)
4. **Tailscale join**: `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh`
   - Approve node in Tailscale admin console
   - Verify: `tailscale status` shows new peer, `ssh reuben@<node-name>` works from agent-node
5. **Base packages**: `sudo apt update && sudo apt install -y git python3 python3-pip rustc cargo build-essential`
6. **DemosMesh deploy**: clone `hummbl-io/demosmesh`, build Rust core (`cargo build --release`), install Python governance layer
7. **Cloudflare tunnel**: install `cloudflared`, create tunnel, route edge service to `<node-name>.hummbl.io`
   - `cloudflared tunnel create <node-name>`
   - Configure ingress rules, DNS CNAME
   - Run as systemd service: `sudo cloudflared service install`
8. **Fleet registration**: add node to `hummbl-mesh` machine inventory, `hummbl-mesh-ping` machines.json
9. **Verify**: `hummbl-mesh-ping --machines machines.json` shows node ONLINE
10. **Receipt**: post to coordination bus — `STATUS node=<node-name> provisioned ts=<ts> tailscale=<ip> tunnel=<url>`

### `operate <node-name>`

Run operational tasks on an existing edge node.

- SSH to node via Tailscale: `ssh reuben@<node-name>`
- Check DemosMesh service: `systemctl status demosmesh`
- Check Cloudflare tunnel: `systemctl status cloudflared`
- Check Tailscale: `tailscale status`
- Run DemosMesh governance commands via PyO3 Python layer
- View logs: `journalctl -u demosmesh -f` / `journalctl -u cloudflared -f`
- Update node packages: `sudo apt update && sudo apt upgrade`

### `monitor [node-name|all]`

Health check edge nodes. If no node specified, check all.

```bash
# From agent-node or Workstation
hummbl-mesh-ping --machines machines.json

# Per-node deep check
ssh reuben@<node-name> 'tailscale status; systemctl is-active demosmesh cloudflared; df -h /; free -m; uptime'
```

Surface: peer state (ONLINE/OFFLINE/STALE), service state (active/inactive/failed),
disk usage, memory, load average, tunnel connectivity.

Post BLOCKED to bus if any node is OFFLINE or any critical service is failed.

### `recover <node-name>`

Recover a failed or unresponsive edge node.

1. **Diagnose**: attempt SSH via Tailscale; if unreachable, check Tailscale admin console for last-seen
2. **Tailscale recovery**: if node dropped from Tailscale, re-auth via `tailscale up --ssh` on physical console or serial
3. **Service recovery**: restart failed services
   - `sudo systemctl restart demosmesh`
   - `sudo systemctl restart cloudflared`
   - `sudo systemctl restart tailscaled`
4. **OS recovery**: if filesystem corrupted, re-flash and re-provision (see `provision`)
5. **Mesh recovery**: if DemosMesh routing broken, check `demosmesh` logs, re-sync routing tables
6. **Verify**: full `monitor <node-name>` pass
7. **Receipt**: post to bus — `STATUS node=<node-name> recovered ts=<ts> root_cause=<text>`

### `deploy <node-name>`

Deploy DemosMesh firmware/software updates to an edge node.

1. **Build**: on agent-node (or build host), `cd demosmesh && git pull && cargo build --release --target aarch64-unknown-linux-gnu`
2. **Transfer**: `scp target/aarch64-unknown-linux-gnu/release/demosmesh reuben@<node-name>:~/`
3. **Stop service**: `ssh reuben@<node-name> 'sudo systemctl stop demosmesh'`
4. **Swap binary**: replace installed binary, keep previous as `.bak`
5. **Start service**: `ssh reuben@<node-name> 'sudo systemctl start demosmesh'`
6. **Verify**: `ssh reuben@<node-name> 'systemctl is-active demosmesh && demosmesh --version'`
7. **Rollback if failed**: restore `.bak`, restart service, post BLOCKED
8. **Receipt**: post to bus — `STATUS node=<node-name> deployed version=<ver> ts=<ts>`

### `tunnel <node-name> [create|status|remove]`

Manage Cloudflare tunnels for edge nodes.

- `create`: `cloudflared tunnel create <node-name>`, configure ingress, DNS CNAME, systemd service
- `status`: `cloudflared tunnel info <node-name>`, verify connectivity from edge
- `remove`: `cloudflared tunnel delete <node-name>`, remove DNS records, cleanup systemd

### `mesh-status`

Full mesh topology and health overview.

```bash
# Tailscale topology
tailscale status

# DemosMesh routing tables
ssh reuben@<any-edge-node> 'demosmesh route show'

# Cloudflare tunnels
cloudflared tunnel list

# Fleet ping
hummbl-mesh-ping --machines machines.json
```

Surface a unified table: node | tailscale_ip | tailscale_state | demosmesh_state | tunnel_url | last_seen | disk | mem | load

## Safety Boundaries

- **No destructive ops without confirmation**: re-flashing OS, deleting tunnels, removing nodes from mesh
- **No firmware deployment to multiple nodes simultaneously** — deploy to one, verify, then proceed
- **Tailscale auth requires operator** — agent cannot approve Tailscale nodes; surface for operator action
- **Cloudflare credentials**: never log API tokens; use `cloudflared` with cert-auth or env vars
- **Physical access**: agent cannot physically interact with rpi5; surface any hardware-level needs for operator
- **Serial console**: if node unreachable via SSH, surface for operator physical console access

## Authority

- **T1-T2**: full execution — provision, operate, monitor, recover, deploy
- **T3**: monitor and operate only; provisioning and recovery require operator confirmation
- **T4**: monitor only (read-only)
- **Operator**: override any restriction

## Skill Chains

### Mandatory

- After `provision`: run `mesh-status` to verify new node integrated
- After `deploy`: run `monitor <node-name>` to verify deployment health
- After `recover`: run `monitor <node-name>` to verify full recovery

### Advisory

- Before `provision`: `[tunnel-check]` to verify Tailscale fleet connectivity
- During `monitor`: chain to `[bus]` for BLOCKED posts on node failures
- After `deploy`: `[rollback]` if deployment verification fails

## When to Use

- Provisioning a new rpi5 edge node
- Deploying DemosMesh updates to edge nodes
- Monitoring edge mesh health
- Recovering a failed edge node
- Managing Cloudflare tunnels for edge services
- Checking mesh topology and routing

## When NOT to Use

- General fleet health (use `[fleet-status]` or `[machine-health]`)
- Tailscale-only diagnostics without edge context (use `[tailscale-status]`)
- Cloudflare Workers/Pages deployment (use `[cloudflare]` or `[wrangler]`)
- Non-edge embedded work (use `metal` repo directly)

## Changelog

### v0.1.0 (2026-08-31)
- Initial skill authored from evidence base: demosmesh, edge-agent-bench, hummbl-mesh,
  hummbl-production (Cloudflare), metal, hummbl-engineering repos
- Covers full edge-node lifecycle: provision, operate, monitor, recover, deploy, tunnel, mesh-status
- Safety boundaries: no destructive ops without confirmation, no multi-node simultaneous deploy,
  Tailscale auth requires operator, physical access surfaced for operator
