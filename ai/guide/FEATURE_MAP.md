<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Feature map — feature → files, intent, gotchas

> Humans think in features; agents should too. This file holds the SHORT version —
> per-feature pointers and non-obvious notes. The full generated catalog lives in
> `ai/analysis/FEATURE_CATALOG.md` (via /create-feature-catalog).

## Template (copy per feature)

### <Feature name>  `[inferred]`
- **Business goal:** <one line>
- **Touches:** <dirs/files across layers — UI, backend, persistence, tests>
- **Verify with:** <the specific test command or suite>
- **Gotchas:** <the non-obvious thing that bites people>
- **Related:** <other features that share code paths>

## Candidate features (drafted by /cold-start 2026-07-07, audit before trusting)

### Standard SysML diagrams  `[inferred]`
- **Business goal:** create/edit SysML v2 diagrams (General View and siblings) in the browser
- **Touches:** `backend/views/syson-standard-diagrams-view`, `backend/views/syson-diagram-common-view`, `backend/services/syson-diagram-services`, `frontend/syson-components`
- **Verify with:** mvn -B test on the views/services modules; E2E in `integration-tests-cypress`
- **Gotchas:** UNSURE which exact diagram kinds live in the consolidated standard-diagrams-view module — audit
- **Related:** Custom node styles, Direct edit

### Custom diagram node styles (Package / ImportedPackage / Note / ViewFrame)  `[inferred]`
- **Business goal:** SysML-specific node renderings beyond stock Sirius Web nodes
- **Touches:** `backend/metamodel/syson-siriusweb-customnodes-metamodel`, `backend/application/syson-application-configuration/src/main/resources/schema/sysmlcustomnodes.graphqls`, `frontend/syson-components`
- **Verify with:** backend module tests + Cypress diagram specs
- **Gotchas:** four node styles OBSERVED in the GraphQL schema; each has paired Appearance input types that must stay in sync frontend↔backend
- **Related:** Standard SysML diagrams

### Direct edit of element labels  `[inferred]`
- **Business goal:** type SysML textual syntax directly on diagram labels
- **Touches:** `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4`, `backend/services/syson-diagram-services`
- **Verify with:** tests in the two services modules (recent upstream fixes: [2318], [2306])
- **Gotchas:** parser code is GENERATED from the .g4 — change the grammar, regenerate
- **Related:** Standard SysML diagrams

### SysML v2 textual import / export  `[inferred]`
- **Business goal:** exchange models as standard SysML v2 text
- **Touches:** `backend/application/syson-sysml-import`, `backend/application/syson-sysml-export`
- **Verify with:** module test suites (upstream fix [2329] "importing requirements as text" shows active churn)
- **Gotchas:** import adds its own GraphQL mutations via `backend/application/syson-sysml-import/src/main/resources/schema/syson-import.graphqls`
- **Related:** SysML v2 REST API

### SysML v2 standard REST API  `[inferred]`
- **Business goal:** OMG SysML v2 API endpoint compliance for interop
- **Touches:** `backend/services/syson-sysml-rest-api-services`
- **Verify with:** module tests + integration tests in syson-application
- **Gotchas:** UNSURE of endpoint coverage vs. the OMG spec — audit
- **Related:** Textual import/export

### Expressions editor (details form)  `[inferred]`
- **Business goal:** edit SysML expressions (incl. default/initial values) from the details panel
- **Touches:** `backend/application/syson-application-configuration/src/main/resources/schema/expressions.graphqls`, `backend/services/syson-form-services`, `frontend/syson`
- **Verify with:** form-services tests; recent upstream commits [2325]/[2336] are the change trail
- **Gotchas:** GraphQL extends EditingContext — state lives server-side in ExpressionEditorState
- **Related:** Direct edit (both parse SysML expressions)

### Requirements table & model explorer tree  `[inferred]`
- **Business goal:** tabular requirements management and model navigation
- **Touches:** `backend/views/syson-table-requirements-view`, `backend/services/syson-table-services`, `backend/views/syson-tree-explorer-view`, `backend/services/syson-tree-services`
- **Verify with:** module tests + Playwright/Cypress suites
- **Gotchas:** none known yet — audit
- **Related:** Standard SysML diagrams

### AI knowledge layer (OURS)  `[inferred]`
- **Business goal:** make this fork legible and safe for AI coding agents (the actual research object of SysON++)
- **Touches:** `ai/`, `scripts-spp/`, `.github/workflows/ai-check.yml`, `.cursor/rules`, `.github/prompts`, `.github/chatmodes`, `README.md`
- **Verify with:** ai-fication-kit verify (CI) or `scripts-spp/win/verify-ai-docs.ps1` locally
- **Gotchas:** everything in ai/ is `[inferred]` until a human flips it; agents never flip the tag
- **Related:** — (meta-layer over all other features)
