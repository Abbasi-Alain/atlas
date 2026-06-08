# ATLAS benchmark ledger

Every `atlas bench` run is appended here (newest last) for longitudinal comparison —
track ATLAS's orientation-token reduction across versions, repos, models, and dates.
Source of truth: `results/ledger.jsonl`. Per-run detail: the linked report.

| date | atlas version | runtime | model | effort | repo | metric | without | with | reduction pct | ratio |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-06-08T02:10:14Z | 0.1.4 | openai | qwen3.6-35b | default | Atlas@cf801fe | input_tokens | 16571 | 1297 | 92.2 | 12.78 |
| 2026-06-08T11:05:45Z | 0.1.5 | claude | claude-opus-4-8 | high | Atlas@34853fe | num_turns | 6 | 5 | 16.7 | 1.2 |
