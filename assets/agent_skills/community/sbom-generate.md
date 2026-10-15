---
name: sbom-generate
description: Generate Software Bill of Materials in SPDX or CycloneDX format from project dependencies
version: 0.1.0
execution-mode: advisory
argument-hint: "[--format spdx|cyclonedx|json] [--include-dev]"
category: backend-infra
status: candidate
---
# SBOM Generate

Produce a Software Bill of Materials listing all project dependencies with versions, licenses, and supplier information. Outputs in industry-standard SPDX or CycloneDX format for compliance, auditing, and supply chain transparency. Can include or exclude dev/test dependencies.

## When to Use
- Client or regulatory requirement for software transparency
- Before a release to document the dependency footprint
- Supply chain security audit needs a machine-readable inventory
- Compliance with US Executive Order on Software Supply Chain or EU CRA

## Execution
1. **Discover dependencies** -- parse `pyproject.toml`, `requirements.txt`, `package.json`, `Cargo.toml`, or equivalent manifest files in the project root.
2. **Resolve versions** -- use lockfile if available for exact versions; fall back to manifest version specifiers.
3. **Enrich metadata** -- for each dependency:
   - License identifier (SPDX expression)
   - Supplier/author
   - Package URL (purl)
   - Hash/checksum if available from lockfile
4. **Include dev dependencies** (if `--include-dev`) -- add test, lint, and build dependencies in a separate group.
5. **Format output** -- render in requested format:
   - `spdx`: SPDX 2.3 tag-value or JSON format
   - `cyclonedx`: CycloneDX 1.5 JSON format
   - `json`: simplified JSON with package name, version, license, purl
6. **Write file** -- save to `sbom.{format extension}` in project root.
7. **Summary** -- report component count, license distribution, and any unresolvable packages.

## Output Format
```
SBOM Generate | format: {format} | include-dev: {yes|no}

## Summary
- Total components: {N}
- Direct dependencies: {N}
- Transitive dependencies: {N}
- Unique licenses: {N}

## License Distribution
| License | Count | Components |
|---------|-------|------------|

## Output File
- Path: {path to generated SBOM file}
- Format: {SPDX 2.3|CycloneDX 1.5|JSON}
- Size: {file size}

## Warnings
- {any unresolvable packages or missing metadata}

## No further action needed | SBOM written to {path}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| SBOM generated | `[license-audit]` to check license compatibility |
| Supply chain questions | `[supply-chain-audit]` for deeper integrity checks |
| Compliance deadline approaching | `[compliance-calendar]` to track submission dates |
