# ATLAS benchmark ledger

Every `atlas bench` run is appended here (newest last) for longitudinal comparison —
track ATLAS's orientation-token reduction across versions, repos, models, and dates.
Source of truth: `results/ledger.jsonl`. Per-run detail: the linked report.

| date | atlas version | runtime | model | effort | repo | metric | without | with | reduction pct | ratio |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-06-08T02:10:14Z | 0.1.4 | openai | qwen3.6-35b | default | Atlas@cf801fe | input_tokens | 16571 | 1297 | 92.2 | 12.78 |
| 2026-06-08T11:05:45Z | 0.1.5 | claude | claude-opus-4-8 | high | Atlas@34853fe | num_turns | 6 | 5 | 16.7 | 1.2 |
| 2026-06-08T11:35:34Z | 0.1.5 | claude | claude-sonnet-4-6 | high | Atlas@da57423 | num_turns | 5 | 4 | 20.0 | 1.25 |
| 2026-06-08T11:46:02Z | 0.1.5 | claude | claude-haiku-4-5-20251001 | high | Atlas@da57423 | num_turns | 15 | 10 | 33.3 | 1.5 |
| 2026-06-08T11:48:37Z | 0.1.5 | codex | default | high | Atlas@da57423 | wall_s | 128 | 98 | 23.4 | 1.31 |
| 2026-06-08T13:32:22Z | 0.1.5 | codex | default | high | Atlas@4ac3bb2 | num_turns | 8 | 7 | 12.5 | 1.14 |
| 2026-06-08T15:37:19Z | 0.1.5 | opencode | qwen3.6-35b | high | Atlas@cd25137 | wall_s | 141 | 99 | 29.8 | 1.42 |

> **Reading this table.** `openai` rows are the **deterministic single-shot** headline — tokenize a *fixed* context once (reproducible, model-independent) — the source of **−92% / 12.8×**. `claude` (agentic) rows are a live task loop: metric = **turns** (lower-is-better), N per `reps`, **directional**. Their cost/wall vary with model, task, and repo size — on a tiny repo the quartet's fixed injection may not amortize, so agentic *cost* can rise even when turns fall. Don't headline agentic token counts (SCARS §BENCH-TOKEN-SUM-CACHE). See [methodology](methodology.md).
