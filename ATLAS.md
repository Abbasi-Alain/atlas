# ATLAS — atlas project map

> **Purpose.** Graph index of this repo. Any agent dropped into this
> directory reads this file *first* and follows links to the exact
> file/section it needs — no grep, no glob, no wasted context.
>
> **Pair-with.** [`SCARS.md`](SCARS.md) = the **failure memory** (what not to
> repeat); [`.agents/skill/atlas/SKILL.md`](.agents/skill/atlas/SKILL.md) = the
> **task playbook** (how to do things). ATLAS = *"where things live"*.
>
> **This repo dogfoods itself** — it *is* the ATLAS tool, described in
> the ATLAS format. See the [spec](docs/SPEC.md). Update this file in
> the same commit as any structural change. SCARS §ATLAS-IS-INDEX.

---

## 0. Quick orientation

| You want to … | Start here |
|---|---|
| Understand what ATLAS is | [`README.md`](README.md) |
| Read/modify the CLI | [`bin/atlas`](bin/atlas) — one bash monolith (§2) |
| Add a CLI command | §2.2 — `cmd_*` fn + dispatch + header doc |
| Change generated docs | [`templates/`](templates/) (§3) |
| Add/fix a runtime adapter | [`adapters/`](adapters/) (§4) |
| Publish to a package channel | [`packaging/`](packaging/) + [`docs/RELEASING.md`](docs/RELEASING.md) (§6) |
| Prove a change works (done-gate) | §5 — `bash tests/bootstrap.test.sh` + `shellcheck` + `atlas check --deep --strict` |
| When to hand up / escalate | scarred cores in [`SCARS.md`](SCARS.md); release/publish is maintainer-only (SPEC §12) |
| Reason / operate well (any agent) | [`ASOP.md`](ASOP.md) principles · [`ASOP-EXECUTOR.md`](ASOP-EXECUTOR.md) the executor card |
| Debug a known trap | [`SCARS.md`](SCARS.md) |
| Look up a term (trio/anchor/style/stack) | §G Glossary |
| The format rules | [`docs/SPEC.md`](docs/SPEC.md) |

---

## 1. Top-level files (repo root)

| Node | Role | Talks-to |
|---|---|---|
| [`bin/atlas`](bin/atlas) | **The CLI.** Pure bash, zero deps. All subcommands live here. | templates/, adapters/, hooks/ |
| [`bin/atlas-node`](bin/atlas-node) | npm/npx wrapper — execs `bin/atlas` via bash | bin/atlas |
| [`bin/atlas-mcp`](bin/atlas-mcp) | **MCP server** (Python stdlib, zero-dep). `atlas mcp` serves the map (atlas_orient/find/scars/measure) to any MCP client; deep tools proxy to an opt-in backend | bin/atlas, ATLAS.md |
| [`install.sh`](install.sh) | `curl \| bash` installer → `~/.atlas` + launcher on PATH | bin/atlas |
| [`package.json`](package.json) | npm metadata; `bin: atlas → bin/atlas-node`; test script | §6 |
| [`templates/`](templates/) | The `.tmpl` files `atlas init` renders (§3) | bin/atlas |
| [`adapters/`](adapters/) | Per-runtime install scripts (§4) | bin/atlas |
| [`hooks/`](hooks/) | `atlas-skill-loader.sh` — Claude Code SessionStart hook | adapters/claude-code |
| [`packaging/`](packaging/) | aur / debian / homebrew / ppa manifests (§6) | .github/workflows |
| [`docs/`](docs/) | [SPEC](docs/SPEC.md), [RELEASING](docs/RELEASING.md), [CONTRIBUTING](docs/CONTRIBUTING.md), [INTEGRATIONS](docs/INTEGRATIONS.md) | — |
| [`.github/workflows/`](.github/workflows/) | CI + release fan-out (§6) + `atlas-pr.yml` (the PR bot — dogfoods [`action.yml`](action.yml)) | packaging/ |
| [`tests/`](tests/) | `bootstrap.test.sh` smoke test (§5) | bin/atlas |
| [`CHANGELOG.md`](CHANGELOG.md) | Release history (drives release notes) | §6 |
| [`CITATION.cff`](CITATION.cff) | Citation metadata — GitHub "Cite this repository" + Zenodo DOI on release | §6 |
| [`AKIGI.md`](AKIGI.md) | **Purpose contract** (SPEC §11) — why this repo exists; the triage criterion for incoming requests | FRQ.md, BRD.md, SRD.md |
| [`FRQ.md`](FRQ.md) | **Feature Request Queue** (SPEC §11) — sibling-repo agents file asks here; triaged against AKIGI.md | AKIGI.md |
| [`BRD.md`](BRD.md) | **Bug disclosure intake** (SPEC §11) — outside agents file defects (evidence+repro); accepted → internal BUGS.md flow | AKIGI.md |
| [`SRD.md`](SRD.md) | **Security disclosure** (SPEC §11) — minimal public marker; full detail via private channel; maintainer-only triage | AKIGI.md |
| [`ASOP.md`](ASOP.md) | **Operating methodology** (SPEC §12) — 13 reasoning moves + a 5-question self-test; canonical, copied verbatim | ASOP-EXECUTOR.md |
| [`ASOP-EXECUTOR.md`](ASOP-EXECUTOR.md) | **Executor card** (SPEC §12) — role-based mechanical protocol (pre-flight · verify · **escalate** · report) any subagent runs | ASOP.md |
| [`data/leaderboard.csv`](data/leaderboard.csv) | Leaderboard dataset — source of truth for [`docs/LEADERBOARD.md`](docs/LEADERBOARD.md) (`atlas leaderboard --render`) | docs/ |

> **Not applicable** (deleted per spec convention): §3 service layer,
> §4 front-end, §D data model, §R runtime topology, §O observability,
> §Sec security boundaries — ATLAS is a CLI + Markdown templates, no
> services, DB, or network surface.

---

## 2. The CLI — `bin/atlas`

A single `set -euo pipefail` bash script (~1.9k lines). One advantage:
zero runtime dependencies (only `bash`, `git`, coreutils). The cost: it's
a monolith — see SCARS §BASH-MONOLITH for the modularization plan.

### 2.1 Shape & helpers

| Piece | Role |
|---|---|
| `_resolve_self` → `ATLAS_HOME` | Resolves the install dir through symlinks; `TEMPLATES`/`ADAPTERS`/`HOOKS` hang off it |
| `_die / _say / _warn / _ok / _fail / _banner` | Output helpers (color-aware via `_c_*`, auto-off when not a TTY / `NO_COLOR`) |
| `_render <in> <out> <force>` | Render a `.tmpl` → file with `{{PLACEHOLDER}}` substitution |
| `_project_name` | Repo name from `git remote origin` or cwd basename |
| `main()` | Subcommand dispatch (`case "$sub"`) at the bottom of the file |

### 2.2 Adding a command

1. Write a `cmd_<name>()` function (follow the existing ones — parse flags
   with a `while/case`, use the `_*` helpers, never `echo` raw errors).
2. Add a `case` arm in `main()`.
3. Document it in the header comment block (lines ~4–65) so it shows in
   `atlas help` (which prints header lines 2–40).
4. `shellcheck bin/atlas` must stay clean (CI enforces). Mind SCARS §SET-E-AND-AND.

### 2.3 Command surface

| Core | Purpose |
|---|---|
| `init [--style --stack --force]` | Scaffold the trio (+ style seeds / stack docs) |
| `check` | Lint the trio; verify SCARS anchors are unique |
| `measure [--badge]` | Estimate orientation-token savings (with vs without ATLAS) |
| `doctor` | Diagnose install + project harness + runtime-export drift |
| `badge` | Print a "Powered by ATLAS" README badge |
| `export --to <runtime>` | Fan the trio out to AGENTS/Copilot/Gemini/Cursor/llms.txt |
| `anchors` / `anchor add` | List / append SKILL failure-mode anchors |

| Advanced | Purpose |
|---|---|
| `install --runtime <name>` | Wire ATLAS into a runtime (delegates to `adapters/<name>/install.sh`) |
| `styles` / `stacks` | List style presets / per-style stack add-ons |
| `adr` / `research` / `critique` | Decision records, research notes, hostile-review prompts |
| `mirror` / `auth` / `repo` / `cost` / `gap-to-article` | GitLab→GitHub mirroring, login, repo create, cost audit, article scaffold |

---

## 3. Templates — `templates/`

`atlas init` renders these. Placeholders: `{{PROJECT_NAME}}`, `{{SRC_DIR}}`,
`{{PRIMARY_BUILD_FILE}}`, `{{TEST_CMD}}`, `{{DATE}}` (see `_render`).

| Path | Renders to |
|---|---|
| `ATLAS.md.tmpl` | `ATLAS.md` (this file's shape) |
| `SKILL.md.tmpl` | `.agents/skill/<project>/SKILL.md` |
| `CLAUDE.md.tmpl` | `CLAUDE.md` (then mirrored to `AGENTS.md`) |
| `EXAMPLES.md.tmpl` | `EXAMPLES.md` |
| `BUGS.md.tmpl` | `BUGS.md` — optional open-issues register, opt-in via `atlas init --bugs` |
| `CRITICS.md.tmpl` | `CRITICS.md` — optional cross-vendor second-opinion log, opt-in via `atlas init --critics` |
| `styles/<name>/` | Per-style overrides + `seeds/` + `stacks/`. Resolution: a style file wins over the root `.tmpl`; missing files fall back to root. |

> The `abbasi` style is **private** (maintained in a sibling GitLab repo,
> symlinked in by an overlay installer) and is `.gitignore`d here — never
> commit it. SCARS §PRIVATE-STYLE-OVERLAY.

---

## 4. Adapters — `adapters/<runtime>/install.sh`

One idempotent bash script per runtime; running twice duplicates nothing.
Supported: `claude-code`, `codex`, `opencode`, `cursor`, `gemini`, `zed`,
`copilot`, `hermes`, `generic`. Adding one: see [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md)
+ the `🔌 New runtime adapter` issue template (~30–60 lines each).

---

## 5. Tests — `tests/`

| Concern | Where |
|---|---|
| Bootstrap smoke (`init`→`check` in a tmpdir) | [`tests/bootstrap.test.sh`](tests/bootstrap.test.sh) |
| Static analysis | `shellcheck bin/atlas hooks/*.sh install.sh adapters/*/install.sh` |
| CI matrix (ubuntu + macos) | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) |

**Smoke set** (after touching the CLI):
```
shellcheck bin/atlas && bash tests/bootstrap.test.sh && (cd examples/sample-project && ../../bin/atlas check)
```

---

## 6. Packaging & release — `packaging/` + `.github/workflows/`

Tag `vX.Y.Z` → `release.yml` cuts the GitHub release → four channel
workflows fire on `release: published`:

| Channel | Manifest | Workflow | Needs |
|---|---|---|---|
| npm | `package.json` | `release-npm.yml` | `NPM_TOKEN` |
| Homebrew | `packaging/homebrew/atlas.rb` | `release-homebrew.yml` | `HOMEBREW_TAP_TOKEN` |
| `.deb` (download) | `packaging/debian/build-deb.sh` | `release-deb.yml` | — (`GITHUB_TOKEN`) |
| AUR | `packaging/aur/PKGBUILD` | `release-aur.yml` | `AUR_*` secrets |
| Launchpad PPA | `packaging/ppa/` | (manual `dput`) | Launchpad account + GPG |

Reusable CI badge for *other* repos: [`action.yml`](action.yml) → `uses: Abbasi-Alain/atlas@v1`.
Release runbook + secret setup: [`docs/RELEASING.md`](docs/RELEASING.md).

---

## 9. Edit-and-where rules of thumb

- **New CLI command** → `cmd_*` in `bin/atlas` + dispatch + header doc + a line in `tests/` if it has logic worth pinning. §2.2.
- **New generated section** → edit `templates/*.tmpl`, not the rendered output.
- **New runtime** → `adapters/<name>/install.sh` + README support table + `atlas export` arm if it has a context file.
- **New package channel** → `packaging/<channel>/` + a `release-<channel>.yml` + a row in §6 + `docs/RELEASING.md`.
- **Any structural change** → update *this file* in the same commit. SCARS §ATLAS-IS-INDEX.

---

## A. Architecture references

| File | What it covers |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | The ATLAS format: file locations, anchors, the one-commit rule |
| [`docs/RELEASING.md`](docs/RELEASING.md) | Release pipeline + one-time secret setup |
| [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) | How to add adapters / styles / commands |
| [`docs/INTEGRATIONS.md`](docs/INTEGRATIONS.md) | Per-runtime wiring details |

### A3. ADR index

| # | Title | Status | Date |
|---|---|---|---|
| — | _(none yet — use `atlas adr add "title"`)_ | | |

---

## G. Glossary

| Term | Definition |
|---|---|
| **the quartet** | `ATLAS.md` (map) + `SKILL.md` (task playbook) + `SCARS.md` (failure memory) + `CLAUDE.md`/`AGENTS.md` (behavioral contract) |
| **anchor** | A stable `<a id="…">` failure-mode entry in SCARS.md; treated as load-bearing — never renumbered |
| **style** | A preset under `templates/styles/<name>/` that overrides some/all templates (e.g. `minimal`, `strict`, `karpathy`, `google`) |
| **stack** | A per-style add-on (`styles/<name>/stacks/<stack>/`) dropped into `docs/stacks/` via `--stack` |
| **adapter** | A per-runtime installer that wires the trio into an agent (Claude/Codex/Cursor/…) |
| **harness** | The full set of files + wiring an agent reads before doing work |

---

## Maintenance

This file is the **graph entry point**. Add a top-level module, a command,
a package channel, or a runtime → update it **in the same commit**. A stale
ATLAS forces every future agent to re-grep the tree. Validate: `atlas check`.
Enumerate SCARS anchors: `atlas anchors`. Measure the payoff: `atlas measure`.
