<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Module map — directory → responsibility → entry point

> **Index only.** Find the area here, then open the entry file directly. Don't crawl
> the tree. The directory list can be regenerated; **Responsibility** and **Stability**
> are judgement and must be audited by a human.
> Last verified: — pending human audit. Drafted `[inferred]` by /cold-start on
> 2026-07-07 at commit 21834e82e (branch dev-ai, upstream version 2026.5.4).

## Stability legend (the most important column)
- `frozen` — inherited / load-bearing legacy. **DO NOT edit** without explicit instruction.
- `stable` — works; change carefully and with tests.
- `ours`   — active development surface. Safe for agents to modify.
- `?`      — not yet audited. **Treat as `frozen` until a human decides.**

## Fork boundary — the one fact that sets every Stability value  `[inferred]`

OBSERVED (2026-07-07): HEAD (21834e82e) sits **exactly on upstream/main** — the
merge-base equals HEAD and the three-dot diff against upstream is empty. Every
*committed* file is therefore inherited from eclipse-syson/syson and marked `frozen`
below. Everything of ours lives in the (currently untracked) working tree: `ai/`,
`scripts-spp/`, the SysON++ additions under `.github/`, `.cursor/`, and the modified
`README.md`. UNSURE — needs human: confirm this boundary at audit time; it changes the
moment a commit lands on dev-ai.

## Modules — backend (Maven reactor at root `pom.xml`)  `[inferred]`

All groups are `<module>` entries of the root pom. There is NO backend/pom.xml — the
reactor is the repo root. Java 21 enforced; Spring Boot parent 4.0.7; Sirius Web 2026.5.4.

### backend/application — the runnable server & model exchange

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/application/syson-application` | Spring Boot executable assembling Sirius Web + all SysON services; also hosts the main backend integration-test suite (231 test files) | `backend/application/syson-application/src/main/java/org/eclipse/syson/SysONApplication.java` | frozen |
| `backend/application/syson-application-configuration` | Spring configuration + SysON GraphQL schema extensions (expressions editor, custom node styles) | `backend/application/syson-application-configuration/src/main/resources/schema/sysmlcustomnodes.graphqls` | frozen |
| `backend/application/syson-frontend` | Packages the built frontend as a Maven artifact served by the backend — UNSURE, verify packaging mechanism | `backend/application/syson-frontend/pom.xml` | frozen |
| `backend/application/syson-sysml-export` | Export of SysML v2 models to the standard textual notation | `backend/application/syson-sysml-export/pom.xml` | frozen |
| `backend/application/syson-sysml-import` | Import of SysML v2 models (adds its own GraphQL mutations) | `backend/application/syson-sysml-import/src/main/resources/schema/syson-import.graphqls` | frozen |
| `backend/application/syson-sysml-validation` | SysML model validation rules | `backend/application/syson-sysml-validation/pom.xml` | frozen |

### backend/metamodel — the EMF domain model (GENERATED code)

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/metamodel/syson-sysml-metamodel` | EMF-generated Java model of the SysML v2 language (PartUsage, ActionDefinition, …); source of truth is the ecore, never hand-edit generated Java | `backend/metamodel/syson-sysml-metamodel/src/main/resources/model/sysml.ecore` | frozen |
| `backend/metamodel/syson-sysml-metamodel-edit` | EMF .edit layer (item providers, labels, icons) for the SysML metamodel | `backend/metamodel/syson-sysml-metamodel-edit/pom.xml` | frozen |
| `backend/metamodel/syson-siriusweb-customnodes-metamodel` | Ecore metamodel describing SysON custom diagram node styles (Package, ImportedPackage, Note, ViewFrame) | `backend/metamodel/syson-siriusweb-customnodes-metamodel/src/main/resources/model/sysml-customnodes.ecore` | frozen |
| `backend/metamodel/syson-siriusweb-customnodes-metamodel-edit` | EMF .edit layer for the custom-nodes metamodel | `backend/metamodel/syson-siriusweb-customnodes-metamodel-edit/pom.xml` | frozen |

### backend/services — behavior over the metamodel

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/services/syson-services` | Core shared services — UNSURE exact scope, audit | `backend/services/syson-services/pom.xml` | frozen |
| `backend/services/syson-model-services` | Model-level edit/query services | `backend/services/syson-model-services/pom.xml` | frozen |
| `backend/services/syson-sysml-metamodel-services` | Services directly over the SysML metamodel (element creation, naming, …) | `backend/services/syson-sysml-metamodel-services/pom.xml` | frozen |
| `backend/services/syson-diagram-services` | Services shared by SysON diagram representations (tools, direct edit handling) | `backend/services/syson-diagram-services/pom.xml` | frozen |
| `backend/services/syson-direct-edit-grammar` | ANTLR grammar + generated parser for direct-edit of element labels | `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4` | frozen |
| `backend/services/syson-form-services` | Details/form view services (expression editor backend — inferred from recent upstream commits) | `backend/services/syson-form-services/pom.xml` | frozen |
| `backend/services/syson-representation-services` | Representation lifecycle/metadata services | `backend/services/syson-representation-services/pom.xml` | frozen |
| `backend/services/syson-sysml-rest-api-services` | SysML v2 standard REST API endpoints | `backend/services/syson-sysml-rest-api-services/pom.xml` | frozen |
| `backend/services/syson-table-services` | Table representation services | `backend/services/syson-table-services/pom.xml` | frozen |
| `backend/services/syson-tree-services` | Tree/explorer representation services | `backend/services/syson-tree-services/pom.xml` | frozen |

### backend/views — Sirius View-DSL descriptions of the representations

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/views/syson-common-view` | Helpers shared by all View-DSL descriptions | `backend/views/syson-common-view/pom.xml` | frozen |
| `backend/views/syson-diagram-common-view` | Diagram description parts shared by all SysON diagrams + diagram GraphQL schema extension | `backend/views/syson-diagram-common-view/src/main/resources/schema/syson-diagrams.graphqls` | frozen |
| `backend/views/syson-standard-diagrams-view` | View descriptions of the standard SysML diagrams — UNSURE which exact diagram kinds; audit | `backend/views/syson-standard-diagrams-view/pom.xml` | frozen |
| `backend/views/syson-table-requirements-view` | Requirements table view description | `backend/views/syson-table-requirements-view/pom.xml` | frozen |
| `backend/views/syson-tree-explorer-view` | Model explorer tree view description | `backend/views/syson-tree-explorer-view/pom.xml` | frozen |
| `backend/views/syson-diagram-tests` | Diagram-view test utilities/tests | `backend/views/syson-diagram-tests/pom.xml` | frozen |

### backend/releng + backend/tests — build support

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `backend/releng/syson-test-coverage` | JaCoCo aggregate coverage reactor module | `backend/releng/syson-test-coverage/pom.xml` | frozen |
| `backend/releng/syson-resources` | Shared build resources — Checkstyle config lives here (NOT a Maven module) | `backend/releng/syson-resources/checkstyle/CheckstyleConfiguration.xml` | frozen |
| `backend/tests/syson-tests` | Backend test-support module — UNSURE scope (only 2 test files), audit | `backend/tests/syson-tests/pom.xml` | frozen |

## Modules — frontend (npm workspaces at root `package.json`, Turborepo)  `[inferred]`

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `frontend/syson` | The SysON web app — Vite + React 18 + Apollo GraphQL + Sirius Web application shell; unit tests via vitest | `frontend/syson/src/index.tsx` | frozen |
| `frontend/syson-components` | Publishable React component library (custom nodes, SysON widgets) consumed by the app; has NO test script | `frontend/syson-components/src/index.ts` | frozen |

## Modules — E2E tests, docs, tooling  `[inferred]`

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `integration-tests-cypress` | Cypress end-to-end suite against a running app | `integration-tests-cypress/cypress.config.ts` | frozen |
| `integration-tests-playwright` | Playwright end-to-end suite against a running app | `integration-tests-playwright/playwright.config.ts` | frozen |
| `doc` | Documentation site content (Antora-style layout under `doc/content`) | `doc/content` | frozen |
| `scripts` | Upstream release/CI helper scripts (changelog, copyright, version checks) | `scripts/prepare-release.js` | frozen |
| `docker-compose.yml` | Dev PostgreSQL database (single file, not a directory) | `docker-compose.yml` | frozen |

## Modules — OURS (SysON++ additions, currently untracked)  `[inferred]`

| Directory | Responsibility (one line) | Entry point | Stability |
|---|---|---|---|
| `ai` | The AI knowledge layer: guide (maps), analysis (generated), lab (specs/reviews/ledger) | `ai/INDEX.md` | ours |
| `scripts-spp` | SysON++ dev tooling: start/stop dev environment (PowerShell), ai-docs verification | `scripts-spp/verify-ai-docs.ps1` | ours |
| `.cursor/rules` | Kit-installed Cursor mirrors of the ai/ workflows | `.cursor/rules/ai-knowledge-layer.mdc` | ours |
| `.github/chatmodes` | Kit-installed Copilot chatmodes mirroring the subagents | `.github/chatmodes/repo-explorer.chatmode.md` | ours |
| `.github/prompts` | Kit-installed Copilot prompts mirroring the slash commands (plus `.github/copilot-instructions.md`) | `.github/prompts/cold-start.prompt.md` | ours |
| `.github/workflows/ai-check.yml` | CI: verifies ai/ path claims + drift on push/PR (single file — the REST of .github is upstream and frozen; mixed-ownership directory) | `.github/workflows/ai-check.yml` | ours |
| .claude + .agents | Claude Code commands/agents/skills + tool-agnostic skill mirrors — machine-local, git-ignored by upstream .gitignore, so their paths stay UNbackticked here (entry: .claude/rules/ai-knowledge-layer.md) | — | ours |
| `README.md` | SysON++ README (ours; upstream's original preserved as `README-upstream.md`) | `README.md` | ours |

Detected test locations (drafted during cold start, `[inferred]`): backend tests are
per-module under src/test/java — largest suites: syson-application (231 test files),
syson-sysml-metamodel (44), syson-sysml-metamodel-services (21), syson-services (11);
frontend unit tests only in `frontend/syson` (vitest — `frontend/syson-components` has
no test script); E2E in `integration-tests-cypress` and `integration-tests-playwright`
(both need a running app — UNSURE how CI launches it, audit).

## Audit protocol
1. /cold-start fills rows and tags them `[inferred]`.
2. A human sets Stability per row and flips confirmed rows to `[verified] (date)`.
3. Agents treat `?` rows as `frozen`. Agents never flip tags.

Field guide for the human audit (how to decide, evidence bar, worked rows):
https://github.com/kunalsuri/ai-fication-kit/blob/main/docs/AUDIT-GUIDE.md
