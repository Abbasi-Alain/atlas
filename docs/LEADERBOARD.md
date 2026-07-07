# 🏆 ATLAS leaderboard — biggest orientation-token savings

How much does ATLAS shrink the context an agent loads just to *orient* in your
repo? Run it and submit your number — one click:

```bash
atlas measure --share     # prints your row + a one-click GitHub-issue link
```

<!-- leaderboard:start -->
| repo | orientation tokens (without → with) | reduction | date |
|---|---|---|---|
| Abbasi-Alain/atlas | ~19105 → ~1341 tok | −93% to −99% | 2026-07-07 |
<!-- leaderboard:end -->

> The reduction is a **range** — *smart skim → whole-repo dump* (see the
> [methodology](benchmarks/methodology.md)). The deterministic single-shot
> benchmark on this repo measured **−92% / 12.8×** ([RESULTS](benchmarks/RESULTS.md)).

## Submit yours

1. `atlas measure --share` in your repo — prints your row + a one-click
   GitHub-issue submit link.
2. Or open a PR adding a row to [`data/leaderboard.csv`](../data/leaderboard.csv)
   (see its header for column order) — a maintainer runs
   `atlas leaderboard --render` to regenerate the table above before merging.

Keep it honest: `atlas measure` is reproducible, so anyone can re-run your number.
Bigger repos → bigger savings (the spine stays ~constant while the skim grows).
The table above is generated from `data/leaderboard.csv` — don't hand-edit it.
