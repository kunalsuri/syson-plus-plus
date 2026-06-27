<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Project overview — syson-plus-plus

> Status: drafted by /cold-start on 2026-06-27 (first-run wizard: 2026-06-27); every
> `[inferred]` section needs a human audit before it is trusted.

## What this is
A FORK of **eclipse-syson/syson** (Eclipse SysON) — an open-source, web-based tool for
editing **SysML v2** models, built on the **Sirius Web** modeling platform.

## Stack (from `ai/repo-profile.json` — deterministic; build/test verified in code 2026-06-27)
- Languages: **Java 21** (backend, enforced by `maven-enforcer`), **TypeScript/JavaScript** (frontend)
- Build systems: Maven (reactor, root `pom.xml`) + npm workspaces + Turborepo
- Runtimes pinned: Node `22.16.0`, npm `10.9.2` (`package.json` engines)
- Build: `mvn -B clean install -DskipTests  &&  npm install && npm run build`
- Test:  `mvn -B test  &&  npm test`

> ⚠️ `repo-profile.json` records `stack.kind: "single"`, but the repo is a confirmed
> **backend + frontend split** (observed 2026-06-27: `backend/` = Java 21 / Spring Boot,
> `frontend/` = TypeScript / Vite + Vitest). Treat the catalog as split; the profile
> field is wrong — human may correct `repo-profile.json` if desired.

## Why it exists  `[inferred from README.md]`
SysML v2 (a 2018+ OMG redesign of SysML, now based on KerML rather than UML) needs a
robust open-source editor for the MBSE community. CEA and Obeo jointly build SysON on
the Sirius Web platform: CEA leads SysML v2 standards compliance/extensibility; Obeo
leads product & UX. SysON provides graphical, table, form-based, and textual editors,
and aims to interoperate with Papyrus and Capella. License: EPL-2.0.

## What we add vs. what we inherit  `[inferred]`
- **Inherited (frozen):** essentially the *entire* committed codebase. Branch
  `dev-expt-01` currently has **zero code divergence** from upstream `main`
  (`git diff upstream/main...HEAD` is empty; merge-base == HEAD). Do not edit
  `backend/`, `frontend/`, `integration-tests-*`, `doc/`, or `scripts/` unless a task
  explicitly requires it.
- **Ours:** the untracked `ai/` knowledge layer (this folder). Future experimental work
  ("plus-plus") should land in **new modules**, not by mutating upstream files.

## Glossary  `[inferred]`
| Term | Meaning here |
|---|---|
| SysML v2 | OMG systems-modeling language (v2); the domain this tool edits |
| KerML | Kernel Modeling Language — the formal core SysML v2 is built on |
| MBSE | Model-Based Systems Engineering — the target user community |
| Sirius Web | Obeo's web modeling platform SysON is built upon (provides GraphQL API, diagram/form/tree engines) |
| EMF | Eclipse Modeling Framework — backs the metamodel implementation |
| Representation | A Sirius concept: a diagram / table / form / tree view of model elements |
| Metamodel | The EMF definition of SysML v2 / KerML types (`backend/metamodel`) |
| View (View-DSL) | Sirius declarative definition of a representation (`backend/views`) |
| Direct edit | In-place label editing in a diagram, parsed by a grammar (`syson-direct-edit-grammar`) |
