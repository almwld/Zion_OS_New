---
name: machine-inventory
description: Hardware and software inventory across all machines with diff capability
version: 0.2.0
execution-mode: advisory
argument-hint: "[--machine local|all] [--diff-since DATE]"
category: fleet-ops
status: candidate
---
# Machine Inventory

Hardware and software inventory across all machines with diff capability to spot changes. Maintains a record of what is installed where, enabling change tracking and capacity planning.

## When to Use
- Need to know what hardware/software is available on each machine
- Tracking changes to the environment over time
- Planning where to run a workload based on capabilities
- Documenting the mesh for onboarding or reference

## Execution
1. Parse `$ARGUMENTS` for `--machine` (default: `local`) and `--diff-since` (optional date)
   Resolve fleet roles from `~/.agents/rules/machine-roster.md` and
   `~/.agents/ROSTER.md`. `all` means active hosts only: Huxley is retired,
   remote-node is dormant and requires a separately approved re-entry lane.
2. Collect inventory for specified machines:
   - **Hardware**: CPU (model, cores), RAM (total, available), GPU (model, VRAM), disk (total, free), OS version
   - **Software**: Python version, key CLI tools and versions, running services, package managers
   - **Network**: hostname, Tailscale IP, SSH accessibility
   - **Capabilities**: CUDA available, MLX available, Ollama status, Docker status
3. For local machine: use system commands (python --version, systeminfo/sysctl, nvidia-smi, etc.)
4. For remote machines: SSH only within operator-authorized scope. Reuse existing
   authorization; do not ask again. Separate DNS, TCP, SSH authentication, and
   route evidence. Discover current addresses instead of using stored IPs.
5. Write inventory snapshot to a runtime-state directory outside repositories,
   such as `~/_state/ops/inventory/{machine}_{date}.json` on agent-node. Record UTC
   capture time and skipped probes. Save only credential presence if needed;
   never secret values, environment dumps, or authenticated command arguments.
6. If `--diff-since`: load previous snapshot and diff against current
   - Added: new software/hardware
   - Removed: uninstalled or disconnected
   - Changed: version updates, capacity changes
7. Display summary using current machine roles. Distinguish installed capability
   from tested availability (for example, CUDA toolkit vs a successful workload,
   or a runner service vs a verified GitHub connection).

## Output Format
```
Machine Inventory | {machine} | {date}

{machine_name} ({os}):
  CPU: {model} ({cores} cores)
  RAM: {total} ({available} free)
  GPU: {model} ({vram}) {cuda/mlx status}
  Disk: {total} ({free} free)
  Network: {hostname} / {tailscale_ip}
  Python: {version}
  Key Tools: {list}
  Services: {list}

{diff section if --diff-since}

Next action: {recommendation}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Inventory complete | `[fleet-status]` for operational status |
| Capacity questions | `[cross-machine-task]` to run on best machine |
| Changes detected | `[config-drift]` for detailed comparison |
