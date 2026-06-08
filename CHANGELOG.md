# Changelog

All notable changes to ATLAS will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and ATLAS uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- `atlas init --analyze` — scans the repo (languages, build/test commands, CI, entry points, top-level inventory with guessed roles) and injects a pre-filled **§0.5 Auto-detected map** into ATLAS.md, so the map isn't a blank page. The auto-draft lever from CRITICS #8.
- `atlas check --changed-files[=REF]` — **drift gate**: fails if files were added/moved/removed without updating `ATLAS.md` (the map is stale). Wire it into CI to enforce the spec's *"a stale ATLAS is worse than none"* (CRITICS #7).

---

## [0.1.5] — 2026-06-08

### Added

- `atlas bench` is now **provider-agnostic + reproducible**: `--model`, `--effort`, and `--exec '<cmd>'` (any provider via `$ATLAS_BENCH_TASK`); records runtime version + model + effort + date + repo sha; writes a **Markdown report** (with tables) alongside the JSON; claude token parsing now handles the streamed JSON-array output (sums per-turn input tokens, reads cost/turns from the result event). Built-in runtimes: **claude, codex, opencode, and `openai`** — the last a deterministic single-shot mode that points at any OpenAI-compatible endpoint (`--api-base`, e.g. a local vLLM/Qwen) and measures the orientation context (the §0-1 spine vs the raw repo) with **deterministic local tokenization** — reproducible + endpoint-independent (the endpoint's `usage` is recorded only as a cross-check, after a local vLLM reported inconsistent counts under prefix caching). Every run appends to a **ledger** (`docs/benchmarks/RESULTS.md` + `results/ledger.jsonl`) for longitudinal comparison. First measured result (atlas repo): **92% fewer orientation tokens — 12.8×**.

### Fixed

- `bin/atlas` `ATLAS_VERSION` was stuck at `0.1.0`, so the shipped CLI reported the wrong version. Bumped to match the release; SCARS §CLI-VERSION-DRIFT documents keeping it in sync with `package.json`.

### Changed

- README + GitHub now lead with the **measured** −92% (12.8×) orientation-token result + a one-command reproduce + benchmark badges; `package.json` description updated; hero reflects the quartet (four files). Turns CRITICS #1's claim into proof.

---

## [0.1.4] — 2026-06-08

### Added

- **SCARS.md** — a fourth canonical file at the repo root: hard-won failure memory (the stable `§ANCHOR` playbook). The trio is now a **quartet**: ATLAS (structural) + SKILL (procedural how-to) + SCARS (failure memory) + CLAUDE/AGENTS (behavioral). `atlas init` scaffolds it; `atlas check` / `anchors` / `anchor add` operate on it; the SessionStart hook surfaces its ToC; SPEC, templates, dogfood, and the sub-agent adapter updated.
- `atlas bench [--runtime claude|codex] [--task …] [--reps N] [--dry-run]` — real A/B benchmark: runs the same task on a repo copy **with** vs **with the quartet hidden** through a headless agent, parses the runtime's usage JSON, and reports the token/turn/cost/time delta (results written as JSON under `docs/benchmarks/`). The measured foundation for the README's claims (CRITICS #1).

### Changed

- `SKILL.md` is now the procedural **task playbook** (how-to recipes); the failure-mode `§ANCHORS` moved to `SCARS.md`.

---

## [0.1.3] — 2026-06-08

### Fixed

- PPA build: `build-ppa.sh` now passes `-d` (skip the local build-dependency check — source-only builds compile on Launchpad, not in CI) and `--no-lintian`. Fixes the `release-ppa` `dpkg-checkbuilddeps: Unmet build dependencies` failure.
- Release pipeline: all channel workflows trigger on `push: tags` instead of `release: published`, which never fired (a release created by the built-in `GITHUB_TOKEN` does not cascade events). AUR self-skips until `AUR_SSH_PRIVATE_KEY` is set.

---

## [0.1.2] — 2026-06-08

### Added

- `atlas measure [--badge]` — estimate orientation-token savings (with vs without ATLAS) and emit a shields.io badge for the README.
- `atlas doctor` — diagnose the install, the project harness, CLAUDE.md size, AGENTS.md drift, and per-runtime export status.
- `atlas export --to <codex|copilot|gemini|cursor|llms-txt|all>` — fan the canonical trio out to other runtimes' context files from one source of truth.
- `atlas badge` — print a "Powered by ATLAS" README badge (markdown + HTML).
- `atlas uninstall [--purge] [-y]` — cleanly remove a `curl|bash`/manual install; defers package-manager installs to brew/apt/AUR/npm (install-trust, CRITICS #6).
- `action.yml` — reusable GitHub Action (`uses: Abbasi-Alain/atlas@v1`) that runs `atlas check` and posts an `atlas measure` job summary.
- Launchpad PPA packaging under `packaging/ppa/` (proper `/usr` install, `git archive`-based build, full account/GPG/`dput` runbook).
- `release-ppa.yml` — GitHub Actions builds + `dput`s the signed PPA source package per Ubuntu series (noble, jammy) on each release; self-skips until `LAUNCHPAD_GPG_PRIVATE_KEY` + `LAUNCHPAD_PPA` are set.
- Release now publishes `checksums.txt` (sha256 of the `.deb` + source tarball) for install-trust (CRITICS #6).
- This repo now dogfoods ATLAS: real `ATLAS.md`, `.agents/skill/atlas/SKILL.md`, `CLAUDE.md`/`AGENTS.md`, and `llms.txt`.

### Changed

- `packaging/README.md` + `docs/RELEASING.md` document the PPA channel and a `gh secret set` cheat-sheet.

### Fixed

- The private `abbasi` style shipped as a committed symlink with an absolute local-disk target — a dangling link plus a path leak in every npm/brew/.deb/AUR/clone consumer. It is now untracked and `.gitignore`d (SKILL §PRIVATE-STYLE-OVERLAY).
- Stale `PortfoliaX/Atlas` URLs corrected to `Abbasi-Alain/atlas` (installed Claude Code hook + private overlay docs).

---

## [0.1.0] — 2026-06-03

First public release. ATLAS — Agentic Harness Standard.

### Added

#### The trio
- `ATLAS.md` — structural project graph (§0 quick-orientation + §1–9 module index + §A architecture refs + §G glossary + §D data model + §X external deps + §R runtime topology + §O observability + §Sec security + §B build/deploy).
- `SKILL.md` at `.agents/skill/<project>/SKILL.md` — procedural playbook with stable `§ANCHOR-NAMES`.
- `CLAUDE.md` + byte-identical `AGENTS.md` mirror — behavioral contract for the agent.
- `EXAMPLES.md` — vague→concrete transformations that teach the patterns by contrast.

#### CLI (`bin/atlas`)
- `init [--style <preset>] [--force]` — bootstrap the trio (plus per-style seeds and per-stack docs where supported).
- `check` — validate ATLAS+SKILL; flag duplicate anchors and missing structure.
- `anchors` — list every SKILL anchor (machine-readable).
- `anchor add NAME "summary"` — append a stub anchor.
- `install --runtime <name>` — wire ATLAS into an agent runtime via adapters.
- `styles` — list available `--style` presets.
- `stacks` — list `--stack` add-ons per style (where supported).
- `mirror init [--staged|--direct|--dual-repo --public-repo URL]` — scaffold the GitLab→GitHub mirror allowlist + optional GitHub Action.
- `mirror push [--remote NAME] [--dry-run]` — push only allowlisted refspecs; hard-refuses pushing to a remote named `origin`.
- `mirror status` — show config + what would be pushed.
- `auth login [--method ssh|vendor] [--email]` — set up GitHub + GitLab auth via SSH keys or via brew-installed gh + glab.
- `auth status` — diagnostic.
- `repo create [--github|--gitlab] [--public|--private] [--name NAME] [--description "..."]` — wrap `gh` / `glab` `repo create` + initial push.
- `critique <topic> [--with-codex|--with-claude]` — append a CRITICS.md row + print a brutal-honest prompt; optionally pipe through codex/claude CLIs.
- `gap-to-article <gap-id>` — scaffold an article directory from a resolved + novel implementation gap.
- `cost` — parse ATLAS §C + §GPU; flag non-zero idle costs + stale audits.
- `adr add "<title>"`, `adr list` — scaffold and list Architecture Decision Records.
- `research add "<topic>"`, `research list` — scaffold and list deep-research notes.
- `version`, `help` — colorized ASCII logo + tagline.

#### Style presets
- `default` — universal scaffolding.
- `minimal` — solo project / low ceremony.
- `strict` — high-stakes codebase; required reports.
- `karpathy` — 65-line behavioral spec, four numbered principles.
- `google` — one-thing-per-change, style-as-contract.

#### Runtime adapters
`claude-code` · `codex` · `opencode` · `cursor` · `gemini` · `zed` · `copilot` · `hermes` · `generic`. Each is a single idempotent bash script.

#### Distribution
- `curl | bash` install script.
- npm package `@alainabbasi/atlas` (scoped) — `npx @alainabbasi/atlas init`.
- GitHub release with `social-card.png` asset.
- CI on Ubuntu + macOS (shellcheck + bootstrap test + self-check the example).

#### Docs
- `docs/SPEC.md` (v0.1).
- `docs/INTEGRATIONS.md` — per-runtime wiring + CI snippet.
- `docs/CONTRIBUTING.md`.
- `examples/sample-project/` — minimal trio.

[Unreleased]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.5...HEAD
[0.1.5]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/Abbasi-Alain/atlas/releases/tag/v0.1.0
