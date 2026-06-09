# 🏆 ATLAS leaderboard — biggest orientation-token savings

How much does ATLAS shrink the context an agent loads just to *orient* in your
repo? Run it and submit your number — one click:

```bash
atlas measure --share     # prints your row + a one-click GitHub-issue link
```

| repo | orientation tokens (without → with) | reduction | date |
|---|---|---|---|
| Abbasi-Alain/atlas | ~16,591 → ~1,225 tok | −93% to −99% | 2026-06-09 |

> The reduction is a **range** — *smart skim → whole-repo dump* (see the
> [methodology](benchmarks/methodology.md)). The deterministic single-shot
> benchmark on this repo measured **−92% / 12.8×** ([RESULTS](benchmarks/RESULTS.md)).

## Submit yours

1. `atlas measure --share` in your repo.
2. Click the printed link (opens a pre-filled GitHub issue) — or open a PR adding
   your row above.

Keep it honest: `atlas measure` is reproducible, so anyone can re-run your number.
Bigger repos → bigger savings (the spine stays ~constant while the skim grows).
