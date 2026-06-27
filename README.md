<!-- Copyright (c) 2026 CEA LIST. All rights reserved. -->
<div align="center">

<h1>🛸 The SysON++ Project</h1>
<h3>The AI-Native Codebase</h3>

[![Status: experimental](https://img.shields.io/badge/status-experimental%20R%26D-blueviolet?style=for-the-badge)](#-the-experiment)
[![License: EPL-2.0](https://img.shields.io/badge/license-EPL--2.0-informational?style=for-the-badge)](LICENSE)

[![Java 21](https://img.shields.io/badge/Java-21-orange?style=for-the-badge&logo=openjdk&logoColor=white)](pom.xml)
[![Node 22.16](https://img.shields.io/badge/Node-22.16.0-green?style=for-the-badge&logo=nodedotjs&logoColor=white)](package.json)
[![PostgreSQL 15](https://img.shields.io/badge/PostgreSQL-15-blue?style=for-the-badge&logo=postgresql&logoColor=white)](docker-compose.yml)

[![Agent-ready](https://img.shields.io/badge/agents-Claude%20%7C%20Cursor%20%7C%20Copilot%20%7C%20Windsurf-black?style=for-the-badge&logo=anthropic&logoColor=white)](ai/INDEX.md)

</div>

---

> **An experimental sandbox for turning a complex, industrial-grade codebase into an AI-native
> environment** — to test agentic workflows, and to eventually contribute high-confidence
> improvements back to the [Eclipse Foundation](https://www.eclipse.org/) and the MBSE community.

---

## 🔬 The Experiment

**SysON++** (pronounced *"SysON Plus Plus"*) is an R&D project by researchers at **CEA LIST**. It is a
**fork of [Eclipse SysON](https://github.com/eclipse-syson/syson)** — the web-based SysML&nbsp;v2 modelling
platform built by [Obeo](https://www.obeosoft.com/) on [Sirius Web](https://eclipse.dev/sirius/sirius-web.html) —
used as a testbed for making a real, legacy systems-engineering codebase legible and safe for AI coding agents.

We are actively:

1. **Understanding the transformation** — which metadata formats, guardrails, and developer tools actually
   work (and which don't) when introducing AI agents to a complex existing enterprise system.
2. **Building the foundation** — the AI-native context, persistent memory, developer guides, and automated
   verification layers agents need to operate safely.
3. **Paving the way for agentic DevOps** — so a **Verified-by-Humans agentic system** can help build features,
   maintain the codebase, and eventually contribute trusted enhancements upstream.

> 🌱 **Current status:** the `ai/` knowledge layer was bootstrapped via `/cold-start` on **2026-06-27**.
> Every entry is `[inferred]` until a human audits it to `[verified]` — agents must treat any
> un-audited module as **frozen**. This is intentional: the layer fails *cautious*, not *confident*.

---

## ❄️ What's ours vs. what's frozen

This is a fork, so the **single most important rule** is knowing what you may touch. All inherited
upstream code is **frozen**; our experimental work is isolated to `ai/`, `scripts-spp/`, and any new modules.

```
syson-plus-plus/
├── ai/                      🧠 OURS — AI knowledge layer (guide · analysis · lab)
├── scripts-spp/             🛠️ OURS — dev tooling & guardrails (Windows PowerShell)
├── backend/                 ❄️ frozen upstream — Java 21 · Spring Boot · Sirius Web
├── frontend/                ❄️ frozen upstream — React + TypeScript (Vite)
├── integration-tests-*/     ❄️ frozen upstream — Cypress · Playwright E2E
└── pom.xml · package.json · docker-compose.yml   ❄️ upstream
```

---

## 🤖 AI Agent Context Engine

For agents working in this repo: **don't guess or crawl the tree.** Start from the knowledge layer in
[`ai/`](ai/INDEX.md), which maps responsibilities, stack boundaries, and module stability.

| Doc | What it gives you |
|---|---|
| 🧭 [`ai/INDEX.md`](ai/INDEX.md) | Role → path manifest (start here) |
| 🌐 [`ai/guide/PROJECT_OVERVIEW.md`](ai/guide/PROJECT_OVERVIEW.md) | Workspace context, scope, glossary |
| 🏛️ [`ai/guide/ARCHITECTURE.md`](ai/guide/ARCHITECTURE.md) | System layers, the GraphQL seam, invariants |
| 🗺️ [`ai/guide/MODULE_MAP.md`](ai/guide/MODULE_MAP.md) | Directory responsibilities + **stability** (`frozen` / `ours`) |
| 📐 [`ai/guide/CONVENTIONS.md`](ai/guide/CONVENTIONS.md) | How to write code that fits |
| 📦 [`ai/analysis/FEATURE_CATALOG.md`](ai/analysis/FEATURE_CATALOG.md) | Feature → files index |
| 🧩 [`ai/analysis/diagrams/`](ai/analysis/diagrams/) | Mermaid: package deps, domain core, frontend↔backend seam |

The layer is tool-agnostic — Claude Code, Cursor, Copilot, and Windsurf all read the same maps
(see [`AGENTS.md`](AGENTS.md)).

---

## ⚡ Core Paradigms

New features are built spec-first, with automated feedback loops — so structure is correct *before* code is written.

* **🎯 Specification-Driven Development (SDD)** — features start as a spec in
  [`ai/lab/specs/`](ai/lab/specs/), aligned to OMG SysML&nbsp;v2 / KerML as the source of truth, then
  implemented as strict types and schema definitions before operational code.
* **🧪 Evaluation-Driven Development (EDD)** *(goal)* — guardrails and evaluators that run during
  development and CI to give agents and humans immediate, contract-level feedback.

---

## 🧱 AI-Native Guardrails (what actually exists today)

* **Knowledge-layer verification** — [`scripts-spp/verify-ai-docs.ps1`](scripts-spp/verify-ai-docs.ps1)
  (+ `-backend` / `-frontend`) extracts every backtick-quoted `.java` / `.graphqls` / `.g4` claim from the
  `ai/` docs and cross-checks it against the real source tree, so the knowledge layer can't silently drift.
* **EMF generated-code shield** — [`scripts-spp/check-generated-edits.js`](scripts-spp/check-generated-edits.js)
  inspects git diffs and blocks edits inside `@generated` EMF blocks that lack the `@generated NOT` marker.
  Installed as a local **pre-commit hook** via
  [`scripts-spp/install-hooks.js`](scripts-spp/install-hooks.js). *(Local hook today — not yet wired into CI.)*

---

## 🚀 Quick Start

> **Windows-first.** The `scripts-spp/` launchers are PowerShell. Prerequisites: **Java 21**,
> **Node 22.16.0** (via [fnm](https://github.com/Schniz/fnm)), **Docker Desktop**, and a GitHub PAT with
> `read:packages` (the Maven build pulls Sirius Web from GitHub Packages — set `$env:PASSWORD`).
> Full walkthrough: open [`scripts-spp/dev-guide.html`](scripts-spp/dev-guide.html).

```powershell
# First time on a machine — check deps, build, and run everything
.\scripts-spp\setup-dev.ps1

# Daily — start database → backend → frontend
.\scripts-spp\start-dev.ps1

# Stop everything (DB container is paused, not deleted)
.\scripts-spp\stop-dev.ps1
```

| Service | URL |
|---|---|
| 🖥️ Frontend (the app) | http://localhost:5173 |
| ⚙️ Backend API | http://localhost:8080 |
| 🔌 GraphQL | http://localhost:8080/api/graphql |
| 🗄️ PostgreSQL | `localhost:5432` (`test_username` / `test_password`) |

---

## 🛠️ Build & Test (manual)

```bash
# Backend — Maven reactor at repo root (Java 21)
mvn -B clean install -DskipTests

# Frontend — npm workspaces + Turborepo (Node 22.16.0)
npm install && npm run build

# Tests
mvn -B test     # backend (JUnit)
npm test        # frontend (Vitest via turbo)
```

```powershell
# Install the EMF generated-code pre-commit hook
node scripts-spp\install-hooks.js

# Verify the ai/ knowledge layer against the codebase
.\scripts-spp\verify-ai-docs.ps1
```

---

## ⚖️ Licensing & Attribution

This fork is maintained by researchers at **CEA LIST** under the **Eclipse Public License v2.0 (EPL-2.0)** —
the same license as upstream [Eclipse SysON](https://github.com/eclipse-syson/syson). See [`LICENSE`](LICENSE).

> *SysML® is a trademark owned by the OMG ([guidelines](https://www.omg.org/legal/tm_guidelines.htm)).
> All credit for the underlying platform goes to the Eclipse SysON contributors at Obeo and CEA.*

<br>

<details>
<summary><b>🗂️ Click to expand: the original SysON Project README (from upstream)</b></summary>

---

# SysON Project

Welcome to the repository of the Eclipse SysON project.

## Background

Obeo, a prominent contributor to Eclipse's Modeling technologies, has a history of active involvement in the Model-Based Systems Engineering (MBSE) community notably through Capella. Our commitment to advancing modeling tools is evident through our work on Eclipse Sirius Web, which aims to revolutionize modeling tools. As we progress with Sirius Web, we see it becoming better suited for managing complex languages and domains.

CEA is another significant player in the Eclipse Modeling technologies world. It is the main contributor to the Papyrus modeling platform. This platform provides support for OMG standards such as UML 2.X and SysML 1.X and comes with a wide set of satellite tools providing capabilities such as simulation, code generation and document generation. CEA is widely involved in the definition of OMG standards that are provided by the Papyrus platform and its satellite tools. In particular, CEA chairs specifications such as MARTE (Model and Analysis of Real-Time and Embedded Systems), PSCS (Precise Semantics for UML Composite Structures) and PSSM (Precise Semantics for UML State Machines).

In 2018, the Object Management Group (OMG) initiated a major revision of SysML 1.X to increase its MBSE adoption. The intention was to develop language improvements over precision, expressiveness, consistency, interoperability, and usability. This work led to the production of SysML V2. SysML V2 introduces major changes that have an impact on both the user and tool vendor levels. For instance, SysML V2 is no longer based on UML but on KerML (a core modeling language with a well-grounded formal semantics). This redesign, SysMLv2, a crucial language for systems engineering, is highly important for system design and compatibility among MBSE tools. Notably Papyrus which already supports UML, SysMLv1 and Eclipse Capella, which is gaining strong traction, stands to benefit from this adoption.

To facilitate this transformative vision, the System Engineering community acknowledged the need for a robust open-source tool dedicated to SysMLv2. This realization prompted both CEA and Obeo to initiate the development of a web-based SysMLv2 modeling tool using the Sirius Web platform. CEA will represent the project at the OMG and will lead the effort regarding SysMLv2 compliance and extensibility capabilities while Obeo will focus on the product and its user experience.

## Scope

Eclipse SysON project provides an open-source and interoperable tool for editing SysMLv2 models conforming to the OMG Standard for the MBSE community.

This software will prominently showcase structured editors: graphical, form-based and tables, effectively utilizing the capabilities of the Sirius Web modeling platform. Additionally, the project will ensure seamless integration with Open-Source solutions like Papyrus and Capella, further enhancing the usability and versatility of the tool.

## Description

The Eclipse SysON project provides open-source web-based tooling to edit SysML v2 models. It includes a set of editors (graphical, textual, form-based, etc.) enabling users to build the various parts of system models. Capitalizing on the capabilities of the Sirius Web platform, SysON offers a user-friendly interface, facilitating seamless model creation, modification, and visualization.

Furthermore, Eclipse SysON is the core of the SysMLv2 model editing feature of Papyrus and seamlessly enables co-design of SysMLv2 models alongside Eclipse Capella.

Additionally, Eclipse SysON embraces the standard API for interconnection, enhancing the interoperability of these vital modeling resources and will support the SysML v2 textual specifications as an exchange format, to ensure seamless transitions.

Through this initiative, we seek to foster growth within the MBSE community by providing a robust and accessible tool that harmonizes seamlessly with modern modeling landscapes.

## Licenses

Eclipse Public License 2.0

## Legal Issues

SysML® is a trademark owned by OMG with specific guidelines detailed here: <https://www.omg.org/legal/tm_guidelines.htm>

## More about SysON

You can visit the [SysON Website](https://mbse-syson.org/) or contact [Obeo](https://www.obeosoft.com/en/contact) for more information.

</details>
