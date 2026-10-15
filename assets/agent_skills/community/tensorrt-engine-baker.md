---
name: tensorrt-engine-baker
description: Headless ONNX-to-TensorRT engine compiler for in-game neural models. Compiles local AI models (NPC behavior trees, voice synthesis, style transfer, custom neural denoisers) via trtexec, targeting Ampere Tensor Cores with native FP16 and TF32 acceleration.
version: 1.0.0
execution-mode: advisory
container:
  tier: "TRT"
  base_image: "nvcr.io/nvidia/tensorrt:24.08-py3"
  gpu: true
category: dev-tools
status: candidate
providers:
  required: [docker, pytest, python, uv]
  off-host: [workstation]
---

# TensorRT Engine Baker

Compiles ONNX models to optimized TensorRT `.engine` binaries for low-latency in-engine inference on RTX 3080 Ti.

## CLI Usage

```bash
# Dry run (validates trtexec availability)
python scripts/main.py --dry-run --json-output /dev/stdout

# Build FP16 engine (default)
python scripts/main.py \
  --onnx model.onnx \
  --engine model_fp16.engine \
  --precision fp16 \
  --workspace 4096 \
  --batch 1 \
  --json-output result.json

# Build with validation
python scripts/main.py \
  --onnx model.onnx \
  --engine model_fp16.engine \
  --validate \
  --json-output result.json

# With docker compose
docker compose run --rm skill \
  --onnx /workspace/model.onnx \
  --engine /workspace/model_fp16.engine \
  --precision fp16 \
  --json-output /workspace/result.json
```

## Output Schema

```json
{
  "status": "ok|error",
  "skill": "tensorrt-engine-baker",
  "version": "1.0.0",
  "result": {
    "onnx_path": "model.onnx",
    "engine_path": "model_fp16.engine",
    "precision": "fp16",
    "workspace_mb": 4096,
    "batch_size": 1,
    "build": {
      "success": true,
      "stdout": "trtexec output...",
      "stderr": "",
      "engine_path": "model_fp16.engine"
    },
    "validation": {
      "success": true,
      "stdout": "Throughput: 1234 infer/sec...",
      "stderr": ""
    }
  },
  "error": null
}
```

## Precision Modes

| Mode | Use Case | RTX 3080 Ti Support |
|------|----------|---------------------|
| `fp32` | Maximum accuracy | ✅ Native |
| `fp16` | Balanced (default) | ✅ Native (Tensor Cores) |
| `tf32` | TF32 tensor cores | ✅ Native (Ampere) |
| `int8` | Maximum throughput | ✅ Requires calibration |

## Container

- **Tier**: TRT (TensorRT)
- **Base Image**: `nvcr.io/nvidia/tensorrt:24.08-py3`
- **GPU**: Required (`--gpus all`)
- **Volumes**: Workspace (RW), Cache (RO), Config (RO)
- **Includes**: TensorRT 10.9, ONNX parser, polygraphy, pycuda