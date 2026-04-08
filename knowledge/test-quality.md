# Test quality (RRX knowledge layer)

Org-local rules consumed by `/speckit.rrx.automate` and reviewers. Edit freely.

- Prefer **event-driven** waits; ban fixed `sleep` except when documented as unavoidable (e.g. animation under test).
- Assertions must target **specific** user-visible text, URLs, status codes, or structured payloads—not generic “element exists.”
- Each automated test name must include the **`TC-NNN-X`** id from `rrx/test-cases.md`.
- Tests must be **isolated**: no order dependence; use fixtures for login and data setup.
- **Selectors**: prefer `data-testid="..."` from implementation; avoid brittle CSS chains.
- **Flakes**: if a TC is inherently flaky, mark skip with reason and link to tracking issue in `automation-notes.md`.
