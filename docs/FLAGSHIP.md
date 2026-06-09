# 🚩 ATLAS on famous repos — the proof

ATLAS's headline is measured on its own repo. Here's the *same* deterministic
**`atlas measure`** (reproducible, zero-API, no agent) run on repos you know —
after a one-command `atlas onboard` (an **auto-drafted** map, no hand-tuning).

## The AI-agent ecosystem (the tools you build agents with)

| repo | files | smart skim → ATLAS spine | vs smart skim | vs whole-repo dump |
|---|---|---|---|---|
| [openclaw/openclaw](https://github.com/openclaw/openclaw) | 19,878 | ~32,354 → ~2,035 tok | **−94%** | 3809× |
| [safishamsi/graphify](https://github.com/safishamsi/graphify) | 567 | ~19,711 → ~1,440 tok | **−93%** | 1671× |
| [affaan-m/ecc](https://github.com/affaan-m/ecc) | 3,143 | ~29,096 → ~2,190 tok | **−92%** | 2243× |
| [zilliztech/claude-context](https://github.com/zilliztech/claude-context) | 176 | ~11,653 → ~1,493 tok | **−87%** | 3129× |
| [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | 897 | ~12,125 → ~1,771 tok | **−85%** | 1784× |
| [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | 4,902 | ~12,589 → ~2,311 tok | **−82%** | 5283× |

## General famous repos

| repo | files | smart skim → ATLAS spine | vs smart skim | vs whole-repo dump |
|---|---|---|---|---|
| [fastapi/fastapi](https://github.com/fastapi/fastapi) | 2,978 | ~12,451 → ~1,398 tok | **−89%** | 3932× |
| [expressjs/express](https://github.com/expressjs/express) | 213 | ~7,136 → ~1,332 tok | **−81%** | ~130× |
| [django/django](https://github.com/django/django) | 7,063 | ~6,822 → ~1,533 tok | **−78%** | ~3500× |
| [curl/curl](https://github.com/curl/curl) | ~4,000 | ~7,730 → ~1,721 tok | **−78%** | 1961× |
| [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) | 665 | ~11,583 → ~1,314 tok | **−89%** | — |
| [langchain-ai/langchain](https://github.com/langchain-ai/langchain) | 2,898 | ~11,206 → ~1,366 tok | **−88%** | — |
| [gin-gonic/gin](https://github.com/gin-gonic/gin) | 130 | ~8,913 → ~1,930 tok | **−78%** | ~100× |
| [pallets/flask](https://github.com/pallets/flask) | 236 | ~5,428 → ~1,362 tok | **−75%** | ~150× |

**−75% to −94% vs a smart skim** (the conservative, fair-fight baseline) — and
**100×–5000× vs loading the whole repo** into context (what a naive RAG dump does).
The bigger the repo, the bigger the win; the spine stays ~constant.

## Reproduce — free, ~30s per repo

```bash
git clone --depth 1 https://github.com/openclaw/openclaw && cd openclaw
atlas onboard      # scaffolds the quartet + auto-drafts the map
atlas measure      # the numbers above
```

No agent, no API key, no spend — `atlas measure` tokenizes a *fixed* context
locally, so the result is reproducible and endpoint-independent.

> **Honest caveats.** These numbers measure the **orientation *surface*** — how
> much smaller the context an agent loads to self-orient becomes. They are **not**
> whole-task performance. In an N=1 *agentic* run on fastapi, a **raw auto-drafted**
> map actually made claude take *more* turns (it added context without pointing at
> the answer) — the agentic win needs a **hand-curated** §0 ("where X lives"), which
> the auto-draft isn't yet. So: the **−75–94% surface reduction is real and
> reproducible**; the end-to-end agentic payoff depends on map *quality* and grows
> as the map is refined (see [ROADMAP](ROADMAP.md) — "ATLAS gets better with usage").
> The whole-repo column is an upper bound (few tools load the entire repo).
