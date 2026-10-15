---
name: csv-analyze
description: Load CSV, compute stats (mean, median, std dev, outliers, correlations), generate summary
version: 0.1.0
execution-mode: advisory
argument-hint: "<file> [--columns COL...] [--top N]"
category: data-science
status: candidate
---
# CSV Analyze

Load a CSV file and compute descriptive statistics including mean, median, standard deviation, outlier detection, and pairwise correlations. Produces a structured summary suitable for decision-making or further visualization.

## When to Use
- You have a CSV file and need quick statistical insights
- You want to identify outliers or anomalies in tabular data
- You need correlation analysis between numeric columns
- Before creating charts, to understand data shape and distribution

## Execution
1. Parse `$ARGUMENTS` for file path, optional `--columns` filter, and `--top N` limit
2. Load the CSV file using Python stdlib `csv` module
3. Identify column types (numeric, categorical, datetime)
4. For numeric columns: compute count, mean, median, std dev, min, max, Q1, Q3, IQR
5. Flag outliers using 1.5x IQR rule
6. Compute pairwise Pearson correlations for numeric columns
7. For categorical columns: compute value counts, cardinality, mode
8. If `--top N` specified, show top N rows by the first numeric column
9. Present structured summary

## Output Format
```
CSV Analyze | <filename>

## Shape
Rows: <N>  |  Columns: <N>  |  Numeric: <N>  |  Categorical: <N>

## Numeric Summary
| Column | Count | Mean | Median | Std Dev | Min | Max | Outliers |
|--------|-------|------|--------|---------|-----|-----|----------|
| ...    | ...   | ...  | ...    | ...     | ... | ... | ...      |

## Correlations (|r| > 0.5)
- <col_a> ~ <col_b>: r = <value>

## Categorical Summary
| Column | Unique | Mode | Mode % |
|--------|--------|------|--------|
| ...    | ...    | ...  | ...    |

## Findings
- <finding with severity and action>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Stats reveal trends | `[chart]` to visualize distributions or correlations |
| Data needs export | `[data-export]` to convert format |
| Results need documentation | `[docgen]` to generate a report |
