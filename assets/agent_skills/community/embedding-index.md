---
name: embedding-index
description: Build and manage vector embedding indices — HNSW, IVF, or flat indices with metadata filtering
version: 0.1.0
execution-mode: advisory
argument-hint: "<vectors-or-docs> [--index-type hnsw|ivf|flat] [--metric cosine|l2|dot]"
category: backend-infra
status: candidate
---
# embedding-index | Vector Embedding Index Management

## When to Use
- Building a vector store for semantic search or RAG pipelines
- Comparing index types (HNSW, IVF, flat) for latency vs recall tradeoffs
- Adding metadata-filtered nearest-neighbor search
- Rebuilding or reindexing after embedding model changes

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: path to vectors (`.npy`, `.json`) or documents to embed
- `--index-type hnsw|ivf|flat`: index structure (default `hnsw`)
- `--metric cosine|l2|dot`: distance metric (default `cosine`)
- `--dim N`: vector dimensionality (auto-detect if not specified)

### 2. Load or Generate Vectors
- If documents provided, generate embeddings using configured model
- If vectors provided, load and validate shape `(N, dim)`
- Report count, dimensionality, and memory footprint

### 3. Build Index
- **hnsw**: Set `M=16`, `ef_construction=200`, `ef_search=50` (tunable)
- **ivf**: Set `nlist=100` (or `sqrt(N)`), train with k-means
- **flat**: Brute-force exact search, no training needed
- Use `faiss`, `hnswlib`, or `annoy` depending on availability
- Persist index to `_state/indices/<name>.index`

### 4. Attach Metadata
- Store metadata (doc_id, source, tags) in parallel JSON or SQLite
- Enable pre-filtering: filter by metadata before vector search
- Validate all vectors have corresponding metadata entries

### 5. Evaluate Index Quality
- Run recall@k test against ground-truth (if available)
- Measure query latency p50/p99 on sample queries
- Report index size on disk and build time

### 6. Serialize and Document
- Save index file and metadata store
- Write config JSON: index type, metric, dim, params, model name
- Record build timestamp and vector count for reproducibility

## Output Format

```
embedding-index | <name>

## Configuration
- Index type: hnsw | Metric: cosine | Dim: 768
- Vectors: 50,000 | Model: text-embedding-3-small

## Build
- M: 16 | ef_construction: 200 | ef_search: 50
- Build time: 42.3s | Index size: 89.4 MiB
- Metadata store: _state/indices/<name>.meta.json

## Quality
| Metric       | Value  |
|--------------|--------|
| Recall@10    | 0.97   |
| Latency p50  | 1.2 ms |
| Latency p99  | 4.8 ms |

## Files
- Index: _state/indices/<name>.index
- Config: _state/indices/<name>.config.json

## Verdict
READY / LOW_RECALL / BUILD_FAILED / METADATA_MISMATCH
```

## Skill Chains
- After index built -> `[rag-pipeline]` to wire retrieval into generation
- After index built -> `[rag-hybrid]` to combine with keyword search
- Before indexing -> `[rag-evaluate]` to establish evaluation harness
