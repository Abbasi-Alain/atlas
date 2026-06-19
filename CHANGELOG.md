# Changelog

All notable changes to ATLAS will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and ATLAS uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- **Fully automated DOI on release** — a `release-zenodo-doi` workflow (fires on tag push, re-runnable via `workflow_dispatch`) waits for Zenodo to mint the new version DOI and stamps it into the GitHub Release notes. Combined with the auto-resolving **concept DOI** badge, pushing a `vX.Y.Z` tag is now the only manual step — every channel (npm/.deb/brew/AUR/PPA), the signed release, the Zenodo archive, and the DOI stamp happen automatically.

## [0.3.0] — 2026-06-19

### Added

- **`atlas check --json`** — a machine-readable conformance report (`{ok, version, strict, counts, errors[], warnings[], quartet{…}}`), each finding carrying a stable `code` (e.g. `SKILL_DIR_NOT_KEBAB`, `AGENTS_DRIFT`). Lets any CI, agent, or tool consume `atlas check` programmatically — the SPEC's machine-readable thesis, now realized. (bash-3.2 safe, zero deps.)
- **`atlas check --strict`** — promote warnings to errors (exit 1), so a team can gate CI on the full quartet (CLAUDE/AGENTS present + mirrored, kebab skill dir), not just the hard MUSTs.
- **`atlas fix`** — auto-resolve the conformance *warnings* `atlas check` surfaces: rename a non-kebab `SKILL.md` directory to the spec name (and update path references), re-mirror a missing/drifted `AGENTS.md` from `CLAUDE.md`, and regenerate a stale `llms.txt`. Idempotent; missing files still defer to `atlas init`.

### Fixed

- **Case-only `SKILL.md` directory renames now work on case-insensitive filesystems (macOS).** `atlas fix` renames e.g. `Proxima-Finance/` → `proxima-finance/` via a temp two-step (a plain `mv Foo foo` is a no-op there, and `[ -e foo ]` matches `Foo`). SCARS §MACOS-SED.
- **SessionStart hook header comment** now matches its body — it documents loading ATLAS + **SCARS** + SKILL (the body already surfaced SCARS; the doc line was stale).

## [0.2.0] — 2026-06-17

### Added

- **🚩 Flagship proof** — [`docs/FLAGSHIP.md`](docs/FLAGSHIP.md): `atlas measure` run on famous repos (openclaw **−94%**, graphify −93%, ECC −92%, claude-context −87%, claude-mem −85%, hermes-agent −82%; fastapi −89%, express −81%, django/curl/gin −78%, flask −75%) — **−75% to −94%** orientation-token reduction, free + reproducible. Kept as **dated history** under `docs/benchmarks/flagship/`.
- **`atlas measure --log`** — append a dated row (`date · version · repo · files · tokens · %`) to a central history ledger, so flagship/longitudinal measurements are kept and comparable later.
- **`atlas map` draws a real graph in the terminal** — a Unicode box-and-arrow diagram (fan-out adjacency + standalone modules), not just a Mermaid code block. In a terminal you get the picture; piped or `--out`'d it still emits Mermaid for GitHub. `--ascii` / `--mermaid` force either.
- **Explicit MCP platform compatibility in the README** — OpenClaw · NemoClaw · opencrust · zeroclaw · Qwen · Windsurf: one `mcpServers` snippet, conformance-tested (protocol `2024-11-05`, 4 tools) — verified with a live JSON-RPC handshake.
- **Refreshed brand assets** — social card on the measured **−92%** + four-file framing; a more detailed hero GIF (onboard → map → mcp → hooks → check) plus dedicated **map** and **orient** GIFs, driven by a reproducible `assets/demo-fixture.sh`.
- **Signed releases (supply-chain)** — the GitHub release now ships a reproducible source tarball + `checksums.txt` with **SLSA build provenance**, signed keyless via Sigstore (`actions/attest-build-provenance`); npm already publishes with provenance. Verify with `gh attestation verify atlas-X.Y.Z.tar.gz --repo Abbasi-Alain/atlas`. (README → "Verify a release".)

### Changed

- **`atlas check` now validates the full quartet with an errors-vs-warnings severity model.** Errors fail the check (exit 1): `ATLAS.md` §0, `SKILL.md` `## Table of contents`, `SCARS.md` `## Table of contents` + unique anchors. New **warnings** are advisory (still exit 0): a missing `CLAUDE.md` (the behavioral contract — a MUST if the repo targets Claude), a missing or **drifted** `AGENTS.md` (byte-compared to `CLAUDE.md` via `cmp -s`), and a `SKILL.md` directory that isn't the kebab-cased project name. So a Claude-targeted repo with no contract — or a `Proxima-Finance/` skill dir where the spec wants `proxima-finance/` — no longer passes silently (BUGS §BUG-2, §BUG-3; SPEC §6).
- **`atlas init` now scaffolds the spec-correct kebab-case skill directory** `.agents/skill/<kebab-project>/SKILL.md` (derived from the kebab-cased git-remote/repo basename), so freshly-initialized repos are conformant out of the box (BUGS §BUG-3; SPEC §1).
- **The SessionStart `llms.txt`/orientation surface now leads with the full quartet in reading order** — ATLAS → SCARS → SKILL → CLAUDE/AGENTS (SPEC §1).

### Fixed

- **`SKILL.md`'s Table-of-contents requirement is now spec-aligned and the failure is actionable.** SPEC §3 now states plainly that `SKILL.md`'s minimal required structure is an H1 **+** a `## Table of contents` — required because the SessionStart hook and `atlas measure` surface it as the playbook index — and `atlas check`'s message says *why* it's needed and that `atlas init` scaffolds one, instead of a bare "missing Table of contents" (BUGS §BUG-1).
- **`llms.txt`'s "read these first" set now includes `SCARS.md`.** The failure memory was omitted, so an agent reading `llms.txt` never saw the stable §anchors; the read-first order is now ATLAS → SCARS → SKILL → CLAUDE/AGENTS (BUGS §BUG-5).
- **`atlas check`'s remediation hint is now non-destructive.** It clarifies that `atlas init` scaffolds only the missing files and never overwrites without `--force`, so following the hint on an already-populated repo is safe (BUGS §BUG-4).
- **`atlas measure` silently aborted on any repo with >400 files** — `git ls-files | head -400` SIGPIPEs the producer, which under `set -o pipefail` + `set -e` aborts the command *before any output*. It had shipped broken for every real-world repo; the atlas repo (83 files) was too small to trigger it. Caught the instant the flagship ran on fastapi. Guarded the head-pipes + added a >400-file regression test (SCARS §PIPE-HEAD-SIGPIPE).

## [0.1.10] — 2026-06-09

### Added

- **`atlas onboard [--pr]`** — drop ATLAS into any repo in one command: scaffold the quartet, auto-draft the map, measure the savings, and (with `--pr`) open a pull request via `gh`. The zero-friction "spread" path.
- **Deeper `init --analyze`** — the auto-draft now generates a real **§0 "Where to look" table** *and* a **§1 module graph** with detected **talks-to** dependency edges (grep-based, language-agnostic). A fresh repo gets a near-complete map — and a real `atlas map` picture — out of the box, so the first 60 seconds don't start from a blank page.

### Fixed

- `atlas bench --runtime codex` now records codex's **real model** (read from `~/.codex/config.toml` when no `--model` is passed) instead of `default` — `codex exec --json`'s stdout never carries it. Existing codex ledger rows back-filled to `gpt-5.5`.
- `atlas measure` no longer prints a nonsensical negative reduction on a **tiny repo** (where the quartet spine exceeds the whole repo); it shows an honest "light overhead now, grows with the codebase" note.

## [0.1.9] — 2026-06-09

### Added

- **Self-maintaining map** — `atlas hooks install [--auto]` adds a git pre-commit hook that catches map drift; `--auto` runs `atlas init --analyze` and stages the refreshed **§0.5 into the commit**, so ATLAS.md never goes stale. (`atlas hooks status` / `uninstall`.) Also made `init --analyze` **idempotent** — re-running refreshes §0.5 instead of duplicating it (it duplicated before).
- **MCP router** — ATLAS now *conducts the ecosystem*: the deep tools (`atlas_graph` / `atlas_deepsearch`) appear when a backend **or** an installed graph/vector CLI (**graphify**, **CodeGraphContext**) is present, and ATLAS routes the query to it. Orient free via ATLAS, drill down via whatever's installed; a configured `ATLAS_MCP_BACKEND_URL` (FuseGraph/FuseRAG) still takes precedence.
- **Leaderboard + share** — `atlas measure --share` prints your repo's leaderboard row **and a one-click pre-filled GitHub-issue link**; `docs/LEADERBOARD.md` is the board. Turns the −92→99% number into social proof.

## [0.1.8] — 2026-06-09

### Added

- **Task-aware orientation** — `atlas orient "<task>"` (and the MCP `atlas_orient(task)` tool) returns just the *relevant slice* of the map: the map entries, SKILL anchors, and the **SCARS that bite *this* task**, ranked by keyword overlap (zero-infra, no embeddings). No task → the full §0 map. The agent's first move, conditioned on what it's about to do — nobody else does this.
- **`atlas map`** — render the repo's structure (ATLAS.md §1) as a **Mermaid** graph (renders natively on GitHub) or a standalone HTML page (`--html [--out F]`) to screenshot. A shareable picture of the repo's brain.
- **The "ATLAS bot"** — `action.yml` now posts a **sticky PR comment** with the measured orientation savings + **map-drift status** (compared against the PR base), not just a job summary. Zero hosting — runs in your CI. New inputs: `comment` (default true) and `drift-gate` (fail the build if files changed without updating the map). This repo **dogfoods it on its own PRs** (`.github/workflows/atlas-pr.yml`).

## [0.1.7] — 2026-06-09

### Added

- **`atlas mcp` — a Model Context Protocol server** (`bin/atlas-mcp`, Python stdlib, zero deps). Serves this project's map to *any* MCP client (Claude Code, Cursor, OpenClaw, Codex, Gemini…) via four local tools: **`atlas_orient`** (the §0 map + SKILL/SCARS ToCs — call it first instead of grepping), **`atlas_find`**, **`atlas_scars`**, **`atlas_measure`**. stdio transport (the OS process boundary is the auth — no token needed locally); `atlas mcp --config` prints the registration snippet. Deep tools (**`atlas_graph` / `atlas_deepsearch` / `atlas_recall`**) appear *only* when `ATLAS_MCP_BACKEND_URL` is set, proxying to an opt-in graph+vector+memory backend (e.g. FuseGraph/FuseRAG) with an optional bearer token — ATLAS stays 100% local + free by default.
- **`atlas mcp --http [--host H] [--port N] [--token T]`** — serve the same MCP over HTTP for team/remote use. Token auth is **opt-in** (`--token` / `ATLAS_MCP_TOKEN`): a request without `Authorization: Bearer …` gets `401`; with nothing set it's open (and warns if bound off-localhost). `GET /health` for liveness.

## [0.1.6] — 2026-06-08

### Added

- `atlas bench` is now a **cross-runtime benchmark board**: first-class parsers for **claude / codex / opencode / openai**, each appending an honest row to the ledger. Measured on this repo: openai-deterministic **−92% (12.8×)** orientation tokens; agentic turns/wall reductions on every runtime (Haiku −33% turns, opencode −30% wall). The headline metric auto-selects the first non-degenerate signal (so a 1-vs-1 message count never shows as "0%").
- `atlas init --analyze` — scans the repo (languages, build/test commands, CI, entry points, top-level inventory with guessed roles) and injects a pre-filled **§0.5 Auto-detected map** into ATLAS.md, so the map isn't a blank page. The auto-draft lever from CRITICS #8.
- `atlas check --changed-files[=REF]` — **drift gate**: fails if files were added/moved/removed without updating `ATLAS.md` (the map is stale). Wire it into CI to enforce the spec's *"a stale ATLAS is worse than none"* (CRITICS #7).
- `atlas measure` now reports a **range**, not a single point — orientation reduction against a *smart skim* (mid) **and** a *whole-repo dump* (upper bound): **−93% to −99%** on this repo. It now measures the same front-loaded **spine** the benchmark does (ATLAS §0-1 + SKILL/SCARS ToCs) instead of the whole files, so `measure` and `bench` finally agree; the `--badge` shows the range.
- `atlas bench` gained **first-class `codex` and `opencode` parsers** (no longer "generic"): codex via `exec --json` (counts turns, reads `token_count` usage), opencode via `run --pure --format json` (per-message `tokens` + `cost` + `modelID`). Both headline **turns** with a `wall_s` fallback when token parsing isn't available. `--pure` fixes opencode's plugin-log stdout pollution (SCARS §OPENCODE-PURE-JSON), and opencode now requires `--model` so it can't hang on selection. Both parsers are unit-tested against real stored sessions.

### Fixed

- `atlas bench` **agentic metric is now honest** (SCARS §BENCH-TOKEN-SUM-CACHE). Summing per-turn `input_tokens` double-counts cached context — it can climb even as **cost falls** — so it is no longer the headline for `--runtime claude\|codex\|opencode`. Those runtimes now report **turns / cost / wall-time** (all lower-is-better) and are logged as *directional*; the deterministic single-shot `openai` / `measure` mode remains the source of the reproducible **−92% / 12.8×** (which rises to **~99%** when the baseline is a whole-repo dump rather than a smart skim). First agentic matrix (effort=high, N=1, atlas repo) shows **fewer round-trips — most for the smallest model**: Opus 4.8 6→5 turns, Sonnet 4.6 5→4, **Haiku 4.5 15→10 (−33%)**; codex 128→98s wall (−23%). Cost is ~flat/noisy at N=1 on this tiny repo (the spine's fixed injection ≈ the turn savings); the consistent signal is turns/wall, and it scales with repo size.
- `atlas bench` now **records the model the runtime actually resolved** (e.g. `default` → `claude-opus-4-8` / `claude-haiku-4-5-20251001`) by reading it back from the run's own JSON, so the ledger never just says "default".
- `atlas bench --runtime codex` previously scored **0/0** silently (SCARS §BENCH-NEEDS-GIT): the `git archive` work dir has no `.git`, so `codex exec` refused to run and bailed in ~0s — and its stderr was discarded. Now passes `--skip-git-repo-check`, keeps stderr, and flags empty output as a `parse_error` so a dead run can't masquerade as a datapoint. **Validated**: a clean codex datapoint now records (128→98s wall with the quartet).

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

[Unreleased]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.11...HEAD
[0.1.11]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.10...v0.1.11
[0.1.10]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.9...v0.1.10
[0.1.9]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/Abbasi-Alain/atlas/releases/tag/v0.1.0
