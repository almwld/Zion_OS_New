---
name: rag-evaluate
description: Evaluate RAG pipeline quality with retrieval accuracy, faithfulness, answer relevance, and context recall
version: 0.1.0
execution-mode: advisory
argument-hint: "<rag-endpoint> --dataset <eval-set>"
category: backend-infra
status: candidate
---
# rag-evaluate | RAG Pipeline Quality Evaluation

## When to Use
- Measuring end-to-end RAG pipeline quality before deployment
- Comparing RAG configurations (chunking, retrieval, reranking, generation)
- Detecting retrieval failures, hallucinations, or low answer relevance
- Establishing a quality baseline for regression tracking

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<rag-endpoint>` (URL of RAG API)
- `--dataset`: eval dataset path (JSONL with `query`, `ground_truth`, `gold_context`)
- `--metrics`: subset of metrics to compute (default: all)
- `--sample`: number of eval queries to run (default: full dataset)

### 2. Load Eval Dataset
- Read JSONL eval set; validate each record has required fields
- Report dataset size and any malformed records
- Optionally subsample with `--sample N` for quick runs
- Shuffle order to avoid ordering bias

### 3. Run RAG Pipeline per Query
- Send each query to `<rag-endpoint>` and capture: answer, retrieved contexts, latency
- Store full trace (query, retrieved docs, generated answer, ground truth)
- Flag queries where no context was retrieved (empty retrieval)
- Flag queries where endpoint errors or times out

### 4. Compute Metrics
- **Retrieval accuracy**: fraction of queries where gold context appears in top-k
- **Faithfulness**: answer supported by retrieved context (LLM-judge or NLI model)
- **Answer relevance**: answer addresses the query (LLM-judge or embedding similarity)
- **Context recall**: fraction of gold context sentences covered by retrieved docs
- **Context precision**: fraction of retrieved docs that are relevant

### 5. Aggregate & Report
- Compute mean and per-query scores for each metric
- Identify failure clusters: low retrieval, low faithfulness, low relevance
- Rank queries by worst composite score for manual review
- Save full eval trace to `_state/rag-eval-<timestamp>.json`

## Output Format

```
rag-evaluate | <rag-endpoint>

## Configuration
- Dataset: eval-set.jsonl | Queries: 150 | Endpoint: http://localhost:8000

## Metrics
| Metric              | Score  | Target | Status |
|---------------------|--------|--------|--------|
| Retrieval accuracy  | 0.82   | 0.85   | WARN   |
| Faithfulness        | 0.91   | 0.90   | PASS   |
| Answer relevance    | 0.88   | 0.85   | PASS   |
| Context recall      | 0.79   | 0.80   | WARN   |
| Context precision   | 0.74   | 0.75   | WARN   |

## Failure Clusters
| Cluster            | Count | Example query              |
|--------------------|-------|----------------------------|
| Empty retrieval    | 12    | "What is X in section Y?"  |
| Low faithfulness   | 8     | "Summarize the Z policy"   |
| Low relevance      | 5     | "Compare A vs B metrics"   |

## Verdict
EVALUATED | 150 queries | faithfulness 0.91 PASS | retrieval 0.82 WARN
```

## Skill Chains
- After evaluation -> `[eval-suite]` to integrate into CI regression suite
- After evaluation -> `[ml-evaluate]` to compare against model-only baseline
- Before evaluation -> `[rag-pipeline]` to build the pipeline under test
- For LLM-based judging for evaluation metrics -> `[reasoning-router]` (`python ~/bin/reasoning_router.py route`)
