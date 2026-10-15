---
name: fullstack-development
description: Design, implement, and verify a production-oriented full-stack web application from requirements to deployment.
version: 0.1.0
execution-mode: advisory
category: backend-infra
tags:
- full-stack
- frontend
- backend
- deployment
- validation
status: candidate
---
# Full Stack Development

Build or extend a full-stack web system end-to-end with consistent architecture, implementation, and validation.

## When to Use

Use this skill when the user asks for:

- a full feature in frontend + backend + database + deployment
- end-to-end application scaffolding
- API + UI integration
- deployment hardening, smoke tests, and launch checks
- debugging workflow spanning frontend/backend/db/infrastructure
- use this skill when both UI and service/data layers are in scope in the same flow (for example, feature + API + DB + deployment)

## Preflight

Before editing:

- identify the target repo and architecture constraints
- confirm stack (or select one if missing)
- confirm persistence model (Postgres/SQLite/None)
- confirm hosting target (Pages/Cloudflare Workers/Vercel/other)

## Core Workflow

1. Clarify scope and acceptance criteria in one sentence.
2. Freeze stack and boundaries before implementation.
3. Define or inspect:
   - domain entities
   - API contracts
   - front-end route/state model
   - auth/session model
   - storage and migration plan
4. Draft a minimal slice implementation plan with dependencies in order:
   - backend contract + data model
   - API/service handlers
   - frontend state and UI integration
   - validation tests
   - deployment + smoke checklist
5. Implement incrementally, keeping each PR/slice narrow.
6. Validate with direct verification commands and fix failures before moving to next layer.
7. Finish with a deploy smoke pass and rollback-ready plan.

## Recommended Build Order

- Backend models and schema
- Typed DTOs/contracts and API tests
- Core services and handlers
- Frontend state and UI integration
- E2E/acceptance smoke paths
- Observability and error envelopes
- Deployment/config hardening

## Commands (example baseline)

- Backend tests: `python -m pytest` / `npm test` / project-appropriate test runner
- Lint/type check: `npm run lint`, `npm run typecheck`, `ruff check`, etc.
- Frontend build: `npm run build`
- Local run: `npm run dev` and API/server equivalent
- Deploy: `wrangler deploy`, `vercel`, or project-standard deploy command

## Quality Gates

Before completion, verify:

- no unhandled API boundary errors
- required auth checks are covered
- DB migrations are idempotent or reversible
- key user flows are smoke-tested
- deployment artifact is live in target environment
- failure modes are logged and surfaced to operator with remediation steps

## Output Requirements

For every build step report:

- files touched and rationale
- test command(s) and results
- blockers (environmental and code)
- next action if blocked

## Completion Rule

Do not declare completion on feature scope alone. Completion requires:

- implemented slice acceptance criteria
- green local checks above
- deployment smoke check in target environment (or explicit blocked reason)

## Category

Primary: `fullstack`
