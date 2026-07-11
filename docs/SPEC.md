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
- `SKILL.md` exists at `.agents/skill/<project-name>/SKILL.md` and has a `## Table of contents` with at least one entry (`SKILL_TOC_EMPTY` — a heading with nothing listed beneath it is the same failure as no ToC at all).
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

`atlas check --deep` adds opt-in anchor-body conformance for `SCARS.md` (all
warnings, so it never breaks an existing repo unless paired with `--strict`):
- Every anchor in the ToC has a matching `<a id>` body (`ANCHOR_TOC_NO_BODY`)
  and every body anchor is linked from the ToC (`ANCHOR_NOT_IN_TOC`).
- A scar that states a problem (`**Symptom.**` / `**Root cause.**`) also gives a
  remedy (`**Do.**` / `**Do NOT.**`) (`ANCHOR_NO_REMEDY`).
- File-path references in `**Where.**` resolve on disk; glob patterns are skipped
  (`ANCHOR_WHERE_UNRESOLVED`).

Schema examples inside code blocks (fenced or indented) are ignored, so a SCARS
file may document how to write a scar without tripping its own deep check.

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

### EXECUTOR PACK — cross-model handoff (optional enrichment of `ROADMAP.md`)

Strong-model planning + weak-model execution is the only affordable way to run
long autonomous loops, but a weaker executor fails in specific, avoidable ways:
repo-specific landmines it has no way to know about, over-claiming success
without the test that would falsify it, and architectural drift ("improving"
scarred code whose shape is load-bearing). The **EXECUTOR PACK** is a block at
the top of `ROADMAP.md` that packages `SCARS.md`'s accumulated knowledge into a
handoff any executor reads once, before its first ticket.

- Required fields when a pack is present:
  1. **Ticket→spec pointer convention** — tickets point at specs (a design doc,
     ADR, or the ticket's own why/how); an executor never restates or
     re-scopes them.
  2. **Trap-sheet** — a numbered list derived from `SCARS.md`, each row citing
     its anchor (`§ANCHOR`) — the traps an executor would otherwise rediscover
     at the cost of a broken commit.
  3. **Per-ticket model/tier tag** — which capability tier a ticket needs
     (mechanical/well-spec'd · cross-cutting/subtle-correctness ·
     spec-design/scarred-core-surgery), so routing doesn't depend on a human.
  4. **Universal Definition of Done** — the checks every ticket must pass
     regardless of which model executes it (test suite green with a new
     regression test, `atlas check --deep --strict`, docs/spec updated
     coherently, one commit citing anchors).
  5. **Escalate-up protocol** — when a ticket exceeds an executor's tier (two
     failed approaches, a DoD check it cannot make pass, or the ticket turns
     out to touch a scarred core): revert to a clean tree, annotate the ticket
     `blocked: <tier> <UTC> — <reason + failing evidence>` and bump its
     difficulty, log what was learned so the next executor doesn't repeat the
     failed approach, then take the next in-tier ticket. A clean escalation
     with evidence is a successful outcome, not a failure — verifying
     correctness is easier than designing it, so even an executor that
     couldn't have designed a ticket can usually prove whether an
     implementation satisfies it.
- The pack is OPTIONAL. A repo with `LOOP.md`/`ROADMAP.md` but no pack is not
  flagged by a plain `atlas check` — the pack is a scaling aid for repos
  running enough autonomous iterations that `SCARS.md` has accumulated real
  trap knowledge worth packaging, not a requirement for adopting the loop
  surface at all. (`atlas check --deep --strict` — a repo's own optional,
  stricter gate — CAN fail on `EXECUTOR_PACK_MISSING` once `SCARS.md` reaches
  the anchor floor below; "optional" describes the base surface, not every
  gate a repo might choose to run.)

`atlas init --loop` scaffolds `templates/ROADMAP.md.tmpl` with a generic pack
skeleton (universal DoD + escalate-up protocol pre-filled; the trap-sheet starts
empty for the adopter to grow from their own `SCARS.md`). `atlas check --deep`
warns `EXECUTOR_PACK_MISSING` when `SCARS.md` has accumulated 5 or more anchors
and a present `ROADMAP.md` has no SEMANTICALLY complete pack: the heading-
bounded pack section must carry all five field markers — the literal phrases
`tickets point to specs` · `trap-sheet` · `routing` · `definition of done` ·
`escalate-up` (case-insensitive, matched across line wraps) — AND the
trap-sheet must cite at least one real `SCARS.md` `§ANCHOR`. A bare heading
mention or a degenerate two-line pack does not satisfy it. The warning names
exactly which fields are missing. The SessionStart hook surfaces a one-line
pointer when a pack is present.

### Capability tiers — portable routing (RM-26)

The pack's model/tier tag (field 3 above) is deliberately vendor-neutral:
tickets are tagged `tier: fast|strong|frontier` by ROLE — mechanical/
well-spec'd work · cross-cutting/subtle-correctness work · spec-design or
scarred-core surgery — never a vendor's specific model name. A standard that
hardcodes `sonnet`/`opus`/`gpt-5` into its routing silently assumes one vendor;
tiers keep the EXECUTOR PACK and `LOOP.md` copy-paste portable to any stack
(Claude, GPT, Gemini, Qwen, a local model).

- An OPTIONAL **tier mapping block** binds tiers to an operator's actual
  models for THIS repo — a `## Model tier mapping` section in `LOOP.md`
  (the only location `atlas check` parses today), a two-column table: *tier ·
  the operator's model for it*. A repo with no mapping block is unaffected;
  tiers stay descriptive-only until one is added.
- `atlas check` (no `--deep` needed) warns `UNMAPPED_TIER_TAG` when a mapping
  block is present but a `ROADMAP.md` ticket's `tier:` value isn't one of the
  block's declared tiers (a typo'd or stale tag silently escapes routing).
  Without a mapping block, tier values are never validated — there is nothing
  to check them against.

---

## 9. BUGS.md — the open-issues register (OPTIONAL surface)

`SCARS.md` holds failures that are **fixed and understood** (symptom → root
cause → remedy). There is no standard home for issues that are **open, known,
but not yet understood** — so each session re-discovers the same weirdness at
full cost. `BUGS.md` is that home: the SCARS antechamber.

- `BUGS.md` is OPTIONAL. A repo without it is fully conformant and unaffected.
- If present and **not git-ignored** (i.e. public), `BUGS.md` **SHOULD** be
  linked from `ATLAS.md` so agents find it during orientation. ("Not
  git-ignored" — not "tracked": the check is lenient by design, including in
  an unborn repo with no commits yet; it does not require `git ls-files` to
  already show the file.)
- A `BUGS.md` that is **git-ignored** is a valid, private choice (a repo may
  keep its open-issues register local-only, e.g. SCARS §PRIVATE-STYLE-OVERLAY)
  — the link requirement does not apply to a git-ignored file.
- Entry shape: *date · symptom · evidence (file:line / log) · suspicion · owner
  ticket*.
- **Graduation convention.** When an open issue is understood and fixed, it
  graduates: strike it through in `BUGS.md` (with the fixing commit) and add
  the lesson as a new `SCARS.md` `§ANCHOR`. An issue never lives in both files
  at once — open here, or fixed-and-learned there.

`atlas check` validates `BUGS.md` **only when present**: a `BUGS.md` that is
not git-ignored (public) and not referenced from `ATLAS.md` by a real Markdown
link warns (`BUGS_MD_UNLINKED`) — a plain-text mention of the filename is not
a link and does not suppress the warning (SCARS §BUGS-LINK-NOT-SUBSTRING).
`atlas init --bugs` scaffolds a `BUGS.md` already linked from `ATLAS.md`. The
SessionStart hook surfaces a one-line pointer ("check BUGS.md before
debugging") when a repo has one.

---

## 10. CRITICS.md — the second-opinion log (OPTIONAL surface)

Same-family agents share blind spots: a model reviewing its own design tends
to rationalize its own choices. `CRITICS.md` is the standard home for a
**cross-vendor adversarial pass** — the strongest objection a different model
family raises against a decision, logged before that decision ships.

- `CRITICS.md` is OPTIONAL. A repo without it is fully conformant and
  unaffected.
- Entry shape: one block per review session — `### <date> — <topic>`,
  `**Critic:**` (the model/vendor consulted, stamped with **provenance**:
  model id + reasoning effort, and whether each came from an explicit
  override or the tool's own config default — so authority is auditable),
  `**Topic:**`, `**Inputs they had:**` (the exact diff range · files touched
  · verification commands already run — never a static placeholder),
  followed by a table of individual critique rows: *# · critique (verbatim)
  · severity (high/med/low) · disposition (fixed / accepted / rejected with
  rationale / deferred / **verified-no-issue**) · ADR/GAPS link*, an
  **Assumptions challenged** section, and a **Proposals** section (each
  proposal carries an explicit evidence bar — what would have to be true, or
  what test would confirm it). A critic that only finds bugs is
  under-reporting what it checked — `verified-no-issue` rows are first-class.
- Mantra: bring the strongest objection, not the most polite one.
- **Graduation convention.** A critique that was rejected or deferred and is
  later proven right MUST become a new `SCARS.md` `§ANCHOR` citing the
  `CRITICS.md` row — an ignored-then-vindicated objection is a scar, not a
  footnote.
- A `CRITICS.md` that is **git-ignored** is a valid, private choice (SCARS
  §PRIVATE-STYLE-OVERLAY) — it is exempt from the staleness check below (a
  private review log's cadence is the repo's own business).

`atlas check` validates `CRITICS.md` **only when present**. When both
`CRITICS.md` and `ROADMAP.md` exist and `CRITICS.md` is tracked
(non-git-ignored), a `ROADMAP.md` **Done** log that has grown to 3+ shipped
items while `CRITICS.md` logs zero critique rows warns (`CRITICS_STALE`) —
decisions are landing with no adversarial pass. `atlas init --critics`
scaffolds `templates/CRITICS.md.tmpl`.

`atlas critique "<topic>" [--range <A>..<B>] [--verify "<cmds>"]
[--with-codex | --with-claude | --no-auto]` prints the hostile-review
prompt. When the caller doesn't force a choice, it **auto-detects an
installed cross-vendor critic** (a `codex` CLI on `PATH` first — the
reliable, synchronous dispatch; a background/fire-and-forget integration is
deliberately NOT used here, since its output can't be captured back) and
drives it: the diff range + files + verification inputs are sent, the raw
response is captured **synchronously**, and the appended `CRITICS.md` entry
is stamped with real provenance automatically. It degrades to the manual,
print-only prompt (unchanged from the base surface) when no critic CLI is
installed — `--no-auto` forces print-only even when one is, and
`--with-codex`/`--with-claude` force a specific critic. Reported under
`"critics"` in `--json`.

---

## 11. AKIGI.md + FRQ.md — cross-repo agent collaboration (OPTIONAL surfaces)

Multi-repo agent ecosystems need two things a single repo's quartet doesn't
give: a durable statement of **why this repo exists** that outsiders can triage
against, and a **standard inbox** where an agent working in a *sibling* repo
can request a capability from this one — and reliably learn the outcome.

### AKIGI.md — the purpose contract

One document, read identically by three audiences: humans deciding whether to
adopt, this repo's own agents triaging what to build, and outside agents
framing a request (concept: *ikigai*, for a repository).

- `AKIGI.md` is OPTIONAL and lives at the repo root when present.
- Sections: **Purpose** (the one problem this repo solves) · **Serves whom**
  (named consumers, not "users") · **Scope / Non-goals** (Non-goals are the
  sharpest triage signal) · **Acceptance principles** (REQUIRED — how incoming
  requests are triaged: purpose-fit first, evidence over assertion, the
  escalation line between what the repo's agent may decide alone and what
  waits for the maintainer, and reply-always) · optional
  **Values / constraints**.
- `atlas init --akigi` scaffolds `templates/AKIGI.md.tmpl`. `atlas check`
  (only when present) warns `AKIGI_NO_ACCEPTANCE` when no Acceptance section
  exists — a purpose contract that can't triage is decoration. The
  SessionStart hook surfaces a one-line pointer; the `llms.txt` export lists
  `AKIGI.md` so outside agents can discover it.

### FRQ.md — the Feature Request Queue

The cross-agent inbox, generalized from a production protocol (an agent in one
repo filed a request; the target repo's agent shipped the endpoint and replied
inline with the exact contract, later appending a dated **⚠ BREAKING** notice
when auth changed — the requester's agent picked each update up on its next
read).

- `FRQ.md` is OPTIONAL and lives at the repo root when present. A request is a
  *new capability*; *broken existing behavior* is a bug report, not an FRQ.
- **Protocol** (both roles in the file itself): the requesting agent reads
  `AKIGI.md` FIRST, then appends `## FRQ-NNN — <title> (YYYY-MM-DD)` with
  **Requested by** · **Why** (the concrete blocker, with evidence) · **Ask**
  (the exact capability/shape), and adds an Index row with status `🕒 open`.
  The owning agent triages open FRQs against the AKIGI's acceptance
  principles and appends `### ✅ RESOLVED FRQ-NNN` (the concrete surface:
  endpoint/command, request/response shape, errors, auth, how-to-wire) or
  `### ⛔ DECLINED FRQ-NNN` (reason citing the AKIGI + recommended
  alternative), flipping the Index row. Contract changes to a shipped FRQ get
  a dated **⚠ BREAKING** note appended to its RESOLVED subsection.
- **Index**: a table (*FRQ · Title · Requester · Status*) so open requests are
  scannable in one read.
- `atlas init --frq` scaffolds `templates/FRQ.md.tmpl` **and implies
  `--akigi`** — an FRQ without a purpose contract has no triage criterion.
  `atlas check` (only when present) warns `FRQ_NO_PROTOCOL` / `FRQ_NO_INDEX`
  on a file missing those sections, and `FRQ_NO_AKIGI` when `FRQ.md` exists
  without `AKIGI.md`. Listed in the `llms.txt` export. Reported with
  `"akigi"`/`"frq"` in `check --json`.
- **Reply-always freshness** (`atlas check --deep`): an Index row still
  marked `🕒 open` with no `✅`/`⛔` disposition, whose `## FRQ-NNN — <title>
  (YYYY-MM-DD)` entry date is more than 14 days old, warns `FRQ_UNANSWERED` —
  demand exists but the owning agent isn't triaging (the cross-repo analogue
  of `CRITICS_STALE`, and the check-side half of the reply-always acceptance
  principle). The 14-day cutoff is computed once (portable across BSD/GNU
  `date`) and every row is then compared against it as a plain lexicographic
  `YYYY-MM-DD` string — no per-row date parsing.

### BRD.md — Bugs Responsible Disclosure

The defect-disclosure inbox for OUTSIDE agents. The split is architectural:
**`BUGS.md` (§9) is internal** — this repo's own agents' register — while
**`BRD.md` is external** — a sibling-repo agent consuming this repo hit
broken behavior. An ACCEPTED disclosure graduates into the internal flow
(BUGS.md / fix ticket → fixed → SCARS lesson) and the outcome is replied
inline in the BRD entry.

- OPTIONAL; repo root when present. Entry: `## BRD-NNN — <symptom> (date)`
  with **Reported by** · **Evidence** (exact command + wrong output) ·
  **Repro** · **Impact**, plus an Index row (`🕒 open`). No evidence/repro →
  declined asking for it (evidence is what makes disclosure *responsible*).
- Owner dispositions: `### ✅ FIXED BRD-NNN` (fix commit, how the discloser
  verifies) or `### ⛔ DECLINED BRD-NNN` (reason + what would change it).
- `atlas init --brd` scaffolds it (implies `--akigi`). `atlas check` warns
  `BRD_NO_PROTOCOL` / `BRD_NO_INDEX` / `BRD_NO_AKIGI` only-when-present.

### SRD.md — Security Responsible Disclosure

Like BRD but for vulnerabilities, with two hard differences:

1. **Nothing exploitable in public.** The public entry is a minimal marker
   only — `## SRD-NNN — <affected surface, no detail> (date)` with reporter,
   severity class, and nothing an attacker can act on. Full detail goes
   through the file's **Private channel** (a security email or the repo's
   private-advisory link). `atlas check` warns `SRD_NO_CONTACT` on an SRD.md
   with no private channel — the file would otherwise invite exploit detail
   into public.
2. **Never auto-triaged.** Agents may acknowledge but never dispose; the
   maintainer is always escalated (the AKIGI escalation line). Disposition
   after the fix ships: `### ✅ FIXED SRD-NNN` / `### ⛔ INVALID SRD-NNN`.

`atlas init --srd` scaffolds it (implies `--akigi`); also warns
`SRD_NO_PROTOCOL` / `SRD_NO_INDEX` / `SRD_NO_AKIGI`. `atlas init --intake`
scaffolds the full quartet (AKIGI + FRQ + BRD + SRD) in one command.
Reported as `"brd"`/`"srd"` in `check --json`; both listed in the `llms.txt`
export.

### The AKIGI protocol (v0) — where this is going

AKIGI + FRQ + BRD + SRD are the **file-based v0 of the AKIGI protocol** for
multi-repo, multi-agent coordination: with them, a repo *lives* — it
improves from ecosystem demand (requests and disclosures from outside
agents, triaged against its own purpose contract), not just its owner's
attention. Each repo's AKIGI facets (Purpose · Serves whom · Scope ·
Non-goals · Acceptance principles · Values) differ, like ikigai differs per
human; the constant is the PROTOCOL: read the AKIGI → file into the right
intake → get an inline, machine-readable disposition. The protocol is
designed to graduate into its own standard (an `AKIGI` repo) and evolve
beyond files — per-agent identity/registration, inboxes, and compensation
for verified disclosures are planned protocol phases, deliberately NOT part
of this spec yet. ATLAS remains a first-class integration of whatever the
protocol becomes.
