---
name: container-scan
description: Scan container images for vulnerabilities, bloat, unnecessary packages, and hardening issues
version: 0.1.0
execution-mode: remedial
argument-hint: "<image> [--format summary|detailed|sbom]"
status: tested
category: security
providers:
  required: [python]
---
# Container Image Scanner

Scan Docker/OCI container images for security vulnerabilities, image bloat, unnecessary packages, and hardening gaps. Generates actionable reports with remediation priorities and optional SBOM output.

## When to Use
- Before pushing a new image to a registry
- Auditing existing production images for vulnerabilities
- Optimizing image size by finding unnecessary packages and layers
- Generating an SBOM (Software Bill of Materials) for compliance

## Execution
1. Parse `$ARGUMENTS` for image reference and `--format` (default: `summary`)
2. Inspect the image layers and metadata (`docker inspect`, `docker history`)
3. Check for known vulnerabilities using available scanners (trivy, grype, or manual package version checks)
4. Analyze image size: identify large layers, unnecessary build artifacts, dev dependencies left in prod image
5. Check hardening: running as root, exposed ports, writable filesystem, missing health check, no USER directive
6. For `summary`: one-page overview with critical/high/medium counts
7. For `detailed`: full vulnerability list with CVE IDs, fix versions, and remediation steps
8. For `sbom`: generate package inventory in CycloneDX or SPDX-lite format
9. Score the image on a 0-100 hardening scale

## Output Format
```
Container Scan | {image}
────────────────────────────────
Image size: {size} | Layers: {N}
Hardening score: {N}/100

Vulnerabilities:
| Severity | Count | Fixable |
|----------|-------|---------|
| CRITICAL | 2     | 2       |
| HIGH     | 5     | 3       |

Hardening issues:
- Running as root (CRITICAL)
- No HEALTHCHECK defined (MEDIUM)
- Dev packages present: {list} (LOW)

Top bloat: {largest unnecessary layers/packages}
Action: {next steps or "No further action needed"}
```

## Skill Chains
| After this skill... | Consider... |
|--------------------|-------------|
| Vulnerabilities found | `[security-scan]` for application-level scanning |
| SBOM generated | `[license-audit]` to check package licenses |
| Image optimized | `[docker-manage]` to rebuild and push the leaner image |
| CVE enrichment needed | `[free-apis]` — NVD/OSV for CVE details (`python ~/bin/free_apis.py nvd "<cve-id>"` or `python ~/bin/free_apis.py osv "<package>"`) |
