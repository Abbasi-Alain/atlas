# SCARS — atlas hard-won failure memory

> **The "what not to repeat" file.** Every entry is a scar paid for in real
> breakage — symptom → root cause → do NOT → do → file pointer. Read this
> **before** fixing a bug.
>
> **Reading order.** [`ATLAS.md`](ATLAS.md) (*where*) → **this file** (*what
> breaks*) → [`.agents/skill/atlas/SKILL.md`](.agents/skill/atlas/SKILL.md) (*how*).
>
> Anchors are stable + immutable. Cite them in commits/PRs. Add one with
> `atlas anchor add NAME "summary"`.

---

## Table of contents

**Process / hygiene**
- [§NO-COAUTHOR — never add AI-assistant attribution to commits](#no-coauthor)
- [§ATLAS-IS-INDEX — update ATLAS.md when structure changes](#atlas-is-index)
- [§SMOKE-AFTER-CHANGE — run the smoke set after touching the CLI](#smoke-after-change)

**Bash / CLI** *(this repo's real scars)*
- [§SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`](#set-e-and-and)
- [§BASH-MONOLITH — `bin/atlas` is one file; keep shellcheck green](#bash-monolith)
- [§MACOS-SED — `sed -i` is not portable; use the `.bak` + `rm` idiom](#macos-sed)
- [§PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style symlink](#private-style-overlay)

**Release / packaging**
- [§TAG-TRIGGER-NOT-RELEASE — channel workflows must fire on tag push](#tag-trigger-not-release)
- [§PPA-PLACEHOLDER-SECRET — a `<placeholder>` LAUNCHPAD_PPA silently drops uploads](#ppa-placeholder-secret)
- [§CLI-VERSION-DRIFT — bump ATLAS_VERSION in bin/atlas with every release](#cli-version-drift)

---

## Process / hygiene

<a id="no-coauthor"></a>
### §NO-COAUTHOR — never add AI-assistant attribution to commits

Do not add `Co-Authored-By: Claude …` or equivalent lines in commits.

---

<a id="atlas-is-index"></a>
### §ATLAS-IS-INDEX — update ATLAS.md when structure changes

Add a top-level module / command / package channel / runtime → update
[`ATLAS.md`](ATLAS.md) in the **same commit**. A stale ATLAS forces every
future agent to re-grep. Verify with `atlas check`.

---

<a id="smoke-after-change"></a>
### §SMOKE-AFTER-CHANGE — run the smoke set after touching the CLI

`shellcheck bin/atlas && bash tests/bootstrap.test.sh` (ATLAS §5). Don't ship
commits that don't green it.

---

## Bash / CLI

<a id="set-e-and-and"></a>
### §SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`

**Symptom.** A `cmd_*` function exits silently partway through.

**Root cause.** `bin/atlas` runs `set -euo pipefail`. `A && B && C` where a
middle link is false, or `(( x++ ))` when the result is 0, returns non-zero and
trips `set -e`.

**Do NOT.** Use `(( count++ ))` (returns 1 when count was 0), or chain
multi-step guards with `&&`.

**Do.** `count=$(( count + 1 ))`; use `if [[ cond ]]; then …; fi` for guards.

**Where.** `bin/atlas::cmd_measure`, `cmd_doctor`.

---

<a id="bash-monolith"></a>
### §BASH-MONOLITH — `bin/atlas` is one ~2k-line file; keep it green

**Do NOT.** Add a runtime dependency (node/python/jq) to the core path.

**Do.** Keep changes `shellcheck`-clean (CI enforces). Mirror the existing
`cmd_*` + flag-parse + dispatch + header-doc pattern when adding a command.

**Where.** `bin/atlas`, `.github/workflows/ci.yml`.

---

<a id="macos-sed"></a>
### §MACOS-SED — `sed -i` is not portable; use the `.bak` + `rm` idiom

**Do NOT.** Use bare `sed -i` in code that ships to both macOS and Linux.

**Do.** `sed -i.bak "expr" file && rm file.bak`, as in `cmd_adr_add`. Prefer awk
for anything structural.

**Where.** `bin/atlas::cmd_adr_add`.

---

<a id="private-style-overlay"></a>
### §PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style symlink

**Symptom.** Every consumer gets a dangling `templates/styles/abbasi` symlink
pointing at the maintainer's local disk — broken style + leaked path.

**Do NOT.** `git add templates/styles/abbasi`; don't remove it from `.gitignore`.

**Do.** Keep it `.gitignore`d; the private overlay installer symlinks it locally.

**Where.** `.gitignore`, `templates/styles/`.

---

## Release / packaging

<a id="tag-trigger-not-release"></a>
### §TAG-TRIGGER-NOT-RELEASE — channel workflows must fire on tag push

**Symptom.** A release is created but npm/.deb/brew/AUR/PPA never publish.

**Root cause.** A GitHub release created by the built-in `GITHUB_TOKEN` does
**not** cascade events, so `on: release: published` workflows never run.

**Do.** Trigger channel workflows on `push: tags: ['v*']` (they then run from
the tag's own files too). `release-deb` waits for `release.yml` to create the
release before uploading assets.

**Where.** `.github/workflows/release-*.yml`.

---

<a id="ppa-placeholder-secret"></a>
### §PPA-PLACEHOLDER-SECRET — a `<placeholder>` LAUNCHPAD_PPA silently drops uploads

**Symptom.** `release-ppa` is green, `dput` reports success, but nothing appears
on the Launchpad PPA.

**Root cause.** `LAUNCHPAD_PPA` left as `ppa:<your-launchpad-user>/atlas` → dput
uploads to a nonexistent `~<your-launchpad-user>/atlas` path → Launchpad drops it.

**Do.** Set the real value (`ppa:alainabbasi/atlas`). The dput step now fails
fast if the secret contains `<`/`>`.

**Where.** `.github/workflows/release-ppa.yml`.

---

<a id="cli-version-drift"></a>
### §CLI-VERSION-DRIFT — bump ATLAS_VERSION in bin/atlas with every release

**Symptom.** `atlas version` (and `atlas bench` metadata) report an old version
while npm/AUR/etc. ship a newer one.

**Root cause.** The version lives in **two** places: `package.json` (bumped at
release) and the hardcoded `ATLAS_VERSION="…"` in `bin/atlas`. The `.deb`/AUR
packages ship `bin/` without `package.json`, so the constant can't be derived —
it must be bumped by hand. It silently drifted 0.1.0 → 0.1.4.

**Do.** In the cut-release recipe, bump `ATLAS_VERSION` in `bin/atlas` in the
same commit as `package.json`. (A CI check comparing the two would prevent this.)

**Where.** `bin/atlas` (top), `package.json`.

---

## Adding scars

Scaffold with `atlas anchor add NAME "summary"`, fill in Symptom / Root cause /
Do NOT / Do / Where, and cite the anchor in the commit that fixes it.
