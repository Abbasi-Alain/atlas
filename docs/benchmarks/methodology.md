# ATLAS benchmark methodology

> **Status: protocol, not results.** This file defines *how* to measure ATLAS's
> effect so the numbers are reproducible and defensible. No headline figures
> live here until a run produces them. The README's estimates are clearly
> labelled as estimates; this is the path to replacing them with evidence.

## Why

The claim "ATLAS reduces agent orientation cost" is only worth anything if it's
measured the same way twice. The goal is a public, re-runnable benchmark that
others can cite — not a marketing number.

## Two measurements (don't conflate them)

| | `atlas measure` (shipped) | `atlas bench` (roadmap) |
|---|---|---|
| What | Static byte/token estimate of the orientation *surface* | Live A/B: run real tasks with real agents |
| Cost | Instant, offline | Expensive (API + wall time) |
| Use | A quick proxy + a shareable badge | The citable result |

`atlas measure` compares the bytes of the ATLAS trio against a proxy for "what
an agent skims to self-orient" (README + file tree + heads of top source
files), at ~4 bytes/token. It is an **estimate** and says so. It is not a
substitute for the live benchmark below.

## The live protocol (`atlas bench`, to build)

Hold everything constant except the presence of ATLAS.

**Conditions** (same repo, same tasks, same model, N repetitions each):

- **A — none**: no repo-context file.
- **B — AGENTS.md only**.
- **C — CLAUDE.md only**.
- **D — README only**.
- **T — ATLAS** (trio + runtime exports).

**Inputs**: a fixed repo at a pinned SHA; a fixed task list (e.g. "add an OAuth
provider", "fix failing test X", "add endpoint Y"); one agent runtime; one
model; a token budget; ≥5 repetitions per (condition × task) to get a spread.

**Metrics** (per run, logged to JSON):

```
orientation_tokens   tokens consumed before the first file edit
total_input_tokens   whole-task input tokens
tool_calls           number of tool invocations
files_opened         distinct files read
wrong_file_edits     edits later reverted / outside the target module
test_pass            did the task's acceptance test pass?
correction_turns     user/self correction turns
final_diff_lines     size of the accepted diff
wall_time_s
```

**Report**: mean ± stdev per metric per condition, plus the deltas T vs A/B/C/D.
Publish raw JSON so anyone can recompute.

## Layout (when results exist)

```
docs/benchmarks/
  methodology.md          # this file
  tasks/                  # task definitions + acceptance tests
  results/                # per-run JSON (committed)
  results-<runtime>.md    # human-readable summaries
```

## Honesty rules

1. No number in the README without a committed run behind it.
2. Report variance, not just the mean.
3. Compare *against* AGENTS.md/CLAUDE.md/README — ATLAS is a complement, and the
   benchmark should show where it does and doesn't help.
4. If a condition wins on a metric, say so.
