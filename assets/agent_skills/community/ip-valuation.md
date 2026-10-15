---
name: ip-valuation
description: Find all IP assets (repositories, packages, domains) and rank them by estimated market value.
version: 0.1.0
execution-mode: advisory
argument-hint: "[--detailed]"
category: finance-legal
status: candidate
---

## Live Context
- **Local Repositories**: !`find $HOME/PROJECTS -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' '`
- **PyPI Packages**: !`ls -d $HOME/PyPi/*/ 2>/dev/null | wc -l | tr -d ' ' || echo "0"`
- **Primary Domains**: !`grep -rohE '([a-zA-Z0-9-]+\.)+(com|org|net|ai|io|dev|sh)' ~/.agents/ /work/active/oss/ 2>/dev/null | sort -u | grep -E 'reuben|foundermode|hummbl' | tr '\n' ', ' || echo "reubenbowlby.com, hummbl-governance"`

# IP Valuation Command

Scan local and remote directories to list and grade intellectual property (IP) assets, estimating their market value based on lines of code, uniqueness of safety primitives, domain brand value, and community integrations.

## When to Use
- When assessing business equity or preparing investor updates
- Before pricing fractional engineering or advisory retainers
- To identify high-value proprietary codebases vs generic tools

## Execution

### 1. Enumerate and Grade Repositories
Locate all repositories under `PROJECTS/` or local directories.
Measure lines of code (LOC), language, and complexity:
```bash
find $HOME/PROJECTS -maxdepth 2 -name "README.md" -exec dirname {} \;
```

For each repository, compute valuation:
- **Base Dev Cost**: LOC * $15/line (standard baseline dev cost)
- **Safety Multiplier**: 3.5x for safety-critical, runtime-zero-dependency frameworks (e.g. `hummbl-governance`)
- **Product Multiplier**: 2.0x for ready-to-launch applications (e.g. `foundermode-app`)
- **Utility Multiplier**: 1.0x for helper tools or internal-only automation scripts

### 2. Identify Domains and Brands
Look up domain assets referenced in the system.
Classify domains:
- **Personal Brand Domains**: `reubenbowlby.com` (Estimated value: $5,000 - $15,000 based on target hourly rates/client pipeline)
- **SaaS/Product Domains**: `foundermode.ai`, `hummbl.com` (Estimated value: $20,000 - $75,000+ based on extension premium)

### 3. Identify Package Registry Assets
List packages published to PyPI or npm.
For example, evaluate the `hummbl-governance` package on PyPI:
- **Base utility value**: Integration rate, usage across the mesh, and zero-dependency runtime guarantee.
- **Enterprise value multiplier**: AI OS bus security and delegation token standards.

## Output Format

```
IP Valuation Report | <date>
════════════════════════════════════

## Repository Valuation
| Repo Name | LOC | Category | Multiplier | Est. Value | Key IP Feature |
|-----------|-----|----------|------------|------------|----------------|
| hummbl-governance | 14k | Core Safety | 3.5x | $735,000 | 7 Safety Primitives (Kill Switch, etc.) |
| foundermode-app | 25k | SaaS Front | 2.0x | $750,000 | Interactive voice-coaching frontend |
| hummbl-governance | 18k | Ops Platform| 1.5x | $405,000 | Coordination bus, agent scheduler |

## Domain & Brand Valuation
| Domain Name | Brand Tier | Primary Use | Est. Value |
|-------------|------------|-------------|------------|
| hummbl.com | Premium Commercial | Parent Brand | $120,000 |
| foundermode.ai | Tech/AI Premium | Consumer SaaS | $45,000 |
| reubenbowlby.com | Personal Pro | Advisory/Coaching | $15,000 |

## Package Registry Assets
| Package Name | Registry | Downloads | Value Grade |
|--------------|----------|-----------|-------------|
| hummbl-governance | PyPI | Active | Tier-1 Core |

## Summary
- **Total Estimated IP Portfolio Value**: $X,XXX,XXX
- **Highest Value Asset**: <Asset Name>
- **Strategic Recommendation**: Leverage <High Value Asset> in advisory positioning and packaging.
```
