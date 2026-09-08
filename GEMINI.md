# GEMINI

## Agent skills

### Standard-Compliant Coding & Documentation (Context7)

Always implement code following the official framework and library standards. Query Context7 MCP (`resolve-library-id` and `query-docs`) for official documentation, architectural patterns, and API signatures for all dependencies (Flutter, Dart, Drift, Riverpod, Local Notifications, etc.) before writing implementation code.

### Low-Disk Workstation Constraint

The developer workstation has strictly limited storage. All heavy builds, compilations, and Android APK packaging must be executed in GitHub Actions CI (`.github/workflows/`). Never install or trigger multi-gigabyte local Android SDK, Gradle, or AVD emulator caches. Local development must strictly use Flutter Windows Desktop or Chrome.

### Issue tracker

Issues and specs live in GitHub Issues (`gh` CLI / GitHub MCP). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical 5-role triage vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout (`CONTEXT.md` + `docs/adr/` at repo root). See `docs/agents/domain.md`.
