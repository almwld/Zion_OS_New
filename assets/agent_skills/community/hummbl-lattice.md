---
name: hummbl-lattice
description: Domain-specific reasoning operator lattices for the Domain120 framework
version: 0.1.0
execution-mode: advisory
argument-hint: "[hummbl-lattice] validate my_lattice.json | compute-kappa ratings.csv"
category: governance-compliance
status: candidate
---
# hummbl-lattice

Domain-specific reasoning operator lattices for the Domain120 framework. Tools for building, validating, and rating domain-specific reasoning operator sets that generalize TRIZ's 40-principle structure across arbitrary domains of practice.

## When to Use

- You need to build a domain-specific reasoning operator lattice (generalizing TRIZ's 40 principles)
- You want to validate a lattice JSON file for structural correctness and completeness
- You need to compute inter-rater reliability (Cohen's / Fleiss' kappa) for lattice operator ratings
- You want to programmatically construct a lattice with operators and composition matrices
- You need a composition matrix to model how operators combine within a domain

## Usage

```bash
hummbl-lattice validate my_lattice.json
hummbl-lattice compute-kappa ratings.csv
```

## Python API

```python
from hummbl_lattice import (
    Lattice, LatticeOperator, CompositionMatrix,
    LatticeValidator, ValidationReport,
    KappaCalculator, KappaResult,
)
```

## Key Concepts

- **Lattice**: Container for a domain-specific operator set; `add_operator()` accepts code, name, family, definition, and base120_ancestor
- **LatticeOperator**: Individual reasoning operator with a family code (e.g., IN, SE, TR) and a base120 ancestor reference
- **CompositionMatrix**: Models how operators combine within a domain
- **LatticeValidator**: Validates lattice JSON files and produces a `ValidationReport`
- **KappaCalculator**: Computes inter-rater reliability from rating CSV files, returning a `KappaResult`

## Install

```bash
cd /work/active/oss/packages/python/hummbl-lattice/
pip install -e ".[test]"
```

## Package

- **Repo**: `hummbl-io/oss`
- **Path**: `packages/python/hummbl-lattice/`
- **License**: MIT OR Apache-2.0
- **Dependencies**: stdlib only
