# CLAUDE.md

> Behavioral contract for agents working in **atlas**.
> Pair with [`ATLAS.md`](ATLAS.md) (where things live),
> [`SCARS.md`](SCARS.md) (what breaks), and
> [`.agents/skill/atlas/SKILL.md`](.agents/skill/atlas/SKILL.md) (how to do tasks).
>
> Four files. One purpose: **don't grep, don't guess, don't repeat.**

A mirror of this file MUST also exist as [`AGENTS.md`](AGENTS.md) so Codex /
OpenCode / other runtimes that look for `AGENTS.md` find it. Keep them
identical. *(The `atlas init` CLI sets up the mirror automatically.)*

---

## 0. The three rules

**Don't grep.** If you reach for `find` or `grep` for orientation, you've already lost. Read [`ATLAS.md`](ATLAS.md) §0 first. Every important module is one click away.

**Don't guess.** If something is unclear, stop. State the ambiguity. Ask. Half the bugs in [`SCARS.md`](SCARS.md) started as a silent guess.

**Don't repeat.** Before fixing a bug, search [`SCARS.md`](SCARS.md) for the anchor. If we paid for this lesson once, we don't pay again.

---

## 1. Think before coding

**State assumptions explicitly. Surface tradeoffs.**

Before writing code:
- Read the relevant ATLAS section. Cite it back in your plan.
- If multiple interpretations of the request exist, list them. Don't pick silently.
- If a simpler approach exists, name it. Push back when warranted.
- If something is unclear, **stop and ask**. Mid-implementation realisation is the most expensive moment to clarify.

---

## 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- No backwards-compat shims when you can just change the code.

**The test:** *"Would a senior engineer reading this diff in six months ask 'why is this here?'"* If yes, simplify.

If you wrote 200 lines and it could be 50, rewrite it.

---

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd write it differently.
- If you notice unrelated dead code, *mention* it — don't delete it.

When your changes orphan something:
- Remove imports / variables / functions that **your** changes made unused.
- Don't remove pre-existing dead code unless explicitly asked.

**The test:** *"Does every changed line trace to the user's request?"* If not, the diff is too big.

---

## 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Transform vague tasks into verifiable goals:

| Vague | Concrete |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Existing tests pass before and after; behaviour unchanged" |
| "Improve perf" | "Benchmark shows ≥30% reduction in latency for endpoint Y" |
| "Clean up" | _(reject — ask for specifics)_ |

For multi-step tasks, write a brief plan with checkpoints:

```
1. <step>   → verify: <check>
2. <step>   → verify: <check>
3. <step>   → verify: <check>
```

Strong success criteria let you loop independently. Weak criteria ("make it work") guarantee back-and-forth.

---

## 5. Commit hygiene

**One change. One message. Cite the anchor.**

- Commit messages cite SKILL anchors when applicable: *"fix: guard the `&&` chain in measure under set -e — SCARS §SET-E-AND-AND."*
- Update [`ATLAS.md`](ATLAS.md) in the **same commit** as any structural change (new module, new dep, new service, file moves across §-boundaries).
- Run the smoke set before committing (command in `ATLAS.md` §5).
- No `Co-Authored-By: Claude …` or equivalent AI-assistant attribution — SCARS §NO-COAUTHOR.

---

## 6. Reporting back

**State what changed. State what you didn't change.**

Every non-trivial task ends with a report under 250 words:

```
## What changed
- file: <one line>

## What I did NOT change (and why)
- <thing>: <reason>

## Smoke
<last 2-3 lines of test output>

## New SCARS anchor (if any)
- §NAME — one-line summary

## Open items
- <thing>: <next step>
```

Boundaries matter as much as actions. Stating what you *didn't* touch prevents the next agent from undoing your scope decisions.

---

## ATLAS is working in your project when:

- New agents stop asking *"where is X?"* — they read ATLAS §0 instead.
- Commit messages cite `§ANCHOR-NAMES` instead of restating context.
- The same bug doesn't appear twice — its anchor exists and gets cited from the new attempt.
- Diff sizes match request sizes — no surprise refactors.
- "What I did NOT change" lines appear in reports.

---

*This file is part of the [ATLAS](https://github.com/Abbasi-Alain/atlas) standard. Spec: [docs/SPEC.md](https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md).*
