---
name: rag-rerank
description: Rerank retrieved documents with cross-encoders or LLM-based reranking for improved precision
version: 0.1.0
execution-mode: advisory
argument-hint: "<query> <documents> [--model cross-encoder|cohere|llm] [--top-k 5]"
category: backend-infra
status: candidate
---
# rag-rerank | Rerank Retrieved Documents for Improved RAG Precision

## When to Use
- Improving precision of top-k retrieved documents in a RAG pipeline
- Reordering first-stage retrieval results with a more expensive, accurate model
- Boosting relevant docs that rank low in vector or BM25 search
- Evaluating reranker model choices (cross-encoder vs LLM-judge vs API)

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<query> <documents>` (documents: file path to JSONL or directory)
- `--model`: `cross-encoder` | `cohere` | `llm` (default `cross-encoder`)
- `--top-k`: number of documents to return after reranking (default 5)
- `--cross-encoder-model`: specific cross-encoder checkpoint (default `ms-marco-MiniLM-L-6-v2`)
- `--llm-model`: LLM for LLM-based reranking (default `gpt-4o-mini`)

### 2. Load Query & Documents
- Parse query string and document list (each doc: `{id, text, score, source}`)
- Validate documents are non-empty and text is retrievable
- Record initial retrieval order and scores for comparison
- Warn if document count < top-k (no reranking needed)

### 3. Score Documents with Reranker
- **cross-encoder**: load model, compute `(query, doc)` relevance score per document
- **cohere**: call Cohere Rerank API with query and documents
- **llm**: prompt LLM to rate each document's relevance to query (1-10 scale)
- Normalize scores to [0, 1] for cross-model comparison

### 4. Reorder & Select Top-K
- Sort documents by reranker score descending
- Select top-k documents
- Compare new order against original retrieval order (rank changes, new entries)
- Compute NDCG@k improvement if ground-truth relevance labels available

### 5. Export Reranked Results
- Save reranked documents to `_state/rag-rerank-<timestamp>.json`
- Each record: `{id, text, original_rank, new_rank, rerank_score}`
- Print order comparison and precision delta

## Output Format

```
rag-rerank | <query>

## Configuration
- Model: cross-encoder | Top-k: 5 | Documents: 20

## Reranking Results
| Rank | Doc ID | Original rank | Rerank score | Change |
|------|--------|---------------|--------------|--------|
| 1    | doc-07 | 3             | 0.94         | +2     |
| 2    | doc-12 | 1             | 0.91         | -1     |
| 3    | doc-03 | 5             | 0.88         | +2     |
| 4    | doc-15 | 8             | 0.85         | +4     |
| 5    | doc-01 | 2             | 0.82         | -3     |

## Impact
| Metric          | Before  | After   |
|-----------------|---------|---------|
| Precision@5     | 0.60    | 0.80    |
| NDCG@5          | 0.71    | 0.89    |
| Rank changes    | --      | 4 of 5  |

## Verdict
RERANKED | precision@5 0.60 -> 0.80 | NDCG@5 +0.18
```

## Skill Chains
- After reranking -> `[rag-pipeline]` to integrate reranker into the pipeline
- Before reranking -> `[rag-evaluate]` to measure reranker impact on end-to-end quality
- For LLM-based reranking via free-tier -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)
