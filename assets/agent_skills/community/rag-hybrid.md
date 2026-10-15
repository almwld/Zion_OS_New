---
name: rag-hybrid
description: Combine keyword (BM25) and semantic (vector) search in hybrid RAG pipelines with reciprocal rank fusion
version: 0.1.0
execution-mode: advisory
argument-hint: "<query> [--bm25-weight 0.3] [--vector-weight 0.7] [--fusion rrf|linear]"
category: backend-infra
status: candidate
---
# rag-hybrid | Hybrid Keyword + Semantic Search with Rank Fusion

## When to Use
- Combining BM25 keyword search and vector semantic search for better recall
- Handling queries with exact terms (IDs, names) that semantic search misses
- Handling conceptual queries that keyword search misses
- Evaluating fusion strategies (RRF vs linear weighted) for a corpus

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<query>` (search query string)
- `--bm25-weight`: weight for BM25 scores in linear fusion (default 0.3)
- `--vector-weight`: weight for vector scores in linear fusion (default 0.7)
- `--fusion`: `rrf` | `linear` (default `rrf`)
- `--top-k`: number of final results to return (default 10)
- `--corpus`: path to document corpus index (BM25 + vector store)

### 2. Run Parallel Retrieval
- **BM25**: query the keyword index; return top-N documents with BM25 scores
- **Vector**: embed query and search vector store; return top-N with cosine similarity
- Run both retrievals in parallel to minimize latency
- Record per-retrieval rankings and scores

### 3. Apply Rank Fusion
- **RRF (Reciprocal Rank Fusion)**: `score = sum(1 / (k + rank))` for each retriever, k=60
- **Linear**: `score = bm25_weight * norm(bm25) + vector_weight * norm(vector)`
- Normalize scores per retriever to [0,1] before linear fusion
- Merge document IDs from both retrievers into unified candidate set

### 4. Select Top-K & Deduplicate
- Sort fused candidates by combined score descending
- Deduplicate documents appearing in both retrievers (keep highest fused score)
- Select top-k final results
- Record which retriever contributed each result (bm25, vector, or both)

### 5. Report Fusion Impact
- Compare hybrid top-k against BM25-only and vector-only top-k
- Compute recall improvement over single-retriever baselines
- Identify queries where hybrid outperforms or underperforms either retriever alone
- Save results to `_state/rag-hybrid-<timestamp>.json`

## Output Format

```
rag-hybrid | <query>

## Configuration
- Fusion: rrf | BM25 weight: 0.3 | Vector weight: 0.7 | Top-k: 10

## Retrieval Comparison
| Rank | Doc ID  | BM25 rank | Vector rank | Fused score | Source   |
|------|---------|-----------|-------------|-------------|----------|
| 1    | doc-42  | 1         | 3           | 0.0328      | both     |
| 2    | doc-17  | 5         | 1           | 0.0317      | both     |
| 3    | doc-88  | --        | 2           | 0.0161      | vector   |
| 4    | doc-03  | 2         | --          | 0.0159      | bm25     |

## Recall Impact
| Strategy     | Recall@10 |
|--------------|-----------|
| BM25 only    | 0.65      |
| Vector only  | 0.72      |
| Hybrid (RRF) | 0.88      |

## Verdict
HYBRID | recall@10 0.88 | +0.16 over vector | +0.23 over bm25
```

## Skill Chains
- After hybrid search -> `[rag-pipeline]` to integrate into end-to-end pipeline
- After hybrid search -> `[rag-rerank]` to add a reranking stage on fused results
- Before hybrid search -> `[rag-evaluate]` to define eval criteria for retrieval quality
