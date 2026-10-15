---
name: machine-health
description: Verify local and fleet health with layered SSH, Tailscale route, Docker, resource, and compare-only repository checks.
version: 1.1.1
execution-mode: advisory
argument-hint: "[workstation|huxley|remote-node|all] [--include-dormant-remote-node] [--post-docker-update]"
category: fleet-ops
status: tested
providers:
  required: [bash, python]
---

# Machine Health

Produce evidence for each layer. Do not reduce DNS, TCP, SSH negotiation, authentication, or Tailscale route failures to a single `UNREACHABLE` result.

## Fleet policy

| Machine | Alias | Observed Tailscale IP | Role |
|---|---|---|---|
| Workstation | `workstation` | `[REDACTED_NODE_IP]` | Primary Windows/GPU host and canonical bus |
| Huxley | `huxley` | `[REDACTED_NODE_IP]` | Secondary macOS host; may sleep |
| remote-node | `mini` / `remote-node` | `[REDACTED_NODE_IP]` (last observed; off tailnet 2026-09-20) | Dormant/receive-only service host; never bus authority |

Treat IPs as observed values. Prefer the current `tailscale status` mapping and report drift.

Do not probe remote-node by default. Probe it only when `--include-dormant-remote-node` is explicitly supplied or the operator has approved a re-entry lane. Re-entry never implies permission to sync repositories, merge ledgers, restart services, remove SSH keys, or restore authority.

## 1. Local baseline

On Windows:

```powershell
$os = Get-CimInstance Win32_OperatingSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$uptime = (Get-Date) - $os.LastBootUpTime
[pscustomobject]@{
    Host = $env:COMPUTERNAME
    DiskUsedPercent = [math]::Round((1-$disk.FreeSpace/$disk.Size)*100,1)
    DiskFreeGiB = [math]::Round($disk.FreeSpace/1GB,1)
    MemoryUsedPercent = [math]::Round((1-$os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,1)
    MemoryFreeGiB = [math]::Round($os.FreePhysicalMemory*1KB/1GB,1)
    Uptime = $uptime.ToString()
} | Format-List
Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion
```

On macOS:

```bash
hostname
sw_vers
df -h /
vm_stat
sysctl -n vm.loadavg
uptime
```

## 2. Layered SSH classification

On Windows, run this function for each in-scope alias. Preserve stderr in the evidence.

```powershell
function Test-FleetSsh {
    param([Parameter(Mandatory)][string]$Alias)

    $configPath = Join-Path $HOME ".ssh\config"
    $declared = $false
    if (Test-Path $configPath) {
        foreach ($line in Get-Content $configPath) {
            if ($line -match '^\s*Host\s+(.+)$') {
                if (($Matches[1] -split '\s+') -contains $Alias) { $declared = $true }
            }
        }
    }
    if (-not $declared) {
        return [pscustomobject]@{Alias=$Alias; State="CONFIG_MISSING"; Detail=$configPath}
    }

    $effective = & ssh -G $Alias 2>&1
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{Alias=$Alias; State="CONFIG_ERROR"; Detail=($effective -join " ")}
    }
    $hostName = (($effective | Select-String '^hostname ' | Select-Object -First 1).Line -split '\s+')[1]
    $userName = (($effective | Select-String '^user ' | Select-Object -First 1).Line -split '\s+')[1]

    if ($hostName -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
        try { Resolve-DnsName $hostName -ErrorAction Stop | Out-Null }
        catch { return [pscustomobject]@{Alias=$Alias; Target=$hostName; User=$userName; State="DNS_FAIL"; Detail=$_.Exception.Message} }
    }

    if (-not (Test-NetConnection $hostName -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue)) {
        return [pscustomobject]@{Alias=$Alias; Target=$hostName; User=$userName; State="TCP_22_CLOSED_OR_TIMEOUT"; Detail="Port 22 probe failed"}
    }

    $sshOutput = & ssh -o BatchMode=yes -o ConnectTimeout=5 $Alias "echo SSH_OK" 2>&1
    $sshCode = $LASTEXITCODE
    $detail = $sshOutput -join " "
    if ($sshCode -eq 0 -and $detail -match 'SSH_OK') { $state = "SSH_OK" }
    elseif ($detail -match 'Permission denied|authentication failures|no supported authentication') { $state = "SSH_AUTH_FAILED" }
    elseif ($detail -match 'Host key verification failed|REMOTE HOST IDENTIFICATION HAS CHANGED') { $state = "SSH_HOSTKEY_FAILED" }
    else { $state = "SSH_NEGOTIATION_FAILED" }

    [pscustomobject]@{Alias=$Alias; Target=$hostName; User=$userName; State=$state; Detail=$detail}
}

Test-FleetSsh huxley
# Re-entry only:
Test-FleetSsh mini
```

Valid states are `CONFIG_MISSING`, `CONFIG_ERROR`, `DNS_FAIL`, `TCP_22_CLOSED_OR_TIMEOUT`, `SSH_HOSTKEY_FAILED`, `SSH_AUTH_FAILED`, `SSH_NEGOTIATION_FAILED`, and `SSH_OK`.

## 3. Tailscale peer and route class

```powershell
tailscale status
tailscale ip -4
$routeEvidence = tailscale ping --c 10 [REDACTED_NODE_IP] 2>&1
$routeEvidence
if ($routeEvidence -match 'direct connection not established|via DERP') {
    "remote-node route: RELAY_ONLY"
} elseif ($routeEvidence -match 'pong from') {
    "remote-node route: DIRECT"
} else {
    "remote-node route: OFFLINE_OR_NO_REPLY"
}
```

If remote-node SSH is `SSH_OK`, collect a reciprocal sample:

```powershell
ssh -o ConnectTimeout=10 mini 'tailscale ping --c 10 workstation.tail16e16c.ts.net'
```

Report each direction separately. A DERP route is degraded but does not mean SSH authentication failed. If direct routing returns after bilateral pings, report the transition as observed; do not claim the pings caused it.

## 4. Docker post-update verification

Run when `--post-docker-update` is supplied and after every Docker Desktop update:

```powershell
docker desktop version
docker desktop status
docker desktop update --check-only
docker version
docker compose version
docker buildx version
docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Driver={{.Driver}} Containers={{.Containers}} Running={{.ContainersRunning}}'
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'

$runnerRows = docker ps --format '{{.Names}}|{{.Image}}' |
    Where-Object { $_ -match '(?i)(github|actions).*(runner)|runner.*(github|actions)' }
foreach ($row in $runnerRows) {
    $runnerName = ($row -split '\|',2)[0]
    Write-Output "[$runnerName]"
    docker logs --tail 80 $runnerName 2>&1 |
        Select-String 'Listening for Jobs|Runner reconnected|Connected to GitHub|Running job|completed with result' |
        Select-Object -Last 5
}

$os = Get-CimInstance Win32_OperatingSystem
"Host memory used: {0}%" -f [math]::Round((1-$os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,1)
```

Pass only when:

- Docker Desktop is running and the update check is explicit.
- Client and server versions/API negotiation are reported.
- The engine responds to `docker info`.
- Expected containers remain running and none are unhealthy/restarting.
- Every expected runner has a recent connection/listener marker.
- Resource use is captured after the update.

Do not pull images, start test containers, restart Docker, or prune resources as part of verification.

## 5. remote-node compare-only repository check

This section requires the approved re-entry flag:

```bash
for repo in \
  /Users/Shared/hummbl-io/hummbl-governance \
  $REMOTE_HOST/hummbl-governance \
  $REMOTE_HOST/workspace/hummbl-governance
do
  echo "REPO:$repo"
  git -c safe.directory="$repo" -C "$repo" branch --show-current
  git -c safe.directory="$repo" -C "$repo" rev-parse HEAD
  git -c safe.directory="$repo" -C "$repo" status --short --branch
done
```

Use command-scoped `safe.directory`; do not write global Git configuration. Do not fetch or mutate remote-node repositories. Label dirty, stale, or distinct repositories `QUARANTINED_NO_SYNC`.

## Output

Report the evidence matrix:

| Layer | State | Evidence |
|---|---|---|
| Local resources | `OK/WARN/CRIT` | exact values |
| SSH config | named state | alias, target, user |
| DNS | named state | resolver result |
| TCP 22 | named state | probe result |
| SSH auth | named state | exit code and sanitized stderr |
| Tailscale route | `DIRECT/RELAY_ONLY/OFFLINE_OR_NO_REPLY` | each direction |
| Docker | `OK/WARN/FAIL/NOT_REQUESTED` | versions, engine, containers, runners |
| remote-node repository state | `SKIPPED/QUARANTINED_NO_SYNC` | exact paths and HEADs |

Never report `HEALTHY` when a required layer is untested.

