<!-- Copyright (c) 2026 Kunal Suri (CEA LIST). All rights reserved. -->
# Work ledger — syson-plus-plus

The repo's **episodic memory of work**: one row per unit of work (feature added,
bug fixed, refactor, process change), linking the spec that authorized it, the
decisions behind it, the review that checked it, the evaluation that scored it,
and the commits that shipped it. The maps in `ai/guide/` say what the repo *is*;
this ledger says *what was done to it, when, and under which contract*.

## Rules

- **Append-only.** New work gets a new row with the next `W-<n>` ID. Never delete
  or renumber rows; a rolled-back change gets Status `rolled-back`, not removal.
- **One row per unit of work** — the same unit the spec describes. A row without
  a spec link is a process violation, not a shortcut.
- **Backtick every artifact path, written from the repo root** (e.g.
  ai/lab/specs/SPEC_x.md, backticked). `verify` checks backticked paths against
  the file tree, so a row whose artifacts vanished fails CI instead of rotting
  silently. Use `—` for artifacts that genuinely don't apply (e.g. no ADR was
  needed).
- **Agents append rows tagged `[inferred]`** like everything else in `ai/`;
  the human flips them to `[verified]` when auditing. Never flip it yourself.
- **Status vocabulary:** `specced` → `in-progress` → `in-review` → `shipped`
  (or `rolled-back` / `dropped`).
- **Type vocabulary:** `feature` · `bugfix` · `refactor` · `docs` · `process`.

## Ledger

<!-- Example row (copy, replace the angle-bracket fields, backtick real paths
     written from the repo root). The example ID W-000 is reserved for this
     comment — real rows start at W-001:
| W-000 | 2026-01-15 | feature | Short title | ai/lab/specs/SPEC_<name>.md | ai/lab/decisions/ADR_<n>-<t>.md | ai/lab/reviews/REVIEW_W-000.md | ai/lab/evaluations/EVAL_<name>.md | <commit/PR> | FEATURE_MAP row | shipped | [inferred] |
-->

| ID | Date | Type | Title | Spec | ADRs | Review | Eval | Commits / PR | Knowledge updated | Status | Provenance |
|---|---|---|---|---|---|---|---|---|---|---|---|
| W-001 | 2026-07-07 | process | /cold-start bootstrap of the ai/ knowledge layer (kit 0.3.0) | /cold-start kit workflow (.claude/commands/cold-start.md, git-ignored) | — | — | — | uncommitted (branch dev-ai, base 21834e82e) | `ai/guide/MODULE_MAP.md` `ai/guide/PROJECT_OVERVIEW.md` `ai/guide/ARCHITECTURE.md` `ai/guide/CONVENTIONS.md` `ai/guide/FEATURE_MAP.md` `ai/analysis/diagrams/package-deps.mmd` `ai/analysis/diagrams/domain-core.mmd` `ai/analysis/diagrams/seam.mmd` | in-review | [inferred] |
