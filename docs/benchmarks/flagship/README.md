# Flagship measurements — dated history

Deterministic `atlas measure` runs on real, famous repos, kept as dated history
so they're reproducible and comparable over time.

- **`YYYY-MM-DD-flagship.jsonl`** — a dated snapshot (one line per repo). See
  [`../FLAGSHIP.md`](../FLAGSHIP.md) for the rendered table.
- **`measure-history.jsonl`** — a rolling log. Append to it from any repo with:

  ```bash
  atlas measure --log
  ```

  Each line records `date · atlas_version · repo · files · skim_tok · spine_tok ·
  whole_tok · pct_vs_skim · pct_vs_whole`.

All numbers are the **deterministic** estimate (`bytes ÷ 4`), zero-API and
reproducible — distinct from the agentic/`openai` runs in
[`../RESULTS.md`](../RESULTS.md).
