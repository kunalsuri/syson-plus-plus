<!-- Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved. -->
# Backend Verification Report - SysON++

> **Generated:** 2026-07-12T23:42:24
> **Repo commit:** `cf03a57cc`
> **Manifest:** `ai/analysis/audit-reports/VERIFICATION_MANIFEST_BACKEND.json`
> **Scope:** Java classes . GraphQL schemas . ANTLR grammars
> **Total claims checked:** 6

---

## Summary

| Status | Count | % of claims |
|---|---|---|
| [OK] Confirmed (file found in backend/) | 6 | 100% |
| [FAIL] Not found - fix or remove from catalog | 0 | 0% |
| [Patterns] Pattern template (intentional Xxx placeholder) | 0 | 0% |

### Backend catalog coverage

> Percentage of actual `backend/` source files documented in the ai/ knowledge layer.
> EMF-generated `*Impl`, `*ItemProvider`, `*Switch`, `*AdapterFactory` files are excluded.

| Type | In codebase | In catalog | Coverage |
|---|---|---|---|
| Java business-logic classes | 977 | 1 | 0% |

---

## Coverage Gaps - Java Classes Not in Catalog (976)

> Business-logic `.java` files in `backend/` that are **not mentioned** in any ai/ knowledge file. Top 80 of 976 shown.

- `AbstractAllocateEdgeDescriptionProvider.java`
- `AbstractBindingConnectorAsUsageEdgeDescriptionProvider.java`
- `AbstractChecker.java`
- `AbstractCodingRulesTests.java`
- `AbstractCompartmentNodeDescriptionProvider.java`
- `AbstractCompartmentNodeToolProvider.java`
- `AbstractControlNodeActionNodeDescriptionProvider.java`
- `AbstractDefinitionNodeDescriptionProvider.java`
- `AbstractDefinitionOwnedUsageEdgeDescriptionProvider.java`
- `AbstractDependencyEdgeDescriptionProvider.java`
- `AbstractEdgeDescriptionProvider.java`
- `AbstractFakeNodeDescriptionProvider.java`
- `AbstractFeatureTypingEdgeDescriptionProvider.java`
- `AbstractFeatureValueEdgeDescriptionProvider.java`
- `AbstractFlowUsageEdgeDescriptionProvider.java`
- `AbstractFreeFormCompartmentNodeToolProvider.java`
- `AbstractIntegrationTests.java`
- `AbstractIntegrationTestWithElasticsearch.java`
- `AbstractInterfaceUsageEdgeDescriptionProvider.java`
- `AbstractItemUsageBorderNodeDescriptionProvider.java`
- `AbstractNodeDescriptionProvider.java`
- `AbstractPackageNodeDescriptionProvider.java`
- `AbstractPortUsageBorderNodeDescriptionProvider.java`
- `AbstractRedefinitionEdgeDescriptionProvider.java`
- `AbstractSubclassificationEdgeDescriptionProvider.java`
- `AbstractSubsettingEdgeDescriptionProvider.java`
- `AbstractSuccessionEdgeDescriptionProvider.java`
- `AbstractTransitionEdgeDescriptionProvider.java`
- `AbstractUsageNestedUsageEdgeDescriptionProvider.java`
- `AbstractUsageNodeDescriptionProvider.java`
- `AcceptActionNodeToolProvider.java`
- `AcceptActionPayloadNodeToolProvider.java`
- `AcceptActionPortUsageReceiverToolNodeProvider.java`
- `AcceptActionUsage.java`
- `ActionDefinition.java`
- `ActionDefinitionParameterBorderNodeDescriptionProvider.java`
- `ActionDefinitionParametersCompartmentNodeDescriptionProvider.java`
- `ActionFlowCompartmentNodeDescriptionProvider.java`
- `ActionFlowCompartmentNodeToolProvider.java`
- `ActionFlowCompartmentTestProjectData.java`
- `ActionFlowTests.java`
- `ActionFlowViewCreateService.java`
- `ActionFlowViewDiagramDescriptionProvider.java`
- `ActionFlowViewInsideActionUsageEmptyTestProjectData.java`
- `ActionFlowViewJavaServiceProvider.java`
- `ActionItemNodeDescriptionProvider.java`
- `ActionTransitionUsagesProjectData.java`
- `ActionTransitionUsagesTests.java`
- `ActionUsage.java`
- `ActionUsageParametersCompartmentNodeDescriptionProvider.java`
- `ActorCompartmentNodeToolProvider.java`
- `ActorMembership.java`
- `ActorNodeDescriptionProvider.java`
- `AddYourFirstElement.java`
- `AFVAddTopControlNodeActionTests.java`
- `AllCustomNodesProjectData.java`
- `AllDiagramsBeforeMergeOfAllDiagramDescriptionsTestProjectData.java`
- `AllocateEdgeDescriptionProvider.java`
- `AllocationDefinition.java`
- `AllocationDefinitionEndsCompartmentItemNodeDescriptionProvider.java`
- `AllocationDefinitionEndsCompartmentNodeDescriptionProvider.java`
- `AllocationUsage.java`
- `AnalysisCaseDefinition.java`
- `AnalysisCaseUsage.java`
- `AnnotatingElement.java`
- `AnnotatingElementOnRelationshipNodeToolProvider.java`
- `AnnotatingNodeDescriptionProvider.java`
- `Annotation.java`
- `AnnotationAnnotatingElementMigrationParticipant.java`
- `AnnotationEdgeDescriptionProvider.java`
- `Appender.java`
- `AQLConstants.java`
- `AQLExpressionCallsExistingServicesChecker.java`
- `AQLUtils.java`
- `ArchitectureConstants.java`
- `AssertConstraintUsage.java`
- `AssertConstraintUsageWithOperatorExpressionTestModel.java`
- `AssignmentActionNodeToolProvider.java`
- `AssignmentActionUsage.java`
- `Association.java`

---

## [OK] Confirmed Claims (6)

<details>
<summary>Expand to see all confirmed claims with verified file locations</summary>

| File | Type | Confidence | Source | Found At |
|---|---|---|---|---|
| `DirectEdit.g4` | grammar | unknown | MODULE_MAP.md | `backend\services\syson-direct-edit-grammar\src\main\resources\DirectEdit.g4 | backend\services\syson-direct-edit-grammar\target\classes\DirectEdit.g4` [WARN] Filename is not unique - 2 matches found |
| `expressions.graphqls` | graphql | unknown | ARCHITECTURE.md | `backend\application\syson-application-configuration\src\main\resources\schema\expressions.graphqls | backend\application\syson-application-configuration\target\classes\schema\expressions.graphqls` [WARN] Filename is not unique - 2 matches found |
| `sysmlcustomnodes.graphqls` | graphql | unknown | MODULE_MAP.md | `backend\application\syson-application-configuration\src\main\resources\schema\sysmlcustomnodes.graphqls | backend\application\syson-application-configuration\target\classes\schema\sysmlcustomnodes.graphqls` [WARN] Filename is not unique - 2 matches found |
| `syson-diagrams.graphqls` | graphql | unknown | MODULE_MAP.md | `backend\views\syson-diagram-common-view\src\main\resources\schema\syson-diagrams.graphqls | backend\views\syson-diagram-common-view\target\classes\schema\syson-diagrams.graphqls` [WARN] Filename is not unique - 2 matches found |
| `syson-import.graphqls` | graphql | unknown | MODULE_MAP.md | `backend\application\syson-sysml-import\src\main\resources\schema\syson-import.graphqls | backend\application\syson-sysml-import\target\classes\schema\syson-import.graphqls` [WARN] Filename is not unique - 2 matches found |
| `SysONApplication.java` | java | unknown | MODULE_MAP.md | `backend\application\syson-application\src\main\java\org\eclipse\syson\SysONApplication.java` |

</details>

---

## Human Audit Checklist (Backend)

Automated checks verify **file existence only**. Descriptions require human eyes:

- [ ] **Fix every [FAIL] Not Found** - open the source catalog, correct the filename or delete the row.
- [ ] **Audit `[inferred]` descriptions** - open each confirmed-but-inferred Java class and verify
       the stated responsibility is accurate. Mark `[verified]` in the catalog when done.
- [ ] **Audit Status column** - every `?` in MODULE_MAP.md needs a human decision:
       `frozen` / `ours` / `stable`. Use `git log -- <path>` to check authorship.
- [ ] **Review Coverage Gaps** - decide if any undocumented class belongs in the catalog.
- [ ] **Re-run** after fixes: `.\scripts-spp\win\verify-ai-docs-backend.ps1`

