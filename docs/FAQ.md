# FAQ — atlas project knowledge (Q&A ledger)

> The **ask-once file** (SPEC §13): questions a human asked and the answers
> (or surprising findings) an agent surfaced — answered **once, with
> pointers** — so the next session looks it up instead of re-deriving it.
> Check here before asking or investigating; append an entry (next `FAQ-NNN`
> id, append-only) whenever a question worth keeping gets answered.
> Conventions: [`templates/FAQ.md.tmpl`](../templates/FAQ.md.tmpl) ·
> [SPEC §13](SPEC.md#13-faqmd--the-qa-knowledge-ledger-optional-surface).

## Design decisions

### FAQ-001 · Q: Why is the whole CLI one bash file with zero dependencies? (2026-07-26)
- asked-by: maintainer (recurring, every new contributor/agent)
- tags: architecture, bash

Reach: `bin/atlas` must run on any POSIX machine an agent lands on — no
Python/Node/jq guaranteed, bash 3.2 (macOS default) as the floor. One file
keeps install = copy, and shellcheck-green is the whole static gate. See
SCARS `§BASH-MONOLITH` and trap T3/T9 in the EXECUTOR PACK.

### FAQ-002 · Q: Why does this repo git-ignore its own BUGS.md / CRITICS.md / ROADMAP.md when the standard scaffolds them public? (2026-07-26)
- asked-by: agent (session orientation, repeatedly)
- tags: conventions, privacy

Both are valid per the SPEC: those surfaces are validated only when present,
and a **git-ignored copy is an explicitly supported private choice** (SPEC
§9/§10; SCARS `§PRIVATE-STYLE-OVERLAY`). This repo keeps its own operational
queue private while shipping the public templates — `atlas check` skips the
link/staleness rules for git-ignored files, so both modes stay warning-free.

### FAQ-003 · Q: Why is the ready release (version bumped, CHANGELOG written) not tagged yet? (2026-07-26)
- asked-by: agent (before every release since v0.5.0)
- tags: release, process

A tag push triggers the FULL public fan-out — GitHub release, npm, brew, AUR,
PPA, and a **permanent** Zenodo DOI (SCARS `§TAG-TRIGGER-NOT-RELEASE`). Tag
pushes are therefore human-only, always: agents prepare the release and STOP.
`ATLAS_VERSION` + `package.json` bump together when they do move (SCARS
`§CLI-VERSION-DRIFT`).

## Measurement

### FAQ-004 · Q: Why does `atlas measure` estimate tokens as bytes ÷ 4 instead of tokenizing exactly? (2026-07-26)
- asked-by: human reviewers (paper + README)
- tags: measure, honesty

Exact tokenization is tokenizer-specific (per vendor, per model version), so
an "exact" number would be false precision that silently drifts; bytes ÷ 4 is
a stated, reproducible, vendor-neutral estimate — the same rule for both arms
of the comparison, so the *reduction* is fair even when the absolute counts
are approximate. The realized-savings question is measured separately by
`atlas bench` (turns/cost, not token guesses — SCARS `§BENCH-TOKEN-SUM-CACHE`).

### FAQ-005 · Q: Can `atlas` tell me whether my code-graph/context tools are safe to trust right now? (2026-07-26)
- asked-by: maintainer (ProximAgent dogfooding, 2026-07)
- tags: tools, freshness

Yes — that's the SPEC §14 tool context contract: `atlas init --tools` writes
`.atlas/tools.json` (canonical project id + the commit an indexer last
stamped), `atlas check --json` reports `"tools"` freshness (`--deep` warns
`TOOLS_INDEX_STALE` on drift), and `atlas measure --tools` adds worktree
state, dead-preload env detection, and the telemetry ledger aggregates in one
report.
