---
name: docker-manage
description: Inspect and manage Docker resources, including a non-mutating post-update verification checklist for Desktop, engine, containers, runners, and host memory.
version: 0.2.0
execution-mode: side_effecting
argument-hint: "[--action verify-update|ps|inspect|build|run|clean] [--image NAME]"
category: backend-infra
status: candidate
---

# Docker Manage

Default to `--action ps`. `verify-update`, `ps`, and `inspect` are read-only. Build, run, restart, update, and clean actions require their normal authority and confirmation gates.

## Post-update verification

Use `--action verify-update` after every Docker Desktop update:

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
[pscustomobject]@{
    MemoryUsedPercent = [math]::Round((1-$os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,1)
    MemoryFreeGiB = [math]::Round($os.FreePhysicalMemory*1KB/1GB,1)
    Uptime = ((Get-Date)-$os.LastBootUpTime).ToString()
} | Format-List
```

Pass when:

- Docker Desktop reports `running`.
- The update check explicitly reports current state.
- Client and server versions plus API negotiation are visible.
- `docker info` succeeds.
- Expected containers remain running without unhealthy/restarting states.
- Every expected CI runner has a recent connection/listener marker.
- Container and host resource use are captured.

`verify-update` must not pull images, create containers, restart Docker, or prune resources.

## Other actions

- `ps`: list all containers, status, ports, and one-shot resource use.
- `inspect`: run `docker inspect`, `docker logs --tail 50`, and `docker stats --no-stream` for an explicit target.
- `build`: locate the Dockerfile, print context and tag, then build after authorization.
- `run`: print image, ports, volumes, and environment-variable names before authorization. Never print secret values.
- `clean`: run `docker system df`, obtain explicit confirmation, then prune only the approved resource classes.

## Output

| Check | Result | Evidence |
|---|---|---|
| Desktop/update | `OK/WARN/FAIL` | exact output |
| Client/server/API | `OK/WARN/FAIL` | versions |
| Engine | `OK/FAIL` | `docker info` |
| Containers | counts and unhealthy/restarting list | `docker ps` |
| CI runners | listener proof per expected runner | bounded logs |
| Resources | container and host values | stats |

Do not infer that an update caused a resource change without a comparable pre-update baseline.

## Skill Chains

### Mandatory

- None — this skill is self-contained.

## Authority

- **T1 (TRUSTED)**: May run without restriction
- **T2 (Active/High)**: May run without restriction
- **T3 (Medium)**: MUST get operator approval before execution
- **T4 (Probationary)**: BLOCKED — cannot invoke this skill
