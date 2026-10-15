---
name: nsight-frame-profiler
description: Profiles D3D12/Vulkan/CUDA executables using NVIDIA Nsight CLI (nsys/ncu), isolates GPU vs CPU bottlenecks, and reports SM occupancy and memory throughput.
version: 1.0.0
execution-mode: advisory
container:
  tier: "3"
  base_image: "nvidia/cuda:12.4.1-devel-ubuntu22.04"
  gpu: true
category: dev-tools
status: candidate
providers:
  required: [docker, pytest, python, uv]
  off-host: [workstation]
---

# NVIDIA Nsight Frame Profiler

When invoked to profile a game executable or render pass on the RTX 3080 Ti:

## 1. Trace Execution

Run Nsight Systems CLI targeting graphics APIs and GPU metrics:

```bash
nsys profile \
  --trace=vulkan,dx12,cuda,nvtx,osrt \
  --gpu-metrics-device=0 \
  --sample=process-tree \
  --output=./profiles/capture_%p \
  --force-overwrite=true \
  --duration=15 \
  path/to/game_executable.exe
```

## 2. Metric Extraction

Parse the resulting `.nsys-rep` or export stats to SQLite/JSON:

```bash
nsys stats \
  --report gputrace,gpumetricsum \
  --format json \
  --output ./profiles/summary \
  ./profiles/capture_*.nsys-rep

python3 ~/.agents/skills/nsight-frame-profiler/scripts/main.py \
  --executable path/to/game_executable.exe \
  --duration 15 \
  --vram-limit 12288 \
  --json-output profile_result.json
```

## 3. Bottleneck Analysis

Evaluate extracted metrics against RTX 3080 Ti hardware limits:

- **SM Throughput / Occupancy**: Target > 65% active warps across 80 SMs.
- **Memory Bandwidth**: Flag any sub-pass exceeding 800 GB/s (>85% of the 912 GB/s GDDR6X ceiling).
- **Pipeline Bubbles**: Highlight GPU idle intervals > 0.5 ms caused by CPU draw submission stalls.

## CLI Usage

```bash
# Dry run (validates nsys/ncu availability)
python scripts/main.py --dry-run --json-output /dev/stdout

# Profile an executable
python scripts/main.py \
  --executable /path/to/game.exe \
  --duration 15 \
  --vram-limit 12288 \
  --json-output result.json

# With docker compose
docker compose run --rm skill \
  --executable /workspace/game.exe \
  --duration 15 \
  --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "nsight-frame-profiler",
  "version": "1.0.0",
  "result": {
    "executable": "string",
    "duration_seconds": "int",
    "profile_report": "string",
    "summary_dir": "string",
    "analysis": {
      "gpu": "RTX 3080 Ti",
      "architecture": "Ampere (GA102)",
      "sm_count": 80,
      "max_bandwidth_gb_s": 912,
      "vram_limit_mb": 12288,
      "findings": [
        {
          "category": "SM Throughput",
          "target": "> 65% active warps across 80 SMs",
          "status": "PASS|FAIL|NEEDS_DATA",
          "recommendation": "string"
        }
      ]
    }
  },
  "error": null|"string"
}
```

## Container

- **Tier**: 3 (Full CUDA Dev - needs nsys, ncu, nvcc)
- **Base Image**: `nvidia/cuda:12.4.1-devel-ubuntu22.04`
- **GPU**: Required (`--gpus all`)
- **Volumes**: Workspace (RW), Cache (RO), Config (RO)