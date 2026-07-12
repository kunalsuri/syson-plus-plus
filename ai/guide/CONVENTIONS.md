<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Conventions — how to write code that fits syson-plus-plus

> Status: drafted by /cold-start on 2026-07-07; observations `[inferred]`; humans
> confirm and add the rules that live only in heads.

## Languages & style  `[inferred]`
- Java 21 — enforced by the maven-enforcer rule in the root `pom.xml` (build fails
  outside [21,22)); Maven ≥ 3.6.3 required.
- Checkstyle (13.3.0 via maven-checkstyle-plugin) with the shared config at
  `backend/releng/syson-resources/checkstyle/CheckstyleConfiguration.xml`; each
  backend module carries a .checkstyle file.
- TypeScript 5.4 / React 18; Prettier 2.7.1 per package (OBSERVED .prettierrc in
  `frontend/syson`, `frontend/syson-components`, both integration-test dirs);
  `npm run format-lint` (Turborepo) checks formatting.
- Node 22.16.0 / npm 10.9.2 pinned in the root `package.json` engines field.
- License: EPL-2.0. Every upstream source file carries an Obeo/contributor EPL
  header — copy the header style of neighboring files. SysON++ files (ours) carry a
  CEA LIST header (see `scripts-spp/win/verify-ai-docs.ps1` for the pattern).

## Patterns to follow  `[inferred]`
- **Generated EMF code is regenerated, never hand-edited.** The metamodel source of
  truth is `backend/metamodel/syson-sysml-metamodel/src/main/resources/model/sysml.ecore`
  (and sysml-customnodes.ecore for custom nodes); the Java under those modules is
  generated from it.
- **GraphQL is extended, not owned.** New API surface goes in a module-local
  *.graphqls file using `extend type` on Sirius Web's base schema — exemplar:
  `backend/application/syson-application-configuration/src/main/resources/schema/sysmlcustomnodes.graphqls`.
  Never edit the base schema.
- **Definition/Usage duality.** SysML v2 metamodel types come in pairs
  (PartDefinition/PartUsage, …); services and views usually need to handle both.
- **Direct-edit changes go through the grammar.** Label parsing is generated from
  `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4`
  (ANTLR) — change the grammar, regenerate; don't patch generated parser code.
- **Tests live with their module** in src/test/java; cross-cutting backend
  integration tests live in `backend/application/syson-application` (231 test
  files — the de-facto integration suite). Frontend unit tests: vitest in
  `frontend/syson` only.
- **Upstream commit style** (for reference, ours may differ): subject prefixed with
  an issue/tag like [1234], [releng], [doc], [test], [cleanup].

## Things that look wrong but are right  `[verified] required`
<Only humans add rows. The institutional knowledge that prevents "helpful" breakage.>

## Definition of done
- Builds: `mvn -B clean install -DskipTests  &&  npm install && npm run build`
- Tests pass: `mvn -B test  &&  npm test`
- License headers match neighbors; diffs are surgical; ai/ knowledge updated if the
  change moved or added modules/features.
- If ai/ was touched: path claims verified — CI runs ai-fication-kit verify via
  `.github/workflows/ai-check.yml`; locally run `scripts-spp/win/verify-ai-docs.ps1`
  (writes reports to ai/analysis/audit-reports/).
