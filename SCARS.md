# SCARS — atlas hard-won failure memory

> **The "what not to repeat" file.** Every entry is a scar paid for in real
> breakage — symptom → root cause → do NOT → do → file pointer. Read this
> **before** fixing a bug.
>
> **Reading order.** [`ATLAS.md`](ATLAS.md) (*where*) → **this file** (*what
> breaks*) → [`.agents/skill/atlas/SKILL.md`](.agents/skill/atlas/SKILL.md) (*how*).
>
> Anchors are stable + immutable. Cite them in commits/PRs. Add one with
> `atlas anchor add NAME "summary"`.

---

## Table of contents

**Process / hygiene**
- [§NO-COAUTHOR — never add AI-assistant attribution to commits](#no-coauthor)
- [§ATLAS-IS-INDEX — update ATLAS.md when structure changes](#atlas-is-index)
- [§SMOKE-AFTER-CHANGE — run the smoke set after touching the CLI](#smoke-after-change)
- [§SKILL-TOC-LOAD-BEARING — the SKILL.md ToC is required; orientation depends on it](#skill-toc-load-bearing)

**Bash / CLI** *(this repo's real scars)*
- [§SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`](#set-e-and-and)
- [§PIPE-HEAD-SIGPIPE — `cmd | head` SIGPIPEs the producer; aborts under pipefail](#pipe-head-sigpipe)
- [§BASH-MONOLITH — `bin/atlas` is one file; keep shellcheck green](#bash-monolith)
- [§MACOS-SED — `sed -i` is not portable; use the `.bak` + `rm` idiom](#macos-sed)
- [§AWK-MULTILINE-V — a multi-line value via `awk -v` warns on macOS's default awk](#awk-multiline-v)
- [§PRINTF-LEADING-DASH — a printf format string starting with `-` is misparsed as an option](#printf-leading-dash)
- [§PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style symlink](#private-style-overlay)
- [§BUGS-LINK-NOT-SUBSTRING — "linked from ATLAS.md" must match a link, not a filename mention](#bugs-link-not-substring)

**Release / packaging**
- [§TAG-TRIGGER-NOT-RELEASE — channel workflows must fire on tag push](#tag-trigger-not-release)
- [§PPA-PLACEHOLDER-SECRET — a `<placeholder>` LAUNCHPAD_PPA silently drops uploads](#ppa-placeholder-secret)
- [§CLI-VERSION-DRIFT — bump ATLAS_VERSION in bin/atlas with every release](#cli-version-drift)

**Benchmarking** *(`atlas bench`)*
- [§BENCH-NEEDS-GIT — `codex exec` bails (0s, no output) in a `git archive` dir; keep stderr](#bench-needs-git)
- [§BENCH-TOKEN-SUM-CACHE — summed per-turn `input_tokens` double-counts cache; use turns/cost](#bench-token-sum-cache)
- [§OPENCODE-PURE-JSON — opencode floods stdout with plugin logs; run `--pure`](#opencode-pure-json)

---

## Process / hygiene

<a id="no-coauthor"></a>
### §NO-COAUTHOR — never add AI-assistant attribution to commits

Do not add `Co-Authored-By: Claude …` or equivalent lines in commits.

---

<a id="atlas-is-index"></a>
### §ATLAS-IS-INDEX — update ATLAS.md when structure changes

Add a top-level module / command / package channel / runtime → update
[`ATLAS.md`](ATLAS.md) in the **same commit**. A stale ATLAS forces every
future agent to re-grep. Verify with `atlas check`.

---

<a id="smoke-after-change"></a>
### §SMOKE-AFTER-CHANGE — run the smoke set after touching the CLI

`shellcheck bin/atlas && bash tests/bootstrap.test.sh` (ATLAS §5). Don't ship
commits that don't green it.

---

<a id="skill-toc-load-bearing"></a>
### §SKILL-TOC-LOAD-BEARING — the SKILL.md ToC is required; orientation depends on it

**Symptom.** A "fix" proposes removing the `## Table of contents` requirement from
`atlas check` for `SKILL.md`, citing SPEC §3 as saying SKILL "has no fixed structure"
(BUGS §BUG-1 suggested exactly this).

**Root cause.** SPEC §3 mandates a *minimal* structure — an H1 **plus** a
`## Table of contents`. That ToC is the navigational index the SessionStart hook
(`hooks/atlas-skill-loader.sh`) prints and that `atlas measure` counts as the
playbook's orientation surface. The "no fixed structure" reading drops the
"beyond an H1 + a ToC" clause.

**Do NOT.** Remove the SKILL.md ToC assertion from `cmd_check`, or relax SPEC §3 to
make the ToC optional. It would silently break the orientation surface for every
repo while the repo still "passes" `atlas check`.

**Do.** Keep the ToC an **error**-level requirement. If the failure confuses, make
the *message* actionable (say why it's needed + that `atlas init` scaffolds one)
and clarify the spec — which v0.2.0 did. Reserve warnings for SHOULD/conditional
rules (CLAUDE/AGENTS presence, kebab dir).

**Where.** `bin/atlas::cmd_check` (SKILL.md block); `docs/SPEC.md` §3/§6;
`hooks/atlas-skill-loader.sh`; `tests/bootstrap.test.sh` (BUG-1 regression).

**Shipped in.** v0.2.0.

---

## Bash / CLI

<a id="set-e-and-and"></a>
### §SET-E-AND-AND — `A && B` as a standalone line can abort under `set -e`

**Symptom.** A `cmd_*` function exits silently partway through.

**Root cause.** `bin/atlas` runs `set -euo pipefail`. `A && B && C` where a
middle link is false, or `(( x++ ))` when the result is 0, returns non-zero and
trips `set -e`.

**Do NOT.** Use `(( count++ ))` (returns 1 when count was 0), or chain
multi-step guards with `&&`.

**Do.** `count=$(( count + 1 ))`; use `if [[ cond ]]; then …; fi` for guards.

**Where.** `bin/atlas::cmd_measure`, `cmd_doctor`.

---

<a id="pipe-head-sigpipe"></a>
### §PIPE-HEAD-SIGPIPE — `cmd | head` SIGPIPEs the producer; aborts under pipefail

**Symptom.** `atlas measure` printed **nothing** (silently aborted) on any repo
with **>400 files** — but worked on small repos. Found the instant the flagship
ran it on fastapi (2,978 files); it had shipped broken for every real repo.

**Root cause.** `tree_b=$(git ls-files | head -400 | wc -c)`. `head -400` closes
the pipe after 400 lines → `git ls-files` gets **SIGPIPE** (exit 141). Under
`bin/atlas`'s `set -o pipefail`, the whole pipeline returns 141, so the command
substitution fails, and `set -e` aborts the function **before it prints anything**.
Small repos (< 400 files) never close the pipe early, so it never surfaced in tests.

**Do NOT.** Leave a `… | head -N | …` command substitution bare under
`set -euo pipefail`. The producer *will* SIGPIPE on big inputs.

**Do.** Wrap it: `count=$( { producer | head -N | wc -c; } || true )` — the count
is already on stdout before the failure, so `|| true` keeps the value and clears
the exit. Add a regression test that runs `measure` on a **>400-file** repo.

**Where.** `bin/atlas::cmd_measure` (tree count), `cmd_bench` (openai context).
`tests/bootstrap.test.sh` (the >400-file guard).

---

<a id="bash-monolith"></a>
### §BASH-MONOLITH — `bin/atlas` is one ~2k-line file; keep it green

**Why one file (deliberate).** ATLAS ships as a single zero-dep script that
`install.sh`, the npm wrapper, brew, `.deb`, AUR and PPA all distribute *as-is*.
Splitting into `lib/*.sh` would mean every install path ships and `source`s the
right files from the right location — real distribution risk for ~no user
benefit. So the monolith stays. Rigor comes from `shellcheck` + the 80+ test
`tests/bootstrap.test.sh` + the macOS/Linux CI matrix, **not** from modularizing.

**Do NOT.** Add a runtime dependency (node/python/jq) to the core path. Don't
split the monolith into modules. Don't add a blocking `shfmt` gate — it would
force a full reformat of the hand-tuned file; `shellcheck` already guards
correctness (contributors may run `shfmt -d` locally if they like).

**Do.** Keep changes `shellcheck`-clean (CI enforces). Mirror the existing
`cmd_*` + flag-parse + dispatch + header-doc pattern when adding a command.

**Where.** `bin/atlas`, `.github/workflows/ci.yml`.

---

<a id="macos-sed"></a>
### §MACOS-SED — `sed -i` is not portable; use the `.bak` + `rm` idiom

**Do NOT.** Use bare `sed -i` in code that ships to both macOS and Linux.

**Do.** `sed -i.bak "expr" file && rm file.bak`, as in `cmd_adr_add`. Prefer awk
for anything structural.

**Where.** `bin/atlas::cmd_adr_add`.

---

<a id="awk-multiline-v"></a>
### §AWK-MULTILINE-V — a multi-line value via `awk -v` warns on macOS's default awk

**Symptom.** `awk: newline in string <...>` printed to stderr (once per
embedded newline) when replacing a marker block in a file — the final output
can still end up looking correct, so this is easy to miss unless stderr is
actually checked.

**Root cause.** macOS ships `/usr/bin/awk` as the "one true awk" (BWK awk),
which does not reliably handle `-v name="multi\nline\nvalue"`. It doesn't
depend on content length or a specific trigger threshold in any principled
way — "hasn't warned yet" on one block's content is not evidence it's safe.

**Do NOT.** Pass a multi-line bash variable to awk via `-v` for a
marker-block replace.

**Do.** Write the multi-line content to a temp file and stream it in with
`getline line < file` inside the awk program (`close()` it after) — portable
across every awk variant.

**Where.** `bin/atlas::cmd_auth`, `bin/atlas::cmd_leaderboard`.

---

<a id="printf-leading-dash"></a>
### §PRINTF-LEADING-DASH — a printf format string starting with `-` is misparsed as an option

**Symptom.** `printf: - : invalid option` on stderr; the intended content is
silently never written. A caller that doesn't check `$?` (or a test fixture
whose later assertion happens to still pass) can miss this entirely — the
RM-42 regression test this broke passed vacuously for an entire iteration.

**Root cause.** bash's builtin `printf` parses a leading `-` in the format
argument as an option flag unless told otherwise.

**Do NOT.** Pass literal content starting with `-` (or containing `%`) as
printf's format argument directly.

**Do.** Use `printf -- '...'` to end option parsing, or `printf '%s\n' '...'`
so the content is never interpreted as a format string at all.

**Where.** `tests/bootstrap.test.sh`.

---

<a id="private-style-overlay"></a>
### §PRIVATE-STYLE-OVERLAY — never commit the `abbasi` style symlink

**Symptom.** Every consumer gets a dangling `templates/styles/abbasi` symlink
pointing at the maintainer's local disk — broken style + leaked path.

**Do NOT.** `git add templates/styles/abbasi`; don't remove it from `.gitignore`.

**Do.** Keep it `.gitignore`d; the private overlay installer symlinks it locally.

**Where.** `.gitignore`, `templates/styles/`.

---

<a id="bugs-link-not-substring"></a>
### §BUGS-LINK-NOT-SUBSTRING — "linked from ATLAS.md" must match a link, not a filename mention

**Symptom.** `BUGS_MD_UNLINKED` (and `init --bugs`'s auto-link guard) never
fired once `ATLAS.md` merely *mentioned* the string "BUGS.md" anywhere — a
plain sentence, a comment — with no actual Markdown link to the register.
Agents landed on an unlinked `BUGS.md` and never found it; found by an
adversarial cross-vendor review (CRITICS.md, 2026-07-07).

**Root cause.** The check used `grep -q "BUGS.md" file` — a substring test,
not a link test. Any incidental occurrence of those six characters satisfied
it, and the regression test asserted the same weak oracle.

**Do NOT.** Test "is X referenced from file" with a bare substring grep when X
is meant to be a Markdown *link* target — false positives suppress the very
warning meant to catch a missing link.

**Do.** Match the link syntax, not the filename: `grep -qE '\]\((\./)?BUGS\.md\)'`
— label text (backticked or not) doesn't matter, only the `(...)` target does.
One helper (`_bugs_md_linked`) backs both the `init --bugs` auto-link guard and
the `check` warning so they can't drift apart.

**Where.** `bin/atlas::_bugs_md_linked`, `cmd_init`, `cmd_check`.

---

## Release / packaging

<a id="tag-trigger-not-release"></a>
### §TAG-TRIGGER-NOT-RELEASE — channel workflows must fire on tag push

**Symptom.** A release is created but npm/.deb/brew/AUR/PPA never publish.

**Root cause.** A GitHub release created by the built-in `GITHUB_TOKEN` does
**not** cascade events, so `on: release: published` workflows never run.

**Do.** Trigger channel workflows on `push: tags: ['v*']` (they then run from
the tag's own files too). `release-deb` waits for `release.yml` to create the
release before uploading assets.

**Where.** `.github/workflows/release-*.yml`.

---

<a id="ppa-placeholder-secret"></a>
### §PPA-PLACEHOLDER-SECRET — a `<placeholder>` LAUNCHPAD_PPA silently drops uploads

**Symptom.** `release-ppa` is green, `dput` reports success, but nothing appears
on the Launchpad PPA.

**Root cause.** `LAUNCHPAD_PPA` left as `ppa:<your-launchpad-user>/atlas` → dput
uploads to a nonexistent `~<your-launchpad-user>/atlas` path → Launchpad drops it.

**Do.** Set the real value (`ppa:alainabbasi/atlas`). The dput step now fails
fast if the secret contains `<`/`>`.

**Where.** `.github/workflows/release-ppa.yml`.

---

<a id="cli-version-drift"></a>
### §CLI-VERSION-DRIFT — bump ATLAS_VERSION in bin/atlas with every release

**Symptom.** `atlas version` (and `atlas bench` metadata) report an old version
while npm/AUR/etc. ship a newer one.

**Root cause.** The version lives in **two** places: `package.json` (bumped at
release) and the hardcoded `ATLAS_VERSION="…"` in `bin/atlas`. The `.deb`/AUR
packages ship `bin/` without `package.json`, so the constant can't be derived —
it must be bumped by hand. It silently drifted 0.1.0 → 0.1.4.

**Do.** In the cut-release recipe, bump `ATLAS_VERSION` in `bin/atlas` in the
same commit as `package.json`. (A CI check comparing the two would prevent this.)

**Where.** `bin/atlas` (top), `package.json`.

---

## Benchmarking (`atlas bench`)

<a id="bench-needs-git"></a>
### §BENCH-NEEDS-GIT — a runtime that bails in a non-git dir produces a silent 0/0

**Symptom.** `atlas bench --runtime codex` reported `output_chars 0 / wall_s 0`
for both conditions — "no delta computed." No error, no clue why.

**Root cause.** Two compounding traps. (1) The per-run work dir is built with
`git archive HEAD | tar -x`, which has **no `.git`** — and `codex exec` refuses
to run outside a git repo, exiting in ~0s. (2) The runner sent stderr to
`/dev/null`, so the refusal was invisible. `claude -p` has no such guard, so it
ran and masked the asymmetry.

**Do NOT.** Discard a benchmarked runtime's stderr — a silent failure scores as
"0," which a naive primary metric reads as a result.

**Do.** Pass `codex exec --skip-git-repo-check` (or `git init -q` the work dir);
capture stderr to a `.err` file; flag empty output as a `parse_error` so a dead
run can never masquerade as a datapoint.

**Where.** `bin/atlas` `cmd_bench` (the `codex)` agent array + the run redirect +
the empty-output check in the python parser).

---

<a id="bench-token-sum-cache"></a>
### §BENCH-TOKEN-SUM-CACHE — summed per-turn `input_tokens` is not a cost/efficiency metric

**Symptom.** An agentic A/B claimed ATLAS made things **−98.6%** (1.95× *more*
input_tokens) — while the same run finished in **fewer turns (5 vs 6), 33% less
wall-time (58s vs 87s), and ~10% lower cost ($0.38 vs $0.42)**. The headline
contradicted every real signal.

**Root cause.** The parser summed each assistant turn's `usage.input_tokens`.
In an agentic loop every turn re-sends the whole (cached) context, so the sum
grows super-linearly with turns and counts cache **reads** (priced ~10×) as if
they were fresh input. The dogfooded SessionStart hook injecting the quartet
into the "with" copy widened the gap further. The tell: the token sum *rose*
while **cost fell** — impossible if it were a real cost measure.

**Do NOT.** Headline summed per-turn `input_tokens` for agentic runs, or mix it
with the deterministic single-shot count in the same "reduction" claim.

**Do.** For agentic runtimes (claude/codex/opencode) use **turns / cost / wall**
as the metric (all lower-is-better); reserve token counts for the deterministic
`openai` / `atlas measure` single-shot mode, which tokenizes a *fixed* context
once and is reproducible. That single-shot path is the source of the headline
**−92% / 12.8×**; agentic rows are logged as *directional*.

**Where.** `bin/atlas` `cmd_bench` (`prim`/`plabel` selection + the claude
parser); `docs/benchmarks/methodology.md`; `docs/benchmarks/RESULTS.md`.

---

<a id="opencode-pure-json"></a>
### §OPENCODE-PURE-JSON — opencode floods stdout with plugin logs; run `--pure`

**Symptom.** `atlas bench --runtime opencode` produced unparseable output (or
hung): the JSON was preceded by `[TelegramRemote] …` / `[Config] …` plugin log
lines, and a no-`-m` invocation waited forever on model selection.

**Root cause.** opencode loads user plugins that log to **stdout**, corrupting
`--format json`; and `opencode run` with no model blocks on selection when headless.

**Do.** Invoke `opencode run --pure --format json -m <provider>/<model> …` —
`--pure` skips user plugins so stdout is clean JSON, and `-m` is required (the CLI
`_die`s without it rather than hang). The parser still defensively scans for the
first `[`/`{` in case a stray line slips through. opencode messages carry
`tokens:{input,output,…}` + `cost` + `modelID`; sum them, count assistant messages
as turns (same cache caveat as [[§BENCH-TOKEN-SUM-CACHE]] → headline **turns**).

**Where.** `bin/atlas` `cmd_bench` (opencode agent array + the `opencode` parser).

---

## Adding scars

Scaffold with `atlas anchor add NAME "summary"`, fill in Symptom / Root cause /
Do NOT / Do / Where, and cite the anchor in the commit that fixes it.
