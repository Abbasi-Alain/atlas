# Changelog

All notable changes to ATLAS will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and ATLAS uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- `atlas measure [--badge]` — estimate orientation-token savings (with vs without ATLAS) and emit a shields.io badge for the README.
- `atlas doctor` — diagnose the install, the project harness, CLAUDE.md size, AGENTS.md drift, and per-runtime export status.
- `atlas export --to <codex|copilot|gemini|cursor|llms-txt|all>` — fan the canonical trio out to other runtimes' context files from one source of truth.
- `atlas badge` — print a "Powered by ATLAS" README badge (markdown + HTML).
- `action.yml` — reusable GitHub Action (`uses: Abbasi-Alain/atlas@v1`) that runs `atlas check` and posts an `atlas measure` job summary.
- Launchpad PPA packaging under `packaging/ppa/` (proper `/usr` install, `git archive`-based build, full account/GPG/`dput` runbook).
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

[Unreleased]: https://github.com/Abbasi-Alain/atlas/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Abbasi-Alain/atlas/releases/tag/v0.1.0
