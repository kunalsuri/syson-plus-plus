<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Project overview — syson-plus-plus

> Status: drafted by /cold-start on 2026-07-07 (kit first-run 2026-07-06, branch
> dev-ai); every section `[inferred]` until audited.

## What this is
SysON++ — an experimental R&D sandbox by researchers at CEA LIST for turning a
complex, industrial-grade codebase into an AI-native environment. It is a FORK of
**eclipse-syson/syson** (upstream): the web-based SysML v2 modeling platform built by
Obeo on Sirius Web. Upstream version at fork point: 2026.5.4.

## Stack (from `ai/repo-profile.json` — deterministic, cross-checked 2026-07-07)
- Languages: Java 21 (backend), TypeScript/React 18 (frontend)
- Build: `mvn -B clean install -DskipTests  &&  npm install && npm run build`
  — VERIFIED plausible: the Maven reactor is the repo-root `pom.xml` (there is no
  backend/pom.xml) and npm workspaces + Turborepo are driven from the repo-root
  `package.json` / `turbo.json` (`build` = turbo run build).
- Test: `mvn -B test  &&  npm test` — VERIFIED plausible: root scripts exist;
  npm test = turbo run test → vitest in `frontend/syson`.
- Node 22.16.0 / npm 10.9.2 pinned via engines; PostgreSQL via `docker-compose.yml`.

## Why it exists  `[inferred — from our README.md]`
To test which metadata formats, guardrails, and developer tools actually work when
introducing AI coding agents to a real, legacy systems-engineering codebase; to build
the AI-native context/memory/verification layers agents need to operate safely; and to
eventually contribute high-confidence improvements back to the Eclipse Foundation and
the MBSE community. The fork is the testbed; the product is the method.

## What we add vs. what we inherit  `[inferred]`
OBSERVED (2026-07-07): zero committed divergence — HEAD (21834e82e) equals the
merge-base with upstream/main, so **every committed file is upstream's** and frozen.
Ours (untracked working tree so far):
- `ai/` — the knowledge layer (guide, analysis, lab) managed by ai-fication-kit 0.3.0
- `scripts-spp/` — SysON++ dev tooling (PowerShell start/stop, ai-docs verification)
- `.github/chatmodes`, `.github/prompts`, `.github/copilot-instructions.md`,
  `.github/workflows/ai-check.yml` — multi-tool mirrors + CI knowledge-base check
- `.cursor/rules` — Cursor mirrors; .claude + .agents (git-ignored, machine-local) — Claude Code layer
- `README.md` (rewritten; upstream original kept as `README-upstream.md`)

Inherited (frozen): everything else — `backend/`, `frontend/`,
`integration-tests-cypress/`, `integration-tests-playwright/`, `doc/`, `scripts/`,
root build manifests. See `ai/guide/MODULE_MAP.md` for the row-by-row map.

## Glossary  `[inferred]`
| Term | Meaning here |
|---|---|
| SysML v2 | The systems-modeling language this tool edits; defined by the OMG spec |
| Sirius Web | Obeo's platform for web modeling tools; SysON extends it (backend Java + `@eclipse-sirius/*` npm packages, both 2026.5.4) |
| EMF / Ecore | Eclipse Modeling Framework; the SysML metamodel is GENERATED Java from `backend/metamodel/syson-sysml-metamodel/src/main/resources/model/sysml.ecore` |
| Definition / Usage | The SysML v2 duality: types come in pairs (PartDefinition/PartUsage, ActionDefinition/ActionUsage, …) mirrored throughout the metamodel |
| View DSL | Sirius Web's description mechanism; `backend/views/` modules describe diagrams/tables/trees programmatically |
| GraphQL seam | Frontend↔backend protocol: Sirius Web's base GraphQL schema + SysON extensions in module-local *.graphqls files |
| Direct edit | In-diagram label editing parsed by the ANTLR grammar `backend/services/syson-direct-edit-grammar/src/main/resources/DirectEdit.g4` |
| Turborepo | Frontend monorepo task runner (root `turbo.json`); npm workspaces live under frontend |
| ai-fication-kit | The tooling that installed and verifies the `ai/` layer (CI: `.github/workflows/ai-check.yml`) |
| frozen / ours | Stability values in `ai/guide/MODULE_MAP.md`; frozen = inherited upstream, hands off |
