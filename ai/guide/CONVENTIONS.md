<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Conventions — how to write code that fits syson-plus-plus

> Status: drafted by /cold-start (2026-06-27). `[inferred]` observations below; a human
> confirms them and adds the rules that live only in heads.

## Languages & style  `[inferred]`
- **Java 21** (backend) — enforced by `maven-enforcer` (`requireJavaVersion [21,22)`).
- **TypeScript/JavaScript** (frontend) — Node `22.16.0`, npm `10.9.2` (pinned in
  `package.json` engines).
- **Frontend formatting:** Prettier (`frontend/syson/.prettierrc`); run via
  `turbo run format` / `turbo run format-lint`. `format-lint` is a `build` dependency in
  `turbo.json`, so it gates the build.
- **Frontend test runner:** **Vitest** (`frontend/syson` `vite.config.js`); build uses
  Vite + `tsc`. GraphQL client is **Apollo Client** (`@apollo/client`). (observed 2026-06-27)
- **Java formatting / static analysis:** Sonar profile present in root `pom.xml`;
  Checkstyle config at `backend/releng/syson-resources/checkstyle/CheckstyleConfiguration.xml`
  (observed 2026-06-27); architecture/coding-rules tests live in `backend/tests/syson-tests`
  (e.g. `AbstractCodingRulesTests`).

## License headers (match neighbors)  `[inferred]`
- **Upstream-area code** (`backend/`, `frontend/`, …): EPL-2.0 block, e.g.
  `Copyright (c) <years> Obeo.` … `SPDX-License-Identifier: EPL-2.0`. Copy the header
  from a neighboring file in the same module.
- **Our additions** (`ai/`, future new modules): the repo uses
  `Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved.` Confirm the intended
  header/license for any new *source* module with a human (EPL-2.0 vs. ours).

## Patterns to follow  `[inferred]`
- **Maven reactor:** one module = one responsibility; `-edit` companion modules pair
  with their metamodel. Imitate an existing sibling under `backend/<group>/`.
- **Sirius GraphQL backend:** server-side data exposed via `*DataFetcher.java`
  (queries) and `Mutation*DataFetcher.java` (mutations) — see
  `backend/views/syson-diagram-common-view/.../datafetchers/`.
- **GraphQL schema = `extend type` only (verified):** SysON's `*.graphqls` schemas
  (e.g. `backend/views/syson-diagram-common-view/src/main/resources/schema/syson-diagrams.graphqls`)
  **extend** Sirius Web's base schema; **never edit Sirius Web's base schema** — add an
  `extend type` block.
- **Direct-edit grammar is ANTLR (generated):** `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4`.
  Edit the `.g4`, regenerate; treat generated parser/lexer sources as frozen.
- **Representations are declarative:** diagrams/tables/trees are defined in the Sirius
  **View-DSL** under `backend/views`, not hand-coded UI. Add representation behavior
  there + matching `backend/services`.
- **Frontend extension model:** custom nodes/extensions register through
  `frontend/syson-components/src/extensions` (see `SysONExtensionRegistry`).

## Things that look wrong but are right  `[verified] required`
<Only humans add rows. The institutional knowledge that prevents "helpful" breakage.>

## Definition of done
- Builds: `mvn -B clean install -DskipTests  &&  npm install && npm run build`
- Tests pass: `mvn -B test  &&  npm test`
- License headers match neighbors; diffs are surgical; `ai/` knowledge updated if the
  change moved or added modules/features.
