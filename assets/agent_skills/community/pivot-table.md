---
name: pivot-table
description: Aggregate tabular data with groupby, sum, avg, count, and pivot operations
version: 0.1.0
execution-mode: advisory
argument-hint: <file> --group COL --agg sum|avg|count|min|max --value COL
category: fleet-ops
status: candidate
---
# Pivot Table

Aggregate tabular data using groupby operations with sum, average, count, min, and max. Produces pivot-style output from flat CSV or TSV files using Python stdlib only.

## When to Use
- You need to summarize data by category (e.g., revenue by region, counts by status)
- You want to create cross-tabulations from flat data
- You need quick aggregate metrics without spinning up a database
- Before charting, to prepare grouped data for visualization

## Execution
1. Parse `$ARGUMENTS` for file path, `--group` column(s), `--agg` function, and `--value` column
2. Load the data file (CSV, TSV)
3. Validate that specified columns exist in the data
4. Group records by the specified column(s)
5. Apply the aggregation function to the value column for each group
6. Sort results by aggregate value (descending)
7. If multiple group columns, create a cross-tabulation matrix
8. Compute grand totals and group percentages
9. Present as a formatted table

## Output Format
```
Pivot Table | <filename>

## Grouped by: <column> | Aggregation: <function>(<value_column>)

| <group_column> | <agg_function> | % of Total | Count |
|----------------|----------------|------------|-------|
| Group A        | 1,234.56       | 45.2%      | 23    |
| Group B        | 891.23         | 32.6%      | 18    |
| Group C        | 607.89         | 22.2%      | 12    |
| **Total**      | **2,733.68**   | **100%**   | **53**|

Records: <N>  |  Groups: <N>  |  Nulls skipped: <N>

Next action: <recommendation>
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Aggregated data ready | `[chart]` to visualize the grouped results |
| Need deeper stats | `[csv-analyze]` for full statistical analysis |
