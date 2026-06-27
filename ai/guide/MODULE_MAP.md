<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Module map — directory → responsibility → entry point

> **Index only.** Find the area here, then open the entry file directly. Don't crawl
> the tree. The directory list can be regenerated; **Responsibility** and **Stability**
> are judgement and must be audited by a human.
> Drafted by /cold-start: 2026-06-27 @ commit `0551e64e8` (branch `dev-expt-01`). `[inferred]` — needs human audit.

## Stability legend (the most important column)
- `frozen` — inherited / load-bearing legacy. **DO NOT edit** without explicit instruction.
- `stable` — works; change carefully and with tests.
- `ours`   — active development surface. Safe for agents to modify.
- `?`      — not yet audited. **Treat as `frozen` until a human decides.**

## Fork status (read before trusting any Stability below) `[inferred]`
This branch (`dev-expt-01`) sits **exactly on upstream `eclipse-syson/syson` `main`** —
`git merge-base HEAD upstream/main` returns HEAD's own commit and `git diff
upstream/main...HEAD` is **empty**. Therefore **every committed file under `backend/`,
`frontend/`, `integration-tests-*`, `doc/`, and `scripts/` is upstream code → `frozen`.**
The only local (untracked) addition is `ai/` (this knowledge layer → `ours`). Our future
work goes in NEW modules, not by editing the rows below.

## Modules — top-level navigation
| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/` | Java / Spring Boot server built on the Sirius Web platform (SysML v2 / KerML modeling) — Maven reactor, 6 module groups | `backend/application/syson-application/src/main/java/org/eclipse/syson/SysONApplication.java` | `frozen` `[inferred]` |
| `frontend/` | React/TypeScript web client (npm workspaces, Turborepo) | `frontend/syson` (`@eclipse-syson/syson`) | `frozen` `[inferred]` |
| `integration-tests-cypress/` | Cypress end-to-end UI tests | `integration-tests-cypress/` | `frozen` `[inferred]` |
| `integration-tests-playwright/` | Playwright end-to-end UI tests | `integration-tests-playwright/` | `frozen` `[inferred]` |
| `doc/` | Documentation: ADRs, docs-site, UI docs, shapes, SysML import notes | `doc/docs-site/`, `doc/adrs/` | `frozen` `[inferred]` |
| `scripts/` | Repo / CI maintenance scripts (Node + shell): changelog, copyright, coverage, release | `scripts/` | `frozen` `[inferred]` |
| `ai/` | **OURS** — AI knowledge layer (maps, diagrams, catalogs); not committed yet | `ai/INDEX.md` | `ours` `[inferred]` |

## Backend Maven modules (all `frozen` upstream — see Fork status) `[inferred]`
| Module group | Submodules | Responsibility |
|---|---|---|
| `backend/application` | `syson-application` (Spring Boot main), `syson-application-configuration`, `syson-frontend` (serves built UI), `syson-sysml-import`, `syson-sysml-export`, `syson-sysml-validation` | Deployable app + SysML v2 textual import/export/validation |
| `backend/metamodel` | `syson-sysml-metamodel`(+`-edit`), `syson-siriusweb-customnodes-metamodel`(+`-edit`) | EMF metamodels: SysML v2 / KerML domain + custom Sirius diagram nodes |
| `backend/services` | `syson-services`, `syson-model-services`, `syson-diagram-services`, `syson-form-services`, `syson-table-services`, `syson-tree-services`, `syson-representation-services`, `syson-sysml-metamodel-services`, `syson-sysml-rest-api-services`, `syson-direct-edit-grammar` | Business services per representation kind + REST API + direct-edit grammar |
| `backend/views` | `syson-common-view`, `syson-diagram-common-view`, `syson-standard-diagrams-view`, `syson-table-requirements-view`, `syson-tree-explorer-view`, `syson-diagram-tests` | Sirius View-DSL definitions for diagrams, tables, tree explorer |
| `backend/tests` | `syson-tests` | Backend integration / architecture (coding-rules) tests |
| `backend/releng` | `syson-resources`, `syson-test-coverage` | Release engineering: shared resources + aggregated coverage |

## Frontend packages (all `frozen` upstream) `[inferred]`
| Package | npm name | Responsibility | Source roots |
|---|---|---|---|
| `frontend/syson` | `@eclipse-syson/syson` | Main web application | `src/core`, `src/extensions`, `src/theme` |
| `frontend/syson-components` | `@eclipse-syson/syson-components` | Reusable Sirius Web extensions + custom SysML diagram nodes | `src/extensions`, `src/nodes` |

## Detected test locations (observed) `[inferred]`
- Backend: per-module `src/test/java` (Maven Surefire) + `backend/tests/syson-tests` (integration & architecture tests) + `backend/views/syson-diagram-tests`; coverage aggregated in `backend/releng/syson-test-coverage`.
- Frontend: `frontend/syson` runs **Vitest** (`"test": "vitest --run --config vite.config.js"`) via `turbo run test`; `frontend/syson-components` has no test script (build-only: `vite build && tsc`). (observed 2026-06-27)
- End-to-end: `integration-tests-cypress/` and `integration-tests-playwright/`.

## Build & test (verified against config 2026-06-27) `[inferred]`
- Build: `mvn -B clean install -DskipTests  &&  npm install && npm run build` — root `pom.xml` is a 6-module reactor; `npm run build` → `turbo run build` (`package.json`). **Java 21 required** (enforced by `maven-enforcer`: `[21,22)`); Node `22.16.0` / npm `10.9.2` pinned (`package.json` engines). ✔ verified
- Test: `mvn -B test  &&  npm test` — `npm test` → `turbo run test` (depends on build). ✔ verified

## Audit protocol
1. /cold-start fills rows and tags them `[inferred]`.
2. A human sets Stability per row and flips confirmed rows to `[verified] (date)`.
3. Agents treat `?` rows as `frozen`. Agents never flip tags.

Field guide for the human audit (how to decide, evidence bar, worked rows):
https://github.com/kunalsuri/ai-fication-kit/blob/main/docs/AUDIT-GUIDE.md
