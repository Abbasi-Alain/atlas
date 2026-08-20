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
| Look up an answered question (*"why does it do that?"*) | [`docs/FAQ.md`](docs/FAQ.md) (SPEC §13) |
| Look up a term (trio/anchor/style/stack) | §G Glossary |
| The format rules | [`docs/SPEC.md`](docs/SPEC.md) |

---

## 1. Top-level files (repo root)

| Node | Role | Talks-to |
|---|---|---|
| [`bin/atlas`](bin/atlas) | **The CLI.** Pure bash, zero deps. All subcommands live here. | templates/, adapters/, hooks/ |
| [`bin/atlas-node`](bin/atlas-node) | npm/npx wrapper — execs `bin/atlas` via bash | bin/atlas |
| [`bin/atlas-mcp`](bin/atlas-mcp) | **MCP server** (Python stdlib, zero-dep) — serves the map to any MCP client | bin/atlas, ATLAS.md |
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
| [`docs/FAQ.md`](docs/FAQ.md) | **Q&A knowledge ledger** (SPEC §13) — questions answered once, with pointers; check before asking/re-deriving; stable `FAQ-NNN` ids | ATLAS.md |
| [`data/leaderboard.csv`](data/leaderboard.csv) | Leaderboard dataset — source of truth for [`docs/LEADERBOARD.md`](docs/LEADERBOARD.md) (`atlas leaderboard --render`) | docs/ |
| [`assets/`](assets/) | README demo GIFs/tapes ([VHS](https://github.com/charmbracelet/vhs)), logo, social-card image — no runtime code | README.md |

> **Not applicable** (deleted per spec convention): §3 service layer,
> §4 front-end, §D data model, §R runtime topology, §O observability,
> §Sec security boundaries — ATLAS is a CLI + Markdown templates, no
> services, DB, or network surface.

---

## 2. The CLI — `bin/atlas`

A single `set -euo pipefail` bash script (~5k lines), zero runtime
dependencies (bash, git, coreutils). Deliberately one file — SCARS
§BASH-MONOLITH; shellcheck-green always.

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

The authoritative, always-current command list is `bin/atlas`'s own header
doc block (what `atlas help` prints) — don't duplicate it here. Families:
`init / check / fix / measure` (conformance) · `orient / context / capsule`
(read side) · `remember / anchor / handoff / claim / promote` (write +
multi-agent) · `bench / loop / critique` (science + loop) ·
`export / mcp / install / onboard` (distribution) · `mirror / auth / repo /
adr / research / cost` (ops).

---

## 3. Templates — `templates/`

`atlas init` renders these. Placeholders: `{{PROJECT_NAME}}`, `{{SRC_DIR}}`,
`{{PRIMARY_BUILD_FILE}}`, `{{TEST_CMD}}`, `{{DATE}}` (see `_render`).

One `.tmpl` per surface (quartet + every optional surface — BUGS, CRITICS,
FAQ, LOOP/ROADMAP, DECISION_GRAPH, DATA_SOURCE_LADDER, SKILL_GRAPH, ASOP,
intake quartet); each renders via its matching `atlas init --<flag>`.
`styles/<name>/` overrides some/all templates (+ `seeds/`, `stacks/`);
missing files fall back to root. The `abbasi` style is private +
gitignored — never commit it (SCARS §PRIVATE-STYLE-OVERLAY).

---

## 4. Adapters — `adapters/<runtime>/install.sh`

One idempotent bash script per runtime; running twice duplicates nothing.
Supported: `claude-code`, `codex`, `opencode`, `cursor`, `gemini`, `zed`,
`copilot`, `hermes`, `generic`. Adding one: see [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md)
+ the `🔌 New runtime adapter` issue template (~30–60 lines each).

---

## 5. Tests — `tests/`

[`tests/bootstrap.test.sh`](tests/bootstrap.test.sh) (tmpdir fixtures) +
shellcheck + the CI matrix ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).
**Smoke set** (after touching the CLI):
```
shellcheck bin/atlas && bash tests/bootstrap.test.sh && (cd examples/sample-project && ../../bin/atlas check)
```

---

## 6. Packaging & release — `packaging/` + `.github/workflows/`

Tag `vX.Y.Z` (human-only, SCARS §TAG-TRIGGER-NOT-RELEASE) → channel
workflows fan out: npm · Homebrew · `.deb` · AUR · PPA · Zenodo DOI. One
manifest dir per channel under `packaging/`; the authoritative runbook +
secret setup is [`docs/RELEASING.md`](docs/RELEASING.md). Reusable CI badge
for other repos: [`action.yml`](action.yml).

---

## 9. Edit-and-where rules of thumb

- **New CLI command** → `cmd_*` in `bin/atlas` + dispatch + header doc + a line in `tests/` if it has logic worth pinning. §2.2.
- **New generated section** → edit `templates/*.tmpl`, not the rendered output.
- **New runtime** → `adapters/<name>/install.sh` + README support table + `atlas export` arm if it has a context file.
- **New package channel** → `packaging/<channel>/` + a `release-<channel>.yml` + a row in §6 + `docs/RELEASING.md`.
- **Any structural change** → update *this file* in the same commit. SCARS §ATLAS-IS-INDEX.

---

## A. Architecture references

[`docs/SPEC.md`](docs/SPEC.md) (the format) ·
[`docs/RELEASING.md`](docs/RELEASING.md) (release pipeline + secrets) ·
[`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) (adding adapters/styles/commands) ·
[`docs/INTEGRATIONS.md`](docs/INTEGRATIONS.md) (per-runtime wiring).
ADRs: none yet — `atlas adr add "title"`.

---

## G. Glossary

**quartet** = map + playbook + failure memory + contract · **anchor** = a
stable `<a id>` SCARS entry, never renumbered · **style/stack** = template
preset / its add-on · **adapter** = per-runtime installer · **harness** =
everything an agent reads before working.

---

## Maintenance

The graph entry point: any structural change updates this file **in the
same commit** (SCARS §ATLAS-IS-INDEX). Validate: `atlas check`.
