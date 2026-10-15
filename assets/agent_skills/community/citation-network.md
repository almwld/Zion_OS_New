---
name: citation-network
description: Analyze citation networks - build directed graphs of citations, identify influential works, and detect citation clusters
version: 0.1.0
execution-mode: advisory
argument-hint: "<seed-paper-or-doi> [--depth 2] [--layout force|circular]"
category: dev-tools
status: candidate
---
# citation-network | Citation Network Analysis

## When to Use
- Mapping the intellectual structure of a research area via citation relationships
- Identifying influential or foundational works in a field
- Detecting citation clusters (invisible colleges, research fronts)
- Understanding how ideas propagate through a literature

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: seed paper (DOI, title, or arXiv ID)
- `--depth`: citation graph depth (default 2; 1 = direct citations only)
- `--layout`: graph layout algorithm (force, circular, hierarchical)
- Defaults: `depth=2`, `layout=force`

### 2. Retrieve Citation Data
- Resolve seed paper to DOI (use Crossref or Semantic Scholar API)
- Retrieve forward citations (papers citing the seed) and backward citations (seed's references)
- Expand recursively to specified depth
- Collect metadata: title, authors, year, venue, citation count

### 3. Build Directed Graph
- Nodes: papers (with metadata attributes)
- Edges: directed citation links (citing -> cited)
- Deduplicate nodes (same paper via different IDs)
- Compute graph statistics: node count, edge count, density, components

### 4. Centrality Analysis
- In-degree centrality: most-cited works (foundational/influential)
- Out-degree centrality: most-citing works (review-like or integrative)
- PageRank: iterative influence accounting for citation weight
- Betweenness centrality: bridge papers connecting clusters

### 5. Cluster Detection
- Apply community detection (Louvain, Leiden, or Walktrap)
- Label clusters by dominant topic (keyword frequency or LDA)
- Identify inter-cluster bridges and citation flow patterns

### 6. Temporal Analysis
- Plot citation timeline (papers per year, citations per year)
- Identify citation cascades and delayed recognition (sleeping beauties)
- Track cluster emergence over time

### 7. Visualization and Reporting
- Render graph with specified layout
- Size nodes by in-degree or PageRank; color by cluster
- Export graph (GraphML, GEXF) for interactive exploration
- Report key findings: top influential works, cluster summaries, temporal trends

## Output Format

```
citation-network | <seed-paper>

## Configuration
- Seed: <DOI/title> | Depth: 2 | Layout: Force-directed
- Nodes: N | Edges: M | Density: 0.03 | Components: 4

## Most Influential Works (by in-degree)
| Rank | Paper                          | Year | In-degree | PageRank |
|------|--------------------------------|------|-----------|----------|
| 1    | <title>                        | 2018 | 142       | 0.085    |
| 2    | <title>                        | 2015 | 98        | 0.061    |
| 3    | <title>                        | 2020 | 76        | 0.044    |

## Clusters (Louvain, modularity = 0.62)
| Cluster | Size | Dominant Topic          | Key Paper        |
|---------|------|-------------------------|------------------|
| A       | 45   | methodological advances | <paper 1>        |
| B       | 32   | clinical applications   | <paper 2>        |
| C       | 18   | theoretical foundations | <paper 3>        |

## Temporal Trends
- Peak publication year: 2021 (28 papers)
- Citation cascade: seed paper -> cluster A (2019-2022)
- Sleeping beauty: <paper> (2016, cited surge in 2022)

## Bridge Papers (high betweenness)
1. <paper> (betweenness 0.21) -- connects clusters A and B

## Verdict
NETWORK MAPPED | PARTIAL (depth-limited) | INSUFFICIENT CITATION DATA
```

## Skill Chains
- After network built -> `[graphify]` to convert to persistent knowledge graph
- After analysis -> `[bibliometric]` for quantitative impact metrics on key works
- Before network analysis -> `[research-ingest]` to load seed paper and metadata
- For OpenAlex citation graph queries (forward/backward citations, paper metadata) -> `[free-apis]` (`python ~/bin/free_apis.py openalex "<query>"`)
