# ATLAS — Agentic Harness Standard — for better multi agents performance, agents token and context reduction by design, graph based. Zero infrastructure. 

> ## −92% agent orientation tokens (12.8×) — *measured, not claimed*. Up to −99% on whole-repo loads; bigger on larger repos.
>
> Stop your agents from burning **100k+ tokens per session** on `ls`, `find`, `grep`, and `git ls-files` just to figure out where things live. **Four Markdown files** ship the project map, the task playbook, the scar memory, and the behavior contract into context **before the first tool call** — every Claude / Codex / Cursor / Gemini / Zed / OpenCode / Copilot / Hermes session.
>
> Not a claim — **[benchmarked + logged](docs/benchmarks/RESULTS.md)**: 12.8× (92%) on this very repo, reproducible with `atlas bench`.
>
> **Don't grep. Don't guess. Don't repeat.**

<p align="center">
  <img src="assets/logo.svg" alt="ATLAS" width="180" />
</p>

<p align="center">
  <a href="docs/benchmarks/RESULTS.md"><img src="https://img.shields.io/badge/orientation_tokens-%E2%88%9292%25_measured-06b6d4?style=for-the-badge&logo=markdown&logoColor=white" alt="92% fewer orientation tokens (measured)"></a>
  <a href="docs/benchmarks/RESULTS.md"><img src="https://img.shields.io/badge/benchmark-reproducible-22c55e?style=for-the-badge" alt="reproducible benchmark"></a>
  <a href="#install--pick-your-flavor"><img src="https://img.shields.io/badge/install-npm·brew·apt·AUR·PPA-f59e0b?style=for-the-badge" alt="install channels"></a>
</p>

<p align="center">
  <img src="assets/atlas-demo.gif" alt="atlas CLI — version · help · init · check · anchors · install --runtime · mirror init" width="900" />
</p>

<p align="center">
  <a href="https://github.com/Abbasi-Alain/atlas/stargazers"><img src="https://img.shields.io/github/stars/Abbasi-Alain/atlas?style=for-the-badge&logo=github&logoColor=white&color=facc15" alt="Stars"/></a>
  <a href="https://github.com/Abbasi-Alain/atlas/network/members"><img src="https://img.shields.io/github/forks/Abbasi-Alain/atlas?style=for-the-badge&logo=github&logoColor=white&color=22d3ee" alt="Forks"/></a>
  <a href="https://github.com/Abbasi-Alain/atlas/graphs/contributors"><img src="https://img.shields.io/github/contributors/Abbasi-Alain/atlas?style=for-the-badge&logo=github&logoColor=white&color=3b82f6" alt="Contributors"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-3b82f6?style=for-the-badge" alt="License: MIT"/></a>
  <a href="https://github.com/Abbasi-Alain/atlas/actions"><img src="https://github.com/Abbasi-Alain/atlas/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/@alainabbasi/atlas"><img src="https://img.shields.io/npm/v/@alainabbasi/atlas?style=flat-square&logo=npm&color=cb3837" alt="npm"/></a>
  <a href="https://www.npmjs.com/package/@alainabbasi/atlas"><img src="https://img.shields.io/npm/dw/@alainabbasi/atlas?style=flat-square&logo=npm&color=cb3837" alt="npm downloads"/></a>
  <img src="https://img.shields.io/badge/spec-v0.1-a78bfa?style=flat-square" alt="Spec v0.1"/>
  <img src="https://img.shields.io/badge/deps-zero-22c55e?style=flat-square" alt="Zero deps"/>
  <img src="https://img.shields.io/badge/runtimes-9-0ea5e9?style=flat-square" alt="9 runtimes"/>
  <img src="https://img.shields.io/badge/harness-agnostic-f59e0b?style=flat-square" alt="Harness agnostic"/>
  <img src="https://img.shields.io/badge/built_with-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white" alt="Bash"/>
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square" alt="PRs welcome"/>
</p>

---

## The 30-second pitch


| Metric                                    | Without ATLAS     | With ATLAS                  | Reduction  |
| ----------------------------------------- | ----------------- | --------------------------- | ---------- |
| **Orientation tokens per session**        | 55–180k           | ~1.8k auto + 1–5k on demand | **12.8× [measured](docs/benchmarks/RESULTS.md)** |
| **Orientation tool calls**                | 10–30             | **0**                       | ∞×         |
| **Same bug re-introduced**                | every fresh agent | never (cite `§ANCHOR`)      | —          |
| **"While I'm here" cleanup churn in PRs** | high              | 30–60% lower *(est.)*       | —          |
| **Infrastructure required**               | —                 | **none** (4 Markdown files) | —          |
| **Runtimes supported**                    | varies            | **9** out of the box        | —          |


ATLAS is **a harness performance tool disguised as documentation**. Three files. No daemon, no DB, no service to run, no SDK to wire. Works with whatever agent runtime your team picked, and the next one.

---

## Why now

Three things are exploding at once:

1. **Context windows are growing, but tokens-per-task keep rising faster.** A 1M-token context isn't the answer if every fresh agent spends 100k of it on `ls` / `find` / `grep` before doing real work.
2. **Multi-agent dispatch is becoming default.** Lead agents spawn sub-agents (Claude Code's Task tool, Cursor's Background Agents, Codex worker mode, ECC squads, Manus, Replit Agent). Each sub-agent re-pays the orientation tax. ATLAS amortises it.
3. **AGENTS.md is becoming a real standard.** Codex / OpenCode / Cursor / Gemini / Zed all read AGENTS.md-style files at session start. ATLAS gives that file the shape that maximizes its value — not just behavior rules, but a real map.

## How it works *(in 30 seconds)*

```mermaid
flowchart LR
  A[Fresh agent session] --> B{ATLAS.md<br/>exists?}
  B -- no --> C[ls · find · grep · read x5<br/>~55-180k tokens<br/>10-30 tool calls]
  C --> Z[Start work<br/>tired + confused]
  B -- yes --> D[SessionStart hook<br/>auto-prints §0 + §1 + SKILL ToC<br/>~1.8k tokens<br/>0 tool calls]
  D --> E[Read one specific module<br/>1-5k tokens<br/>1-2 tool calls]
  E --> F[Start work<br/>oriented + with the playbook]
```

The hook fires once per session, before the agent's first action.

---

## The quartet *(four files. that's it.)*


| File                                                              | Axis           | Question it answers                                                                                                                                                                           | Token cost              |
| ----------------------------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `[ATLAS.md](templates/ATLAS.md.tmpl)`                             | **Structural** | *Where is X?* Graph index — every important module, its role, what it talks to. Plus glossary, data model, external deps, runtime topology, observability, security boundaries, build/deploy. | ~1.4k auto-loaded §0+§1 |
| `[SCARS.md](templates/SCARS.md.tmpl)`                             | **Failure memory** | *What did we learn the hard way?* Stable anchors (`§NAME-LIKE-THIS`) — symptom → root cause → do NOT → do → file pointer. Cite from PRs and commits.                                     | ~0.4k ToC auto-loaded   |
| `[.agents/skill/<project>/SKILL.md](templates/SKILL.md.tmpl)`     | **Procedural** | *How do I do X here?* Task recipes — goal → steps → how to verify.                                                                                                                            | on-demand               |
| `[CLAUDE.md](templates/CLAUDE.md.tmpl)` + `[AGENTS.md](#)` mirror | **Behavioral** | *How should the agent act?* Don't assume. Don't refactor adjacent code. Match existing style. Define success criteria. Loop until verified.                                                   | on-demand               |


Plus `[EXAMPLES.md](templates/EXAMPLES.md.tmpl)` — vague→concrete transformations that teach the patterns by contrast.

**Net:** ~1.8k tokens of project orientation lands in the agent's context **before the first tool call**, eliminating 10–30 redundant `ls`/`find`/`grep`/`read` round trips per session.

---

## Benchmarks — measured, not just claimed

ATLAS ships an A/B benchmark (`atlas bench`) and appends every run to a
[ledger](docs/benchmarks/RESULTS.md) so the reduction is trackable across
versions, models, and dates. First result on **this repo** (deterministic, reproducible) —
the reduction is a *range*, set by how the agent would otherwise orient:

| "Without ATLAS" orientation | tokens | vs the spine |
|---|---|---|
| Whole-repo dump (RAG / "load everything") | 104,390 | **−99% · 80×** |
| Smart skim (README + file tree + source heads) | 16,571 | **−92% · 12.8×** |
| ATLAS §0–1 spine (auto-injected before the first tool call) | 1,297 | — |

`atlas measure` prints this range for any repo; the `atlas bench` ledger logs the
**−92%** (the conservative, fair-fight baseline — not the whole-repo strawman).

```bash
# any OpenAI-compatible endpoint (incl. a local vLLM), free + deterministic:
atlas bench --runtime openai --api-base http://localhost:8000/v1 --model <model>
# or a live agentic A/B with a real coding agent:
atlas bench --runtime claude   # or codex | opencode
```

The skim grows with codebase size while the spine stays ~constant, so on large
repos even the conservative (vs-skim) number climbs toward that upper bound. In
**multi-agent** setups it compounds — every sub-agent pays the orientation tax
independently, and ATLAS pays it once into the shared quartet. Methodology +
honesty rules:
[docs/benchmarks/methodology.md](docs/benchmarks/methodology.md).

---

## Install — pick your flavor

### One-liner (bash, any platform)

```bash
curl -fsSL https://raw.githubusercontent.com/Abbasi-Alain/atlas/main/install.sh | bash
```

### Homebrew *(macOS / Linuxbrew)*

```bash
brew tap Abbasi-Alain/atlas
brew install atlas
```

### npx *(zero-install, Node already on PATH)*

```bash
npx @alainabbasi/atlas init
```

### Debian / Ubuntu / Mint / Pop!_OS

**`apt install` via the PPA** *(recommended — tracks releases, auto-updates):*

```bash
sudo add-apt-repository ppa:alainabbasi/atlas
sudo apt update && sudo apt install atlas
```

**Or a one-off `.deb`** from the [latest release](https://github.com/Abbasi-Alain/atlas/releases/latest):

```bash
curl -L https://github.com/Abbasi-Alain/atlas/releases/latest/download/atlas_0.1.5_all.deb \
  -o /tmp/atlas.deb && sudo apt install /tmp/atlas.deb
```

### Arch / Manjaro *(AUR)*

```bash
yay -S atlas       # or: paru -S atlas
```

### Manual clone

```bash
git clone https://github.com/Abbasi-Alain/atlas.git ~/.atlas
~/.atlas/install.sh
```

After install you have the `atlas` CLI on PATH and adapters ready to wire into your agent runtime.

---

## 60-second start

```bash
cd your-project/

atlas init                          # write ATLAS.md + SKILL.md + SCARS.md
                                    # + CLAUDE.md + AGENTS.md mirror + EXAMPLES.md

atlas check                         # verify anchors unique, structure valid
atlas measure                       # estimate the orientation-token savings

atlas install --runtime claude-code # SessionStart hook + /init-atlas command
                                    # (or: codex / opencode / hermes / generic)
```

Open a new agent session in any project with these files. The agent's first action will be reading `ATLAS.md §0` and the `SKILL.md` table of contents — automatically, no prompt engineering required.

---

## Plug into any agent — the MCP server

ATLAS ships a **zero-dependency Model Context Protocol server**, so *any* MCP client — Claude Code, Cursor, OpenClaw, Codex, Gemini — reads the map directly instead of grepping:

```bash
atlas mcp --config                  # prints the registration snippet
claude mcp add atlas -- atlas mcp   # or paste the snippet into .mcp.json / Cursor
```

Four local tools — no infra, no embeddings, no API key:

| tool | what the agent gets |
|---|---|
| `atlas_orient` | the §0 map + SKILL/SCARS tables of contents — *"where things live"* |
| `atlas_find` | where a thing lives, by keyword |
| `atlas_scars` | the failure lessons for a topic |
| `atlas_measure` | the orientation-token reduction for this repo |

Need deep queries? Set `ATLAS_MCP_BACKEND_URL` and three more tools (`atlas_graph`, `atlas_deepsearch`, `atlas_recall`) light up, proxying to a bring-your-own graph+vector backend. With nothing set, ATLAS stays **100% local and free**.

Sharing with a team? `atlas mcp --http --token "$SECRET"` serves the same tools over HTTP — token auth is opt-in (no token locally, required off-localhost), with `GET /health` for liveness.

---

## Superpowers

- **Task-aware orientation** — `atlas orient "fix the failing auth test"` returns *only* the relevant slice of the map **plus the SCARS that bite that task** — not the whole file. Over MCP too (`atlas_orient(task)`). The agent's first move, conditioned on the job. Nobody else does this.
- **A picture of your repo** — `atlas map` emits a **Mermaid** graph (renders right here on GitHub) or `atlas map --html` for a standalone page to screenshot.
- **The ATLAS PR bot** — drop `uses: Abbasi-Alain/atlas@v1` into a workflow and every PR gets a sticky comment with the measured **−92→99% orientation savings** + map-drift status. Zero hosting — runs in your CI. *(This repo runs it on its own PRs.)*
- **A map that never goes stale** — `atlas hooks install --auto` adds a git pre-commit hook that auto-refreshes `ATLAS.md §0.5` on structural change and stages it *into the commit*. Docs-as-code that can't rot.
- **ATLAS conducts the ecosystem** — the MCP deep tools (`atlas_graph`, `atlas_deepsearch`) light up when **graphify** or **CodeGraphContext** is installed and route the query to it. Orient free via ATLAS, drill down via whatever you've got.
- **Leaderboard** — `atlas measure --share` prints your savings + a one-click submit link. See the [board](docs/LEADERBOARD.md).
- **Onboard any repo in one command** — `atlas onboard` scaffolds the quartet, **auto-drafts a real map** (a §0 "where to look" table + a §1 dependency graph, not a blank page), and measures the savings; `--pr` opens the pull request for you.

---

## Style presets — pick a vibe

Not every project wants the same temperament. `atlas init --style <preset>` picks the templates:


| Style      | When to use                                                                                                                                                                                    |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `default`  | The complete universal scaffolding — §0-§9 + §A architecture refs + §G glossary + §D data model + §X external deps + §R runtime topology + §O observability + §Sec security + §B build/deploy. |
| `minimal`  | Solo project, small surface, low ceremony. Three short files, no tables you'd leave empty.                                                                                                     |
| `strict`   | High-stakes codebase. Hard rules, pre-flight checklists, required "What I did NOT change" reports.                                                                                             |
| `karpathy` | The 65-line behavioral spec made viral by Andrej Karpathy's repo. Four numbered principles. Quotable mantras.                                                                                  |
| `google`   | Boring code, small CLs, one-thing-per-change, style-as-contract, design-note-first.                                                                                                            |


```bash
atlas styles                        # list available presets
atlas init --style karpathy         # use the karpathy preset
atlas init --style strict --force   # overwrite with strict mode
```

Mix-and-match works: a style only overrides files it ships. Missing files fall back to the default template.

> Want a deeper preset with a research → critics → gaps → ADR pipeline + tech-stack docs (web / mobile / Rust / Python / ML / CLI / desktop / …)? Fork the repo, drop your variant in `templates/styles/<your-style>/`, and open a PR. See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

---

## Subcommands

```bash
atlas init [--style <preset>] [--force] [--analyze]   # scaffold the quartet (--analyze auto-drafts the map)
atlas check [--changed-files]             # validate the quartet; --changed-files gates stale-map drift
atlas measure [--badge]                   # estimate orientation-token savings (with vs without)
atlas bench [--runtime claude|codex]      # A/B a task with vs without ATLAS via a real headless agent
atlas doctor                              # diagnose install + harness + runtime-export drift
atlas export --to <runtime>               # fan the quartet out: codex|copilot|gemini|cursor|llms-txt|all
atlas badge                               # print a 'Powered by ATLAS' README badge
atlas anchors                             # list every SKILL anchor (machine-readable)
atlas anchor add NAME "summary"           # append a stub anchor

atlas install --runtime claude-code       # wire ATLAS into an agent runtime
atlas styles                              # list available --style presets

atlas mirror init [--staged|--direct|--dual-repo --public-repo URL]
                                          # scaffold .atlas/mirror.allow + GH Action
atlas mirror push [--dry-run]             # push only allowlisted refs to the `public` remote
atlas mirror status                       # show config + what would be pushed
                                          #   refuses if remote is named `origin` (origin is private/GitLab)

atlas auth login                          # interactive picker: ssh vs vendor (gh + glab)
atlas auth login --method ssh             # generate per-host keys + configure ~/.ssh/config (idempotent)
atlas auth login --method vendor          # brew install gh + glab + run their browser auth flows
atlas auth status                         # show what's authenticated (CLIs, keys, ssh -T tests)
```

The CLI also ships subcommands designed for deeper workflows (`atlas critique`, `atlas adr add/list`, `atlas research add/list`, `atlas gap-to-article`, `atlas cost`). These work best with a style that scaffolds the matching files (`docs/adr/`, `research/`, `docs/gaps/`, ATLAS §C / §GPU sections) — see `atlas help` for the full list.

### Mirror push — three patterns

```bash
# 1) Direct (simplest)
atlas mirror init --direct
#   one GH repo. local main → remote main. trust your allowlist.

# 2) Staged (default — recommended)
atlas mirror init
#   one GH repo. local main → remote `public` branch.
#   GH Action promotes `public` → `main` after gates pass, auto-deletes staging branch.
#   public repo at rest shows only main + tags.

# 3) Dual-repo (maximum paranoia)
atlas mirror init --dual-repo --public-repo git@github.com:you/project.git
#   TWO GH repos. push lands on the PRIVATE staging repo.
#   GH Action there pushes only main + tags to the PUBLIC release repo.
#   public repo NEVER sees branches, PRs, or any other refs.
#   needs a deploy key (PUBLIC_REPO_DEPLOY_KEY secret).
```

---

## Auth — using GitHub + GitLab side-by-side

`atlas mirror push` is auth-agnostic — it just runs `git push`. You set up auth once for each host. Two clean approaches:

### SSH with per-host keys *(recommended)*

```bash
# Two separate SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "you@github"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_gitlab -C "you@gitlab"
cat ~/.ssh/id_ed25519_github.pub    # → upload to GitHub
cat ~/.ssh/id_ed25519_gitlab.pub    # → upload to GitLab

# Pin each key to its host
cat >> ~/.ssh/config <<'EOF'

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab
  IdentitiesOnly yes
EOF

# Verify
ssh -T git@github.com
ssh -T git@gitlab.com

# Use
git remote add origin git@gitlab.com:you/project.git
git remote add public git@github.com:you/project.git
```

### HTTPS via vendor CLIs *(simpler setup)*

```bash
brew install gh glab
gh auth login              # GitHub: browser flow, stores in Keychain
glab auth login            # GitLab: same
git remote add origin https://gitlab.com/you/project.git
git remote add public https://github.com/you/project.git
```

Pick **SSH** for CI / multi-machine; **HTTPS + gh/glab** for one-machine convenience.

Either way, `atlas auth login` automates the setup — interactive picker, or pass `--method ssh` / `--method vendor` to skip the prompt.

---

## Supported runtimes


| Runtime                                                           | Status        | Adapter                                                                      |
| ----------------------------------------------------------------- | ------------- | ---------------------------------------------------------------------------- |
| [Claude Code](https://claude.ai/code)                             | ✅ first-class | `[adapters/claude-code/](adapters/claude-code/)` — hook + slash command      |
| [Codex CLI](https://github.com/openai/codex)                      | ✅ supported   | `[adapters/codex/](adapters/codex/)` — `AGENTS.md` global                    |
| [OpenCode](https://github.com/sst/opencode)                       | ✅ supported   | `[adapters/opencode/](adapters/opencode/)` — `AGENTS.md` global              |
| [Cursor](https://cursor.com)                                      | ✅ supported   | `[adapters/cursor/](adapters/cursor/)` — `.cursor/rules/atlas.mdc`           |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli)         | ✅ supported   | `[adapters/gemini/](adapters/gemini/)` — `GEMINI.md` global                  |
| [Zed](https://zed.dev)                                            | ✅ supported   | `[adapters/zed/](adapters/zed/)` — `.zed/atlas.md` + agents.md               |
| [GitHub Copilot Chat](https://github.com/features/copilot)        | ✅ supported   | `[adapters/copilot/](adapters/copilot/)` — `.github/copilot-instructions.md` |
| [Hermes](https://github.com/NousResearch/Hermes-Function-Calling) | ✅ supported   | `[adapters/hermes/](adapters/hermes/)` — system-prompt fragment              |
| Any other                                                         | ✅ generic     | `[adapters/generic/](adapters/generic/)` — manual hook                       |


Each adapter is a single idempotent shell script. Run it twice — nothing duplicates. Building one for a new runtime takes about 30 minutes; see `[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)`.

---

## Why ATLAS

Three pains every agent hits, and what each ATLAS file kills:


| Pain                                                                                                                | Killed by                                                |
| ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Re-orientation tax.** Every fresh session re-greps the tree, re-reads the same files, re-asks the same questions. | `ATLAS.md` — a one-shot pointer map.                     |
| **Forgotten scars.** A bug you fixed last month → next agent makes it again → days lost.                            | `SKILL.md` — every lesson has a *name* you can cite.     |
| **Drift in conduct.** Each agent guesses your team's norms — coding style, commit format, refactor appetite.        | `CLAUDE.md` — the behavioral contract, runtime-agnostic. |


---

## Performance — how much does ATLAS actually save?

ATLAS is **a harness performance tool disguised as documentation**. Three measurable wins, in order of size:

### 1. Orientation tokens *(every session, easy win)*


| Without ATLAS, a fresh agent typically does                     | Tool calls | Tokens (est.)       |
| --------------------------------------------------------------- | ---------- | ------------------- |
| `ls -R` / `find . -type f` to map the tree                      | 1–2        | 5–20k               |
| `git ls-files` then open 3–7 random files to learn the codebase | 4–8        | 30–100k             |
| `grep -r "<concept>"` to discover an unknown convention         | 1–3        | 10–30k              |
| 3–5 clarifying back-and-forth turns with the user               | —          | 10–30k              |
| **Total orientation overhead per session**                      | **~10–30** | **~55–180k tokens** |



| With ATLAS, the SessionStart hook auto-prints                  | Tool calls | Tokens    |
| -------------------------------------------------------------- | ---------- | --------- |
| `ATLAS.md §0` (Quick orientation table) + §1 (Top-level files) | **0**      | ~1.4k     |
| `SKILL.md` Table of Contents (every anchor + 1-line summary)   | **0**      | ~400      |
| **Total auto-loaded — before the first tool call**             | **0**      | **~1.8k** |


Then on-demand `Read` for one specific module the agent needs (1–5k). Net per session: **~5–10k vs ~55–180k.**

> **TL;DR: orientation phase — 12.8× ([measured](docs/benchmarks/RESULTS.md), 92%) on this repo, scaling toward 30× on large codebases.** Total session cost: ~10–25% *(estimate — not yet benchmarked)*. Bigger codebase = bigger win.

### 2. Bugs not re-made *(compounding win, pays dividends over months)*

Every SCARS anchor (`§NAME-LIKE-THIS`) is a scar another agent will not re-create. **Audit your own value**: `git log --grep "§"` — every commit citing an anchor is a turn where an agent (or human) skipped 2–10 minutes of re-debugging a known issue.

A 6-month-old codebase with 20 anchors and an active team can save **5–15 person-hours per week** in not-re-debugging tax. At $150/hr engineering rate, that's $30k–$90k/year per project, just from the SKILL-anchor mechanism.

### 3. Bad PRs not opened *(silent win, human-review-time)*

CLAUDE.md §3 (*"Surgical changes — touch only what you must"*) suppresses the **"while I'm here" cleanup commits** that bloat PRs and balloon human review time. Estimated from ~50 PRs reviewed across teams adopting an ATLAS-style behavioral contract: **~30–60% fewer non-load-bearing changes per PR** *(estimate — not benchmarked here)*. Not token savings — reviewer-attention savings, which often dominate engineering throughput.

### Where the savings come from *(visualised)*

```
WITHOUT ATLAS                  WITH ATLAS
                               
[ user prompt ]                [ user prompt ]
       │                              │
       ▼                              ▼
 ┌──────────────┐              ┌──────────────────────┐
 │ ls -R        │ 20k tokens   │ SessionStart hook    │ 1.8k tokens
 │ git ls-files │ 30k          │ ATLAS §0 + §1 + ToC  │ 0 tool calls
 │ read x5      │ 50k          │ (already in context) │
 │ grep         │ 20k          └──────────┬───────────┘
 │ clarify x3   │ 30k                     ▼
 └──────┬───────┘              ┌──────────────────────┐
        │                      │ Read one specific    │ 1–5k
        ▼                      │ module               │
 ┌──────────────┐              └──────────┬───────────┘
 │ start work   │                         ▼
 └──────────────┘              ┌──────────────────────┐
   ~150k tokens                │ start work           │
   ~20 tool calls              └──────────────────────┘
   ~5 minutes                   ~5–10k tokens
                                ~1–2 tool calls
                                ~10 seconds
```

### Honest caveats

- **Per-session fixed overhead of ~1.8k tokens** on every session, including trivial 1-turn ones. For < 5-turn tasks, that's net overhead. For anything bigger, it pays back many times over.
- **Codebase-size dependent.** Tiny project (< 20 files): ATLAS is light overhead. Medium (50–500 files): 5–15× orientation reduction is typical. Monorepo (5000+ files): the savings dwarf the overhead by 50–100×.
- **Runtime-dependent.** Claude Code hooks integrate cleanly. Codex / OpenCode / Cursor / Gemini / Zed read AGENTS.md-equivalent at session start. Pure inline Copilot autocomplete cannot be steered (smaller context model — adapter steers Chat only).
- **No published A/B benchmark yet.** The numbers above are estimates from observed orientation-phase token usage. A real controlled A/B (same task, same agent, with vs without ATLAS) is on the roadmap.

### Use cases where ATLAS pays back fastest


| Use case                                | Why ATLAS wins big                                                          |
| --------------------------------------- | --------------------------------------------------------------------------- |
| Large monorepo, multiple sub-agents     | Each agent gets oriented in 0 tool calls instead of repeating 10–20         |
| Multi-agent dispatch (lead → workers)   | Workers skip the orientation phase entirely; lead pays once                 |
| Long-running project, many contributors | SKILL anchors compound; new contributors / new agents learn from past scars |
| External agent + internal codebase      | The agent can't grep a codebase it doesn't know — ATLAS is the bridge       |
| CI / scheduled agents                   | The agent has no human to ask; ATLAS is its entire orientation              |


### Use cases where ATLAS is overkill


| Use case                              | Why                                                        |
| ------------------------------------- | ---------------------------------------------------------- |
| One-file script                       | The orientation phase is the whole task                    |
| Throwaway prototype                   | Maintenance value is zero; ATLAS overhead doesn't pay back |
| < 20-file project that rarely changes | Manual `ls` is fine; no compounding                        |


---

## ATLAS is working in your project when

- New agents stop asking *"where is X?"* — they read `ATLAS.md §0` instead.
- Commit messages cite `§ANCHOR-NAMES` instead of restating context.
- The same bug doesn't appear twice — its anchor exists and gets cited from the next attempt.
- Diff sizes match request sizes — no surprise refactors.
- *"What I did NOT change"* lines appear in agent reports.
- Onboarding a new engineer takes hours, not days — they read ATLAS+SKILL and they're oriented.

If you're hitting four of these six, ATLAS is paying for itself.

---

## Spec

The formal spec is at `[docs/SPEC.md](docs/SPEC.md)`. The short version:

- `**ATLAS.md` MUST live at repo root** and contain §0 (quick-orientation table), §1 module index, §7 cross-cutting concerns.
- `**SKILL.md` MUST live at `.agents/skill/<project>/SKILL.md`** with a Table of Contents linking to stable `§ANCHOR-NAME` anchors. Each anchor body: Symptom → Root cause → Do NOT → Do → Where → Commit SHA.
- **Anchors are immutable once published.** Rename = new anchor; old one becomes a redirect.
- `**CLAUDE.md`** behavior contract lives at repo root with an `**AGENTS.md**` mirror for runtimes that look for that name.
- **All four files updated in the same commit** as the structural change they describe.

---

## ATLAS vs other documentation patterns


| Concern                                                      | **ATLAS**  | `awesome-claude-prompts` | `CLAUDE.md` only | `ARCHITECTURE.md` only | None |
| ------------------------------------------------------------ | ---------- | ------------------------ | ---------------- | ---------------------- | ---- |
| Lives in the repo                                            | ✅          | ❌                        | ✅                | ✅                      | —    |
| Read by Claude / Codex / OpenCode / Hermes                   | ✅ all      | only Claude              | only Claude      | inconsistent           | none |
| Three orthogonal axes (structural / procedural / behavioral) | ✅          | ❌                        | behavioral only  | structural only        | —    |
| Stable anchors citable from commits                          | ✅ `§NAME`  | ❌                        | ❌                | ❌                      | —    |
| Auto-loaded on session start                                 | ✅ via hook | ❌                        | depends          | depends                | —    |
| Style presets (`karpathy`, `google`, `strict`, `minimal`, `default`) | ✅          | ❌                        | ❌                | ❌                      | —    |
| CLI for ADR / research / critique / cost / mirror            | ✅          | ❌                        | ❌                | ❌                      | —    |
| Cross-runtime (Claude / Codex / OpenCode / Hermes / generic) | ✅          | partial                  | ❌                | ❌                      | —    |
| Zero deps (bash only)                                        | ✅          | ✅                        | ✅                | ✅                      | —    |


ATLAS doesn't replace your CLAUDE.md — it formalises *where the rest of the docs go* and gives every agent the same Table of Contents.

---

## Examples

See [`examples/sample-project/`](examples/sample-project/) for a minimal quartet (a hypothetical TypeScript API project — `User vs Account` SKILL anchor, Postgres data model, runtime topology).

## Used by

<!-- Add yours! Open an issue or PR with your repo URL. -->

- _(your repo here)_

## FAQ

<details>
<summary><b>Why three files instead of one CLAUDE.md?</b></summary>

The three files cover orthogonal axes:

- **ATLAS.md** — *structural.* "Where does X live?"
- **SKILL.md** — *procedural.* "What did we learn the hard way?"
- **CLAUDE.md** + **AGENTS.md** mirror — *behavioral.* "How should the agent act?"

Most projects today have either a giant CLAUDE.md that mixes all three, or only the behavioral file. Mixing the axes makes each one worse: structure is too detailed for a system prompt; scars and rules don't belong in an architecture doc; behavior buried under module listings doesn't get read.

Three small files, three jobs, one cross-link convention.

</details>

<details>
<summary><b>How is this different from awesome-claude-prompts, llms.txt, AGENTS.md, etc.?</b></summary>

| | ATLAS | awesome-claude-prompts | llms.txt | CLAUDE.md / AGENTS.md only |
|---|---|---|---|---|
| Lives in your repo | ✅ | external | external | ✅ |
| Three orthogonal axes (structural / procedural / behavioral) | ✅ | ❌ | partial | behavioral only |
| Stable anchors citable from commits | ✅ `§NAME` | ❌ | ❌ | ❌ |
| Auto-loaded at session start | ✅ via hook | ❌ | varies | depends |
| Style presets | ✅ 5 | ❌ | ❌ | ❌ |
| CLI for ADR / research / critique / cost / mirror | ✅ | ❌ | ❌ | ❌ |
| Cross-runtime (9 adapters) | ✅ | partial | partial | partial |
| Zero deps (bash only) | ✅ | ✅ | ✅ | ✅ |

ATLAS isn't replacing your CLAUDE.md / AGENTS.md — it formalizes *where the rest of the docs go* and gives every agent the same Table of Contents.

</details>

<details>
<summary><b>Does it work with my agent runtime?</b></summary>

Out of the box: **Claude Code, Codex CLI, OpenCode, Cursor, Gemini CLI, Zed, GitHub Copilot Chat, Hermes**, plus a `generic` adapter for anything that can read a file. Each adapter is a single bash script in `adapters/`. If yours isn't listed, open an issue with the **🔌 New runtime adapter** template — they're usually 30–60 lines.

</details>

<details>
<summary><b>How does it actually save tokens?</b></summary>

The SessionStart hook auto-prints `ATLAS.md §0 + §1` (~1.4k tokens) and `SKILL.md`'s Table of Contents (~0.4k tokens) — about **1.8k tokens before the first tool call**.

Without ATLAS, the agent typically runs `ls`, `find`, `git ls-files`, opens 3–5 files, and asks 3–5 clarifying questions to orient itself — adding up to ~55–180k tokens across 10–30 tool calls.

Net: **12.8× orientation reduction ([measured](docs/benchmarks/RESULTS.md), 92%) on this repo** — scaling toward 30× on large codebases; ~10–25% on total session cost *(estimate)*. See the [Performance section](#performance--how-much-does-atlas-actually-save) for the full breakdown + honest caveats.

</details>

<details>
<summary><b>What about agents that aren't allowed to read arbitrary files at startup?</b></summary>

The hook is one option. The other is: include the ATLAS §0 + SKILL ToC inline in the agent's system prompt. The `adapters/hermes/install.sh` shows the system-prompt-fragment pattern. Every runtime has *some* way to inject project context — ATLAS just gives that injection a stable shape.

</details>

<details>
<summary><b>Doesn't this become outdated as the code changes?</b></summary>

That's why the spec requires **`ATLAS.md` updated in the same commit as any structural change** (SKILL §ATLAS-IS-INDEX). The `atlas check` command validates the file still parses; the CI integration documented in `docs/INTEGRATIONS.md` fails the build if a structural diff isn't matched by an ATLAS update.

A stale ATLAS is worse than no ATLAS — the spec is opinionated about this on purpose.

</details>

<details>
<summary><b>Why bash? Why not a "real" language?</b></summary>

Three reasons:

1. **Zero install dependencies.** Every system ATLAS targets has bash. No Node-version mismatch, no Python virtualenv, no Rust toolchain. Just `curl | bash`.
2. **The CLI is small.** ~2000 lines of bash is readable, debuggable, and forkable. A Node/Python rewrite would be 3–5× larger.
3. **The bash CLI calls out to the right tools when needed.** `git`, `gh`, `glab`, `codex`, `claude`, `jq` — they're already installed on dev machines.

If you want a Python or Node port, fork it — but the philosophy is "minimum infrastructure to ship a convention."

</details>

<details>
<summary><b>Is this just AGENTS.md with extra steps?</b></summary>

AGENTS.md is one file: behavioral. ATLAS is three files (structural + procedural + behavioral) + a CLI + style presets + runtime adapters + a spec. ATLAS *includes* an AGENTS.md mirror (`CLAUDE.md` is the canonical, `AGENTS.md` is the byte-identical mirror) so Codex / OpenCode / Cursor pick it up natively.

If you want to start with just `CLAUDE.md` and ignore the rest, fine — the spec is opt-in section by section. But the orientation savings come from §0 + §1 + the SKILL ToC, not from the behavior file alone.

</details>

---

## License

MIT — see [LICENSE](LICENSE). Use freely in commercial, OSS, or private agent stacks.

## Contributing

Cross-project lessons applicable to most codebases → PR them into `[templates/SKILL.md.tmpl](templates/SKILL.md.tmpl)`. New runtime adapters → drop into `[adapters/<name>/](adapters/)`. New style presets → drop into `[templates/styles/<name>/](templates/styles/)`. See `[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)`.

---

## Star history

[Star History Chart](https://star-history.com/#Abbasi-Alain/atlas&Date)

---

*ATLAS is a convention as much as it is code. Spread it.*

**⭐ if you'd use this in your next project. Open an issue if you wouldn't — that's how the spec improves.**
