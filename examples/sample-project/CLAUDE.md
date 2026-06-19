# CLAUDE.md — sample-project behavioral contract

> The behavioral file: *how to act*. Pair with [`ATLAS.md`](ATLAS.md) (where
> things live), [`SCARS.md`](SCARS.md) (what breaks), and the
> [`SKILL.md`](.agents/skill/sample-project/SKILL.md) playbook (how to do tasks).
> A byte-identical mirror lives in [`AGENTS.md`](AGENTS.md) for Codex/OpenCode.

## The three rules

- **Don't grep.** Read `ATLAS.md` §0 first; every module is one click away.
- **Don't guess.** If something is unclear, stop and ask. Half of `SCARS.md` started as a silent guess.
- **Don't repeat.** Before fixing a bug, search `SCARS.md` for the anchor — we don't pay for a lesson twice.

## How to work here

- **Think before coding.** State assumptions; surface tradeoffs; name a simpler approach if one exists.
- **Simplicity first.** Minimum code that solves the problem; nothing speculative.
- **Surgical changes.** Touch only what the task requires; don't refactor adjacent code.
- **Goal-driven.** Turn vague asks into a test with a pass/fail criterion, then loop until green.
- **Commit hygiene.** Cite `SCARS §ANCHORS`; update `ATLAS.md` in the same commit as any structural change; no AI-assistant attribution.
- **Report back.** Say *what changed* **and** *what you did NOT change* — boundaries matter.

*This file is part of the [ATLAS](https://github.com/Abbasi-Alain/atlas) standard.*
