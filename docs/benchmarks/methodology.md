# ATLAS benchmark methodology

> **Status: protocol, not results.** This file defines *how* to measure ATLAS's
> effect so the numbers are reproducible and defensible. No headline figures
> live here until a run produces them. The README's estimates are clearly
> labelled as estimates; this is the path to replacing them with evidence.

## Why

The claim "ATLAS reduces agent orientation cost" is only worth anything if it's
measured the same way twice. The goal is a public, re-runnable benchmark that
others can cite — not a marketing number.

## Three measurements (don't conflate them)

| | `atlas measure` (shipped) | `atlas bench --runtime openai` (shipped) | `atlas bench --runtime claude\|codex\|opencode` (shipped) |
|---|---|---|---|
| What | Static byte/token estimate of the orientation *surface* | **Deterministic single-shot**: tokenize a fixed context (quartet spine vs raw repo) once, locally | Live agentic A/B: same task, full tool-use loop, with vs without the quartet |
| Metric | bytes → ~tokens | **`input_tokens`** (cl100k, local) | **turns / cost / wall** |
| Cost | Instant, offline | One API round-trip (or none — tokenized locally) | Expensive (full agent loop) |
| Reproducible? | Yes | **Yes** — same bytes → same count | No — model/effort/cache-dependent |
| Use | A quick proxy + a shareable badge | **The citable headline number** | Directional sanity check |

`atlas measure` compares the bytes of the ATLAS quartet against a proxy for
"what an agent skims to self-orient" (README + file tree + heads of top source
files), at ~4 bytes/token. It is an **estimate** and says so.

### Which token number is real? (a scar — SCARS §BENCH-TOKEN-SUM-CACHE)

The **headline −92% / 12.8×** comes from the *deterministic single-shot* mode:
it tokenizes a fixed context once, so the count is reproducible and endpoint-
independent (a local vLLM's own `usage` is recorded only as a cross-check — it
drifted under prefix caching).

Do **not** headline summed per-turn `input_tokens` from the agentic loop. Each
turn re-sends the whole cached context, so the sum grows with turns and counts
cache *reads* (priced ~10×) as fresh input — it can rise even as **cost falls**.
In the first claude run it nearly doubled (98.5k→195.7k) while the task finished
in **fewer turns (5 vs 6), 33% less wall-time, and ~10% lower cost**. So agentic
runs are reported on **turns / cost / wall** and logged as *directional*, never
as the token-reduction headline.

## The live protocol (`atlas bench`)

> The MVP is shipped: `atlas bench --runtime claude` (or `codex` / `opencode`) runs the
> two conditions below for the **ATLAS vs none** comparison and writes JSON.
> Extending it to the B/C/D baselines + more tasks is the next step.

Hold everything constant except the presence of ATLAS.

**Conditions** (same repo, same tasks, same model, N repetitions each):

- **A — none**: no repo-context file.
- **B — AGENTS.md only**.
- **C — CLAUDE.md only**.
- **D — README only**.
- **T — ATLAS** (trio + runtime exports).

`--matrix "model-a,model-b"` repeats the same two-condition protocol for each
listed model. The normal summary ledger keeps one comparison row per model; the
raw matrix ledger (`results/matrix-ledger.jsonl`) records one row per
model × condition × repetition so the free local model matrix can be recomputed
without rerunning agents.

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
