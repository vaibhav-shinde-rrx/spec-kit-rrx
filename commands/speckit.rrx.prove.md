---
description: After CI, ingest JUnit XML (and optional coverage), map results to ACs via TC ids, update rrx/trace-ac.md, and write release-readiness.md with a ship/stop verdict.
scripts:
  sh: .specify/extensions/rrx/scripts/check-coverage.sh
  ps: .specify/extensions/rrx/scripts/check-coverage.ps1
handoffs:
  - label: Fix failing AC
    agent: speckit.implement
    prompt: Address failing TCs; keep spec as source of truth for expected behavior
    send: false
---

## User Input

```text
$ARGUMENTS
```

Parse optional arguments from `$ARGUMENTS` when present:

- `--results <path>` — JUnit XML file or directory of XML files (default: probe `FEATURE_DIR` / common CI artifacts such as `junit.xml`, `test-results/**/results.xml`—document which path you used).
- `--coverage <path>` — optional coverage summary JSON for advisory notes only (verdict remains AC/TC oriented unless constitution mandates coverage gates).
- `--force` — emit report even when the coverage gate fails (clearly mark as **FORCED**).
- `--focus AC-01 AC-03` — limit summary sections to listed ACs (still parse full XML).

## Goal

Answer: **“Is this feature releasable with respect to the spec’s acceptance criteria?”**

A green CI run is insufficient: if an AC has **no** executed TC mapping, the feature is **NOT READY** (aligned with RRX strategy slides).

## Execution Steps

### 1. Resolve feature paths

Use the same Spec Kit path resolution as other commands. Require `FEATURE_DIR`, `FEATURE_SPEC`, and `rrx/trace-ac.md`.

Load `constitution.md` `## Testing` for `priority_scheme`, `p0_blocks_merge`, `p1_blocks_merge`, and `ac_id_format`.

### 2. Run deterministic coverage gate

From `REPO_ROOT`, execute `{SCRIPT}` with `--feature-dir` / `-FeatureDir` set to the absolute feature directory (same scripts as `/speckit.rrx.spec`),

unless `$ARGUMENTS` contains `--force`. Capture stdout/stderr.

If the script exits non-zero and `--force` is absent: still read junit for diagnostics, but final verdict must be **NOT READY** with reason `AC/TC coverage gap`.

### 3. Parse JUnit XML

- Collect each `<testcase>`: `classname`, `name`, and status (`failure`, `error`, `skipped` children).
- Extract TC ids by regex `\bTC-\d+-[A-Z]+\b` from `name` (and `classname` if needed).
- Map TC → pass / fail / skip.

If multiple cases share one TC id, aggregate: **fail** overrides pass; **skip** if all skipped.

### 4. Join to ACs

Using `rrx/trace-ac.md` (or `rrx/test-cases.md` as fallback), map each TC id to its AC id.

Detect:

- **Orphan results**: TC in JUnit with no row in trace matrix
- **Missing execution**: AC with zero matching testcase results in this run

### 5. Update `rrx/trace-ac.md`

Replace `Status` column cells with:

- `✅ Passed` — all TCs for that AC passed
- `❌ FAILED` — at least one failed
- `⏭️ Skipped` — no failures, but at least one skipped and none passed
- `⬜ Untested` — no result mapped

Preserve table structure and IDs.

### 6. Write `release-readiness.md`

Place at feature root **or** repo root per project convention—**match where `rrx/` lives**.

Include:

1. **Verdict** line: `READY` / `NOT READY` / `FORCED REVIEW`
2. **Executive summary** — counts: ACs passed/failed/untested; blocking P0/P1 failures
3. **AC summary table** — AC id, short description (from spec), priority, result, blocking?
4. **Failure details** — for each blocking failed AC: TC id, expected vs actual if inferable from XML message, suggested next command to re-run (e.g. `npx playwright test --grep TC-003-A`)
5. **Coverage gate output** — paste or summarize `check-coverage` result

Blocking rules:

- Any failed TC attached to an AC whose priority is `P0` when `p0_blocks_merge` is true → NOT READY
- Same for `P1` when `p1_blocks_merge` is true
- Any AC with no executed TC → NOT READY

### 7. Console summary

Emit a short terminal-friendly block (as in the RRX slides): coverage line, per-AC status, verdict banner.

## Notes

- If JUnit is unavailable, do not fabricate pass/fail—state **NO RESULTS** and keep trace statuses unchanged except append a warning row in the report.
- Keep the report readable for PMs; link to technical paths only as footnotes.
