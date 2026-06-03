# Contributing to ATLAS

ATLAS is a convention as much as it is code. Three kinds of contributions are especially valuable:

## 1. Universal SKILL anchors

If you've earned a scar that **most projects could earn**, it belongs in the template, not in your project. Examples:

- `§NO-COAUTHOR`, `§ATLAS-IS-INDEX`, `§ADR-BEFORE-MAJOR` — every project.
- `§NO-PII-IN-LOGS`, `§MIGRATIONS-IDEMPOTENT` — every production system.
- `§LOCK-ORDER`, `§IDEMPOTENT-OP-KEY` — every distributed system.

PR them into [`templates/SKILL.md.tmpl`](../templates/SKILL.md.tmpl) under the appropriate category. Include:
- A clear `**Symptom.**` paragraph.
- A concrete `**Do NOT.**` and `**Do.**` pair.
- A real-world commit SHA (from any public repo) in the appendix, if available.

## 2. New runtime adapters

If your agent runtime isn't supported, add `adapters/<runtime>/install.sh`. Contract:
- One executable script.
- Reads `ATLAS_HOME` env var (defaults to `~/.atlas`).
- Idempotent — running twice is a no-op.
- Prints clearly what it did.

Open a PR and add a row to [`docs/INTEGRATIONS.md`](INTEGRATIONS.md).

## 3. CLI features

Tightly scoped CLI features welcome:
- `atlas anchor rm NAME` (with redirect insertion).
- `atlas anchor ref NAME` (search code for anchor citations).
- `atlas diff` (compare ATLAS index against actual repo layout, flag drift).
- `atlas migrate vX→vY` (when the spec evolves).

Keep the CLI bash-only — no Node/Python deps. The npx wrapper just execs the bash CLI.

## Style

- Bash: shellcheck-clean, `set -euo pipefail`, no `which` (use `command -v`).
- Markdown: GFM, no HTML except `<a id="…"></a>` anchors.
- Spec changes: bump version, add migration notes.

## Releases

Tag releases as `v0.X.Y`. The `install.sh` defaults to `main`; users can pin via `ATLAS_REF=v0.2.0 bash install.sh`.
