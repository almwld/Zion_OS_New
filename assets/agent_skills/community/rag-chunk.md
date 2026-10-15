---
name: rag-chunk
description: Optimize document chunking strategies (fixed/semantic/sentence/recursive) for RAG pipelines
version: 0.1.0
execution-mode: advisory
argument-hint: "<document-path> [--strategy fixed|semantic|sentence|recursive] [--size 512] [--overlap 50]"
category: backend-infra
status: candidate
---
# rag-chunk | Document Chunking Strategy Optimization for RAG Pipelines

## When to Use
- Preparing documents for a RAG pipeline ingestion step
- Comparing chunking strategies to maximize retrieval relevance
- Tuning chunk size and overlap for domain-specific documents
- Avoiding context fragmentation that degrades answer quality

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: `<document-path>` (file or directory)
- `--strategy`: `fixed` | `semantic` | `sentence` | `recursive` (default `recursive`)
- `--size`: target chunk size in tokens (default 512)
- `--overlap`: overlap between chunks in tokens (default 50)
- `--encoding`: tokenizer encoding for size measurement (default `cl100k_base`)

### 2. Load & Inspect Documents
- Read document(s) and compute total token count
- Detect document structure (headings, paragraphs, lists, tables)
- Flag documents shorter than `--size` (single chunk, no splitting needed)
- Identify language(s) for sentence boundary detection

### 3. Apply Chunking Strategy
- **fixed**: split into N-token windows with overlap; fast but may break mid-sentence
- **sentence**: split at sentence boundaries; group sentences until size target met
- **semantic**: embed sentences, cluster by semantic similarity, group coherent chunks
- **recursive**: split by hierarchy (section -> paragraph -> sentence -> word) respecting structure

### 4. Analyze Chunk Quality
- Compute chunk size distribution (mean, stdev, min, max)
- Measure semantic coherence: average embedding similarity within chunks
- Detect orphan chunks (size < 20% of target) and over-long chunks (> 150% of target)
- Estimate retrieval impact: coverage of key terms across chunks

### 5. Export Chunks
- Save chunks to `<document-path>-chunks-<strategy>/` as JSONL
- Each record: `{id, text, tokens, start_char, end_char, parent_doc}`
- Print summary statistics and chunking recommendations

## Output Format

```
rag-chunk | <document-path>

## Configuration
- Strategy: recursive | Size: 512 tokens | Overlap: 50
- Documents: 12 | Total tokens: 48,230

## Chunk Statistics
| Metric          | Value   |
|-----------------|---------|
| Total chunks    | 112     |
| Mean size       | 498     |
| Stdev size      | 42      |
| Min / Max       | 85 / 560|
| Orphan chunks   | 2       |
| Over-long       | 0       |

## Coherence
| Metric                | Value  |
|-----------------------|--------|
| Avg intra-chunk sim   | 0.78   |
| Avg inter-chunk sim   | 0.31   |
| Key term coverage     | 96.2%  |

## Verdict
CHUNKED | 112 chunks | recursive | coherence 0.78 | coverage 96.2%
```

## Skill Chains
- After chunking -> `[rag-pipeline]` to build the retrieval-augmented pipeline
- After chunking -> `[embedding-index]` to index chunks in a vector store
- Before chunking -> `[rag-evaluate]` to define eval criteria for chunk quality
