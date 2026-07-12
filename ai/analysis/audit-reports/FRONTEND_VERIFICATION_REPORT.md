<!-- Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved. -->
# Frontend Verification Report - SysON++

> **Generated:** 2026-07-12T23:42:25
> **Repo commit:** `cf03a57cc`
> **Manifest:** `ai/analysis/audit-reports/VERIFICATION_MANIFEST_FRONTEND.json`
> **Scope:** TypeScript components (.tsx) . Hooks & utilities (.ts)
> **Scanned directories:** `frontend/` . `integration-tests-cypress/` . `integration-tests-playwright/`
> **Total claims checked:** 0

---

## Summary

| Status | Count | % of claims |
|---|---|---|
| [OK] Confirmed (file found in frontend/) | 0 | n/a |
| [FAIL] Not found - fix or remove from catalog | 0 | n/a |
| [Patterns] Pattern template (intentional Xxx placeholder) | 0 | n/a |

### Frontend catalog coverage

> What percentage of actual `frontend/` source files are documented in the ai/ knowledge layer?
> Test, story, and declaration files are excluded from the counts.

| Type | In codebase | In catalog | Coverage |
|---|---|---|---|
| React components (.tsx) | 41 | 0 | 0% |
| Hooks & utilities (.ts) | 99 | 0 | 0% |

---

## Coverage Gaps - React Components Not in Catalog (41)

> These `.tsx` files exist in `frontend/` but are **not mentioned** in any ai/ knowledge file.

- `DeleteExpressionDiagramToolOverriddenContribution.tsx`
- `DeleteExpressionExplorerToolOverriddenContribution.tsx`
- `DeleteSysMLExpressionMenuContribution.tsx`
- `EditExpressionDiagramToolOverriddenContribution.tsx`
- `EditExpressionExplorerToolOverriddenContribution.tsx`
- `EditSysMLExpressionMenuContribution.tsx`
- `EditSysMLExpressionModal.tsx`
- `ExpressionFeatureValueProperties.tsx`
- `ExpressionPropertySection.tsx`
- `index.tsx`
- `InsertTextualSysMLv2ExplorerToolOverriddenContribution.tsx`
- `InsertTextualSysMLv2MenuContribution.tsx`
- `InsertTextualSysMLv2Modal.tsx`
- `NewExpressionDiagramToolOverriddenContribution.tsx`
- `NewExpressionExplorerToolOverriddenContribution.tsx`
- `NewObjectAsTextDocumentReport.tsx`
- `NewSysMLExpressionMenuContribution.tsx`
- `PublishProjectSysMLContentsAsLibraryCommand.tsx`
- `RotateNodeToolOverriddenContribution.tsx`
- `ShowHideDiagramsIcons.tsx`
- `ShowHideDiagramsInheritedMembers.tsx`
- `ShowHideDiagramsInheritedMembersFromStandardLibraries.tsx`
- `SysMLImportedPackageNode.tsx`
- `SysMLImportedPackageNodePaletteAppearanceSection.tsx`
- `SysMLImportedPackageNodePart.tsx`
- `SysMLNoteNode.tsx`
- `SysMLNoteNodePaletteAppearanceSection.tsx`
- `SysMLNoteNodePart.tsx`
- `SysMLPackageNode.tsx`
- `SysMLPackageNodePaletteAppearanceSection.tsx`
- `SysMLPackageNodePart.tsx`
- `SysMLViewFrameNode.tsx`
- `SysMLViewFrameNodePaletteAppearanceSection.tsx`
- `SysMLViewFrameNodePart.tsx`
- `SysONDiagramPanelMenu.tsx`
- `SysONExtensionRegistry.tsx`
- `SysONFooter.tsx`
- `SysONIcon.tsx`
- `SysONNavigationBarIcon.tsx`
- `SysONNavigationBarMenuIcon.tsx`
- `SysONNodeTypeRegistry.tsx`

---

## Coverage Gaps - TypeScript Hooks & Utilities Not in Catalog (99)

> These `.ts` files (hooks, converters, handlers, types) exist in `frontend/` but are not in any ai/ knowledge file. Top 60 of 99 shown.

- `Batmobile.ts`
- `Batmobile.types.ts`
- `createDocumentCommand.ts`
- `createDocumentCommand.types.ts`
- `createProjectCommand.ts`
- `createProjectCommand.types.ts`
- `deleteProjectCommand.ts`
- `deleteProjectCommand.types.ts`
- `details.cy.ts`
- `Details.ts`
- `Diagram.ts`
- `diagramCreationTests.cy.ts`
- `diagramPanelTests.cy.ts`
- `directEditTests.cy.ts`
- `dropFromExplorer.cy.ts`
- `e2e.ts`
- `EditSysMLExpressionModal.types.ts`
- `Explorer.ts`
- `ExpressionProperties.types.ts`
- `getCurrentEditingContextId.ts`
- `getCurrentEditingContextId.types.ts`
- `getLibraryId.ts`
- `getLibraryId.types.ts`
- `graphql.types.ts`
- `index.ts`
- `InsertTextualSysMLv2Modal.types.ts`
- `insertTextualSysMLv2Tests.cy.ts`
- `NewObjectAsTextDocumentReport.types.ts`
- `nodeCreationTests.cy.ts`
- `PlaywrightDetails.ts`
- `PlaywrightDiagram.ts`
- `PlaywrightEdge.ts`
- `PlaywrightExplorer.ts`
- `PlaywrightLabel.ts`
- `PlaywrightNode.ts`
- `PlaywrightNodeLabel.ts`
- `PlaywrightProject.ts`
- `PlaywrightWorkbench.ts`
- `Project.ts`
- `Projects.ts`
- `PublishProjectSysMLContentsAsLibraryCommand.types.ts`
- `semanticElementCreationTests.cy.ts`
- `ShowHideDiagramsIcons.types.ts`
- `ShowHideDiagramsInheritedMembers.types.ts`
- `ShowHideDiagramsInheritedMembersFromStandardLibraries.types.ts`
- `SysMLImportedPackageNode.types.ts`
- `SysMLImportedPackageNodeConverter.ts`
- `SysMLImportedPackageNodeLayoutHandler.ts`
- `SysMLImportedPackageNodePaletteAppearanceSection.types.ts`
- `SysMLImportedPackageNodePart.types.ts`
- `SysMLNodesDocumentTransform.ts`
- `SysMLNoteNode.types.ts`
- `SysMLNoteNodeConverter.ts`
- `SysMLNoteNodeLayoutHandler.ts`
- `SysMLNoteNodePaletteAppearanceSection.types.ts`
- `SysMLNoteNodePart.types.ts`
- `SysMLPackageNode.types.ts`
- `SysMLPackageNodeConverter.ts`
- `SysMLPackageNodeLayoutHandler.ts`
- `SysMLPackageNodePaletteAppearanceSection.types.ts`

---

## [OK] Confirmed Claims (0)

<details>
<summary>Expand - React components (0) and TypeScript hooks/utilities (0)</summary>

| File | Type | Confidence | Source | Found At |
|---|---|---|---|---|

</details>

---

## Human Audit Checklist (Frontend)

Automated checks verify **file existence only**. Descriptions require human eyes:

- [ ] **Fix every [FAIL] Not Found** - open the source catalog, correct the filename or delete the row.
- [ ] **Audit `[inferred]` descriptions** - open each confirmed-but-inferred component and verify
       the stated role is accurate. Mark `[verified]` in the catalog when done.
- [ ] **Known bug** - `SysMLViewFrameNodePaletteAppearanceSection.canHandle` checks for
       `'sysMLNoteNode'` instead of `'sysMLViewFrameNode'` -> appearance panel never triggers.
       See FEATURE_MAP.md for details.
- [ ] **Review Coverage Gaps** - decide if undocumented TSX/TS files belong in the catalog.
- [ ] **Re-run** after fixes: `.\scripts-spp\win\verify-ai-docs-frontend.ps1`

