<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Architecture — syson-plus-plus

> Status: drafted by /cold-start (2026-06-27). Tag every claim `[inferred]` or
> `[verified] (date)`. A human audits before these are trusted.

## The big pieces  `[inferred]`
Names match real directories in `MODULE_MAP.md`.

- **`backend/application`** — the deployable Spring Boot server (`SysONApplication`),
  configuration, the module that serves the built frontend, and SysML v2 textual
  import / export / validation.
- **`backend/metamodel`** — EMF metamodels: the SysML v2 / KerML domain model and the
  custom Sirius diagram-node metamodel (each with an `-edit` companion).
- **`backend/services`** — business logic per representation kind (diagram, form, table,
  tree, model, representation) plus the SysML REST API and the direct-edit grammar.
- **`backend/views`** — Sirius **View-DSL** definitions that declare the actual
  diagrams, tables, and the tree explorer shown to users.
- **`frontend/syson`** (`@eclipse-syson/syson`) — the React/TypeScript web application.
- **`frontend/syson-components`** (`@eclipse-syson/syson-components`) — reusable Sirius
  Web extensions and custom SysML diagram-node renderers consumed by the app.

## How they connect  `[inferred]`
- **Frontend ↔ backend: GraphQL** (Sirius Web convention) — **verified by code
  presence**: backend exposes `*DataFetcher.java` query/mutation fetchers (e.g.
  `backend/views/syson-diagram-common-view/.../datafetchers/`,
  `backend/application/syson-sysml-import/.../MutationInsertTextualSysMLv2DataFetcher.java`);
  the frontend client is **Apollo Client** (`@apollo/client`). The live-update
  subscription transport is **owned by the Sirius Web platform** (`@eclipse-sirius/sirius-components-core`,
  a dependency) — it is not wired in this repo's own code, so don't expect to find/change
  it here. (observed 2026-06-27)
- **Backend layering (verified by POM dependencies 2026-06-27):** `metamodel` (domain) ←
  `services` (logic) ← `views` (View-DSL representations) ← `application` (wires it into
  Spring Boot + Sirius Web). Each layer depends only downward (e.g. `syson-application`
  → views → services → `syson-sysml-metamodel`). See `ai/analysis/diagrams/package-deps.mmd`.
- **Persistence: PostgreSQL** (observed 2026-06-27) — `docker-compose.yml` runs
  `postgres:15` and the app uses `SPRING_DATASOURCE_URL: jdbc:postgresql://database/postgres`;
  config in `backend/application/syson-application/src/main/resources/application.properties`.
  This is Sirius Web's default store; SysON doesn't customize the persistence layer here.

## Diagrams
Mermaid diagrams live in `ai/analysis/diagrams/`:
- `package-deps.mmd` — module dependency graph
- `domain-core.mmd` — core domain types
- `seam.mmd` — the frontend↔backend boundary
Regenerate via /cold-start; do not hand-maintain.

## Invariants an agent must not break  `[verified] required`
<Only humans add rows here. Candidate invariants observed during cold-start, for the
human to confirm and promote:>
- Upstream code (everything except `ai/`) is frozen — see `MODULE_MAP.md` Fork status.
- Backend must build on **Java 21** (enforced by `maven-enforcer`).
- **Never edit Sirius Web's base GraphQL schema** — SysON's `*.graphqls` use `extend
  type` (verified 2026-06-27 across 4 backend schema files).
- New source files must carry the matching license header (EPL-2.0 / Obeo block in
  upstream areas; see `CONVENTIONS.md`).
