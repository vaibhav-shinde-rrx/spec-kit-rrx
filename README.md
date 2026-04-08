# RRX — Spec-Driven Testing Extension for Spec Kit

Test planning, automated test generation, and **release readiness** tied to **acceptance criteria (AC)** and **test cases (TC)** — without the full regulatory V-Model stack. Built for product teams using [GitHub Spec Kit](https://github.com/github/spec-kit).

## What it adds

| Command | Role |
|---------|------|
| `/speckit.rrx.spec` | After specify, before plan: generate `rrx/test-cases.md`, `trace-ac.md`, `automation-notes.md`, `ci-hints.md` from `spec.md` + constitution `## Testing`. |
| `/speckit.rrx.automate` | After implement: scan real code, emit/merge runnable tests whose titles include `TC-NNN-X` for traceability. |
| `/speckit.rrx.prove` | After CI: read JUnit XML, update `trace-ac.md`, write `release-readiness.md` — **NOT READY** if any AC lacks executed coverage, even when all tests are green. |

Deterministic checks use `.specify/extensions/rrx/scripts/check-coverage.sh` (and `.ps1` on Windows).

## Documentation

- **[docs/PUBLISH-AND-INSTALL.md](docs/PUBLISH-AND-INSTALL.md)** — Maintainer and user steps: public GitHub repo (extension-only), tag, install with `specify extension add rrx --from …`, verify Cursor slash commands, smoke-test workflow.
- **[docs/ALIGNMENT-VS-REFERENCES.md](docs/ALIGNMENT-VS-REFERENCES.md)** — Comparison to `references/commands/claude` and core Spec Kit command templates; optional format alignment and future improvements (testing scope only).

## Prerequisites

- [Spec Kit](https://github.com/github/spec-kit) CLI (`specify`) **v0.1.0+**
- A **Spec Kit project**: repo root contains `.specify/` (from `specify init` or equivalent)
- **Cursor**: the `.cursor/commands` directory must exist **before** you install this extension (see [Troubleshooting](#troubleshooting--why-commands-dont-appear-in-cursor))

## Installation

Run these from your **application repo root** (the project where you use Spec Kit), not from inside the extension source folder only.

### Method 1 — From GitHub release (when published)

Replace the URL with your tagged release archive:

```bash
specify extension add rrx --from https://github.com/vaibhav-shinde-rrx/spec-kit-rrx/archive/refs/tags/v0.1.0.zip
```

### Method 2 — Local development (same as V-Model / QA examples)

```bash
git clone https://github.com/YOUR_ORG/spec-kit-rrx.git
specify extension add --dev /absolute/path/to/spec-kit-rrx
```

On Windows (PowerShell), use a full path:

```powershell
specify extension add --dev "C:\path\to\spec-kit-rrx"
```

### Method 3 — Catalog (only after you publish and register the extension)

```bash
specify extension add rrx
```

### Verify installation

```bash
specify extension list
```

You should see **RRX — Spec-Driven Testing** with 3 commands.

### Verify Cursor slash commands

After a successful install, Spec Kit copies command stubs into Cursor’s commands folder. Check that these files exist:

```text
.cursor/commands/speckit.rrx.spec.md
.cursor/commands/speckit.rrx.automate.md
.cursor/commands/speckit.rrx.prove.md
```

Extension payload (scripts + source command templates) lives under:

```text
.specify/extensions/rrx/
```

Optional: merge **knowledge** files into your project (once per repo or team):

```text
.specify/knowledge/test-quality.md      ← copy or symlink from extension knowledge/
.specify/knowledge/fixture-library.md
```

## Usage (Spec Kit workflow)

Recommended sequence (aligned with RRX strategy):

```text
/speckit.constitution          →  add ## Testing (frameworks, dirs, priorities)
/speckit.specify               →  spec.md with AC-01, AC-02, …

/speckit.rrx.spec              →  rrx/test-cases.md, trace-ac.md, automation-notes.md, ci-hints.md

/speckit.plan
/speckit.tasks
/speckit.implement

/speckit.rrx.automate          →  tests/e2e/*.spec.ts, tests/api/*.test.ts, tests/unit/*.test.ts (per constitution)

# CI runs test suite → produces junit.xml

/speckit.rrx.prove             →  release-readiness.md + updated trace-ac.md
```

### Example invocations

```text
/speckit.rrx.spec

/speckit.rrx.automate E2E only for login flow

/speckit.rrx.prove --results ./artifacts/junit.xml
/speckit.rrx.prove --results ./junit.xml --focus AC-01 AC-03
```

## Hooks

`extension.yml` can register (optional) hooks:

- **`after_specify`** — prompt to run `/speckit.rrx.spec` right after specification.
- **`after_implement`** — prompt to run `/speckit.rrx.automate` after implementation.

Hook behavior is merged into `.specify/extensions.yml` when the installer registers the extension. Core Spec Kit commands (`specify.md`, `implement.md`, …) read that file and surface **Extension Hooks** blocks in the agent transcript.

## Artifacts

| Path | Produced by |
|------|-------------|
| `specs/.../rrx/test-cases.md` | `/speckit.rrx.spec` |
| `specs/.../rrx/trace-ac.md` | `/speckit.rrx.spec` (updated by `/speckit.rrx.prove`) |
| `specs/.../rrx/automation-notes.md` | `/speckit.rrx.spec` |
| `specs/.../rrx/ci-hints.md` | `/speckit.rrx.spec` |
| `specs/.../release-readiness.md` | `/speckit.rrx.prove` (path may match your feature layout) |

Exact `specs/{feature}/` resolution follows Spec Kit’s feature-branch layout (same as core commands).

## Constitution: `## Testing`

Add a **Testing** section to `constitution.md` so `/speckit.rrx.spec` does not stop for a questionnaire. Example:

```yaml
## Testing
test_framework: playwright
unit_framework: vitest
test_directory: ./tests
fixture_source: "@acme/test-fixtures"
ac_id_format: AC-NN
priority_scheme: P0/P1/P2/P3
p0_blocks_merge: true
p1_blocks_merge: true
```

## Troubleshooting — why `/` doesn’t suggest RRX commands

Slash commands in Cursor come from **files under `.cursor/commands/`**. Spec Kit only registers extension commands for agents whose command directory **already exists** when `specify extension add` runs.

1. **Install from the Spec Kit project root**  
   Run `specify extension add …` in the repo that contains `.specify/`, not only in a clone of this extension.

2. **Ensure `.cursor/commands` exists before installing**  
   - If you used `specify init` and chose **Cursor**, that folder is usually created.  
   - If it is missing, create it, then **re-install** the extension:
     ```bash
     mkdir -p .cursor/commands    # macOS/Linux
     mkdir .cursor\commands       # Windows CMD
     New-Item -ItemType Directory -Force .cursor/commands   # PowerShell
     specify extension remove rrx --force
     specify extension add --dev /path/to/rrx-extension
     ```

3. **Reload Cursor**  
   After new files appear under `.cursor/commands/`, reload the window (`Developer: Reload Window`) so the palette picks them up.

4. **Confirm files were written**  
   ```bash
   ls .cursor/commands/speckit.rrx.*
   ```

5. **`specify extension list` shows RRX but Cursor has no commands**  
   Almost always: `.cursor/commands` did not exist at install time — follow step 2.

## ID chain (keep stable)

```text
spec.md (AC-01) → test-cases.md (TC-001-A) → test title contains "TC-001-A"
  → junit.xml <testcase name> → /speckit.rrx.prove → trace-ac.md + release-readiness.md
```

## License

MIT (see `extension.yml`).

## Contributing / publishing checklist

- [ ] Replace `YOUR_ORG` / repository URLs in this README and in `extension.yml`
- [ ] Tag a release and attach a **zip of the repo root** (must contain `extension.yml` at top level)
- [ ] Optionally open a PR to add the extension to Spec Kit’s **community catalog** for `specify extension add rrx` by name
