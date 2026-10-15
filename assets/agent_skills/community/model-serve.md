---
name: model-serve
description: Serve ML models via REST/gRPC with batching, autoscaling, and health checks
version: 0.1.0
execution-mode: advisory
argument-hint: "<model-path> [--framework vllm|tgi|triton|fastapi] [--port 8000]"
category: backend-infra
status: candidate
---
# model-serve | Serve ML Models via REST/gRPC with Batching & Autoscaling

## When to Use
- Deploying a model as an inference API endpoint
- Serving multiple concurrent requests with dynamic batching
- Setting up production inference with health checks and autoscaling
- Benchmarking serving frameworks before committing to one

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<model-path>` (HF repo or local dir)
- `--framework`: `vllm` | `tgi` | `triton` | `fastapi` (default `vllm`)
- `--port`: serving port (default 8000)
- `--max-batch-size`: dynamic batch size (default 32)
- `--replicas`: number of model replicas (default 1)

### 2. Validate Environment
- Confirm GPU available and VRAM sufficient for model + KV cache
- Check framework installed (`vllm`, `text-generation-inference`, `tritonserver`, `fastapi`)
- Verify port is free; warn if occupied
- Estimate required VRAM: model size + batch * KV cache

### 3. Configure Serving Framework
- **vllm**: `python -m vllm.entrypoints.api_server --model <path> --port <port>`
- **tgi**: `text-generation-launcher --model-id <path> --port <port>`
- **triton**: write `config.pbtxt` with dynamic batching policy and model repo
- **fastapi**: generate `serve.py` with `/generate` and `/health` endpoints

### 4. Launch Server
- Start server in background; poll `/health` until ready (timeout 120s)
- Configure dynamic batching: max batch size, max wait time (default 10ms)
- Enable continuous batching where supported (vllm, tgi)
- Set up graceful shutdown handler

### 5. Verify Endpoint
- Send test request to `/generate` with sample prompt
- Confirm response schema and latency
- Run 10 concurrent requests to validate batching behavior
- Report server URL, health status, and throughput

## Output Format

```
model-serve | <model-path>

## Configuration
- Framework: vllm | Port: 8000 | Replicas: 1
- Max batch size: 32 | Continuous batching: enabled

## Server Status
| Check           | Result                        |
|-----------------|-------------------------------|
| Health endpoint | OK (200)                      |
| Generate test   | OK (latency 85 ms)            |
| Concurrent x10  | OK (avg 120 ms, batched 8)    |
| VRAM usage      | 16.2 / 24.0 GB                |

## Endpoints
- POST /generate  -- inference
- GET  /health    -- liveness
- GET  /metrics   -- Prometheus

## Verdict
SERVING | http://localhost:8000 | vllm | throughput 813 tok/s
```

## Skill Chains
- After serving -> `[deploy-health]` to set up monitoring and alerts
- After serving -> `[latency-percentile]` to profile tail latency
- Before serving -> `[mlops-deploy]` to provision infrastructure
- Edge inference baseline -> `[stream-inference]` to compare local throughput vs Cloudflare Workers AI (`python ~/bin/stream_test.py <model> --prompt "test"`)
