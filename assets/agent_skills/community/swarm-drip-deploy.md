---
name: swarm-drip-deploy
description: Formalized drip-deployment strategy for continuous fleet auditing with host-health throttling to prevent CPU/Memory redlining.
tags: [swarm, automation, continuous-audit, load-balancing]
version: 0.1.0
execution-mode: side_effecting
category: fleet-ops
status: candidate
---

# Swarm Drip-Deploy Protocol

This skill defines the canonical methodology for launching a continuous, staggered multi-agent swarm against a massive fleet (e.g., the 373 HUMMBL repositories). 

Deploying too many agents concurrently will trigger severe host machine redlining (100% CPU, OOM crashes). The Drip-Deploy Protocol mitigates this by scheduling staggered agent deployments tied to live hardware telemetry.

## 1. The Strategy
Instead of invoking 50 subagents simultaneously, the primary orchestrator establishes a **60-second cron cycle**. On each cycle, a single lightweight `flash` subagent is deployed to a random or sequenced target.

## 2. Implementation Execution
To execute a drip-deploy, the orchestrator must use the `schedule` tool (or the `/schedule` user slash command).

### The Cron Payload
```json
{
  "CronExpression": "* * * * *",
  "Prompt": "The 60-second timer has elapsed. Validate host hardware health. If healthy, deploy 1 new 'Continuous Audit' subagent to a target repository."
}
```

## 3. Host-Health Throttling (The Governor)
Before executing the `invoke_subagent` call on a cron tick, the orchestrator MUST verify host machine health to prevent the swarm from crashing the local machine (as observed when 16 agents consumed 31.8GB of RAM).

**Windows WMI Telemetry Command:**
```powershell
$mem = Get-CimInstance Win32_OperatingSystem
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
[PSCustomObject]@{
  CPU_Percent = $cpu
  Mem_Free_GB = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
} | ConvertTo-Json
```

**Throttle Rules:**
- If `CPU_Percent` > 90%, SKIP deployment this cycle.
- If `Mem_Free_GB` < 2.0, SKIP deployment this cycle.
- If safe, execute `invoke_subagent`.

## 4. The Kill Switch
The orchestrator must always maintain awareness of the cron Task ID. When the fleet is fully audited or the user requests a halt, the orchestrator must terminate the drip-deploy using the `manage_task` tool with `Action: 'kill'`.

To instantly recover memory in an OOM crisis, the orchestrator should run `manage_subagents` with `Action: 'kill_all'`.

## 5. Surveillance Partite Nomenclature Taxonomy

When describing multi-surface surveillance scope across fleet sweeps and orchestrations, adhere to the canonical Latin numerical *-partite* series:

| Parts | Term | Scope Definition / Surface Context |
| :---: | :--- | :--- |
| **1** | **Unipartite** | Single-party or single-surface (e.g., Bus only) |
| **2** | **Bipartite** | Two-party or dual-surface (e.g., Bus + GitHub) |
| **3** | **Tripartite** | Three-surface (Bus + GitHub + Local Git) |
| **4** | **Quadripartite** | Four-surface (Bus + GitHub + Local Git + Canonical Governance `~/.agents`) |
| **5** | **Quinquepartite** *(or Pentapartite)* | Five-surface (Adding Hardware Telemetry / WMI Governor) |
| **6** | **Sexpartite** *(or Hexapartite)* | Six-surface (Adding Cross-Node Remote Mesh / Tailscale) |
| **7** | **Septempartite** *(or Heptapartite)* | Seven-surface (Full `/nexus` surface gamut) |
| **8** | **Octopartite** | Eight-surface |
| **N** | **Multipartite** | Arbitrary multi-surface surveillance across distributed fleets |

