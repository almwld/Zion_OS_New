---
name: rag-pipeline
description: Design and test RAG pipelines -- chunking strategy, embedding selection, retrieval tuning, and evaluation
version: 0.1.0
execution-mode: advisory
argument-hint: "<corpus> [--action design|chunk|evaluate] [--chunk-size N]"
category: backend-infra
status: candidate
---
# RAG Pipeline Designer

Design, build, and evaluate Retrieval-Augmented Generation pipelines. Covers the full RAG lifecycle from chunking strategy through embedding selection, retrieval tuning, and end-to-end evaluation with precision/recall metrics.

## When to Use
- Building a new RAG system and need to choose chunking and embedding strategies
- Evaluating retrieval quality on a specific corpus with known-good answers
- Tuning chunk size, overlap, and top-k parameters for better answer quality
- Comparing different RAG configurations (chunk sizes, embedding models, rerankers)

## Execution
1. Parse `$ARGUMENTS` for corpus path, `--action` (default: `design`), and `--chunk-size` (default: 512 tokens)
2. For `design`: analyze the corpus (document types, average length, structure) and recommend chunking strategy (fixed, recursive, semantic, document-aware), embedding model, and retrieval parameters
3. For `chunk`: process the corpus with the specified strategy, generate chunk statistics (count, avg size, overlap), and sample chunks for review
4. For `evaluate`: run test queries against the pipeline, measure retrieval precision@k, recall@k, and answer relevance; compare against baseline if available
5. Analyze chunk boundary quality -- do chunks break mid-sentence, mid-paragraph, or at natural boundaries?
6. Check for metadata preservation (source document, page number, section heading)
7. Estimate embedding costs (token count x model pricing) and storage requirements
8. Output configuration recommendations with rationale

## Output Format
```
RAG Pipeline | {action} | {corpus}
────────────────────────────────
Corpus: {N} documents | {total tokens} tokens
Chunk strategy: {strategy} | Size: {N} | Overlap: {N}

Design Recommendations:
- Chunking: {strategy} with {rationale}
- Embedding: {model} ({dimensions}d, ${cost}/1M tokens)
- Retrieval: top-{k} with {reranker if any}
- Storage: ~{size} for {N} chunks

Evaluation (if run):
| Query | Precision@5 | Recall@5 | Relevance |
|-------|-------------|----------|-----------|
| ...   | 0.80        | 0.60     | HIGH      |

Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Pipeline designed | `[deep-research]` to gather domain-specific test queries |
| Evaluation complete | `[eval-suite]` for broader LLM output quality testing |
| Chunking tuned | `[fine-tune-prep]` if the corpus will also be used for fine-tuning |
| generation component needs LLM inference | `[reasoning-router]` (`python ~/bin/reasoning_router.py route`) |
