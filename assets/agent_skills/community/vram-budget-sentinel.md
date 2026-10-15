---
name: vram-budget-sentinel
description: 12 GB VRAM memory allocator and texture footprint auditor. Hooks into nvidia-smi and Vulkan/DXGI memory heaps during runtime or asset imports, calculating render target allocations, shadow cascades, and Ray Tracing Top-Level Acceleration Structure (TLAS/BLAS) memory overhead.
version: 1.0.0
execution-mode: advisory
container:
  tier: "2"
  base_image: "nvidia/cuda:12.4.1-runtime-ubuntu22.04"
  gpu: true
category: dev-tools
status: candidate
providers:
  required: [docker, pytest, python, uv]
  pip: [nvidia-ml-py]
  off-host: [workstation]
---

# VRAM Budget Sentinel

Monitors and audits VRAM usage on RTX 3080 Ti (12 GB GDDR6X), flagging assets pushing VRAM past 10.5 GB to avoid the catastrophic performance cliff of PCIe host-memory paging.

## CLI Usage

```bash
# Dry run (validates environment)
python scripts/main.py --dry-run --json-output /dev/stdout

# Check VRAM budget
python scripts/main.py --json-output result.json

# With custom thresholds
python scripts/main.py --warning-threshold 1024 --critical-threshold 512 --json-output result.json

# With docker compose
docker compose run --rm skill --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "vram-budget-sentinel",
  "version": "1.0.0",
  "result": {
    "gpu_name": "NVIDIA GeForce RTX 3080 Ti",
    "memory": {
      "total_mb": 12288,
      "used_mb": 3992,
      "free_mb": 8296
    },
    "analysis": {
      "total_mb": 12288,
      "used_mb": 3992,
      "free_mb": 8296,
      "usage_percent": 32.5,
      "status": "ok|warning|critical",
      "warning_threshold_mb": 1024,
      "critical_threshold_mb": 512,
      "recommendations": [
        "Consider texture streaming for assets > 512MB",
        "Offload non-critical models to system RAM",
        "Enable texture compression (BC7/ASTC)"
      ]
    }
  },
  "error": null
}
```

## Status Levels

| Status | Free VRAM | Action |
|--------|-----------|--------|
| `ok` | > 1024 MB | Normal operation |
| `warning` | 512-1024 MB | Review large assets, consider compression |
| `critical` | < 512 MB | Immediate action required, risk of PCIe paging |

## Container

- **Tier**: 2 (CUDA Runtime)
- **Base Image**: `nvidia/cuda:12.4.1-runtime-ubuntu22.04`
- **GPU**: Required (`--gpus all` for driver mount)
- **Volumes**: Workspace (RW), Cache (RO), Config (RO)