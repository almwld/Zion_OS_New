---
name: ml-train
description: Train and validate machine learning models with experiment tracking. [Maps to CO7.]
version: 0.1.0
execution-mode: side_effecting
argument-hint: <model-config-or-data-path>
category: backend-infra
status: candidate
---
# Machine Learning Training Command

Train machine learning models with comprehensive experiment tracking, validation, and artifact management. Supports various ML frameworks through configuration-driven approach.

## When to Use
- Starting new ML model development
- Retraining models with new data
- Comparing different model architectures
- Preparing models for deployment
- When user mentions model training requirements

## Execution

### 0. Emit SKILL_INVOKE
Post SKILL_INVOKE to the bus before any stateful action.
```
Type: SKILL_INVOKE
To: all
Message: [skill=ml-train] [mode=side_effecting] [args_hash=<sha256>] [session=<session_id>]
```
(The skill invocation runtime injects the caller's canonical identity as `from_id`.)

### 1. Parse Training Configuration
Interpret the argument as either:
- Path to model configuration file (YAML/JSON)
- Path to training data directory
- Shorthand for predefined training recipes

### 2. Setup Training Environment
- Create isolated experiment directory with timestamp
- Initialize experiment tracking (MLflow, Weights & Biases, or local)
- Prepare data loading and preprocessing pipelines
- Configure compute resources (CPU/GPU detection)

### 3. Execute Training Run
Train model with:
- Automatic train/validation/test splitting
- Early stopping based on validation metrics
- Checkpointing best models
- Hyperparameter logging
- Resource utilization monitoring

### 4. Evaluate and Artifactize
After training:
- Generate comprehensive evaluation report
- Save model artifacts (weights, architecture, preprocessing)
- Log final metrics to experiment tracker
- Create model card with performance details

## Output Format
```
ML Train | <model-config-or-data-path>
════════════════════════════
Experiment: <experiment-id>
Started: <timestamp>

## Configuration
- Model Type: <model-architecture>
- Framework: <tensorflow/pytorch/scikit-learn/etc>
- Data Size: <train/val/test samples>
- Epochs: <planned-vs-actual>
- Batch Size: <size>

## Training Metrics
- Final Train Loss: <value>
- Final Val Loss: <value>
- Best Val Metric: <metric-name>: <value>
- Training Time: <duration>
- Peak Memory: <usage>
- Compute Utilization: <percentage>

## Validation Results
<task-specific-metrics>:
  - Precision: <value>
  - Recall: <value>
  - F1-Score: <value>
  - Accuracy: <value>

## Artifacts Generated
- Model: <output/target.weights>
- Architecture: <output/target.json>
- Preprocessor: <output/target.pkl>
- Evaluation Report: <hummbl-governancert.html>
- Experiment Log: <output/target.log>

## Recommendations
READY FOR DEPLOYMENT: <yes/no>
NEXT STEPS: <suggested-action>
Estimated inference latency: <latency>

## Base120 Context
- Primary: **CO7** (Growth Modeling - developing capabilities that improve with use)
- Related: **IN2** (Premortem - anticipating deployment issues), **SY13** (Designing effective learning systems)

## After Completion
Naturally chains to: `[ml-evaluate]` for deeper analysis, or `[mlops-deploy]` for deployment preparation

## Skill Chains

### Mandatory

- `[experiment-track]` SHOULD be used to track experiments — ensures reproducibility, metric logging, and artifact lineage for every training run.

### Advisory

- After `[ml-train]` → `[ml-evaluate]` for deeper model analysis and validation
- After `[ml-train]` → `[mlops-deploy]` for deployment preparation if model is production-ready
- Before `[ml-train]` → `[research]` to survey relevant architectures and hyperparameter strategies

## Authority

- **T1 (TRUSTED)**: May run
- **T2 (Active/High)**: May run
- **T3 (Medium)**: Operator approval required
- **T4 (Probationary)**: BLOCKED
- **Operator**: Override any restriction
