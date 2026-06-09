# ATLAS roadmap

What's shipped is **complete and proven** for the *orientation surface* (−75–94%
on famous repos, measured). The honest open problem is the **agentic end-to-end
win**: a *raw auto-drafted* map doesn't beat an agent on a specific task (and can
add overhead) — the payoff needs a **good map**. So the through-line of the
roadmap is simple: **ATLAS should get better with usage.**

## Near-term

- **Make the map earn its keep agentically.** The deterministic surface shrinks
  92%; the realized agentic win depends on map *quality*. Tighten the auto-draft's
  §0 "where to look" (e.g. detect the validation/router/entry layers, not just the
  directory list) so a fresh map points at answers, not just structure.
- **Curation helpers** — `atlas` suggests §0 rows + SKILL anchors from the
  codebase (heuristics now; smarter later), so curating a great map is minutes.
- **More benchmark repos** in the flagship set (langgraph, langchain ✓; add more
  iconic ones over time) + an *agentic* flagship tracked honestly (curated vs auto).
- **More runtimes** in `atlas bench` / the MCP matrix as the field grows.

## The big bet — "ATLAS gets better by usage"

- **Learn from sessions.** Capture which files agents actually open to answer a
  task (via the MCP server / hooks), and **auto-enrich** the §0 map + suggest
  SCARS toward what's actually needed. The map converges on the team's real
  hot-paths — the auto-draft overhead problem solves itself over time.
- This is where the negative agentic result becomes the feature: usage data is
  exactly the signal a static auto-draft lacks.

## The deep layer (long-term) — graph + vector retrieval

ATLAS is the *orientation* layer (free, instant, always-on). For *deep* structural
and semantic queries it should route to a real engine — the MCP router already has
the seam (`atlas_graph` / `atlas_deepsearch` / `atlas_recall`).

- Evaluate **graph-RAG** approaches — LightRAG, nano-graphrag (HKU) — for the
  retrieval design.
- Back it with **FuseGraph / FuseRAG** (graph + vector + compression): orient free
  via ATLAS, drill down via FuseGraph when depth is needed. Kept a *bring-your-own*
  backend so ATLAS stays zero-infra by default.

## Always

- **Trust beats hype.** Publish the reproducible *surface* number; label agentic
  results directional; never dress a loss as a win (see the fastapi agentic run).
