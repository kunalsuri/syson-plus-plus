<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Architecture — syson-plus-plus

> Status: drafted by /cold-start on 2026-07-07; a human audits it. Every claim below
> is `[inferred]` unless marked OBSERVED (seen directly in code/config this pass).

## The big pieces  `[inferred]`
- **Web app** — `frontend/syson`: Vite + React 18 SPA wrapping the Sirius Web
  application shell (OBSERVED deps: `@eclipse-sirius/sirius-web-application`, Apollo
  Client, `@xyflow/react` for diagrams, MUI). Entry `frontend/syson/src/index.tsx`.
- **Component library** — `frontend/syson-components`: publishable React library the
  app consumes (custom diagram nodes and SysON widgets).
- **Server** — `backend/application/syson-application`: Spring Boot app (parent
  4.0.7) assembling Sirius Web plus all SysON services. Entry
  `backend/application/syson-application/src/main/java/org/eclipse/syson/SysONApplication.java`.
- **Services layer** — `backend/services/*`: behavior over the model (diagram tools,
  direct edit, forms, tables, trees, REST API).
- **Views layer** — `backend/views/*`: Sirius View-DSL descriptions of each
  representation (standard diagrams, requirements table, explorer tree).
- **Metamodel layer** — `backend/metamodel/*`: EMF-generated Java for SysML v2
  (OBSERVED source models: sysml.ecore, sysml-customnodes.ecore).
- **Database** — PostgreSQL for dev via `docker-compose.yml`; persistence is handled
  by Sirius Web — UNSURE of the exact repository classes, needs human.

## How they connect  `[inferred]`
- **Frontend ↔ backend: GraphQL.** OBSERVED: Apollo Client + graphql deps in
  `frontend/syson/package.json`; `subscriptions-transport-ws` implies WebSocket
  subscriptions for live representation updates. SysON does not own the whole schema:
  it EXTENDS Sirius Web's base schema via module-local *.graphqls files — OBSERVED
  `extend type Mutation` / `extend type EditingContext` in:
  - `backend/application/syson-application-configuration/src/main/resources/schema/sysmlcustomnodes.graphqls`
  - `backend/application/syson-application-configuration/src/main/resources/schema/expressions.graphqls`
  - `backend/application/syson-sysml-import/src/main/resources/schema/syson-import.graphqls`
  - `backend/views/syson-diagram-common-view/src/main/resources/schema/syson-diagrams.graphqls`
  The exact HTTP/WS endpoint paths: UNSURE — needs human (defined by Sirius Web).
- **Backend layering** (dependencies point downward): application → views → services
  → metamodel. INFERRED from naming and the root-pom dependencyManagement; per-pom
  dependency verification is pending — needs human.
- **REST:** `backend/services/syson-sysml-rest-api-services` exposes the SysML v2
  standard REST API — INFERRED from the module name, endpoints unverified.
- **Version coupling:** OBSERVED — sirius.web.version = 2026.5.4 = syson version in
  the root `pom.xml`, and every `@eclipse-sirius/*` npm dep is pinned to 2026.5.4.
  Upstream bumps both in lockstep (see releng commits); never mix versions.

## Diagrams
Text-based (Mermaid) diagrams live in `ai/analysis/diagrams/`. Regenerate them via
/cold-start; do not hand-maintain.

## Invariants an agent must not break  `[verified] required`
<Only humans add rows here. Examples: "generated code in X is never hand-edited",
"public API schemas are backwards compatible".>
