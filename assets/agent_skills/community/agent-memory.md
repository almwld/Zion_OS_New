---
name: agent-memory
description: Design agent memory systems with short-term, long-term, episodic, and semantic memory and retrieval strategies
version: 0.1.0
execution-mode: advisory
argument-hint: "[--type short|long|episodic|semantic] [--capacity <n>] [--retrieval bm25|vector|hybrid]"
category: fleet-ops
status: candidate
---
# agent-memory | Agent Memory System Designer

## When to Use
- Designing memory architecture for a new agent
- Improving context management for long-running sessions
- Adding persistent knowledge to an existing agent
- Evaluating retrieval strategies for recall quality

## Execution

### 1. Parse Arguments
- `--type short|long|episodic|semantic`: memory type to design (default all)
- `--capacity <n>`: max items or tokens in the memory store
- `--retrieval bm25|vector|hybrid`: retrieval strategy (default hybrid)

### 2. Define Memory Tiers
- **Short-term**: working context window, recent turns, ephemeral
- **Long-term**: persistent facts, preferences, learned rules
- **Episodic**: logs of past interactions and outcomes
- **Semantic**: structured knowledge graph or fact store

### 3. Choose Storage Backends
- Short-term: in-process buffer or Redis with TTL
- Long-term: vector DB (pgvector, Qdrant) + key-value store
- Episodic: append-only event log (SQLite, JSONL)
- Semantic: graph store (Neo4j) or triple store

### 4. Design Retrieval Pipeline
- BM25: lexical scoring over episodic and long-term text
- Vector: embedding similarity over semantic and long-term
- Hybrid: reciprocal-rank fusion of BM25 + vector scores
- Define top-k, reranking, and freshness decay parameters

### 5. Define Write and Eviction Policies
- Write triggers: turn boundary, tool result, explicit save
- Eviction: LRU for short-term, relevance decay for long-term
- Consolidation: periodic summarization of episodic into semantic

### 6. Emit Design Document
- Write design to `_state/memory/<agent>.design.md`
- Include schema, retrieval config, and capacity budgets

## Output Format

```
agent-memory | type=all retrieval=hybrid

## Memory Tiers
| Tier       | Backend   | Capacity   | Eviction       |
|------------|-----------|------------|----------------|
| short-term | buffer    | 8k tokens  | LRU (10 turns) |
| long-term  | Qdrant    | 10k items  | relevance 0.3  |
| episodic   | JSONL log | unbounded  | 90-day decay   |
| semantic   | Neo4j     | 5k nodes   | consolidation  |

## Retrieval Pipeline
- Strategy: hybrid (BM25 + vector, RRF k=60)
- Top-k: 5 | Reranker: cross-encoder
- Freshness decay: 0.95^days

## Write Policies
- Short-term: every turn | Long-term: explicit save or tool result
- Episodic: turn boundary | Semantic: nightly consolidation

## Verdict
PASS | 4-tier memory designed, hybrid retrieval configured
```

## Skill Chains
- After designing -> `[agent-design]` to integrate memory into agent architecture
- After designing -> `[rag-pipeline]` to build the retrieval backend
- Before designing -> `[agent-trace]` to analyze existing memory usage
