---
description: Turn rrx/test-cases.md into runnable automated tests by scanning the real codebase and applying the fixture library; merge with existing tests instead of clobbering.
handoffs:
  - label: Prove release readiness
    agent: speckit.rrx.prove
    prompt: After CI produces junit.xml, map results to ACs and update release-readiness
    send: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). Useful flags: target layer (`E2E` only), dry-run (plan files only), or explicit paths.

## Goal

Generate **executable** tests that encode the same `TC-NNN-X` identifiers as `rrx/test-cases.md`, grounded in **actual** routes, handlers, components, and selectors from the implementation—not placeholders.

Typical position in the flow: **after** `/speckit.implement` (optionally triggered via `after_implement` hook).

## Preconditions

- `rrx/test-cases.md` and `rrx/trace-ac.md` exist.
- `constitution.md` contains `## Testing` (frameworks, directories, fixture source).
- Implementation exists to scan; if partially missing, generate **skipped** tests with `test.skip` and a comment citing the missing surface—do not invent passing tests.

## Execution Steps

### 1. Resolve paths

From repo root, run the project’s Spec Kit prerequisite helper with JSON output appropriate for the **implementation** phase (feature dir + `tasks.md` available). Collect `FEATURE_DIR`, `TASKS`, `IMPL_PLAN`, and `FEATURE_SPEC`.

Confirm `rrx/test-cases.md` exists under `FEATURE_DIR` (or `REPO_ROOT/rrx/` if your project places RRX at root—detect which layout is in use and stay consistent).

### 2. Load context

Read:

- `rrx/test-cases.md`, `rrx/trace-ac.md`, `rrx/automation-notes.md`
- `spec.md` (for exact acceptance wording when assertions need strings)
- `plan.md` and `tasks.md` for modules, routes, and feature flags
- `.specify/knowledge/test-quality.md` and `fixture-library.md` if present

### 3. Pre-scan implementation

Before emitting code, search the codebase for:

- HTTP routes / OpenAPI / handler files matching planned endpoints
- UI components and `data-testid` attributes relevant to each E2E TC
- Existing test files under the constitution’s test directories

Produce a short **internal** mapping `{ TC id → file(s), selector or API, fixture helpers }`. If something cannot be found, record it in `rrx/automation-notes.md` under a `## Gaps found during automate` section.

### 4. Naming and traceability (mandatory)

- Every generated `test` / `it` **title** must contain the literal `TC-NNN-X` substring.
- Use `test.describe` / `describe` blocks titled with `[AC-NN] …` matching spec.
- Prefer fixture helpers from `fixture-library.md`; if a helper is missing, **do not** inline a one-off duplicate—add a `// TODO(RRX): add fixture <name> to fixture-library` and minimal local code only if unavoidable.

### 5. Quality bar (from test-quality.md)

Default rules if no knowledge file:

- No hard sleeps; use framework waits and assertions on state.
- Assertions must check **specific** expected values, not only visibility.
- Isolate tests; clean up data where the stack requires it.

### 6. File placement

Follow `constitution.md` `## Testing`:

- E2E → e.g. `tests/e2e/**/*.spec.ts`
- API → e.g. `tests/api/**/*.test.ts`
- Unit → e.g. `tests/unit/**/*.test.ts`

Use the project’s existing naming conventions when they exist.

### 7. Merge strategy

For each target file:

- If the file exists, **merge** new `describe` blocks or tests; preserve hand-written tests.
- If a TC id already exists in the file, update that test in place rather than duplicating.
- Never delete unrelated tests.

### 8. CI hint touch-up

Append or update a subsection in `rrx/ci-hints.md` listing **new** files and example commands to run them (including grep by `TC-` id).

### 9. Output summary

List files created/updated, TC ids generated, and any skipped/blocked TCs with reasons.

## Non-goals

- Changing product behavior or `spec.md` (use `/speckit.rrx.bugfix` or normal spec workflow for that).
- Running the test suite unless the user explicitly asks in `$ARGUMENTS`.
