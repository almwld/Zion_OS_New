---
name: experiment-track
description: Track ML experiments and hyperparameters with versioning and comparison. [Maps to CO7.]
version: 0.1.0
execution-mode: side_effecting
argument-hint: <experiment-spec-or-query>
category: backend-infra
status: candidate
---
# Experiment Tracking Command

Track machine learning experiments with comprehensive logging, hyperparameter management, metrics comparison, and version control to enable reproducible research and model development.

## When to Use
- Starting new ML experiments or research projects
- When user mentions experiment tracking or reproducibility needs
- Comparing multiple model architectures or hyperparameters
- Managing experiment versions and lineage
- Preparing for model registration or deployment

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=experiment-track] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Experiment Specification
Accept either:
- New experiment definition with hyperparameters and configuration
- Query for existing experiments (filter by metrics, date, tags, etc.)
- Experiment ID for detailed inspection or comparison
- Command to compare specific experiments

### 2. Initialize Experiment Tracking
- Create unique experiment identifier with timestamp
- Set up tracking backend (MLflow, Weights & Biases, DVC, or local)
- Log experiment metadata (description, tags, owner, purpose)
- Initialize artifact storage for models, plots, and data

### 3. Log Experiment Details
Record comprehensive experiment information:
- **Hyperparameters**: All model and training parameters
- **Environment**: Dependencies, versions, hardware specs
- **Data**: Dataset versions, splits, preprocessing steps
- **Code**: Git commit, scripts used, configuration files
- **Metrics**: Training/validation/test performance over time
- **Artifacts**: Models, visualizations, logs, predictions

### 4. Enable Comparison and Analysis
- Structure data for easy comparison across experiments
- Provide filtering, sorting, and search capabilities
- Generate visualizations for metric trends and parameter importance
- Identify best-performing experiments based on criteria
- Detect patterns in successful vs. unsuccessful experiments

### 5. Support Experiment Lifecycle
- Promote experiments from staging to production tracking
- Archive or delete old experiments per retention policy
- Share experiments with team members
- Export experiment reports for documentation

## Output Format
```
Experiment Track | <experiment-spec-or-query>
════════════════════════════
Action: <created/queried/compared>
Time: <timestamp>

## Summary
- Total Experiments Tracked: <count>
- Active Experiments: <count>
- Best Performing (by <metric>): <experiment-id>
- Storage Used: <size>

## New Experiment Created
<if experiment-created>
### Experiment: <experiment-id>
**Description**: <experiment-description>
**Started**: <timestamp>
**Tags**: <list-of-tags>
**Git Commit**: <commit-hash>

### Hyperparameters Logged
<parameter-name>: <value> (<type>)
<parameter-name>: <value> (<type>)
...

### Metrics Tracked
<metric-name>: <final-value> (best: <value> at step <step>)
<metric-name>: <final-value>
...

### Artifacts Saved
- Model: <output/target.artifact>
- Plots: <list-of-plot-files>
- Logs: <output/target.log>
- Predictions: <output/target.csv>

### Environment
- Python: <version>
- Key Packages: <list>
- Hardware: <CPU/GPU-details>
## End If

<if experiment-queried>
### Query Results
<filter-criteria>: <applied-filter>
**Found**: <count> experiments

### Top 5 Experiments
1. **Exp ID**: <experiment-id>
   **Description**: <short-description>
   **Primary Metric**: <value>
   **Secondary Metrics**: <values>
   **Duration**: <time>
   **Status**: <completed/running/failed>

2. **Exp ID**: <experiment-id>
   **Description**: <short-description>
   **Primary Metric**: <value>
   ...
<else>
No experiments match query criteria
## End If

<if experiment-compared>
### Comparison: <exp-id-1> vs <exp-id-2>
**Parameter Differences**:
  - <parameter-name>: <value1> → <value2> (<change>%)
  - <parameter-name>: <value1> → <value2> (<change>%)

**Metric Differences**:
  - <metric-name>: <value1> → <value2> (<change>%)
  - <metric-name>: <value1> → <value2> (<change>%)

**Recommendation**: <better-experiment-id> based on <criteria>
## End If

## Recommendations
NEXT: Use best experiment for [mlops-deploy] or continue experimentation
Consider [ml-evaluate] for post-experiment validation
Estimated effort to reproduce: <S/M/L>

## Base120 Context
- Primary: **CO7** (Growth Modeling - systematically improving through experimentation)
- Related: **IN2** (Premortem - learning from experiment failures), **SY13** (Designing effective learning systems)

## After Completion
Naturally chains to: Select best experiment for deployment, or run new experiments with insights

## Skill Chains

### Mandatory

None — experiment tracking is a ledger-append operation with no side effects beyond recording metadata.

### Advisory

- After identifying best experiment → `[mlops-deploy]` to promote to production
- After experiment completion → `[ml-evaluate]` for post-experiment validation
- Before starting new experiments → `[pre-mortem]` to anticipate failure modes

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Run with operator notification
- **T4 (Probationary)**: May run (read-only tracking)
- **Operator**: Override any restriction
