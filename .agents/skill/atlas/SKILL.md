# SKILL — atlas error/pattern playbook

> **For sub-agents.** Read [`/ATLAS.md`](../../../ATLAS.md) first
> ("where things live"); read **this file** second ("what to
> remember when you touch them"). Every entry below was paid for in
> production blood — symptom → root cause → do NOT → do → file
> pointer → commit SHA.
>
> **Anchors are stable and immutable.** Cite them from PR
> descriptions, commit messages, FAQ entries, and other agents'
> prompts. Renaming an anchor = creating a new one + redirect.
>
> **Promote cross-project lessons** to the global template at
> `~/.atlas/templates/SKILL.md.tmpl` (or [upstream Atlas repo](https://github.com/Abbasi-Alain/atlas)).

---

## Table of contents

**Process / hygiene** *(every project keeps these — customise as needed)*
- [§NO-COAUTHOR — never add AI-assistant attribution to commits](#no-coauthor)
- [§ATLAS-IS-INDEX — update ATLAS.md when structure changes](#atlas-is-index)
- [§MAINTAIN-DOCS — append substantive Q&A to docs/FAQ.md](#maintain-docs)
- [§SMOKE-AFTER-CHANGE — run the smoke set after touching runtime](#smoke-after-change)
- [§ADR-BEFORE-MAJOR — non-trivial decisions get an ADR before shipping](#adr-before-major)

**Bash / CLI** *(this repo's real scars)*
- [§SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`](#set-e-and-and)
- [§BASH-MONOLITH — `bin/atlas` is one file; keep shellcheck green, plan to modularize](#bash-monolith)
- [§MACOS-SED — `sed -i` differs on macOS vs GNU; use the `.bak` + `rm` idiom](#macos-sed)
- [§PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style; it's a private symlink](#private-style-overlay)

**Security / secrets**
- _(e.g. §NO-PII-IN-LOGS, §SECRET-ROTATION-90D)_

**Performance / hot paths**
- _(e.g. §N+1-GUARDRAIL, §CACHE-INVALIDATION-RULE)_

**Data integrity / migrations**
- _(e.g. §MIGRATIONS-IDEMPOTENT, §NO-DOWNTIME-COLUMN-ADD)_

**Observability**
- _(e.g. §LOG-CORRELATION-ID, §ALERT-NOISE-BUDGET)_

**Concurrency / state**
- _(e.g. §LOCK-ORDER, §IDEMPOTENT-OP-KEY)_

**Domain-specific** *(add `## <Domain>` headings as you accumulate scars)*
- _(e.g. for a trading app: brokers, microstructure, UI)_

---

## Process / hygiene

<a id="no-coauthor"></a>
### §NO-COAUTHOR — never add AI-assistant attribution to commits

Project preference. Do not add `Co-Authored-By: Claude …` or
equivalent lines in commits.

---

<a id="atlas-is-index"></a>
### §ATLAS-IS-INDEX — update ATLAS.md when structure changes

If you add a top-level module, a new message type, a new external
dependency, or move files across sections — **update
[`/ATLAS.md`](../../../ATLAS.md) in the same commit**. ATLAS is the
graph entry point; a stale ATLAS forces every future agent to grep.

Use `atlas check` to verify the file still parses.

---

<a id="maintain-docs"></a>
### §MAINTAIN-DOCS — append substantive Q&A to docs/FAQ.md

When a user asks a substantive inner-workings question and you
answer it well, append the Q&A to `docs/FAQ.md`. Future agents
reading the FAQ then know without re-asking.

---

<a id="smoke-after-change"></a>
### §SMOKE-AFTER-CHANGE — run the smoke set after touching runtime

The smoke command lives in ATLAS §5. Run it after any change to the
runtime or shared modules. **Don't ship commits that don't green
the smoke set.**

---

<a id="adr-before-major"></a>
### §ADR-BEFORE-MAJOR — non-trivial decisions get an ADR before shipping

If a change introduces a new external dep, alters a public contract,
or changes a long-standing convention — write an ADR in
`docs/adr/NNNN-short-name.md` (copy `docs/adr/0000-template.md`) and
link it from ATLAS §A3 **before** the implementation lands. ADRs
are immutable once accepted; supersede by writing a new one that
references the old.

---

## Bash / CLI

<a id="set-e-and-and"></a>
### §SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`

**Symptom.** A `cmd_*` function exits silently partway through; no error printed.

**Root cause.** `bin/atlas` runs `set -euo pipefail`. A bare `cond && action`
line is *safe* (a false `cond` is exempt), but `A && B && C` where a middle
link is false, or `(( x++ ))` when the result is 0, returns non-zero and trips `set -e`.

**Do NOT.** End a function with `[[ cond ]] && do_thing` if `do_thing`'s
failure should be ignored, or use `(( count++ ))` (returns 1 when count was 0).

**Do.** Use `if [[ cond ]]; then do_thing; fi` for multi-step guards, and
`count=$(( count + 1 ))` (assignment always returns 0) for counters — as in
`cmd_measure` / `cmd_doctor`.

**Where.** `bin/atlas::cmd_measure`, `cmd_doctor`.

---

<a id="bash-monolith"></a>
### §BASH-MONOLITH — `bin/atlas` is one ~1.9k-line file; keep it green

**Symptom.** Hard to test/extend; contributors hesitate to touch it.

**Root cause.** Deliberate zero-dependency design (only bash/git/coreutils).
The trade-off is a monolith. Documented in README + CRITICS.

**Do NOT.** Add a runtime dependency (node/python/jq) to the core path.

**Do.** Keep changes `shellcheck`-clean (CI runs it). When adding a command,
mirror the existing `cmd_*` + flag-parse + dispatch + header-doc pattern. The
roadmap is to split into `lib/*.sh` + `bats` tests — until then, the smoke set
(ATLAS §5) is the safety net.

**Where.** `bin/atlas`, `.github/workflows/ci.yml`.

---

<a id="macos-sed"></a>
### §MACOS-SED — `sed -i` is not portable; use the `.bak` + `rm` idiom

**Symptom.** `sed -i "..."` works on the maintainer's Mac but mangles files
on GNU/Linux (or vice-versa) — BSD `sed -i` requires a backup-suffix arg.

**Do NOT.** Use bare `sed -i` in CLI code that ships to both macOS and Linux.

**Do.** `sed -i.bak "expr" file && rm file.bak` (works on both), as in
`cmd_adr_add`. Prefer awk for anything structural.

**Where.** `bin/atlas::cmd_adr_add`.

---

<a id="private-style-overlay"></a>
### §PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style

**Symptom.** Every consumer (npm/brew/.deb/AUR/clone) gets a dangling
`templates/styles/abbasi` symlink that points at the maintainer's local
disk — broken style + leaked absolute path.

**Root cause.** `abbasi` is maintained privately (GitLab-only) and symlinked
into `templates/styles/` by a sibling overlay's `install.sh` at install time.
A committed symlink has an absolute target that exists only on one machine.

**Do NOT.** `git add templates/styles/abbasi`. Don't remove it from
`.gitignore`.

**Do.** Keep `templates/styles/abbasi` in `.gitignore`. The overlay installer
creates the symlink locally; public ATLAS ships without `abbasi`.

**Where.** `.gitignore`, `templates/styles/`.

---

## Adding scars

When this repo earns a new lesson, add a stable-anchor entry under the right
category above. Scaffold a stub with `atlas anchor add NAME "summary"`, then
fill in Symptom / Root cause / Do NOT / Do / Where / Shipped-in and cite the
anchor in the commit that fixes it. Anchors are immutable — supersede, never
renumber.
