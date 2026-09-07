# Security Policy

## Scope

Zion OS is a defensive cybersecurity and system-diagnostics application. Production functionality is intentionally restricted to authorized, defensive use on systems and networks the operator is permitted to assess.

## Production security boundary

The production registry excludes autonomous propagation, credential theft, password cracking, exploitation, persistence, evasion, botnet control and similar offensive execution. A missing runtime dependency or unsupported platform must produce an explicit `UNAVAILABLE`, `BLOCKED` or `RUNTIME_DEPENDENT` result rather than a simulated success.

## Secrets

Do not commit passwords, API keys, private keys, signing material, shell histories or local environment files. Use CI secret storage or platform secure storage for credentials that are genuinely required.

## Reporting a vulnerability

Please report security issues privately to the repository owner rather than publishing exploit details in a public issue. Include the affected version/commit, affected component, reproduction steps that do not target third-party systems, impact assessment and any suggested remediation.

## Release requirements

A release requires successful static analysis, automated tests, native build verification and manual Android-device validation of the terminal/PTy and security-critical flows. A green APK build alone is not considered sufficient evidence of production readiness.
