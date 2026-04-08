---
description: Generate the RRX test planning bundle (test cases, AC↔TC trace matrix, automation notes, CI hints) from spec.md before implementation planning solidifies.
scripts:
  sh: .specify/extensions/rrx/scripts/check-coverage.sh
  ps: .specify/extensions/rrx/scripts/check-coverage.ps1
handoffs:
  - label: Create implementation plan
    agent: speckit.plan
    prompt: Plan implementation; align technical tasks with rrx/test-cases.md layers and priorities
    send: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). Use it to narrow scope (e.g. focus ACs, extra risks, target release).

## Goal

Produce a **consistent test intent** for the active feature: every acceptance criterion in `spec.md` gets explicit test cases, layers, priorities, and a trace row. This command runs **after** `/speckit.specify` and **before** `/speckit.plan` so testing constraints influence planning—not the reverse.

This is a **write** command: create or update files under `rrx/` inside the feature directory.

## Operating Principles

- **Spec is source of truth for ACs** — do not invent requirements; derive TCs only from stated acceptance criteria.
- **Product scope, not regulatory RTM** — clarity and ship-readiness over audit-style matrices; keep tables lean.
- **Stable IDs** — AC and TC identifiers must stay parseable by scripts and `/speckit.rrx.prove` (see §ID rules).

## Execution Steps

### 1. Resolve feature paths (no plan.md required)

From the repository root, locate the Spec Kit helper that exposes feature paths (typically `check-prerequisites` from the project’s Spec Kit script bundle). Run it with **paths-only** JSON output so `plan.md` is not required yet.

Parse at minimum:

- `FEATURE_DIR` — feature working directory (contains `spec.md`)
- `FEATURE_SPEC` or equivalent path to `spec.md`
- `REPO_ROOT` if returned

If the helper is unavailable, derive `FEATURE_DIR` using the same branch-to-`specs/<feature>` convention as the rest of Spec Kit and abort with a clear error if `spec.md` is missing.

### 2. Constitution gate (`## Testing`)

Resolve `constitution.md` (project memory / constitution path used by this repo’s Spec Kit setup). Read the `## Testing` section.

**Required keys** (YAML-like or bullet list — accept either if unambiguous):

- E2E (or primary UI) runner — e.g. `playwright`, `cypress`
- Unit runner — e.g. `jest`, `vitest`
- Test root — e.g. `./tests`
- Fixture package or path — e.g. npm scope or local `tests/fixtures`
- `ac_id_format` — default `AC-NN` (two-digit) unless constitution states otherwise
- `priority_scheme` — e.g. `P0`–`P3`

If any required item is missing or ambiguous, **stop** and output a short numbered questionnaire titled `## RRX needs a few answers` (mirror the project’s RRX slides). Do not generate `rrx/` files until the user answers or updates `constitution.md`.

### 3. Load optional knowledge

If they exist, read:

- `.specify/knowledge/test-quality.md`
- `.specify/knowledge/test-priorities.md`
- `.specify/knowledge/fixture-library.md`

Treat them as **constraints** on tone, structure, and reusable helpers—not as new requirements.

### 4. Parse acceptance criteria from `spec.md`

Extract every AC using the constitution’s `ac_id_format`. For each AC capture:

- Short title / intent (from the nearest heading or list item)
- Any explicit priorities, non-functional notes, or dependencies already in spec

Assign a **test layer** per AC: `E2E`, `API`, `UNIT`, or `MANUAL`. Default heuristic: user-visible flows → `E2E`; HTTP contracts without UI → `API`; pure logic → `UNIT`; legal/exploratory → `MANUAL`. Document assumptions in `automation-notes.md` if unclear.

### 5. Incremental update rules

If `rrx/test-cases.md` already exists:

- **New ACs in spec** → append sections with new TCs; new TC IDs only.
- **Removed ACs** → mark section `[DEPRECATED]`; do not reuse old TC IDs.
- **Unchanged ACs** → preserve existing TC text unless spec text for that AC changed; if spec changed, bump only affected TCs and add a one-line change note in `automation-notes.md`.
- **Never renumber** existing TC IDs.

### 6. Generate artifacts (batched)

Process ACs in **batches of 5** to keep output focused. After each batch, write/append to the files below.

#### 6a. `rrx/test-cases.md` (primary)

For each AC, emit:

```markdown
## AC-NN — {title}
Layer: {E2E|API|UNIT|MANUAL} · Priority: {Pn}

TC-NNN-A {name}
  Given: ...
  When: ...
  Then: ...

TC-NNN-B ...
```

Rules:

- **NNN** in TC IDs aligns with the AC number (e.g. AC-03 → TC-003-*).
- Suffix letters `A, B, C, …` for multiple TCs per AC.
- Every AC needs at least **happy path**, **error/negative**, and **edge or boundary** where applicable; for trivial ACs, combine explicitly in one TC and note why.
- Use concrete observable outcomes (strings, status codes, redirects), not vague “works correctly.”

#### 6b. `rrx/trace-ac.md`

Markdown table:

| AC ID | TC IDs | Layer | Priority | Status |
|-------|--------|-------|----------|--------|

Status starts as `⬜ Untested` for all rows. This file is the canonical AC↔TC map for `/speckit.rrx.prove`.

#### 6c. `rrx/automation-notes.md`

Per AC (or grouped by layer): stack, fixtures needed from `fixture-library.md`, env secrets, routes/APIs touched, flakiness risks, suggested selectors strategy (`data-testid` first). Leave placeholders where code does not exist yet.

#### 6d. `rrx/ci-hints.md`

Actionable notes: how to run layer subsets, suggested JUnit XML output path, merge-blocking rules from constitution (`p0_blocks_merge`, etc.), and example grep commands to run a single TC id.

### 7. Post-write verification

From repository root, run `{SCRIPT}` (resolved from this command’s `scripts` frontmatter) with `--feature-dir` set to the absolute `FEATURE_DIR`, e.g. `bash .specify/extensions/rrx/scripts/check-coverage.sh --feature-dir "/abs/path/to/specs/001-feature"` or `powershell -File .specify/extensions/rrx/scripts/check-coverage.ps1 -FeatureDir "C:\path\to\specs\001-feature"`.

If the script reports missing TC coverage for any AC, fix `test-cases.md` and the trace table before finishing.

### 8. Summarize

Output a concise completion block: paths written, AC count, TC count, and the next recommended command (`/speckit.plan`).

## ID Rules (normative)

- **AC**: `AC-` + zero-padded decimal matching `ac_id_format` in constitution.
- **TC**: `TC-` + same numeric stem as AC + `-` + uppercase letter sequence (`TC-003-A`).
- These patterns must appear verbatim in headings, test titles, and table cells so `check-coverage` and `/speckit.rrx.prove` remain deterministic.
