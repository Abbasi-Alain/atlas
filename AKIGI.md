# AKIGI — why atlas exists

> **What this is.** The repo's purpose contract — its *ikigai*. ONE document,
> read the same way by three audiences: **humans** deciding whether to adopt
> or contribute, **this repo's own agents** triaging what to build next, and
> **outside agents** (from sibling repos) deciding whether — and how — to ask
> this repo for something. If a request doesn't serve the Purpose below, it
> gets declined, no matter how good it is; that's what makes autonomous
> triage trustworthy. Requests are filed in [`FRQ.md`](FRQ.md) (SPEC §11).

## Purpose

ATLAS is the **project-map standard for agentic codebases**: four fixed,
machine- and human-readable Markdown files (ATLAS.md · SCARS.md · SKILL.md ·
CLAUDE.md/AGENTS.md) that let ANY coding agent orient in a repository without
grep, guesswork, or repeated failure — plus one zero-dependency bash CLI that
scaffolds, validates, and *measures* that promise. ATLAS has succeeded when
agent runtimes treat the quartet the way browsers treat robots.txt/llms.txt:
a boring, universal contract that is simply there.

## Serves whom

- **Coding agents** — Claude Code, Codex, OpenCode, Cursor, Gemini CLI, and
  anything AGENTS.md-aware — orienting in repos that adopted ATLAS.
- **Repo maintainers** who want agents to stop re-learning their codebase
  (and re-making the same mistakes) every session.
- **Autonomous loops** — this repo's own LOOP/ROADMAP surface, and sibling
  repos running the same pattern (e.g. proxima-finance).
- **Researchers** citing the orientation-cost measurements (the paper, the
  leaderboard dataset, `atlas measure`/`bench`).

## Scope / Non-goals

**In scope:**
- The quartet + the optional surfaces (LOOP/ROADMAP · BUGS · CRITICS ·
  AKIGI/FRQ) and their SPEC.
- Conformance checking (`atlas check`), orientation measurement
  (`measure`/`bench`/leaderboard), scaffolding (`init`), runtime adapters and
  exports (Codex/Copilot/Gemini/Cursor/llms.txt), the MCP map server, and
  the packaging channels.

**Non-goals (will be declined even if well-argued):**
- Being an agent framework, runtime, or orchestrator — ATLAS documents repos;
  it does not run agents.
- AST/code-graph indexing in the core — deep code intelligence stays behind
  opt-in MCP backends; the CLI itself never grows heavy analysis.
- Network services, telemetry, or anything that breaks `curl | bash` + one
  offline bash file.
- Vendor lock — no feature may work only for one model vendor (tier routing
  stays capability-based, SPEC §8).
- New runtime dependencies in `bin/atlas` — it stays ONE shellcheck-green,
  bash-3.2-compatible, zero-dependency file (SCARS §BASH-MONOLITH).

## Acceptance principles

How incoming requests ([`FRQ.md`](FRQ.md)) are triaged, in order:

1. **Purpose-fit first.** Serves the standard (spec, validation, measurement,
   adoption) and lands In scope → this repo's agent may accept and implement
   autonomously. Touches a Non-goal → declined with the reason and an
   alternative (usually: an opt-in backend, adapter, or sibling tool).
2. **Evidence over assertion.** State the concrete blocker — the command that
   fails, the orientation cost you measured, the repo where it bit you.
3. **Escalation line.** The repo's agent decides alone: docs, templates, new
   opt-in `init` flags/surfaces, checks, tests, adapters. Maintainer only:
   version tags & releases (§TAG-TRIGGER-NOT-RELEASE — a tag push fans out to
   npm/deb/brew/AUR/PPA + a permanent DOI), packaging-channel changes,
   SPEC-breaking changes to shipped required structure, and anything the
   SCARS trap-sheet marks as scarred core.
4. **Reply always.** Every FRQ gets an inline disposition (resolved /
   declined with rationale) — a request that never hears back breaks the
   cross-repo loop.

## Values / constraints

- Zero runtime dependencies; portability scars are law (§MACOS-SED,
  §AWK-MULTILINE-V, §PRINTF-LEADING-DASH).
- Every capability claim is measured, never asserted (`atlas measure`,
  `atlas bench`, the smoke set gates every commit).
- Spec before code: a behavior change updates `docs/SPEC.md` + templates +
  CHANGELOG in the same commit.
- The public repo is the project's image: only verified, released features
  are public; loop internals stay local.
