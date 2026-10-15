---
name: reproducibility-check
description: Verify research reproducibility - check code availability, data availability, environment pinning, and seed documentation
version: 0.1.0
execution-mode: advisory
argument-hint: "<paper-or-repo> [--level full|partial|computational]"
category: fleet-ops
status: candidate
---
# reproducibility-check | Research Reproducibility Verification

## When to Use
- Verifying that a published paper or repository can reproduce its claimed results
- Auditing computational experiments for transparency before citation or extension
- Pre-submission reproducibility self-check for manuscripts
- Assessing reproducibility of third-party work before building on it

## Execution

### 1. Parse Arguments
- `$ARGUMENTS`: path to paper (PDF, LaTeX source) or code repository
- `--level`: full (all results), partial (key figures only), computational (code + data only, skip paper text)
- Default level: `full`

### 2. Code Availability Check
- Locate source code (repository URL, supplementary files, or embedded in paper)
- Verify code is accessible (public repo, working DOI link, or provided archive)
- Check for license (open license enables reuse; unclear license is a flag)
- Assess code structure: readable, commented, entry point documented

### 3. Data Availability Check
- Locate datasets (public link, repository, supplementary, or upon-request statement)
- Verify data accessibility (download test or repository lookup)
- Check for data documentation (README, data dictionary, schema)
- Flag restricted data: document access conditions and IRB constraints

### 4. Environment Pinning Check
- Locate environment specification: requirements.txt, environment.yml, Dockerfile, renv.lock, Nix
- Verify dependency versions are pinned (exact versions, not ranges)
- Check for container or VM image (strongest reproducibility guarantee)
- Flag unpinned or missing environment specs

### 5. Seed and Randomness Documentation
- Check for random seed documentation in code and paper
- Verify seeds are set for: RNG (numpy, torch, random), GPU non-determinism, parallel workers
- Flag stochastic operations without explicit seeding

### 6. Execution Test (if code + data available)
- Clone/download repository and data
- Set up environment per specification
- Run primary analysis entry point
- Compare output to reported results (figures, tables, metrics)
- Document discrepancies and environment differences

### 7. Reporting
- Assign reproducibility grade per dimension (pass, partial, fail, not-applicable)
- Compute overall reproducibility score
- List specific blockers and recommended fixes

## Output Format

```
reproducibility-check | <paper-or-repo>

## Configuration
- Level: Full | Target: all results

## Dimension Checks
| Dimension         | Status   | Details                              |
|-------------------|----------|--------------------------------------|
| Code availability | PASS     | Public GitHub repo, MIT license      |
| Data availability | PARTIAL  | 2/3 datasets public; 1 upon-request  |
| Environment pin   | FAIL     | requirements.txt has unpinned ranges |
| Seed documentation| PARTIAL  | numpy seeded; torch not seeded       |
| Execution test    | PASS     | Key figures reproduced within tolerance |

## Execution Test Results
- Environment set up: Python 3.10, CUDA 12.1
- Runtime: 42 min | Expected: ~40 min (paper)
- Figure 2: reproduced (SSIM 0.98) | Table 3: metric match within 0.5%

## Blockers
1. Unpinned dependencies -> pip install may resolve to incompatible versions over time
2. Dataset C access requires DUA application (6-8 week wait)

## Recommended Fixes
1. Pin all dependencies to exact versions in requirements.txt
2. Provide Dockerfile for full environment capture
3. Set torch.manual_seed and torch.use_deterministic_algorithms(True)

## Verdict
REPRODUCIBLE | PARTIALLY REPRODUCIBLE | NOT REPRODUCIBLE | CANNOT ASSESS (code/data unavailable)
```

## Skill Chains
- After check -> `[preprint-scan]` to verify reproducibility claims align with preprint
- After check -> `[evidence-grade]` to factor reproducibility into evidence grading
- Before check -> `[research-ingest]` to load paper and repository materials
