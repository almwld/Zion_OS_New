---
name: quinquepartite-watch
description: Continuous five-surface autonomous surveillance orchestrator governing Coordination Bus, Remote GitHub, Local Git Repositories, Canonical Governance Root, and Host Hardware Telemetry.
tags: [governance, surveillance, swarm, monitoring, bus, hardware-governor, audit]
version: 1.0.0
execution-mode: advisory
category: fleet-ops
status: candidate
---

# quinquepartite-watch

Continuous, autonomous five-surface surveillance engine for the HUMMBL agent mesh.

Extends the tripartite and quadripartite monitoring disciplines into a comprehensive **quinquepartite** (5-surface) monitoring loop governed by hardware telemetry thresholds and strict coordination bus protocol.

---

## 1. The Five Surfaces (Quinquepartite Taxonomy)

| Surface # | Surface Name | Canonical Path / Endpoint | Monitored Entities & Invariants |
| :---: | :--- | :--- | :--- |
| **S1** | **Coordination Bus** | https://bus.hummbl-dev.com<br>/opt/hummbl-governance/_state/coordination/messages.tsv | 100% ACK delivery for proposals/sitreps; strict host=<origin> prefix enforcement; receipt durability checks. |
| **S2** | **Remote GitHub** | github.com/hummbl-io/* | PR drift, merge gates, CI workflow run pass/fail/timeout states, issue triage. |
| **S3** | **Local Git Workspaces** | ~\PROJECTS\* (380+ repos) | Dirty working trees, untracked files, unpushed commits on feature branches (PSI-*, hummbl-*), worktree preservation. |
| **S4** | **Canonical Governance** | ~\.agents & ~/.agents | Rules (
ules/*.md), guardrails, skills (skills/), agent definitions (gents/), contract schemas (contracts/), cross-node drift between Workstation and Delta. |
| **S5** | **Hardware Telemetry** | Windows WMI (Win32_OperatingSystem, Win32_Processor) | Real-time CPU load percentage ($\le 90\%$) and free physical memory ($\ge 2.0\text{ GB}$) to throttle swarm expansion. |

---

## 2. Invocation Protocol (§0 Discipline)

Before initiating surveillance cycles, the agent MUST post a SKILL_INVOKE message to the bus:

`powershell
~\bin\bus-post.ps1 <sender> all SKILL_INVOKE "host=agent-node surface=antigravity [skill=quinquepartite-watch] [mode=side_effecting] task=continuous-five-surface-fleet-surveillance"
`

---

## 3. The Hardware Telemetry Throttle

Before spawning subagent sentinels, test the host state:

`powershell
 = Get-CimInstance Win32_OperatingSystem
 = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
[PSCustomObject]@{
  CPU_Percent = 
  Mem_Free_GB = [math]::Round(.FreePhysicalMemory / 1MB, 2)
} | ConvertTo-Json
`

- **Throttling Invariants**:
  - CPU_Percent > 90% -> **SKIP** subagent dispatch this cycle.
  - Mem_Free_GB < 2.0 -> **SKIP** subagent dispatch this cycle.

---

## 4. Subagent Sentinel Swarm Architecture

The orchestrator manages a multi-sentinel swarm mapped to the five surfaces:

1. **Bus Sentinel**: High-frequency tail (us-global.py tail 20) and cryptographic receipt verification.
2. **GitHub Sentinel**: Remote PR and CI monitor (gh pr list, gh run list).
3. **Local Workspace Sentinel**: Macro dirty-tree scanner across ~\PROJECTS.
4. **Governance Integrity Sentinel**: Canonical root auditor (~/.agents) tracking rule and skill drift.
5. **Security & Diff Sentinel**: Deep inspection of unpushed commits for credential/secret leaks.

---

## 5. Partite Scale Reference

Refer to the Latin numerical *-partite* taxonomy in swarm-drip-deploy §5:
- Unipartite (1) -> Bipartite (2) -> Tripartite (3) -> Quadripartite (4) -> **Quinquepartite (5)** -> Sexpartite (6) -> Septempartite (7) -> Multipartite (N).
