# Fixture library index (RRX knowledge layer)

Document helpers your tests import. `/speckit.rrx.automate` should reuse these instead of duplicating setup.

| Fixture | Layer | Purpose | Import / path |
|---------|-------|---------|----------------|
| `loginAs(role, page)` | E2E | Authenticated session | `@org/test-fixtures` (replace) |
| `assertToast(text, page)` | E2E | Toast / snackbar assertion | … |
| `apiClient()` | API | Base URL + default headers | … |

Add rows as your organization grows the shared package.
