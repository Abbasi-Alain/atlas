# Launch kit — copy/paste ready

Three formats for the same story. All numbers are reproducible (`atlas measure`),
so the post is honest by construction.

---

## 1) Show HN (title + body)

**Title:** `Show HN: ATLAS – a 4-file map that cuts AI-agent orientation tokens 75–94%`

**Body:**

> Every time an AI coding agent (Claude Code, Cursor, Codex, OpenClaw…) enters a
> repo, it burns tokens just figuring out *where things are* — grepping, reading
> the README, skimming file trees — before it does any real work. On a big repo
> that "orientation tax" is most of the cost.
>
> ATLAS is a tiny standard to pay it once: four Markdown files — a project **map**
> (where things live), a **playbook** (how to do tasks), a **scars** file (what
> breaks), and a behavioral contract — that the agent reads first instead of
> grepping. Zero infrastructure: no vector DB, no embeddings, no API key.
>
> I didn't want to claim a number, so I measured it. The deterministic
> `atlas measure` (tokenize a fixed context, locally — reproducible) on repos
> you'll recognize, after a one-command `atlas onboard`:
>
> ```
> openclaw     −94%      fastapi   −89%
> graphify     −93%      express   −81%
> ECC          −92%      django    −78%
> claude-mem   −85%      curl      −78%
> hermes-agent −82%      flask     −75%
> ```
>
> **−75% to −94% vs a smart skim**, and 100×–5000× vs dumping the whole repo into
> context. The bigger the repo, the bigger the win — the map stays ~constant.
>
> It also exposes the map over **MCP** (so any agent reads it), keeps itself
> current with a git hook, and comments the savings on every PR. Install:
> `npm i -g @alainabbasi/atlas` (also brew/apt/AUR).
>
> Honest caveats: the "with ATLAS" spine in the table is the *auto-drafted* map
> (a hand-tuned one is tighter); and the whole-repo column is an upper bound. The
> −75–94% vs a smart skim is the number I'd stand on. Reproduce in ~30s:
>
> ```
> git clone --depth 1 https://github.com/fastapi/fastapi && cd fastapi
> atlas onboard && atlas measure
> ```
>
> Repo + the full table: https://github.com/Abbasi-Alain/atlas

---

## 2) Blog post — "I benchmarked the agent-context field"

**Hook.** Vector search, code graphs, session memory — the agent-tooling space is
exploding, and every tool claims it "reduces context." Almost none publish a
number you can reproduce. So I built a benchmark and ran it on the tools
themselves.

**The wedge.** Most tools attack the *deep* problem (semantic search over the
whole codebase) and need infra to do it — Milvus, Neo4j, embeddings. ATLAS
attacks the *first* problem: the 5 seconds an agent spends orienting. That's a
static, human-curated map — 4 Markdown files, zero infra.

**The method (reproducible).** `atlas measure` tokenizes two fixed contexts: what
an agent skims to self-orient (README + file tree + source heads) vs the ATLAS
spine (§0 map + the playbook/scars tables of contents). Same bytes → same count,
every time. No agent, no API, no spend. [link methodology]

**The data.** [the FLAGSHIP table]

**The honest part.** It's an *orientation*-surface measure, not whole-task success.
Real agents are lazier than a full skim, so the realized end-to-end saving is
smaller and noisier — I publish those agentic runs too, labeled directional. And
the whole-repo baseline is a strawman; the vs-smart-skim number is the fair fight.

**The takeaway.** ATLAS isn't competing with the graph/vector tools — it's the
layer that runs *first* and routes to them when you need depth. Orient free, drill
down via whatever you've got.

---

## 3) Thread (X / LinkedIn)

1/ Your AI agent burns most of its tokens just figuring out *where things are* in
your repo — before it writes a line. I measured that "orientation tax" on 12
famous repos. A 4-file Markdown map cuts it **75–94%.** 🧵

2/ Not a vibe — a reproducible number. `atlas measure` tokenizes a fixed context
locally. openclaw −94%. fastapi −89%. django/curl −78%. Zero infra, zero API key.

3/ How: instead of grepping, the agent reads ATLAS.md (where things live) +
SKILL.md (how) + SCARS.md (what breaks) first. The map stays ~constant; the repo
grows → the win grows.

4/ It speaks MCP (any agent reads it), keeps itself current with a git hook, and
comments the savings on every PR. It even *routes* deep queries to graphify /
CodeGraphContext when you have them — orient free, drill down via the rest.

5/ Reproduce in 30s:
`git clone --depth 1 https://github.com/fastapi/fastapi && cd fastapi`
`atlas onboard && atlas measure`
→ github.com/Abbasi-Alain/atlas

---

## Where to post
- **Show HN** (Tue–Thu, ~8–10am ET). Reply to early comments fast.
- **r/LocalLLaMA, r/ChatGPTCoding, r/programming** — lead with the table.
- **X/LinkedIn** thread, tagging the measured tools *positively* (they're the proof, not the target).
- The agent-tool Discords (OpenClaw, etc.) — as "I measured your repo, here's the number," not "use my thing."
