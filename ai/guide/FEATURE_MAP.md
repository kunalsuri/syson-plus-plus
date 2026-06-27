<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Feature map — feature → files, intent, gotchas

> Humans think in features; agents should too. This file holds the SHORT version —
> per-feature pointers and non-obvious notes. The full generated catalog lives in
> `ai/analysis/FEATURE_CATALOG.md` (via /create-feature-catalog).
>
> Drafted by /cold-start (2026-06-27). All entries below are `[inferred]` from module
> names — **a human (or /create-feature-catalog) must confirm files and gotchas.**

## Template (copy per feature)

### <Feature name>  `[inferred]`
- **Business goal:** <one line>
- **Touches:** <dirs/files across layers — UI, backend, persistence, tests>
- **Verify with:** <the specific test command or suite>
- **Gotchas:** <the non-obvious thing that bites people>
- **Related:** <other features that share code paths>

## Candidate features (drafted by /cold-start, audit before trusting)

### SysML v2 graphical diagrams  `[inferred]`
- **Business goal:** Edit SysML v2 models as Sirius diagrams (nodes, edges, palettes).
- **Touches:** `backend/views/syson-standard-diagrams-view`, `syson-diagram-common-view`; `backend/services/syson-diagram-services`; `frontend/syson-components/src/nodes`.
- **Verify with:** `backend/views/syson-diagram-tests`; Cypress/Playwright E2E.
- **Gotchas:** representations are declarative (View-DSL) — change behavior in `views` + `services`, not by hand-coding UI.

### Tree explorer  `[inferred]`
- **Touches:** `backend/views/syson-tree-explorer-view`; `backend/services/syson-tree-services`.

### Tables (e.g. Requirements)  `[inferred]`
- **Touches:** `backend/views/syson-table-requirements-view`; `backend/services/syson-table-services`.

### Form-based editing  `[inferred]`
- **Touches:** `backend/services/syson-form-services`.

### Direct-edit (in-place label editing)  `[inferred]`
- **Touches:** `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4` (ANTLR grammar parses edited labels).
- **Gotchas:** ANTLR-generated — edit the `.g4`, regenerate; treat generated parser/lexer as frozen.

### SysML v2 textual import / export  `[inferred]`
- **Touches:** `backend/application/syson-sysml-import` (`MutationInsertTextualSysMLv2DataFetcher`), `syson-sysml-export`.
- **Business goal:** Round-trip the SysML v2 textual interchange format.

### Model validation  `[inferred]`
- **Touches:** `backend/application/syson-sysml-validation`.

### SysML REST API  `[inferred]`
- **Touches:** `backend/services/syson-sysml-rest-api-services` (SysML v2 API standard surface).
