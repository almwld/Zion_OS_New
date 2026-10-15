---
name: omni-researcher
description: Adaptive and dynamic agentic researcher swarm using poly-agent. Classifies input, dynamically builds a poly-agent manifest, streams JSONL findings via stdlib Python, and renders the result.
version: 0.1.0
execution-mode: side_effecting
argument-hint: "<research-prompt>"
providers:
  required: [python]
---
# Omni-Researcher

Adaptive meta-researcher that maps natural language prompts to specific research skill clusters, dispatches a poly-agent swarm, and streams the output in JSONL for final rendering.

## Architecture

1. **Classification Gate**: Analyzes the prompt and selects the optimal combination of research clusters (e.g., Aggregator Sweep vs Academic Deep Dive).
2. **Dynamic Manifest**: Generates a poly-agent YAML manifest specifying the exact lanes, topologies (fan/dag), and context budgets.
3. **Data Stream (JSONL)**: Dispatches lanes via poly-agent. Lanes write their structured findings (Claim / Evidence / Confidence) as JSONL to a stream. Enforces stdlib-only Python for the stream processor to eliminate dependency drift.
4. **Post-Render**: Parses the JSONL stream into a final session-render dashboard or Markdown report.

## Usage

`ash
python ~/.agents/skills/omni-researcher/omni_stream.py "What is the state of the art in edge AI inference?"
`

## JSONL Data Protocol

Each lane must emit valid JSON strings into the stream with the following schema:
`json
{"lane_id": "lane-1", "type": "status", "status": "running", "timestamp": "2026-09-02T18:00:00Z"}
{"lane_id": "lane-1", "type": "finding", "claim": "Edge AI models are shifting from INT8 to FP8.", "confidence": "high", "source": "arxiv-1234.56789"}
{"lane_id": "lane-1", "type": "complete", "result": "success"}
`

## Required Scripts
- omni_stream.py: stdlib-only python orchestrator that generates the manifest, manages the subprocess streams, and aggregates the JSONL output.