# ATLAS — BUGS / inconsistencies to fix

> Filed from a real-world compatibility pass: making **proxima-finance** conform to ATLAS v0.1.11
> (`atlas check`). Each item is independently verified, with repro + suggested fix. **Tick the
> checkbox when fixed** and add the commit hash. Severity: 🔴 spec-contradiction · 🟠 missing
> validation · 🟡 polish.

Verified against `bin/atlas` v0.1.11 (`atlas check`) + `docs/SPEC.md`.

---

## ✅ Resolution — all six fixed (BUG-1..5 in v0.2.0, BUG-6 in v0.3.0)

- **BUG-1** — kept the load-bearing ToC requirement (the SessionStart hook + `atlas measure` surface it) but made it spec-clear (SPEC §3) and the failure message actionable. *The report read SPEC §3 as "no fixed structure," but it already mandates "H1 + a `## Table of contents`"; removing the ToC would break the orientation surface, so option (b) — clarify, don't drop.*
- **BUG-2** — `atlas check` now validates `CLAUDE.md` (warn) + `AGENTS.md` presence & byte-equality (`cmp -s`, warn).
- **BUG-3** — `_project_slug` (kebab) drives **both** `atlas init` (scaffolds `.agents/skill/<kebab>/`) and `atlas check` (warns on a non-kebab dir); `_project_name` resolves nested/monorepo subprojects via `git rev-parse --show-prefix`. Derived from the spec, not hardcoded.
- **BUG-4** — `atlas init` was already non-destructive (`_render` skips existing); the `check` hint now says so.
- **BUG-5** — `llms.txt` read-first set now includes `SCARS.md` (code + the repo's own regenerated artifact); the SessionStart hook already surfaces it.
- **BUG-6** (v0.3.0) — the hook's header comment now documents ATLAS + **SCARS** + SKILL, matching its body.

Design: `atlas check` gained an **errors-vs-warnings** severity model — a real conformance validator. **v0.3.0** generalizes it toward a universal standard: `atlas check --json` (machine-readable conformance any CI/agent can consume), `--strict` (warnings→errors for CI gating), and `atlas fix` (auto-resolve: kebab the SKILL dir incl. case-only renames on macOS, re-mirror `AGENTS.md`, regenerate stale `llms.txt`). Regression test per bug/feature in `tests/bootstrap.test.sh` (**95/95 green**); `shellcheck` clean; SPEC §1/§3/§6 + `CHANGELOG.md [0.2.0]`/`[0.3.0]` coherent; `ATLAS_VERSION` + `package.json` bumped together (SCARS §CLI-VERSION-DRIFT).

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

## [x] BUG-6 🟡 `hooks/atlas-skill-loader.sh` header comment is stale (says ATLAS+SKILL; body also loads SCARS)
- **Where:** `hooks/atlas-skill-loader.sh` top comment (lines ~4, ~16-20).
- **Detail:** BUG-5's fix correctly added the SCARS block to the hook **body** (it prints
  `SCARS.md (hard-won failure memory)`), but the **header comment** still reads *"Detects ATLAS.md
  and .agents/skill/<project>/SKILL.md"*, lists only ATLAS + SKILL under "Output is bounded", and
  tells sub-agents to *"read ATLAS.md and SKILL.md first"* — no mention of SCARS. Doc/behavior drift.
- **Fix (1-liner-ish):** update the header comment to mention SCARS: "Detects ATLAS.md, SCARS.md, and
  .agents/skill/<project>/SKILL.md"; add a `- SCARS: ToC section (failure §anchors)` bounded-output
  line; and change the sub-agent note to *"read ATLAS.md, SCARS.md, and SKILL.md first"*. No code
  change — comment only. (Found while installing the v0.2.0 hook on a real machine.)

---

## Feature proposals (post-v0.3.0) — from the proxima-finance LOOP dogfooding

> The autonomous improvement loop (`LOOP.md` + `ROADMAP.md`) has now run several real iterations in
> proxima-finance and is producing genuine, validated, anti-churn work. Per the long-term plan
> ("successful LOOP.md ideas graduate into a future ATLAS release"), this proposes making the loop a
> **first-class, optional ATLAS concept** so EVERY ATLAS repo can adopt it. Severity: 🟢 enhancement.
> Tick when landed; **design for all repos, not a proxima one-off** (per the Notes below).

### [x] FEAT-1 🟢 ATLAS-native autonomous improvement loop (bless `LOOP.md` + `ROADMAP.md`) — shipped in v0.4.0
> **Landed (v0.4.0):** `atlas init --loop` scaffolds `templates/LOOP.md.tmpl` + `templates/ROADMAP.md.tmpl` (mechanisms 1–8); `atlas check` validates them only when present (warnings) and reports `"loop"` in `--json`; the SessionStart hook surfaces a one-line pointer; SPEC §8 defines the optional 5th surface. A repo without a loop is unaffected. Regression tests added (99/99 green).
- **Why:** ATLAS already standardizes *orientation* (ATLAS), *failure memory* (SCARS), *contract*
  (CLAUDE/AGENTS) and *how-to* (SKILL) — the static knowledge. The missing piece is a standard for the
  *dynamic* process: how an agent **continuously improves** a repo without a human in the loop. The
  proxima loop shows a working shape; ATLAS should generalize it so it's not re-invented per repo.
- **What (the proven mechanisms to standardize):** a `LOOP.md` (the rulebook + one-command
  entrypoint) + a `ROADMAP.md` (the EV-ranked task queue, planner-rich specs) carrying, per item:
  why · how + exact entry-points · impact · test · complexity · `difficulty`. The loop's
  battle-tested rules worth baking into the template: **(1) anti-churn pre-flight** (grep before
  building; verify+tick what already ships — never rebuild), **(2) EV-ranked selection** (edge ×
  P(real) × leverage ÷ cost, not queue position), **(3) a novelty mandate** (≥1 new falsifiable
  hypothesis/iteration into an idea ledger, with a novelty bar), **(4) self red-team before commit**
  (overfit / leakage / honesty), **(5) measure-then-gate honesty** (ship descriptive-only; wire to
  behavior only after OOS validation), **(6) SCARS-grow on every new failure mode**, **(7) difficulty
  routing** (escalate `hard` to a stronger model / sub-agent), and **(8) `atlas check --strict` as the
  per-commit conformance gate**.
- **Proposal (pick the scalable shape):**
  - `atlas check` **awareness** (opt-in): when `LOOP.md`/`ROADMAP.md` exist, validate their minimal
    structure (LOOP.md has an entrypoint + rules H1; ROADMAP has a tiered `- [ ]` queue + a Done log)
    and surface them in `--json` (`"loop": {...}`) — non-fatal warnings, like CLAUDE/AGENTS.
  - `atlas init --loop` **scaffold**: drop a templated `LOOP.md` + `ROADMAP.md` carrying mechanisms
    (1)–(8) above, so any repo gets the proven loop for free (scaffold-missing-only, per BUG-4).
  - The SessionStart/orientation hook optionally surfaces `LOOP.md` ("this repo has an autonomous
    loop; one iteration = …") alongside the quartet.
  - SPEC: a new §"Autonomous loop (optional 5th surface)" defining LOOP/ROADMAP roles + the mechanism
    checklist, explicitly OPTIONAL (the static quartet stays the core; the loop is an opt-in layer).
- **Acceptance:** a fresh `atlas init --loop` repo passes `atlas check --strict`; `--json` reports the
  loop surface; a repo WITHOUT a loop is unaffected (zero new warnings); regression tests under
  `tests/` (assert scaffold + check behavior, both with and without the loop files).
- **Reference implementation:** `proxima-finance/LOOP.md` + `ROADMAP.md` + `LOOP_REPORT.md` (a real,
  iterating example to lift the template from). Keep ATLAS's role to *bless + validate + scaffold* the
  pattern — the per-repo specifics stay in the repo's own LOOP/ROADMAP.

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
