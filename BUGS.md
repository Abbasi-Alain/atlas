# ATLAS — BUGS / inconsistencies to fix

> Filed from a real-world compatibility pass: making **proxima-finance** conform to ATLAS v0.1.11
> (`atlas check`). Each item is independently verified, with repro + suggested fix. **Tick the
> checkbox when fixed** and add the commit hash. Severity: 🔴 spec-contradiction · 🟠 missing
> validation · 🟡 polish.

Verified against `bin/atlas` v0.1.11 (`atlas check`) + `docs/SPEC.md`.

---

## ✅ Resolution — all five fixed in v0.2.0 (pending maintainer approval to tag)

All boxes ticked below. Landed as a coherent change (no commit/tag yet — staged for review):
- **BUG-1** — kept the load-bearing ToC requirement (the SessionStart hook + `atlas measure` surface it) but made it spec-clear (SPEC §3) and the failure message actionable. *Note: the report read SPEC §3 as "no fixed structure," but it already mandates "H1 + a `## Table of contents`"; removing the ToC would break the orientation surface, so option (b) — clarify, don't drop.*
- **BUG-2** — `atlas check` now validates `CLAUDE.md` (warn) + `AGENTS.md` presence & byte-equality (`cmp -s`, warn).
- **BUG-3** — `_project_slug` (kebab) now drives **both** `atlas init` (scaffolds `.agents/skill/<kebab>/`) and `atlas check` (warns on a non-kebab dir) — derived from the spec, not hardcoded.
- **BUG-4** — `atlas init` was already non-destructive (`_render` skips existing); the `check` hint now says so.
- **BUG-5** — `llms.txt` read-first set now includes `SCARS.md`; the SessionStart hook already surfaced it (re-run `atlas install` to refresh a stale installed copy).

Design: `atlas check` gained an **errors-vs-warnings** severity model so spec MUSTs fail while SHOULD/conditional rules inform — `atlas check` is now a real conformance validator. Regression test per bug in `tests/bootstrap.test.sh` (90/90 green); `shellcheck bin/atlas` clean; SPEC §1/§3/§6 + `CHANGELOG.md [0.2.0]` updated coherently.

---

## [x] BUG-1 🔴 `atlas check` requires a ToC in `SKILL.md`, but the SPEC says SKILL has no fixed structure
- **Where:** `bin/atlas` → `check` subcommand (the "SKILL.md missing Table of contents" assertion).
- **Spec says:** `docs/SPEC.md` §3 (line ~100): *"`SKILL.md` is the procedural how-to file (task
  recipes); it has **no fixed** [structure]"* — only `ATLAS.md` and `SCARS.md` have required structure.
- **Repro:** a valid *procedural* `SKILL.md` (run/test/recipes, no ToC) →
  `❌ SKILL.md missing Table of contents`, `atlas: ok` never prints, exit 1. Adding a dummy
  `## Table of contents` flips it green — so the check enforces structure the spec explicitly disclaims.
- **Expected:** `check` should NOT require a ToC in `SKILL.md` (it's the no-fixed-structure file).
- **Fix (pick one):** (a) remove the SKILL.md ToC assertion from `check`; **or** (b) if a ToC *is*
  wanted, amend SPEC §3 to make it required for SKILL.md too (and update the templates). (a) matches
  the current spec intent.

## [x] BUG-2 🟠 `atlas check` never validates `CLAUDE.md` / `AGENTS.md`
- **Where:** `bin/atlas` → `check` subcommand (only checks `ATLAS.md`, `SKILL.md`, `SCARS.md`).
- **Spec says:** SPEC §1: *`CLAUDE.md` **MUST** be at the repo root if the project targets Claude*;
  *`AGENTS.md` **SHOULD** mirror `CLAUDE.md` byte-for-byte*.
- **Repro:** proxima-finance had **neither** `CLAUDE.md` nor `AGENTS.md`; `atlas check` reported only
  the missing `SCARS.md` and was otherwise silent about them. After adding `SCARS.md` (still no
  CLAUDE/AGENTS) it would have printed `atlas: ok` — i.e. a Claude-targeted repo passes with no
  behavioral contract.
- **Expected:** flag a missing `CLAUDE.md` (error or warn), and warn if `AGENTS.md` is missing or not
  byte-identical to `CLAUDE.md`.
- **Fix:** in `check`, add: `CLAUDE.md` presence (warn/err), `AGENTS.md` presence + `cmp -s CLAUDE.md
  AGENTS.md` byte-equality (warn on drift). `atlas init` already scaffolds both — `check` should guard them.

## [x] BUG-3 🟠 `atlas check` accepts a non-kebab-case `SKILL.md` directory
- **Where:** `bin/atlas` → `check` (SKILL.md path resolution).
- **Spec says:** SPEC §1: *`SKILL.md` **MUST** be at `.agents/skill/<project-name>/SKILL.md`, where
  `<project-name>` is the **kebab-cased** git remote basename.*
- **Repro:** proxima's remote basename is `proxima-finance` (kebab), but its dir is
  `.agents/skill/Proxima-Finance/SKILL.md` (PascalCase). `atlas check` accepts it silently
  (`✅ SKILL.md present at …/Proxima-Finance/SKILL.md`).
- **Expected:** warn when the dir name ≠ kebab-cased remote basename (cross-tool discovery + spec
  conformance).
- **Fix:** compute expected = kebab(`basename` of `git remote get-url origin`); if the found dir
  differs, print a warning (don't hard-fail — repos without a remote use the root basename).

## [x] BUG-4 🟡 "missing SCARS.md (run 'atlas init')" hint risks clobbering a populated repo
- **Where:** `bin/atlas` → `check` failure hint; `atlas init` behavior.
- **Detail:** on an existing repo that already has a rich hand-written `ATLAS.md` + `SKILL.md` (but no
  `SCARS.md`), the suggested `atlas init` could overwrite/scaffold over the existing files. The safe
  path is "scaffold only what's missing."
- **Expected:** the hint should point to a non-destructive path.
- **Fix:** make `atlas init` scaffold-missing-only by default (never overwrite without `--force`), and
  change the hint to e.g. `run 'atlas init' (scaffolds only missing quartet files)`.

---

## [x] BUG-5 🟡 Orientation should surface `SCARS.md`, not just `ATLAS.md` + `SKILL.md`
- **Detail:** SCARS is now the "read before fixing a bug" file, but the onboarding / any
  ATLAS-provided SessionStart-style orientation (and `llms.txt` "read these first") historically
  emphasizes ATLAS + SKILL. A repo's auto-orientation should point at the **full quartet** so the
  failure anchors actually surface. (Verify whether ATLAS owns a SessionStart/orientation hook; if
  not, this is a docs/`llms.txt`/onboarding-template nudge rather than a code change.)
- **Fix:** ensure `atlas onboard` / templates / `llms.txt` list `SCARS.md` in the read-first set, and
  any orientation hook prints ATLAS + SCARS + SKILL.

---

### Notes for the fixing agent
- **Think deeply + design for ALL future repos, not just a one-off patch.** Each fix should be the
  general, scalable behavior (e.g. BUG-2/3 derive expectations from the spec, not hardcode a repo).
- Repro harness: any repo with `ATLAS.md` + a procedural `SKILL.md` (no ToC) + no `SCARS.md`/`CLAUDE.md`.
  proxima-finance (`/Users/ai/PortfoliaX/proxima-finance`) is a real conformant reference to test against.
- Add regression tests under `tests/` for each (assert exit code + emitted lines).
- Keep `bin/atlas` shellcheck-green (SCARS §BASH-MONOLITH); avoid `sed -i` (SCARS §MACOS-SED);
  mind `set -e` + `| head` (§SET-E-AND-AND, §PIPE-HEAD-SIGPIPE).
- Update `docs/SPEC.md` + `templates/` + `CHANGELOG.md` coherently with any behavior change.
- **Release prep (do NOT publish without human approval):** bump `ATLAS_VERSION` in `bin/atlas`
  (§CLI-VERSION-DRIFT) + `package.json`, write the CHANGELOG entry, ensure `atlas check` self-passes
  + tests green — then STOP and let the maintainer push the tag (tag push triggers the signed
  release + npm publish; §TAG-TRIGGER-NOT-RELEASE). Tick each box above as you land it.
