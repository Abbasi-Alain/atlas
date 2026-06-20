# ATLAS specification — v0.1

> Four files (plus one mirror). Fixed names. Fixed structure. Machine-readable, human-readable. The whole point is that any agent — Claude, Codex, OpenCode, Hermes, anything — can rely on them being where they are and structured the way they are.

---

## 1. The quartet

```
<repo-root>/
├── ATLAS.md                              ← structural   (where things live)
├── SCARS.md                              ← failure memory (what breaks / not to repeat)
├── CLAUDE.md                             ← behavioral   (how to act)
├── AGENTS.md                             ← mirror of CLAUDE.md (Codex / OpenCode)
├── EXAMPLES.md  (optional but recommended)  ← teaching by transform pairs
└── .agents/
    └── skill/
        └── <project-name>/
            └── SKILL.md                  ← procedural   (how to do common tasks)
```

- `ATLAS.md` **MUST** be at the repo root.
- `SCARS.md` **MUST** be at the repo root. It holds the stable `§ANCHOR` failure
  memory (symptom → root cause → do NOT → do). Read before fixing a bug.
- `CLAUDE.md` **MUST** be at the repo root if the project targets Claude or wants opinionated behavior. `AGENTS.md` SHOULD mirror `CLAUDE.md` byte-for-byte so Codex/OpenCode/other AGENTS-aware runtimes auto-discover.
- `SKILL.md` **MUST** be at `.agents/skill/<project-name>/SKILL.md`, where `<project-name>` is the kebab-cased git remote basename (or repo-root basename if no remote). It holds procedural task recipes (how-to).
- `EXAMPLES.md` is OPTIONAL but strongly recommended — teaches the conventions by transformation pairs (vague→concrete, bad→good).
- All required files **MUST** be UTF-8 Markdown and checked into version control.

**Reading order (orientation).** An agent orients in this order: `ATLAS.md`
(*where things live*) → `SCARS.md` (*what breaks — read before fixing a bug*) →
`SKILL.md` (*how to do common tasks*) → `CLAUDE.md`/`AGENTS.md` (*how to act*).
Any orientation surface ATLAS generates — the `llms.txt` "read these first" list
and the SessionStart hook — **MUST** include `SCARS.md`, not just the map and
playbook, so the failure anchors actually surface.

### Axes

The quartet covers four orthogonal axes. Conformance means addressing each:

| Axis | File | Question it answers |
|---|---|---|
| Structural | `ATLAS.md` | *Where is X?* |
| Procedural | `SKILL.md` | *How do I do X here?* |
| Failure memory | `SCARS.md` | *What did we learn the hard way?* |
| Behavioral | `CLAUDE.md` / `AGENTS.md` | *How should the agent act?* |

---

## 2. ATLAS.md — required structure

ATLAS.md has numbered top-level sections. **Numbering is fixed** so cross-project agents know where to look. Sections marked OPTIONAL may be deleted; required sections may not.

| § | Title | Status |
|---|---|---|
| 0 | Quick orientation | **REQUIRED** |
| 1 | Top-level files | **REQUIRED** (split into 1.1 code-relevant + 1.2 project documents) |
| 2 | Source | OPTIONAL if no source dir |
| 3 | Service / runtime layer | OPTIONAL if no long-running processes |
| 4 | Front-end / UI | OPTIONAL if no UI |
| 5 | Tests | **REQUIRED** if tests exist |
| 6 | Docs | OPTIONAL |
| 7 | Cross-cutting concerns | **REQUIRED** |
| 8 | Environment variables | OPTIONAL |
| 9 | Edit-and-where rules of thumb | OPTIONAL |
| A | Architecture references (A1 diagrams, A2 rationale, A3 ADR index, A4 roadmap) | OPTIONAL |
| G | Glossary | **STRONGLY RECOMMENDED** for any domain-heavy project |
| D | Data model (D1 entities, D2 schemas, D3 backends) | OPTIONAL |
| X | External dependencies | **STRONGLY RECOMMENDED** |
| R | Runtime topology | OPTIONAL if no services |
| O | Observability | **STRONGLY RECOMMENDED** for production systems |
| Sec | Security boundaries | **STRONGLY RECOMMENDED** for any auth surface |
| B | Build & deploy (B1-B5) | **STRONGLY RECOMMENDED** |

### Section 0 (Quick orientation)

A two-column table mapping "You want to …" → "Start here" with file links. This is the most-read section; keep it terse and complete.

### Section 1.1 (Top-level code-relevant)

A `| Node | Role | Talks-to |` table. Every important top-level file gets one row. The `Talks-to` column lists other files (Markdown links) this one calls or depends on — building the graph.

### Section 1.2 (Project documents)

Pointers to ARCHITECTURE.md, ADRs, ROADMAP, TODO, CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, FAQ, GUIDE, GLOSSARY, LICENSE — **if they exist**. Delete rows for absent files. Do not duplicate content from these into ATLAS.

### Sections 2-9 (project body)

Each section uses `| Node | Role | Talks-to |` tables to map modules. Subsections are encouraged (2.1, 2.2, …); their numbering is per-project, not standardized.

### Section A (Architecture references)

A short router. A1 diagrams, A2 rationale, A3 ADRs (with `# | Title | Status | Date` table), A4 roadmap. ADRs are immutable once accepted — supersede by writing new ones.

### Sections G/D/X/R/O/Sec/B (universal concerns)

These are *cross-language, cross-domain* concerns every nontrivial project has. Their alphabetic-letter naming (instead of more numbers) signals they're not project-tree sections.

### Section 0 must include

A row pointing at `.agents/skill/<project>/SKILL.md` for "Debug a known issue".

---

## 3. SCARS.md — required structure

> **`SKILL.md` required structure (minimal):** an H1 title **and** a
> `## Table of contents`. The recipe bodies below the ToC are otherwise
> free-form — SKILL has no fixed `§ANCHOR` schema. The ToC is required (not
> optional): the SessionStart orientation hook and `atlas measure` read it as
> the playbook's navigational index, so `atlas check` enforces it. The
> structured `§ANCHOR` failure-memory schema described below belongs to
> **SCARS.md**, not SKILL.md.

### 3.1 Header
- H1 title: `# SCARS — <project-name> hard-won failure memory`
- Quote-block intro pointing to ATLAS.md.

### 3.2 Table of Contents
- H2: `## Table of contents`
- Bullet-list entries of form: `- [§ANCHOR-NAME — one-line summary](#anchor-name)`
- Group bullets under bolded category headings: `**Process / hygiene**`, `**Operations**`, `**Security**`, `**Performance**`, `**Data integrity**`, `**Observability**`, `**Concurrency**`, `**Domain-specific**`, …
- New SCARS.md scaffolds include the universal **Process / hygiene** category with these anchors: `§NO-COAUTHOR`, `§ATLAS-IS-INDEX`, `§MAINTAIN-DOCS`, `§SMOKE-AFTER-CHANGE`, `§ADR-BEFORE-MAJOR`.

### 3.3 Anchors
- Anchor name format: `§ANCHOR-NAME` (uppercase, kebab-separated). The HTML anchor is the lowercase form.
- Each section starts with `<a id="anchor-name"></a>` followed by `### §ANCHOR-NAME — one-line summary`.
- Anchor bodies MUST have these labelled paragraphs in order:
  1. `**Symptom.**` — what the user/agent observes.
  2. `**Root cause.**` — why it happens.
  3. `**Do NOT.**` — anti-patterns.
  4. `**Do.**` — correct pattern (code or steps).
  5. `**Where.**` — file:function or path pointer.
  6. `**Shipped in.**` — commit SHA (or `<pending>`).
- Optional `**Why.**` (extra rationale), `**Implementation.**` (longer code), `**Tests.**` (test file pointer).

### 3.4 Anchor stability
- Anchors are **immutable once shipped**. To rename, create a new anchor and leave the old one as a redirect:
  ```
  <a id="old-anchor"></a>
  ### §OLD-ANCHOR — superseded by §NEW-ANCHOR
  Redirects to [§NEW-ANCHOR](#new-anchor).
  ```
- Anchors deleted entirely break inbound citations from commits/PRs — only do this for genuinely obsolete entries.

### 3.5 Appendix (commit-anchor index)
- A `| SHA | Anchor |` table at the bottom listing every commit and which anchors it relates to. Lets agents jump from `git log` to the SKILL entry.

---

## 4. Conventions

### 4.1 The one-commit rule
A structural change (new module, new service, new dependency, file move across §-boundaries) **MUST** update ATLAS.md in the same commit. SKILL §ATLAS-IS-INDEX enforces this. A stale ATLAS is worse than no ATLAS.

### 4.2 Citing anchors
In commit messages, PR titles/bodies, code comments where unavoidable, and in prompts you give sub-agents — cite anchors by their name:

```
fix: prevent CVD freeze in pre-market

Reverts the global Lee-Ready tick test in favor of the
leading-zero-only intra-bar fallback. SKILL §LEE-READY-LEADING-ZERO-ONLY.
```

### 4.3 What does NOT belong in SKILL.md
- General Markdown notes ("we should consider X") — those go in `TODO.md` or ADRs.
- Step-by-step tutorials — those go in `docs/GUIDE.md`.
- API documentation — that lives in code docstrings and `docs/API.md`.
- "Lessons learned" without a concrete file pointer or repro — anchors **must** be actionable.

### 4.4 When to add an anchor
Add an anchor when **you would warn the next agent**. Concrete trigger:
- You spent more than 30 minutes debugging it.
- Your fix touches `Do NOT` territory (something looks right but isn't).
- The root cause is not obvious from reading the code post-fix.
- An external API has a non-obvious gotcha.

If you wouldn't warn anyone, it doesn't need an anchor.

---

## 5. Behavioral file — CLAUDE.md / AGENTS.md

The behavioral file is opinionated and short. It tells the agent **how to act**, not what to read. Recommended structure (the `default` template is ~150 lines, the `karpathy` preset is ~50):

1. **Three-rule lede.** Mantras the agent can quote in PR reviews: *"Don't grep. Don't guess. Don't repeat."*
2. **Think before coding.** State assumptions, surface tradeoffs, ask when unclear.
3. **Simplicity first.** Minimum code, no speculative features, no unrequested flexibility.
4. **Surgical changes.** Touch only what the brief requires; don't refactor adjacent code.
5. **Goal-driven execution.** Vague briefs → concrete tests with success criteria.
6. **Commit hygiene.** Cite SKILL anchors. Update ATLAS in the same commit as structural changes. No AI attribution.
7. **Reporting back.** *What changed* AND *what I did NOT change* (boundaries matter).
8. **Success criteria.** A measurable definition of "working" — onboarders read it and verify against their own repo.

The `AGENTS.md` mirror exists for runtime compatibility (Codex / OpenCode / etc. look for `AGENTS.md`). Keep them byte-identical. The `atlas init` CLI sets up the mirror automatically.

---

## 6. Validation

`atlas check` reports two severities: **errors** (spec MUST violations that break
cross-tool reliance) fail the check (exit 1); **warnings** (SHOULD / conditional
MUST) are advisory and still pass (exit 0).

**Errors — must fix:**
- `ATLAS.md` exists at repo root and has a §0 quick-orientation.
- `SKILL.md` exists at `.agents/skill/<project-name>/SKILL.md` and has a `## Table of contents`.
- `SCARS.md` exists at repo root, has a `## Table of contents`, and all its `§ANCHOR` IDs are unique.

**Warnings — should fix:**
- `CLAUDE.md` is present (the behavioral contract; a MUST if the repo targets Claude).
- `AGENTS.md` is present and **byte-identical** to `CLAUDE.md` (`cmp -s`).
- The `SKILL.md` directory equals the kebab-cased project name (`.agents/skill/<kebab>/`), so every runtime resolves the same path.

`atlas init` is **non-destructive**: it scaffolds only the missing quartet files
and never overwrites an existing file without `--force` — so `check`'s
remediation hint (*"run 'atlas init'"*) is safe to follow on a populated repo.

`atlas check --json` emits the same result as a machine-readable object
(`{ok, errors[], warnings[], quartet{…}}`, each finding carrying a stable
`code`) so any CI or agent can consume conformance programmatically; `--strict`
promotes warnings to errors (exit 1) for CI gating. `atlas fix` auto-resolves the
warnings it can — renaming a non-kebab `SKILL.md` directory, re-mirroring a
drifted `AGENTS.md`, and regenerating a stale `llms.txt`.

Future versions will also check:
- Every anchor in the ToC has a body.
- Every anchor body has the six required `**Label.**` paragraphs.
- File-path references in `**Where.**` resolve.

---

## 7. Versioning

This spec is versioned as `v0.1`. Backwards-incompatible changes bump the major. The CLI's `atlas check` will reject files that declare a higher major than it understands.

To declare conformance, add a comment to the top of ATLAS.md:

```html
<!-- atlas: v0.1 -->
```

This is optional in v0.1 but will be required from v1.0 onward.

---

## 8. Autonomous loop — `LOOP.md` + `ROADMAP.md` (OPTIONAL 5th surface)

The quartet (§1) is the **static** knowledge — *where* things live, *what* breaks,
*how* to do tasks, *how* to act. An OPTIONAL fifth surface captures the **dynamic**
process: how an agent **continuously improves** the repo without a human in the
loop. It is opt-in (`atlas init --loop`); a repo without these files is fully
conformant and unaffected.

- `LOOP.md` **MUST** be at the repo root if present. It is the loop rulebook +
  one-command entrypoint. Minimal required structure: an H1 title. It should carry
  the loop's mechanisms (see below).
- `ROADMAP.md` **MUST** be at the repo root if present. It is the EV-ranked task
  queue. Minimal required structure: a `- [ ]` / `- [x]` checkbox queue and a
  **Done** log; each item should record *why · how + entry-points · impact · test
  · complexity · difficulty*.

**Loop mechanisms** (the battle-tested rules the template bakes in):
1. anti-churn pre-flight (grep + verify before building — never rebuild);
2. EV-ranked selection (`edge × P(real) × leverage ÷ cost`, not queue order);
3. novelty mandate (≥1 new falsifiable hypothesis per iteration);
4. self red-team before commit (overfit / leakage / honesty);
5. measure-then-gate (descriptive first; wire to behavior only after OOS validation);
6. grow `SCARS.md` on every new failure mode;
7. difficulty routing (escalate `hard` items to a stronger model / sub-agent);
8. `atlas check --strict` as the per-commit conformance gate.

`atlas check` validates `LOOP.md`/`ROADMAP.md` **only when present** (warnings, like
the behavioral files) and reports them under `"loop"` in `--json`: it warns on a
`LOOP.md` with no H1, a `ROADMAP.md` with no `- [ ]` queue or no **Done** log, and
on a half-configured loop (one of the pair present without the other). The
SessionStart hook surfaces a one-line pointer, and the `llms.txt` export lists
`LOOP.md` in its read-first set, when a repo has a loop.
