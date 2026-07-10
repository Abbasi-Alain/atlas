#!/usr/bin/env bash
# tests/bootstrap.test.sh — smoke tests for the public atlas CLI.

set -u  # NOT -e or -o pipefail — we deliberately run failing commands.

ATLAS_HOME="$(cd "$(dirname "$0")/.." && pwd)"
export ATLAS_HOME
CLI="$ATLAS_HOME/bin/atlas"

PASS=0; FAIL=0
_pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
_fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
_cleanup() { [[ -n "${TMP:-}" && -d "$TMP" ]] && rm -rf "$TMP"; }
trap _cleanup EXIT

TMP="$(mktemp -d)"
cd "$TMP"
git init -q -b main 2>/dev/null || true

# --- core ----------------------------------------------------------------

# version
if NO_COLOR=1 "$CLI" version | grep -qE 'atlas v[0-9]+\.[0-9]+\.[0-9]+'; then _pass "version prints"; else _fail "version"; fi

# init (default style)
"$CLI" init >/dev/null
[[ -f "$TMP/ATLAS.md" ]]     && _pass "init wrote ATLAS.md"     || _fail "no ATLAS.md"
[[ -f "$TMP/CLAUDE.md" ]]    && _pass "init wrote CLAUDE.md"    || _fail "no CLAUDE.md"
[[ -f "$TMP/AGENTS.md" ]]    && _pass "init wrote AGENTS.md"    || _fail "no AGENTS.md"
[[ -f "$TMP/EXAMPLES.md" ]]  && _pass "init wrote EXAMPLES.md"  || _fail "no EXAMPLES.md"
if diff -q "$TMP/CLAUDE.md" "$TMP/AGENTS.md" >/dev/null 2>&1; then
  _pass "AGENTS.md mirrors CLAUDE.md"
else
  _fail "AGENTS.md != CLAUDE.md"
fi
skill_count=$(find "$TMP/.agents/skill" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
[[ "$skill_count" == "1" ]] && _pass "init wrote SKILL.md" || _fail "no SKILL.md (count=$skill_count)"
[[ -f "$TMP/SCARS.md" ]] && _pass "init wrote SCARS.md" || _fail "no SCARS.md"

# overwrite refused
init_out="$("$CLI" init 2>&1)"
echo "$init_out" | grep -q "skip" && _pass "init refuses overwrite" || _fail "init overwrote"

# check passes
if "$CLI" check >/dev/null 2>&1; then _pass "check passes on fresh init"; else _fail "check failed"; fi

# anchors
anchors_out="$("$CLI" anchors 2>&1)"
echo "$anchors_out" | grep -q "no-coauthor"      && _pass "anchors lists §NO-COAUTHOR"    || _fail "missing §NO-COAUTHOR"
echo "$anchors_out" | grep -q "atlas-is-index"   && _pass "anchors lists §ATLAS-IS-INDEX" || _fail "missing §ATLAS-IS-INDEX"

# anchor add
"$CLI" anchor add TEST-ANCHOR "one-line test" >/dev/null
"$CLI" anchors | grep -q "test-anchor" && _pass "anchor add inserts" || _fail "anchor add"

# duplicate detection
"$CLI" anchor add TEST-ANCHOR "one-line test" >/dev/null
check_out="$("$CLI" check 2>&1)"; check_rc=$?
if [[ $check_rc -ne 0 ]] && echo "$check_out" | grep -q "duplicate"; then
  _pass "check flags duplicate anchors"
else
  _fail "duplicates not detected"
fi

# --- check: quartet validation (BUGS.md regressions) ---------------------
echo ""
echo "-- check: quartet validation --"

# fresh init must be FULLY conformant — zero warnings (standard-grade scaffold).
TMP_B0="$(mktemp -d)"; ( cd "$TMP_B0" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  out=$("$CLI" check 2>&1); rc=$?
  [[ $rc -eq 0 ]] && ! echo "$out" | grep -qi "warning" ) \
  && _pass "fresh init passes check with zero warnings" || _fail "fresh init not fully conformant"
rm -rf "$TMP_B0"

# BUG-1: SKILL.md without a '## Table of contents' is an error with an actionable message.
TMP_B1="$(mktemp -d)"; ( cd "$TMP_B1" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  sk=$(find .agents -name SKILL.md); grep -v "Table of contents" "$sk" > "$sk.t" && mv "$sk.t" "$sk"
  out=$("$CLI" check 2>&1); rc=$?
  [[ $rc -ne 0 ]] && echo "$out" | grep -q "missing '## Table of contents'" ) \
  && _pass "check errors on SKILL.md without a ToC (BUG-1)" || _fail "BUG-1 ToC not enforced"
rm -rf "$TMP_B1"

# BUG-2: a missing CLAUDE.md is a warning, not a hard failure (still exit 0).
TMP_B2="$(mktemp -d)"; ( cd "$TMP_B2" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  rm -f CLAUDE.md AGENTS.md
  out=$("$CLI" check 2>&1); rc=$?
  [[ $rc -eq 0 ]] && echo "$out" | grep -qi "no CLAUDE.md" ) \
  && _pass "check warns (not fails) on missing CLAUDE.md (BUG-2)" || _fail "BUG-2 CLAUDE.md unchecked"
rm -rf "$TMP_B2"

# BUG-2: AGENTS.md drifted from CLAUDE.md is flagged.
TMP_B2D="$(mktemp -d)"; ( cd "$TMP_B2D" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  echo "drift" >> AGENTS.md
  out=$("$CLI" check 2>&1); rc=$?
  [[ $rc -eq 0 ]] && echo "$out" | grep -qi "AGENTS.md drifted" ) \
  && _pass "check warns on AGENTS.md drift (BUG-2)" || _fail "BUG-2 drift undetected"
rm -rf "$TMP_B2D"

# BUG-3: init derives the kebab dir from the remote; check warns on a non-kebab dir.
TMP_B3="$(mktemp -d)"; ( cd "$TMP_B3" && git init -q -b main 2>/dev/null \
  && git remote add origin https://github.com/x/Proxima-Finance.git && "$CLI" init >/dev/null 2>&1
  [[ -d .agents/skill/proxima-finance ]] || exit 1
  mv .agents/skill/proxima-finance .agents/skill/Proxima-Finance
  out=$("$CLI" check 2>&1); rc=$?
  [[ $rc -eq 0 ]] && echo "$out" | grep -qi "expects kebab-case" ) \
  && _pass "init scaffolds kebab dir; check warns on non-kebab (BUG-3)" || _fail "BUG-3 kebab dir"
rm -rf "$TMP_B3"

# BUG-4: the remediation hint is non-destructive wording.
TMP_B4="$(mktemp -d)"; ( cd "$TMP_B4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  rm -f SCARS.md
  "$CLI" check 2>&1 | grep -qi "non-destructive" ) \
  && _pass "check remediation hint is non-destructive (BUG-4)" || _fail "BUG-4 hint wording"
rm -rf "$TMP_B4"

# BUG-5: llms.txt 'read these first' set includes SCARS.md.
TMP_B5="$(mktemp -d)"; ( cd "$TMP_B5" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1 \
  && "$CLI" export --to llms-txt >/dev/null 2>&1 && grep -q "SCARS.md" llms.txt ) \
  && _pass "llms.txt read-first set includes SCARS.md (BUG-5)" || _fail "BUG-5 llms.txt missing SCARS"
rm -rf "$TMP_B5"

# --- v0.3.0: machine-readable check (--json/--strict) + atlas fix --------
echo ""
echo "-- check --json/--strict + atlas fix --"

# check --json emits machine-readable conformance (valid-ish JSON: ok + quartet).
TMP_J="$(mktemp -d)"; ( cd "$TMP_J" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  out=$("$CLI" check --json)
  echo "$out" | grep -q '"ok":true' && echo "$out" | grep -q '"quartet":{"atlas":true' ) \
  && _pass "check --json emits machine-readable conformance (BUG/v0.3.0)" || _fail "check --json"
rm -rf "$TMP_J"

# check --strict turns a warning into a non-zero exit; plain still passes.
TMP_S="$(mktemp -d)"; ( cd "$TMP_S" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1 && rm -f CLAUDE.md AGENTS.md
  "$CLI" check >/dev/null 2>&1; rc_plain=$?
  "$CLI" check --strict >/dev/null 2>&1; rc_strict=$?
  [[ $rc_plain -eq 0 && $rc_strict -ne 0 ]] ) \
  && _pass "check --strict fails on warnings (plain passes)" || _fail "check --strict"
rm -rf "$TMP_S"

# atlas fix kebabs a non-kebab SKILL dir → the kebab warning is gone.
TMP_F="$(mktemp -d)"; ( cd "$TMP_F" && git init -q -b main 2>/dev/null \
  && git remote add origin https://github.com/x/Proxima-Finance.git && "$CLI" init >/dev/null 2>&1
  mv .agents/skill/proxima-finance .agents/skill/Proxima-Finance
  "$CLI" fix >/dev/null 2>&1
  ! "$CLI" check --json | grep -q SKILL_DIR_NOT_KEBAB ) \
  && _pass "atlas fix kebabs the SKILL dir (BUG-3 auto-fix)" || _fail "atlas fix kebab"
rm -rf "$TMP_F"

# atlas fix re-mirrors a drifted AGENTS.md back to byte-identical.
TMP_FM="$(mktemp -d)"; ( cd "$TMP_FM" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  echo "drift" >> AGENTS.md
  "$CLI" fix >/dev/null 2>&1
  cmp -s CLAUDE.md AGENTS.md ) \
  && _pass "atlas fix re-mirrors drifted AGENTS.md" || _fail "atlas fix mirror"
rm -rf "$TMP_FM"

# atlas fix is idempotent on a conformant repo (no-op).
TMP_FI="$(mktemp -d)"; ( cd "$TMP_FI" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  "$CLI" fix 2>&1 | grep -q "nothing to fix" ) \
  && _pass "atlas fix is a no-op when already conformant" || _fail "atlas fix idempotent"
rm -rf "$TMP_FI"

# --- v0.4.0: optional autonomous-loop surface (init --loop + check awareness) ---
echo ""
echo "-- loop surface (init --loop / check) --"

# init --loop scaffolds LOOP.md + ROADMAP.md and the repo still passes --strict.
TMP_L1="$(mktemp -d)"; ( cd "$TMP_L1" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  [[ -f LOOP.md && -f ROADMAP.md ]] && "$CLI" check --strict >/dev/null 2>&1 ) \
  && _pass "init --loop scaffolds LOOP+ROADMAP and passes --strict" || _fail "init --loop"
rm -rf "$TMP_L1"

# check --json reports the loop surface present.
TMP_L2="$(mktemp -d)"; ( cd "$TMP_L2" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  "$CLI" check --json | grep -q '"loop":{"loop_md":true,"roadmap_md":true}' ) \
  && _pass "check --json reports the loop surface" || _fail "check --json loop"
rm -rf "$TMP_L2"

# a repo WITHOUT a loop is unaffected: loop=false, no loop warnings.
TMP_L3="$(mktemp -d)"; ( cd "$TMP_L3" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  "$CLI" check --json | grep -q '"loop":{"loop_md":false,"roadmap_md":false}' \
    && ! "$CLI" check --json | grep -q "LOOP_NO_H1\|ROADMAP_NO_QUEUE" ) \
  && _pass "no-loop repo unaffected by loop checks" || _fail "loop opt-in leak"
rm -rf "$TMP_L3"

# malformed loop files warn (missing H1 / missing queue).
TMP_L4="$(mktemp -d)"; ( cd "$TMP_L4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf 'no h1 here\n' > LOOP.md; printf 'no queue here\n' > ROADMAP.md
  o="$("$CLI" check --json)"; echo "$o" | grep -q LOOP_NO_H1 && echo "$o" | grep -q ROADMAP_NO_QUEUE ) \
  && _pass "malformed LOOP/ROADMAP files warn" || _fail "loop malformed warnings"
rm -rf "$TMP_L4"

# BUG-7: a loop repo's llms.txt read-first set lists LOOP.md; fix repairs a loop-stale one.
TMP_L5="$(mktemp -d)"; ( cd "$TMP_L5" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  "$CLI" export --to llms-txt >/dev/null 2>&1 && grep -q "LOOP.md" llms.txt ) \
  && _pass "llms.txt export lists LOOP.md for a loop repo (BUG-7)" || _fail "BUG-7 llms loop export"
rm -rf "$TMP_L5"

TMP_L6="$(mktemp -d)"; ( cd "$TMP_L6" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  "$CLI" export --to llms-txt >/dev/null 2>&1; grep -v "LOOP.md" llms.txt > t && mv t llms.txt
  "$CLI" fix >/dev/null 2>&1; grep -q "LOOP.md" llms.txt ) \
  && _pass "atlas fix regenerates a loop-stale llms.txt (BUG-7)" || _fail "BUG-7 fix loop-stale"
rm -rf "$TMP_L6"

# BUG-8: a ROADMAP with no Done log warns.
TMP_L7="$(mktemp -d)"; ( cd "$TMP_L7" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  grep -vi "done" ROADMAP.md > t && mv t ROADMAP.md
  "$CLI" check --json | grep -q ROADMAP_NO_DONE ) \
  && _pass "check warns on a ROADMAP with no Done log (BUG-8)" || _fail "BUG-8 done-log"
rm -rf "$TMP_L7"

# BUG-10: a heading that merely CONTAINS "done" (e.g. "## Backlog (nothing done
# yet)") is not a Done log — the warning must still fire; a real "## Done (log)"
# heading must suppress it.
TMP_L7b="$(mktemp -d)"; ( cd "$TMP_L7b" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Backlog (nothing done yet)\n' > ROADMAP.md
  "$CLI" check --json | grep -q ROADMAP_NO_DONE \
    && { printf '# ROADMAP\n- [ ] x\n## Done (log — shipped)\n' > ROADMAP.md
         ! "$CLI" check --json | grep -q ROADMAP_NO_DONE; } ) \
  && _pass "check Done-log anchors 'done' to heading start (BUG-10)" || _fail "BUG-10 done-anchor"
rm -rf "$TMP_L7b"

# BUG-9: a half-configured loop warns, both directions.
TMP_L8="$(mktemp -d)"; ( cd "$TMP_L8" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# LOOP\n' > LOOP.md
  "$CLI" check --json | grep -q LOOP_NO_ROADMAP ) \
  && _pass "check warns on LOOP.md without ROADMAP.md (BUG-9)" || _fail "BUG-9 loop-no-roadmap"
rm -rf "$TMP_L8"

TMP_L9="$(mktemp -d)"; ( cd "$TMP_L9" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n' > ROADMAP.md
  "$CLI" check --json | grep -q ROADMAP_NO_LOOP ) \
  && _pass "check warns on ROADMAP.md without LOOP.md (BUG-9)" || _fail "BUG-9 roadmap-no-loop"
rm -rf "$TMP_L9"

# --- RM-3: BUGS.md open-issues register (init --bugs + check awareness) ---
echo ""
echo "-- BUGS.md open-issues register (init --bugs / check) --"

# init --bugs scaffolds a REAL Markdown link to BUGS.md (not just a mention);
# repo still passes --strict clean.
TMP_BG1="$(mktemp -d)"; ( cd "$TMP_BG1" && git init -q -b main 2>/dev/null && "$CLI" init --bugs >/dev/null 2>&1
  [[ -f BUGS.md ]] && grep -qE '\]\((\./)?BUGS\.md\)' ATLAS.md && "$CLI" check --strict >/dev/null 2>&1 ) \
  && _pass "init --bugs scaffolds a REAL-linked BUGS.md and passes --strict" || _fail "init --bugs"
rm -rf "$TMP_BG1"

# a repo without --bugs is unaffected (no BUGS.md, no warning).
TMP_BG2="$(mktemp -d)"; ( cd "$TMP_BG2" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  [[ ! -f BUGS.md ]] && ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "no-bugs repo unaffected (no BUGS.md, no warning)" || _fail "bugs opt-in leak"
rm -rf "$TMP_BG2"

# a hand-added, unlinked BUGS.md warns.
TMP_BG3="$(mktemp -d)"; ( cd "$TMP_BG3" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "check warns on an unlinked BUGS.md" || _fail "BUGS_MD_UNLINKED not detected"
rm -rf "$TMP_BG3"

# a git-ignored BUGS.md does NOT warn even though unlinked (private register).
TMP_BG4="$(mktemp -d)"; ( cd "$TMP_BG4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md && printf 'BUGS.md\n' >> .gitignore
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "git-ignored BUGS.md doesn't warn (SCARS §PRIVATE-STYLE-OVERLAY)" || _fail "gitignored BUGS.md still warns"
rm -rf "$TMP_BG4"

# RM-3b (SCARS §BUGS-LINK-NOT-SUBSTRING): a plain-text mention of "BUGS.md" is
# NOT a link — it must still warn (the pre-fix regex treated this as linked).
TMP_BG5="$(mktemp -d)"; ( cd "$TMP_BG5" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nSee BUGS.md for known issues.\n' >> ATLAS.md
  "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "plain-text 'BUGS.md' mention still warns (not a real link)" || _fail "substring mention wrongly suppressed BUGS_MD_UNLINKED"
rm -rf "$TMP_BG5"

# a real Markdown link — plain form `[BUGS.md](BUGS.md)` — passes (no warning).
TMP_BG6="$(mktemp -d)"; ( cd "$TMP_BG6" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nOpen issues: [BUGS.md](BUGS.md)\n' >> ATLAS.md
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "a real Markdown link to BUGS.md passes (no warning)" || _fail "real link wrongly still warns"
rm -rf "$TMP_BG6"

# a real link with a backticked label + ./ prefix also passes.
TMP_BG7="$(mktemp -d)"; ( cd "$TMP_BG7" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nOpen issues: [`BUGS.md`](./BUGS.md)\n' >> ATLAS.md
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "backticked label + ./ prefix link passes (no warning)" || _fail "backtick/./ prefix link wrongly still warns"
rm -rf "$TMP_BG7"

# RM-42 (critic-stage finding #8): broader real-link forms all pass —
# a #fragment, a quoted title, and an angle-bracket target.
TMP_BG8B="$(mktemp -d)"; ( cd "$TMP_BG8B" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nOpen issues: [open](BUGS.md#open)\n' >> ATLAS.md
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "a #fragment link (BUGS.md#open) passes (no warning)" || _fail "fragment link wrongly still warns"
rm -rf "$TMP_BG8B"

TMP_BG8C="$(mktemp -d)"; ( cd "$TMP_BG8C" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nOpen issues: [BUGS.md](BUGS.md "open issues")\n' >> ATLAS.md
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "a titled link (BUGS.md \"open issues\") passes (no warning)" || _fail "titled link wrongly still warns"
rm -rf "$TMP_BG8C"

TMP_BG8D="$(mktemp -d)"; ( cd "$TMP_BG8D" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  printf '\nOpen issues: [BUGS.md](<BUGS.md>)\n' >> ATLAS.md
  ! "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "an angle-bracket link (<BUGS.md>) passes (no warning)" || _fail "angle-bracket link wrongly still warns"
rm -rf "$TMP_BG8D"

# missing/failing git binary at check-time doesn't abort check (the
# rev-parse/check-ignore guard is an `if A && B` condition, safe under set -e).
FAKE_BIN_BG8="$(mktemp -d)"
printf '#!/bin/sh\nexit 127\n' > "$FAKE_BIN_BG8/git"; chmod +x "$FAKE_BIN_BG8/git"
TMP_BG8="$(mktemp -d)"; ( cd "$TMP_BG8" && git init -q -b main 2>/dev/null && "$CLI" init --bugs >/dev/null 2>&1
  PATH="$FAKE_BIN_BG8:$PATH" "$CLI" check --strict >/dev/null 2>&1 ) \
  && _pass "check tolerates a missing/failing git binary (no abort)" || _fail "check aborted with git unavailable"
rm -rf "$TMP_BG8" "$FAKE_BIN_BG8"

# a non-git directory (no .git at all): unlinked BUGS.md still warns — the
# link requirement has no hard git dependency.
TMP_BG9="$(mktemp -d)"; ( cd "$TMP_BG9" && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > BUGS.md
  "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "non-git dir: unlinked BUGS.md still warns" || _fail "non-git dir BUGS_MD_UNLINKED behavior wrong"
rm -rf "$TMP_BG9"

# a symlinked BUGS.md is detected like a regular file — unlinked still warns,
# and check doesn't choke resolving the symlink.
TMP_BG10="$(mktemp -d)"; ( cd "$TMP_BG10" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BUGS\n' > .bugs-real.md && ln -s .bugs-real.md BUGS.md
  "$CLI" check --json | grep -q BUGS_MD_UNLINKED ) \
  && _pass "symlinked BUGS.md (unlinked) still warns" || _fail "symlinked BUGS.md behavior wrong"
rm -rf "$TMP_BG10"

# fresh `init --bugs` ships zero fake open entries (SCARS ghost-work fix):
# nothing between '## Open' and the next heading looks like a real BUG-N bullet.
TMP_BG11="$(mktemp -d)"; ( cd "$TMP_BG11" && git init -q -b main 2>/dev/null && "$CLI" init --bugs >/dev/null 2>&1
  ! awk '/^## Open/{f=1;next} /^## /{f=0} f' BUGS.md | grep -qE '^- \*\*BUG-[0-9]' ) \
  && _pass "fresh init --bugs has zero fake open entries" || _fail "fake BUG-N ghost entry present under ## Open"
rm -rf "$TMP_BG11"

# --- RM-2: CRITICS.md second-opinion log (init --critics + check awareness) ---
echo ""
echo "-- CRITICS.md second-opinion log (init --critics / check) --"

# init --critics scaffolds CRITICS.md; repo still passes --strict clean; --json reports it.
TMP_CR1="$(mktemp -d)"; ( cd "$TMP_CR1" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  [[ -f CRITICS.md ]] && "$CLI" check --strict >/dev/null 2>&1 && "$CLI" check --json | grep -q '"critics":true' ) \
  && _pass "init --critics scaffolds CRITICS.md, passes --strict, reports critics:true" || _fail "init --critics"
rm -rf "$TMP_CR1"

# a repo without --critics is unaffected (no CRITICS.md, critics:false, no warning).
TMP_CR2="$(mktemp -d)"; ( cd "$TMP_CR2" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  [[ ! -f CRITICS.md ]] && "$CLI" check --json | grep -q '"critics":false' && ! "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "no-critics repo unaffected (no CRITICS.md, critics:false)" || _fail "critics opt-in leak"
rm -rf "$TMP_CR2"

# a ROADMAP Done log grown to 3+ shipped items with zero critique rows warns CRITICS_STALE.
TMP_CR3="$(mktemp -d)"; ( cd "$TMP_CR3" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  printf '# CRITICS\n' > CRITICS.md
  "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "check warns CRITICS_STALE (Done log grew, zero critique rows)" || _fail "CRITICS_STALE not detected"
rm -rf "$TMP_CR3"

# a logged critique row silences the warning even with the same Done log.
TMP_CR4="$(mktemp -d)"; ( cd "$TMP_CR4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  printf '# CRITICS\n| # | Critique | Severity | Disposition | link |\n|---|---|---|---|---|\n| 1 | obj | high | accepted | - |\n' > CRITICS.md
  ! "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "a logged critique row silences CRITICS_STALE" || _fail "critique row didn't silence CRITICS_STALE"
rm -rf "$TMP_CR4"

# below the 3-item threshold, no warning.
TMP_CR5="$(mktemp -d)"; ( cd "$TMP_CR5" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n' > ROADMAP.md
  printf '# CRITICS\n' > CRITICS.md
  ! "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "below-threshold Done log doesn't warn CRITICS_STALE" || _fail "threshold not respected"
rm -rf "$TMP_CR5"

# RM-42 (critic-stage finding #2): a real init --critics scaffold (shipping
# templates/CRITICS.md.tmpl's own example row unmodified) with a Done log
# grown to 3+ items STILL warns — the template's placeholder row must not
# silently count as a real logged critique.
TMP_CR5B="$(mktemp -d)"; ( cd "$TMP_CR5B" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "a fresh init --critics scaffold still warns CRITICS_STALE (template row doesn't count)" || _fail "template example row silenced CRITICS_STALE"
rm -rf "$TMP_CR5B"

# a git-ignored CRITICS.md is exempt from the staleness check (private register).
TMP_CR6="$(mktemp -d)"; ( cd "$TMP_CR6" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  printf '# CRITICS\n' > CRITICS.md && printf 'CRITICS.md\n' >> .gitignore
  ! "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "git-ignored CRITICS.md exempt from CRITICS_STALE (SCARS §PRIVATE-STYLE-OVERLAY)" || _fail "gitignored CRITICS.md still warns"
rm -rf "$TMP_CR6"

# --- RM-2b: atlas critique auto-dispatch + provenance stamping -----------
echo ""
echo "-- atlas critique (auto-dispatch + provenance stamping) --"

# a stubbed codex CLI on PATH: atlas critique auto-detects it (no --with-*
# flag needed), dispatches synchronously, and stamps the entry with real
# provenance (model id + effort) — never a static placeholder.
FAKE_BIN_CR7="$(mktemp -d)"
cat > "$FAKE_BIN_CR7/codex" <<'FAKECODEX'
#!/usr/bin/env bash
[[ "$1" == "--version" ]] && { echo "codex-cli 0.0.0-stub"; exit 0; }
echo "STUB CRITIQUE: | 1 | fake finding | low | verified-no-issue | - |"
FAKECODEX
chmod +x "$FAKE_BIN_CR7/codex"
TMP_CR7="$(mktemp -d)"; ( cd "$TMP_CR7" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="$FAKE_BIN_CR7:$PATH" HOME="$TMP_CR7" "$CLI" critique "auto dispatch" >/dev/null 2>&1
  grep -q "auto-detected" CRITICS.md \
    && grep -q "STUB CRITIQUE" CRITICS.md \
    && grep -q '\*\*Critic:\*\* codex (model:' CRITICS.md \
    && grep -q "effort:" CRITICS.md ) \
  && _pass "critique auto-detects installed codex CLI, dispatches, stamps provenance" || _fail "critique auto-dispatch/provenance"
rm -rf "$TMP_CR7" "$FAKE_BIN_CR7"

# without any critic CLI on PATH, critique degrades to print-only — no raw
# output block, no crash — and still stamps the manual-paste placeholder.
TMP_CR8="$(mktemp -d)"; ( cd "$TMP_CR8" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="/usr/bin:/bin" "$CLI" critique "no critic installed" >/dev/null 2>&1
  ! grep -q "Raw critic output" CRITICS.md \
    && grep -q "manual paste" CRITICS.md ) \
  && _pass "critique degrades to print-only when no critic CLI is installed" || _fail "critique print-only fallback"
rm -rf "$TMP_CR8"

# --no-auto forces print-only even when a critic CLI IS on PATH.
FAKE_BIN_CR9="$(mktemp -d)"
cat > "$FAKE_BIN_CR9/codex" <<'FAKECODEX'
#!/usr/bin/env bash
echo "SHOULD NOT RUN"
FAKECODEX
chmod +x "$FAKE_BIN_CR9/codex"
TMP_CR9="$(mktemp -d)"; ( cd "$TMP_CR9" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="$FAKE_BIN_CR9:$PATH" "$CLI" critique "no-auto forced" --no-auto >/dev/null 2>&1
  ! grep -q "SHOULD NOT RUN" CRITICS.md && grep -q "manual paste" CRITICS.md ) \
  && _pass "--no-auto forces print-only even with a critic CLI installed" || _fail "--no-auto didn't suppress auto-dispatch"
rm -rf "$TMP_CR9" "$FAKE_BIN_CR9"

# --range/--verify feed real diff-range/files/verification-command inputs
# into the appended entry — never a static placeholder (RM-2b provenance).
TMP_CR10="$(mktemp -d)"; ( cd "$TMP_CR10" && git init -q -b main 2>/dev/null
  echo one > a.txt && git add a.txt && git -c user.email=t@t -c user.name=t commit -q -m one
  echo two >> a.txt && git add a.txt && git -c user.email=t@t -c user.name=t commit -q -m two
  "$CLI" init --critics >/dev/null 2>&1
  PATH="/usr/bin:/bin" "$CLI" critique "ranged" --range "HEAD~1..HEAD" --verify "bash tests/x.sh" >/dev/null 2>&1
  grep -q "diff range: HEAD~1..HEAD" CRITICS.md \
    && grep -q "1 file(s)" CRITICS.md \
    && grep -q "verification commands run: bash tests/x.sh" CRITICS.md ) \
  && _pass "critique --range/--verify stamp real diff-range/files/verification inputs" || _fail "critique --range/--verify inputs"
rm -rf "$TMP_CR10"

# a malformed/unresolvable --range degrades gracefully instead of aborting
# under set -e + pipefail (the diff pipeline can exit non-zero on a bad ref).
TMP_CR11="$(mktemp -d)"; ( cd "$TMP_CR11" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="/usr/bin:/bin" "$CLI" critique "bad range" --range "not..a..real..range" >/dev/null 2>&1 ) \
  && _pass "critique tolerates an unresolvable --range (no set -e/pipefail abort)" || _fail "critique aborted on bad --range"
rm -rf "$TMP_CR11"

# the appended stub's disposition legend + new sections match the richer
# schema (verified-no-issue disposition, Assumptions challenged, Proposals).
TMP_CR12="$(mktemp -d)"; ( cd "$TMP_CR12" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="/usr/bin:/bin" "$CLI" critique "schema check" >/dev/null 2>&1
  grep -q "verified-no-issue" CRITICS.md \
    && grep -q "Assumptions challenged" CRITICS.md \
    && grep -q "Proposals (with evidence bar)" CRITICS.md ) \
  && _pass "critique stub carries the richer schema (verified-no-issue/assumptions/proposals)" || _fail "critique stub missing richer schema"
rm -rf "$TMP_CR12"

# RM-43 (critic-stage finding #3): a critic CLI that exits non-zero must be
# recorded as a FAILED dispatch, not a counted critique row — and must not
# silence CRITICS_STALE.
FAKE_BIN_CR13="$(mktemp -d)"
cat > "$FAKE_BIN_CR13/codex" <<'FAKECODEX'
#!/usr/bin/env bash
echo "error: auth token expired" >&2
exit 42
FAKECODEX
chmod +x "$FAKE_BIN_CR13/codex"
TMP_CR13="$(mktemp -d)"; ( cd "$TMP_CR13" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  printf '# CRITICS\n' > CRITICS.md
  PATH="$FAKE_BIN_CR13:$PATH" "$CLI" critique "failed dispatch test" >/dev/null 2>&1
  grep -q "DISPATCH FAILED" CRITICS.md \
    && ! grep -qE '^\|[[:space:]]*[0-9]+[[:space:]]*\|.*paste verbatim' CRITICS.md \
    && "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "a failed critic dispatch is recorded as failed, not a counted critique" || _fail "failed dispatch masqueraded as a real critique"
rm -rf "$TMP_CR13" "$FAKE_BIN_CR13"

# RM-43 (critic-stage finding #7): the critique prompt only lists context
# files that actually exist — a plain conformant repo (no ARCHITECTURE.md/
# docs/adr//research/) doesn't get pointed at them.
TMP_CR14="$(mktemp -d)"; ( cd "$TMP_CR14" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  ! "$CLI" critique "portable prompt test" --no-auto 2>&1 | grep -qE "ARCHITECTURE\.md|docs/adr/|research/" ) \
  && _pass "critique prompt omits ARCHITECTURE.md/docs/adr//research/ when absent" || _fail "critique prompt mentioned nonexistent private-style files"
rm -rf "$TMP_CR14"

# when those files DO exist, the prompt still lists them (backward-compat).
TMP_CR15="$(mktemp -d)"; ( cd "$TMP_CR15" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  printf '# Architecture\n' > ARCHITECTURE.md
  mkdir -p docs/adr research
  "$CLI" critique "portable prompt test 3" --no-auto 2>&1 | grep -q "ARCHITECTURE.md" \
    && "$CLI" critique "portable prompt test 4" --no-auto 2>&1 | grep -q "docs/adr/" \
    && "$CLI" critique "portable prompt test 5" --no-auto 2>&1 | grep -q "research/" ) \
  && _pass "critique prompt lists ARCHITECTURE.md/docs/adr//research/ when present" || _fail "existing private-style files wrongly omitted"
rm -rf "$TMP_CR15"

# RM-44: a verbose critic's captured output is capped at a byte budget (the
# TAIL is kept, since the final answer usually lands at the end) instead of
# silently ballooning CRITICS.md.
FAKE_BIN_CR16="$(mktemp -d)"
cat > "$FAKE_BIN_CR16/codex" <<'FAKECODEX'
#!/usr/bin/env bash
[[ "$1" == "--version" ]] && { echo "codex-cli 0.0.0-stub"; exit 0; }
awk 'BEGIN{for(i=0;i<50000;i++) printf "X"}'
echo ""
echo "FINAL_ANSWER_MARKER: the real critique"
FAKECODEX
chmod +x "$FAKE_BIN_CR16/codex"
TMP_CR16="$(mktemp -d)"; ( cd "$TMP_CR16" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="$FAKE_BIN_CR16:$PATH" "$CLI" critique "cap test" >/dev/null 2>&1
  grep -q "truncated: showing the final" CRITICS.md && grep -q "FINAL_ANSWER_MARKER" CRITICS.md ) \
  && _pass "a verbose critic's output is capped, keeping the tail" || _fail "output wasn't capped or lost the final answer"
rm -rf "$TMP_CR16" "$FAKE_BIN_CR16"

# a critic's small, real output is never truncated.
FAKE_BIN_CR17="$(mktemp -d)"
cat > "$FAKE_BIN_CR17/codex" <<'FAKECODEX'
#!/usr/bin/env bash
[[ "$1" == "--version" ]] && { echo "codex-cli 0.0.0-stub"; exit 0; }
echo "a small, real critique response"
FAKECODEX
chmod +x "$FAKE_BIN_CR17/codex"
TMP_CR17="$(mktemp -d)"; ( cd "$TMP_CR17" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  PATH="$FAKE_BIN_CR17:$PATH" "$CLI" critique "no cap test" >/dev/null 2>&1
  ! grep -q "truncated: showing the final" CRITICS.md ) \
  && _pass "a small critic response is never truncated" || _fail "small output wrongly truncated"
rm -rf "$TMP_CR17" "$FAKE_BIN_CR17"

# --- v0.5.0: deep anchor validation (atlas check --deep) ------------------
echo ""
echo "-- check --deep (anchor-body conformance) --"

# --deep is opt-in: a fresh scaffold passes even --deep --strict, and a plain
# check never emits anchor warnings (so it cannot regress existing repos).
TMP_D0="$(mktemp -d)"; ( cd "$TMP_D0" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  "$CLI" check --deep --strict >/dev/null 2>&1 \
    && ! "$CLI" check --json | grep -q 'ANCHOR_' ) \
  && _pass "check --deep is opt-in; fresh scaffold passes --deep --strict" || _fail "--deep opt-in"
rm -rf "$TMP_D0"

# --deep flags a ToC link with no matching <a id> body.
TMP_D1="$(mktemp -d)"; ( cd "$TMP_D1" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf -- '- [§GHOST — link only](#ghost)\n' >> SCARS.md
  "$CLI" check --deep --json | grep -q ANCHOR_TOC_NO_BODY ) \
  && _pass "check --deep flags a ToC link with no body" || _fail "--deep TOC_NO_BODY"
rm -rf "$TMP_D1"

# --deep flags an <a id> body with no ToC entry.
TMP_D2="$(mktemp -d)"; ( cd "$TMP_D2" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '\n<a id="orphan"></a>\n### §ORPHAN — body, no ToC\n**Do.** nothing.\n' >> SCARS.md
  "$CLI" check --deep --json | grep -q ANCHOR_NOT_IN_TOC ) \
  && _pass "check --deep flags a body anchor missing from the ToC" || _fail "--deep NOT_IN_TOC"
rm -rf "$TMP_D2"

# --deep flags a scar that states a problem but gives no remedy.
TMP_D3="$(mktemp -d)"; ( cd "$TMP_D3" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '\n- [§NOFIX — problem only](#nofix)\n' >> SCARS.md
  printf '\n<a id="nofix"></a>\n### §NOFIX — problem, no remedy\n**Symptom.** it breaks.\n' >> SCARS.md
  "$CLI" check --deep --json | grep -q ANCHOR_NO_REMEDY ) \
  && _pass "check --deep flags a problem with no '**Do.**' remedy" || _fail "--deep NO_REMEDY"
rm -rf "$TMP_D3"

# --deep flags a 'Where.' path that does not resolve, but skips glob patterns.
TMP_D4="$(mktemp -d)"; ( cd "$TMP_D4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '\n- [§GONE — stale where](#gone)\n- [§GLOBBED — glob where](#globbed)\n' >> SCARS.md
  printf '\n<a id="gone"></a>\n### §GONE — bad path\n**Do.** edit. **Where.** `does/not/exist.go`.\n' >> SCARS.md
  printf '\n<a id="globbed"></a>\n### §GLOBBED — glob path\n**Do.** edit. **Where.** `src/**/*.go`.\n' >> SCARS.md
  o="$("$CLI" check --deep --json)"
  echo "$o" | grep -q "ANCHOR_WHERE_UNRESOLVED.*does/not/exist.go" \
    && ! echo "$o" | grep -q 'src/\*\*' ) \
  && _pass "check --deep resolves Where paths, skips globs" || _fail "--deep WHERE_UNRESOLVED"
rm -rf "$TMP_D4"

# --deep ignores schema EXAMPLES inside code blocks (a fenced sample <a id>
# is documentation, not a real anchor — it must not be flagged).
TMP_D5="$(mktemp -d)"; ( cd "$TMP_D5" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '\n```\n<a id="example-id"></a>\n### §EXAMPLE — how to write a scar\n**Symptom.** ...\n```\n' >> SCARS.md
  "$CLI" check --deep --strict >/dev/null 2>&1 ) \
  && _pass "check --deep ignores example anchors inside code blocks" || _fail "--deep code-block immunity"
rm -rf "$TMP_D5"

# --- RM-1: EXECUTOR PACK (cross-model handoff, SPEC §8) -------------------
echo ""
echo "-- EXECUTOR PACK (atlas check --deep EXECUTOR_PACK_MISSING) --"

# a fresh init --loop scaffold ships the pack skeleton by default, so --deep
# --strict stays clean regardless of the default SCARS.md's anchor count.
TMP_EP0="$(mktemp -d)"; ( cd "$TMP_EP0" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  grep -qi "EXECUTOR PACK" ROADMAP.md \
    && "$CLI" check --deep --strict >/dev/null 2>&1 \
    && ! "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "fresh init --loop ships an EXECUTOR PACK; --deep --strict stays clean" || _fail "fresh EXECUTOR PACK scaffold"
rm -rf "$TMP_EP0"

# a ROADMAP.md with the pack stripped + SCARS.md at/above the 5-anchor floor
# warns EXECUTOR_PACK_MISSING under --deep (knowledge exists, unpackaged).
TMP_EP1="$(mktemp -d)"; ( cd "$TMP_EP1" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  awk '/^## ⚡ EXECUTOR PACK/{skip=1} /^## Now \(high EV\)/{skip=0} !skip' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  ! grep -qi "EXECUTOR PACK" ROADMAP.md \
    && [[ "$(grep -c '<a id=' SCARS.md)" -ge 5 ]] \
    && "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "5+ SCARS anchors + no pack warns EXECUTOR_PACK_MISSING" || _fail "EXECUTOR_PACK_MISSING not detected"
rm -rf "$TMP_EP1"

# below the 5-anchor floor, no warning even with the pack stripped.
TMP_EP2="$(mktemp -d)"; ( cd "$TMP_EP2" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  awk '/^## ⚡ EXECUTOR PACK/{skip=1} /^## Now \(high EV\)/{skip=0} !skip' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  printf '# SCARS\n\n## Table of contents\n\n- [a](#a)\n\n---\n\n<a id="a"></a>\n### a\nbody\n' > SCARS.md
  ! "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "below-threshold SCARS.md (< 5 anchors) doesn't warn EXECUTOR_PACK_MISSING" || _fail "threshold not respected"
rm -rf "$TMP_EP2"

# EXECUTOR_PACK_MISSING is a --deep-only check — a plain 'check' (no --deep)
# must never emit it, even on the same no-pack + 5+ anchor repo.
TMP_EP3="$(mktemp -d)"; ( cd "$TMP_EP3" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  awk '/^## ⚡ EXECUTOR PACK/{skip=1} /^## Now \(high EV\)/{skip=0} !skip' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  ! "$CLI" check --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "EXECUTOR_PACK_MISSING is --deep-only (plain check doesn't warn)" || _fail "EXECUTOR_PACK_MISSING leaked into plain check"
rm -rf "$TMP_EP3"

# RM-42 (critic-stage finding #1): a bare heading MENTION with no real
# trap-sheet content still warns — presence of the bytes "EXECUTOR PACK"
# is not a real pack.
TMP_EP4="$(mktemp -d)"; ( cd "$TMP_EP4" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## notes\nTODO: add EXECUTOR PACK later\n' > ROADMAP.md
  "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "a bare EXECUTOR PACK mention (no trap-sheet) still warns" || _fail "bare mention wrongly passed"
rm -rf "$TMP_EP4"

# a pack whose trap-sheet cites a REAL SCARS anchor (not the template's
# literal `§ANCHOR` placeholder) does NOT warn.
TMP_EP5="$(mktemp -d)"; ( cd "$TMP_EP5" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  grep -q "§NO-COAUTHOR" ROADMAP.md ) \
  && _pass "the template's own pack now seeds a real §NO-COAUTHOR citation" || _fail "template pack has no real anchor citation"
rm -rf "$TMP_EP5"

# an illustrative §ANCHOR cited elsewhere in the pack (e.g. the DoD's own
# §ATLAS-IS-INDEX example) must NOT satisfy the check when the TRAP-SHEET
# itself has no real citation — only the trap-sheet subsection counts.
TMP_EP6="$(mktemp -d)"; ( cd "$TMP_EP6" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  awk '/- \*\*T1\*\* Never add/{print "- <T1> <placeholder> (`§ANCHOR`)."; next} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  grep -q "§ATLAS-IS-INDEX" ROADMAP.md \
    && "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "a DoD-only anchor citation (outside the trap-sheet) doesn't satisfy the check" || _fail "DoD-only citation wrongly satisfied the check"
rm -rf "$TMP_EP6"

# RM-45 (critic finding #2): a degenerate pack — heading + trap-sheet + one
# real anchor but NONE of the other four SPEC fields — must warn, naming the
# missing fields.
TMP_EP7="$(mktemp -d)"; ( cd "$TMP_EP7" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  REAL="$(grep -oE '^### §[A-Z0-9-]+' SCARS.md | head -1 | sed 's/### //')"
  printf '# ROADMAP\n\n## EXECUTOR PACK\ntrap-sheet: %s\n\n- [ ] x\n## Done\n- [x] a\n' "$REAL" > ROADMAP.md
  out="$("$CLI" check --deep --json)"
  echo "$out" | grep -q EXECUTOR_PACK_MISSING \
    && echo "$out" | grep -q "definition of done" ) \
  && _pass "a degenerate pack (trap-sheet+anchor only) warns, naming missing fields" || _fail "degenerate pack wrongly passed"
rm -rf "$TMP_EP7"

# the five-marker match survives line wraps (the template's own 'definition
# of done' wraps across lines — a line-based grep would false-warn).
TMP_EP8="$(mktemp -d)"; ( cd "$TMP_EP8" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  ! "$CLI" check --deep --json | grep -q EXECUTOR_PACK_MISSING ) \
  && _pass "five-marker match is line-wrap tolerant (fresh template passes)" || _fail "line-wrapped field name false-warned"
rm -rf "$TMP_EP8"

# --- RM-26: capability tiers (atlas check UNMAPPED_TIER_TAG) --------------
echo ""
echo "-- capability tiers (atlas check UNMAPPED_TIER_TAG) --"

# no Model tier mapping block at all: tier: tags in ROADMAP.md are never
# validated (descriptive-only until a mapping block exists).
TMP_T1="$(mktemp -d)"; ( cd "$TMP_T1" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n- [ ] ticket A (tier: fast)\n- [ ] ticket B (tier: madeup)\n' >> ROADMAP.md
  ! "$CLI" check --json | grep -q UNMAPPED_TIER_TAG ) \
  && _pass "no mapping block: tier: tags are never validated" || _fail "UNMAPPED_TIER_TAG fired with no mapping block"
rm -rf "$TMP_T1"

# a mapping block + only mapped (case-insensitive) tier tags in the active
# queue: no warning.
TMP_T2="$(mktemp -d)"; ( cd "$TMP_T2" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n| strong | B |\n| frontier | C |\n' >> LOOP.md
  awk '/^## Done/{print "- [ ] ticket A (tier: fast)\n- [ ] ticket B (tier: Strong)\n"} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  ! "$CLI" check --json | grep -q UNMAPPED_TIER_TAG ) \
  && _pass "mapping block + only mapped tiers: no warning (case-insensitive)" || _fail "false positive with mapped tiers"
rm -rf "$TMP_T2"

# a mapping block + a ROADMAP tier: tag not in the block: warns, naming it.
# (tickets are inserted BEFORE the template's own '## Done' heading — RM-42's
# Done-log exclusion means content appended past it would be silently ignored.)
TMP_T3="$(mktemp -d)"; ( cd "$TMP_T3" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n| strong | B |\n' >> LOOP.md
  awk '/^## Done/{print "- [ ] ticket A (tier: fast)\n- [ ] ticket B (tier: quantum)\n"} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  "$CLI" check --json | grep -q 'UNMAPPED_TIER_TAG.*quantum' ) \
  && _pass "mapping block + unmapped tier tag warns, naming it" || _fail "UNMAPPED_TIER_TAG not detected"
rm -rf "$TMP_T3"

# the word 'frontier:' in prose must not false-match the 'tier:' substring
# it contains (a plain grep for 'tier:' would wrongly split 'frontier:').
TMP_T4="$(mktemp -d)"; ( cd "$TMP_T4" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n' >> LOOP.md
  printf '\n- [ ] ticket A (tier: fast) — frontier: some unrelated prose here\n' >> ROADMAP.md
  ! "$CLI" check --json | grep -q UNMAPPED_TIER_TAG ) \
  && _pass "'frontier:' prose doesn't false-match the tier: substring" || _fail "frontier: substring false-positive"
rm -rf "$TMP_T4"

# RM-42 (critic-stage finding #4): a stale tier: tag in the Done log (from a
# scheme predating a mapping change) must NOT warn — only the active queue
# is routing-relevant.
TMP_T5="$(mktemp -d)"; ( cd "$TMP_T5" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n' >> LOOP.md
  awk '/^## Done/{print "- [ ] active ticket (tier: fast)\n"} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  printf -- '- [x] old ticket (tier: quantum)\n' >> ROADMAP.md
  ! "$CLI" check --json | grep -q UNMAPPED_TIER_TAG ) \
  && _pass "a stale tier: tag in the Done log doesn't warn" || _fail "Done-log tier tag wrongly warned"
rm -rf "$TMP_T5"

# a tier: mention inside a fenced code block (an example/snippet) must NOT warn.
TMP_T6="$(mktemp -d)"; ( cd "$TMP_T6" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n' >> LOOP.md
  awk '/^## Done/{print "- [ ] active ticket (tier: fast)\n\n```\nexample: tier: quantum\n```\n"} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  ! "$CLI" check --json | grep -q UNMAPPED_TIER_TAG ) \
  && _pass "a tier: mention inside a fenced code block doesn't warn" || _fail "fenced tier tag wrongly warned"
rm -rf "$TMP_T6"

# an unmapped tier tag in the ACTIVE (non-Done, non-fenced) queue still warns.
TMP_T7="$(mktemp -d)"; ( cd "$TMP_T7" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping (RM-26)\n\n| tier | model |\n|---|---|\n| fast | A |\n' >> LOOP.md
  awk '/^## Done/{print "- [ ] active ticket (tier: quantum)\n"} {print}' ROADMAP.md > ROADMAP.md.new && mv ROADMAP.md.new ROADMAP.md
  "$CLI" check --json | grep -q 'UNMAPPED_TIER_TAG.*quantum' ) \
  && _pass "an unmapped tier tag in the active queue still warns" || _fail "active unmapped tier tag didn't warn"
rm -rf "$TMP_T7"

# RM-45 (critic finding #6): a tier mention in plain PROSE (a heading/notes
# paragraph, not a ticket record) must not warn; a tag inside a ticket's
# indented continuation lines must.
TMP_T8="$(mktemp -d)"; ( cd "$TMP_T8" && git init -q -b main 2>/dev/null && "$CLI" init --loop >/dev/null 2>&1
  printf '\n## Model tier mapping\n\n| tier | model |\n|---|---|\n| fast | A |\n' >> LOOP.md
  awk '/^## Done/{print "## Notes\nprose mentioning tier: quantum in passing\n\n- [ ] real ticket\n  - impact: x · tier: photon\n"} {print}' ROADMAP.md > R.new && mv R.new ROADMAP.md
  out="$("$CLI" check --json)"
  ! echo "$out" | grep -q "quantum" && echo "$out" | grep -q "photon" ) \
  && _pass "prose tier mention ignored; ticket-continuation tier tag warns" || _fail "tier scan not ticket-scoped"
rm -rf "$TMP_T8"

# --- RM-46: AKIGI.md + FRQ.md (cross-repo agent collaboration, SPEC §11) --
echo ""
echo "-- AKIGI.md + FRQ.md (init --akigi / --frq / check) --"

# init --akigi scaffolds AKIGI.md only; passes --deep --strict; json reports it.
TMP_AK1="$(mktemp -d)"; ( cd "$TMP_AK1" && git init -q -b main 2>/dev/null && "$CLI" init --akigi >/dev/null 2>&1
  [[ -f AKIGI.md && ! -f FRQ.md ]] \
    && "$CLI" check --deep --strict >/dev/null 2>&1 \
    && "$CLI" check --json | grep -q '"akigi":true,"frq":false' ) \
  && _pass "init --akigi scaffolds AKIGI.md, passes --deep --strict, json reports it" || _fail "init --akigi"
rm -rf "$TMP_AK1"

# init --frq implies --akigi (an FRQ without a purpose contract is rudderless).
TMP_AK2="$(mktemp -d)"; ( cd "$TMP_AK2" && git init -q -b main 2>/dev/null && "$CLI" init --frq >/dev/null 2>&1
  [[ -f AKIGI.md && -f FRQ.md ]] \
    && "$CLI" check --deep --strict >/dev/null 2>&1 \
    && "$CLI" check --json | grep -q '"akigi":true,"frq":true' ) \
  && _pass "init --frq scaffolds FRQ.md AND implies --akigi; passes --deep --strict" || _fail "init --frq"
rm -rf "$TMP_AK2"

# a repo without either file is fully unaffected.
TMP_AK3="$(mktemp -d)"; ( cd "$TMP_AK3" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  "$CLI" check --json | grep -q '"akigi":false,"frq":false' \
    && ! "$CLI" check --json | grep -qE 'AKIGI_|FRQ_' ) \
  && _pass "no-akigi/no-frq repo unaffected" || _fail "akigi/frq opt-in leak"
rm -rf "$TMP_AK3"

# an AKIGI.md with no Acceptance section warns AKIGI_NO_ACCEPTANCE.
TMP_AK4="$(mktemp -d)"; ( cd "$TMP_AK4" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# AKIGI\n\n## Purpose\nx\n' > AKIGI.md
  "$CLI" check --json | grep -q AKIGI_NO_ACCEPTANCE ) \
  && _pass "AKIGI.md without an Acceptance section warns" || _fail "AKIGI_NO_ACCEPTANCE not detected"
rm -rf "$TMP_AK4"

# an FRQ.md missing Protocol/Index warns both; FRQ without AKIGI warns too.
TMP_AK5="$(mktemp -d)"; ( cd "$TMP_AK5" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# FRQ\nno sections\n' > FRQ.md
  out="$("$CLI" check --json)"
  echo "$out" | grep -q FRQ_NO_PROTOCOL && echo "$out" | grep -q FRQ_NO_INDEX \
    && echo "$out" | grep -q FRQ_NO_AKIGI ) \
  && _pass "bare FRQ.md warns FRQ_NO_PROTOCOL + FRQ_NO_INDEX + FRQ_NO_AKIGI" || _fail "FRQ warnings not detected"
rm -rf "$TMP_AK5"

# adding an AKIGI.md silences FRQ_NO_AKIGI (but section warnings stay honest).
TMP_AK6="$(mktemp -d)"; ( cd "$TMP_AK6" && git init -q -b main 2>/dev/null && "$CLI" init --akigi >/dev/null 2>&1
  printf '# FRQ\nno sections\n' > FRQ.md
  ! "$CLI" check --json | grep -q FRQ_NO_AKIGI ) \
  && _pass "AKIGI.md presence silences FRQ_NO_AKIGI" || _fail "FRQ_NO_AKIGI wrongly persists"
rm -rf "$TMP_AK6"

# the llms.txt export lists AKIGI.md + FRQ.md when present (outside-agent discovery).
TMP_AK7="$(mktemp -d)"; ( cd "$TMP_AK7" && git init -q -b main 2>/dev/null && "$CLI" init --frq >/dev/null 2>&1
  "$CLI" export --to llms-txt >/dev/null 2>&1
  grep -q "AKIGI.md" llms.txt && grep -q "FRQ.md" llms.txt ) \
  && _pass "llms.txt lists AKIGI.md + FRQ.md for outside-agent discovery" || _fail "llms.txt missing akigi/frq"
rm -rf "$TMP_AK7"

# the SessionStart hook surfaces the AKIGI pointer (and mentions FRQ when present).
TMP_AK8="$(mktemp -d)"; ( cd "$TMP_AK8" && git init -q -b main 2>/dev/null && "$CLI" init --frq >/dev/null 2>&1
  out="$(cd "$TMP_AK8" && bash "$ATLAS_HOME/hooks/atlas-skill-loader.sh")"
  echo "$out" | grep -q "AKIGI.md (purpose contract)" && echo "$out" | grep -q "FRQ.md is the cross-agent" ) \
  && _pass "hook surfaces the AKIGI pointer + FRQ mention" || _fail "hook missing akigi/frq pointer"
rm -rf "$TMP_AK8"

# phase 2: init --intake scaffolds the full quartet (AKIGI+FRQ+BRD+SRD) and
# passes --deep --strict; json reports all four true.
TMP_AK9="$(mktemp -d)"; ( cd "$TMP_AK9" && git init -q -b main 2>/dev/null && "$CLI" init --intake >/dev/null 2>&1
  [[ -f AKIGI.md && -f FRQ.md && -f BRD.md && -f SRD.md ]] \
    && "$CLI" check --deep --strict >/dev/null 2>&1 \
    && "$CLI" check --json | grep -q '"akigi":true,"frq":true,"brd":true,"srd":true' ) \
  && _pass "init --intake scaffolds AKIGI+FRQ+BRD+SRD; passes --deep --strict" || _fail "init --intake"
rm -rf "$TMP_AK9"

# --brd alone implies --akigi (and nothing else); passes --deep --strict.
TMP_AK10="$(mktemp -d)"; ( cd "$TMP_AK10" && git init -q -b main 2>/dev/null && "$CLI" init --brd >/dev/null 2>&1
  [[ -f AKIGI.md && -f BRD.md && ! -f FRQ.md && ! -f SRD.md ]] \
    && "$CLI" check --deep --strict >/dev/null 2>&1 ) \
  && _pass "init --brd implies --akigi only; passes --deep --strict" || _fail "init --brd"
rm -rf "$TMP_AK10"

# bare BRD.md / SRD.md warn their section codes — incl. SRD_NO_CONTACT (an
# SRD without a private channel invites exploit detail into a public file).
TMP_AK11="$(mktemp -d)"; ( cd "$TMP_AK11" && git init -q -b main 2>/dev/null && "$CLI" init >/dev/null 2>&1
  printf '# BRD\nbare\n' > BRD.md
  printf '# SRD\nbare\n' > SRD.md
  out="$("$CLI" check --json)"
  echo "$out" | grep -q BRD_NO_PROTOCOL && echo "$out" | grep -q BRD_NO_INDEX \
    && echo "$out" | grep -q BRD_NO_AKIGI && echo "$out" | grep -q SRD_NO_PROTOCOL \
    && echo "$out" | grep -q SRD_NO_INDEX && echo "$out" | grep -q SRD_NO_CONTACT \
    && echo "$out" | grep -q SRD_NO_AKIGI ) \
  && _pass "bare BRD.md/SRD.md warn all section codes incl. SRD_NO_CONTACT" || _fail "BRD/SRD warnings not detected"
rm -rf "$TMP_AK11"

# llms.txt lists the whole quartet for outside-agent discovery.
TMP_AK12="$(mktemp -d)"; ( cd "$TMP_AK12" && git init -q -b main 2>/dev/null && "$CLI" init --intake >/dev/null 2>&1
  "$CLI" export --to llms-txt >/dev/null 2>&1
  grep -q "AKIGI.md" llms.txt && grep -q "FRQ.md" llms.txt \
    && grep -q "BRD.md" llms.txt && grep -q "SRD.md" llms.txt ) \
  && _pass "llms.txt lists the full AKIGI+FRQ+BRD+SRD quartet" || _fail "llms.txt missing brd/srd"
rm -rf "$TMP_AK12"

# --- new commands (smoke) ------------------------------------------------
echo ""
echo "-- new commands --"

"$CLI" measure >/dev/null 2>&1 && _pass "measure runs" || _fail "measure"
"$CLI" measure --badge 2>/dev/null | grep -q 'shields.io' && _pass "measure --badge emits a shield" || _fail "measure --badge"
"$CLI" doctor >/dev/null 2>&1 && _pass "doctor runs" || _fail "doctor"
"$CLI" badge 2>/dev/null | grep -q 'shields.io' && _pass "badge emits markdown" || _fail "badge"
"$CLI" export --to llms-txt >/dev/null 2>&1 && [[ -f "$TMP/llms.txt" ]] && _pass "export --to llms-txt writes llms.txt" || _fail "export llms-txt"
"$CLI" export --to all >/dev/null 2>&1 && [[ -f "$TMP/.github/copilot-instructions.md" ]] && _pass "export --to all fans out" || _fail "export all"
"$CLI" bench --dry-run >/dev/null 2>&1 && _pass "bench --dry-run runs (no agent invoked)" || _fail "bench dry-run"
"$CLI" bench --runtime openai --api-base http://127.0.0.1:1 --model x --dry-run >/dev/null 2>&1 && _pass "bench openai --dry-run runs" || _fail "bench openai dry-run"
ATLAS_HOME=/opt/cellar/atlas "$CLI" uninstall 2>&1 | grep -qi 'package' && _pass "uninstall defers package-managed installs" || _fail "uninstall defer"

# MCP server: registration snippet + a real JSON-RPC handshake
"$CLI" mcp --config 2>/dev/null | grep -q '"mcpServers"' && _pass "mcp --config emits registration JSON" || _fail "mcp --config"
if command -v python3 >/dev/null 2>&1; then
  MCP_IN='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"atlas_orient","arguments":{}}}'
  MCP_OUT="$(printf '%s\n' "$MCP_IN" | ATLAS_PROJECT="$TMP" "$CLI" mcp 2>/dev/null)"
  echo "$MCP_OUT" | grep -q '"serverInfo"'     && _pass "mcp initialize handshake"               || _fail "mcp initialize"
  echo "$MCP_OUT" | grep -q 'atlas_orient'      && _pass "mcp tools/list lists atlas_orient"      || _fail "mcp tools/list"
  echo "$MCP_OUT" | grep -q 'where things live' && _pass "mcp atlas_orient returns the map"        || _fail "mcp atlas_orient"
  echo "$MCP_OUT" | grep -q 'atlas_graph'       && _fail "mcp backend tools must stay hidden"      || _pass "mcp deep tools hidden without a backend"
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | ATLAS_PROJECT="$TMP" ATLAS_MCP_BACKEND_URL="https://x.example" "$CLI" mcp 2>/dev/null | grep -q 'atlas_graph' && _pass "mcp deep tools appear when backend set" || _fail "mcp backend gating"
else
  _pass "mcp JSON-RPC tests skipped (no python3)"
fi

# Task-aware orientation (atlas orient)
if command -v python3 >/dev/null 2>&1; then
  "$CLI" orient >/dev/null 2>&1 && _pass "orient (no task) runs" || _fail "orient full"
  ATLAS_PROJECT="$TMP" "$CLI" orient "add validation" 2>/dev/null | grep -q 'oriented for: add validation' && _pass "orient (task) returns a scoped view" || _fail "orient task-scoped"
  ATLAS_PROJECT="$TMP" "$CLI" map 2>/dev/null | grep -q 'flowchart' && _pass "map emits a Mermaid graph (piped → Markdown)" || _fail "map mermaid"
  ATLAS_PROJECT="$TMP" "$CLI" map --ascii 2>/dev/null | grep -q 'module map' && _pass "map --ascii draws a Unicode graph" || _fail "map ascii"
  ATLAS_PROJECT="$TMP" "$CLI" map --html 2>/dev/null | grep -q 'mermaid.min.js' && _pass "map --html emits a standalone page" || _fail "map html"
else
  _pass "orient/map tests skipped (no python3)"
fi

# MCP HTTP transport + token auth (start the server, assert 401 without / 200 with)
if command -v python3 >/dev/null 2>&1; then
  HPORT=7399
  ATLAS_PROJECT="$TMP" "$CLI" mcp --http --port "$HPORT" --token testtok >/dev/null 2>&1 &
  HPID=$!
  if python3 - "$HPORT" testtok <<'PY'
import sys, time, urllib.request as u
port, token = sys.argv[1], sys.argv[2]
base = "http://127.0.0.1:%s" % port
for _ in range(25):
    try: u.urlopen(base + "/health", timeout=1); break
    except Exception: time.sleep(0.2)
else: sys.exit(2)
body = b'{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
try:
    u.urlopen(u.Request(base + "/", data=body, headers={"Content-Type": "application/json"}), timeout=3)
    sys.exit(3)                                   # should have been rejected
except u.HTTPError as e:
    if e.code != 401: sys.exit(3)
r = u.urlopen(u.Request(base + "/", data=body, headers={"Content-Type": "application/json", "Authorization": "Bearer " + token}), timeout=3)
sys.exit(0 if b"atlas_orient" in r.read() else 4)
PY
  then _pass "mcp --http: token auth (401 without, 200+tools with)"; else _fail "mcp --http auth"; fi
  kill "$HPID" 2>/dev/null
else
  _pass "mcp --http test skipped (no python3)"
fi

# init --analyze injects an auto-detected map
TMP_AN="$(mktemp -d)"; pushd "$TMP_AN" >/dev/null
git init -q -b main 2>/dev/null; echo '{}' > package.json; mkdir -p src; touch src/index.js
"$CLI" init --analyze >/dev/null 2>&1
grep -q '0.5 Auto-detected' ATLAS.md && _pass "init --analyze injects a detected map" || _fail "init --analyze"
"$CLI" check >/dev/null 2>&1 && _pass "--analyze output still passes check" || _fail "--analyze breaks check"
popd >/dev/null; rm -rf "$TMP_AN"

# drift enforcement
TMP_DR="$(mktemp -d)"; pushd "$TMP_DR" >/dev/null
git init -q -b main 2>/dev/null
"$CLI" init >/dev/null 2>&1
git add -A && git -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
"$CLI" check --changed-files >/dev/null 2>&1 && _pass "drift: clean tree passes --changed-files" || _fail "clean tree failed drift"
touch NEWMODULE.js; git add NEWMODULE.js
"$CLI" check --changed-files >/dev/null 2>&1; rc=$?
[[ $rc -ne 0 ]] && _pass "drift: structural add without ATLAS update fails" || _fail "structural drift not caught"
popd >/dev/null; rm -rf "$TMP_DR"

# --- public style presets ------------------------------------------------
echo ""
echo "-- style presets --"

"$CLI" styles | grep -q "karpathy" && _pass "styles lists karpathy" || _fail "missing karpathy"
"$CLI" styles | grep -q "strict"   && _pass "styles lists strict"   || _fail "missing strict"
"$CLI" styles | grep -q "minimal"  && _pass "styles lists minimal"  || _fail "missing minimal"
"$CLI" styles | grep -q "google"   && _pass "styles lists google"   || _fail "missing google"

# unknown style rejected
TMP2="$(mktemp -d)"; pushd "$TMP2" >/dev/null
"$CLI" init --style bogus >/dev/null 2>&1; rc=$?
[[ $rc -ne 0 ]] && _pass "unknown --style rejected (rc=$rc)" || _fail "unknown style accepted"
popd >/dev/null; rm -rf "$TMP2"

# karpathy preset
TMP3="$(mktemp -d)"; pushd "$TMP3" >/dev/null
git init -q -b main 2>/dev/null
"$CLI" init --style karpathy >/dev/null
grep -q "Don't assume" CLAUDE.md && _pass "karpathy preset writes mantra" || _fail "no mantra"
popd >/dev/null; rm -rf "$TMP3"

# minimal preset is short
TMP4="$(mktemp -d)"; pushd "$TMP4" >/dev/null
git init -q -b main 2>/dev/null
"$CLI" init --style minimal >/dev/null
lines=$(wc -l < ATLAS.md | tr -d ' ')
[[ $lines -lt 60 ]] && _pass "minimal ATLAS is short ($lines lines)" || _fail "too long ($lines)"
popd >/dev/null; rm -rf "$TMP4"

# --- mirror --------------------------------------------------------------
echo ""
echo "-- mirror --"

TMP10="$(mktemp -d)"; pushd "$TMP10" >/dev/null
git init -q -b main 2>/dev/null
"$CLI" mirror init >/dev/null 2>&1
[[ -f .atlas/mirror.allow ]]                       && _pass "mirror init writes .atlas/mirror.allow"     || _fail "no mirror.allow"
[[ -f .github/workflows/atlas-promote.yml ]]       && _pass "mirror init writes GH action (staged)"      || _fail "no atlas-promote.yml"
grep -q "refs/heads/main:refs/heads/public" .atlas/mirror.allow && _pass "staged default: main→public"  || _fail "wrong staged refspec"

"$CLI" mirror push --remote origin >/dev/null 2>&1; rc=$?
[[ $rc -ne 0 ]] && _pass "mirror push refuses remote='origin'" || _fail "didn't refuse origin"

status_out="$("$CLI" mirror status 2>&1)"
echo "$status_out" | grep -q "allowed refspecs"  && _pass "mirror status prints allowlist"   || _fail "status missing allowlist"
echo "$status_out" | grep -q "atlas-promote.yml" && _pass "mirror status detects GH action"  || _fail "status missing workflow"

REMOTE="$(mktemp -d)"; git init -q --bare "$REMOTE"
git remote add public "$REMOTE"
echo hi > README.md && git add README.md && git -c user.email=t@t -c user.name=t commit -q -m i
"$CLI" mirror push >/dev/null 2>&1
git --git-dir="$REMOTE" branch | grep -q public && _pass "mirror push lands main on remote 'public' branch" || _fail "main didn't land"
rm -rf "$REMOTE"

"$CLI" mirror init --direct --force >/dev/null 2>&1
grep -q "refs/heads/main:refs/heads/main" .atlas/mirror.allow && _pass "--direct: main→main refspec" || _fail "wrong direct refspec"

"$CLI" mirror init --dual-repo --force >/dev/null 2>&1; rc=$?
[[ $rc -ne 0 ]] && _pass "--dual-repo requires --public-repo" || _fail "didn't refuse missing --public-repo"

"$CLI" mirror init --dual-repo --public-repo "git@github.com:y/p.git" --force >/dev/null 2>&1
grep -q "DUAL-REPO" .atlas/mirror.allow                && _pass "--dual-repo writes DUAL-REPO config"          || _fail "no DUAL-REPO"
[[ -f .github/workflows/atlas-promote-to-public.yml ]] && _pass "--dual-repo writes cross-repo workflow"       || _fail "no cross-repo workflow"
grep -q "PUBLIC_REPO_DEPLOY_KEY" .github/workflows/atlas-promote-to-public.yml && _pass "dual-repo needs deploy key" || _fail "missing deploy key reference"
popd >/dev/null; rm -rf "$TMP10"

# --- auth (read-only + ssh sandboxed via fake HOME) ---------------------
echo ""
echo "-- auth --"

auth_out="$("$CLI" auth status 2>&1)"
echo "$auth_out" | grep -q "vendor CLIs" && _pass "auth status prints vendor section" || _fail "missing vendor section"
echo "$auth_out" | grep -q "SSH keys"     && _pass "auth status prints SSH section"    || _fail "missing SSH section"

FAKE_HOME="$(mktemp -d)"
HOME="$FAKE_HOME" "$CLI" auth login --method ssh --email "t@t" >/dev/null 2>&1
[[ -f "$FAKE_HOME/.ssh/id_ed25519_github" ]]     && _pass "auth login creates github key"  || _fail "no github key"
[[ -f "$FAKE_HOME/.ssh/id_ed25519_gitlab" ]]     && _pass "auth login creates gitlab key"  || _fail "no gitlab key"
grep -q "atlas-auth:start" "$FAKE_HOME/.ssh/config" && _pass "auth login adds marker block" || _fail "no marker block"
replay_out="$(HOME="$FAKE_HOME" "$CLI" auth login --method ssh --email "t@t" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && _pass "auth login --method ssh is idempotent" || _fail "re-run failed"
n=$(grep -c "atlas-auth:start" "$FAKE_HOME/.ssh/config")
[[ "$n" == "1" ]] && _pass "auth login doesn't duplicate marker on re-run" || _fail "marker duplicated ($n)"
# the re-run exercises the ssh-config marker REPLACE path (a multi-line awk
# -v value is unreliable on macOS's default awk — RM-9's finding, ported here).
echo "$replay_out" | grep -qi "awk:" && _fail "ssh-config marker replace triggered an awk warning" || _pass "ssh-config marker replace produces no awk warnings"
rm -rf "$FAKE_HOME"

# --- runtime adapters ---------------------------------------------------
echo ""
echo "-- runtime adapters --"

TMP_ADAPT="$(mktemp -d)"; pushd "$TMP_ADAPT" >/dev/null

PROJECT_DIR="$PWD" "$ATLAS_HOME/adapters/cursor/install.sh" >/dev/null 2>&1
[[ -f .cursor/rules/atlas.mdc ]] && _pass "cursor adapter writes .cursor/rules/atlas.mdc" || _fail "no cursor rule"
grep -q "alwaysApply: true" .cursor/rules/atlas.mdc && _pass "cursor rule has alwaysApply" || _fail "no alwaysApply"

PROJECT_DIR="$PWD" "$ATLAS_HOME/adapters/copilot/install.sh" >/dev/null 2>&1
[[ -f .github/copilot-instructions.md ]] && _pass "copilot adapter writes .github/copilot-instructions.md" || _fail "no copilot instructions"
PROJECT_DIR="$PWD" "$ATLAS_HOME/adapters/copilot/install.sh" >/dev/null 2>&1
n=$(grep -c "atlas-bootstrap:start" .github/copilot-instructions.md)
[[ "$n" == "1" ]] && _pass "copilot adapter idempotent (marker count=1)" || _fail "copilot duplicated ($n)"

PROJECT_DIR="$PWD" ZED_CFG="$PWD/.fake-zed-cfg" "$ATLAS_HOME/adapters/zed/install.sh" >/dev/null 2>&1
[[ -f .zed/atlas.md ]] && _pass "zed adapter writes .zed/atlas.md" || _fail "no zed hint"
[[ -f .fake-zed-cfg/agents.md ]] && _pass "zed adapter writes user-level agents.md" || _fail "no zed user-level"

popd >/dev/null; rm -rf "$TMP_ADAPT"

TMP_GEM="$(mktemp -d)"
GEMINI_DIR="$TMP_GEM" "$ATLAS_HOME/adapters/gemini/install.sh" >/dev/null 2>&1
[[ -f "$TMP_GEM/GEMINI.md" ]] && _pass "gemini adapter writes GEMINI.md" || _fail "no GEMINI.md"
GEMINI_DIR="$TMP_GEM" "$ATLAS_HOME/adapters/gemini/install.sh" >/dev/null 2>&1
n=$(grep -c "atlas-bootstrap:start" "$TMP_GEM/GEMINI.md")
[[ "$n" == "1" ]] && _pass "gemini adapter idempotent (marker count=1)" || _fail "gemini duplicated ($n)"
rm -rf "$TMP_GEM"

echo ""
echo "-- batch 2: self-maintaining map · leaderboard · router --"

# init --analyze is idempotent (re-running refreshes §0.5, never duplicates it)
TMP_ID="$(mktemp -d)"; ( cd "$TMP_ID" && git init -q && echo '{}'>package.json && mkdir s && touch s/a.js \
  && "$CLI" init >/dev/null 2>&1 && "$CLI" init --analyze >/dev/null 2>&1 && "$CLI" init --analyze >/dev/null 2>&1 \
  && [ "$(grep -c '0.5 Auto-detected' ATLAS.md)" = "1" ] ) && _pass "init --analyze is idempotent (1 §0.5 block)" || _fail "analyze idempotent"
rm -rf "$TMP_ID"

# self-maintaining map hook
TMP_HK="$(mktemp -d)"; ( cd "$TMP_HK" && git init -q && "$CLI" init >/dev/null 2>&1 \
  && "$CLI" hooks install --auto >/dev/null 2>&1 && [ -x .git/hooks/pre-commit ] ) \
  && _pass "hooks install writes an executable pre-commit hook" || _fail "hooks install"
( cd "$TMP_HK" && "$CLI" hooks status 2>&1 | grep -qi 'is installed' ) && _pass "hooks status: installed" || _fail "hooks status"
( cd "$TMP_HK" && "$CLI" hooks uninstall >/dev/null 2>&1 && "$CLI" hooks status 2>&1 | grep -qi 'not installed' ) && _pass "hooks uninstall removes the block" || _fail "hooks uninstall"
rm -rf "$TMP_HK"

# leaderboard share
( cd "$TMP" && "$CLI" measure --share 2>/dev/null | grep -q 'share your savings' ) && _pass "measure --share prints a submission" || _fail "measure --share"

# --- RM-9: atlas leaderboard --render (CSV -> Markdown table) ------------
echo ""
echo "-- atlas leaderboard --render --"

# a single-row CSV renders deterministically between markers, preserving
# surrounding content, with no stderr noise (macOS's default awk warns on
# multi-line -v values — the temp-file/getline approach must avoid that).
TMP_LB1="$(mktemp -d)"; ( cd "$TMP_LB1" && mkdir -p data docs
  printf 'repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date\nfoo/bar,abc1234,10,1000,100,90,99,0.5.0,2026-01-01\n' > data/leaderboard.csv
  printf 'intro\n<!-- leaderboard:start -->\nold\n<!-- leaderboard:end -->\noutro\n' > docs/LEADERBOARD.md
  out="$("$CLI" leaderboard --render 2>&1)"
  ! echo "$out" | grep -qi "awk:" \
    && grep -q "foo/bar" docs/LEADERBOARD.md \
    && grep -q "^intro$" docs/LEADERBOARD.md \
    && grep -q "^outro$" docs/LEADERBOARD.md ) \
  && _pass "leaderboard --render regenerates the table, no awk warnings, preserves surrounding content" || _fail "leaderboard --render basic case"
rm -rf "$TMP_LB1"

# multiple rows all render; re-running is idempotent (same output twice).
TMP_LB2="$(mktemp -d)"; ( cd "$TMP_LB2" && mkdir -p data docs
  printf 'repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date\nfoo/bar,abc1234,10,1000,100,90,99,0.5.0,2026-01-01\nbaz/qux,def4567,50,5000,300,90,94,0.5.0,2026-02-02\n' > data/leaderboard.csv
  printf '<!-- leaderboard:start -->\n<!-- leaderboard:end -->\n' > docs/LEADERBOARD.md
  "$CLI" leaderboard --render >/dev/null 2>&1
  out1="$(cat docs/LEADERBOARD.md)"
  "$CLI" leaderboard --render >/dev/null 2>&1
  out2="$(cat docs/LEADERBOARD.md)"
  [[ "$out1" == "$out2" ]] && grep -q "foo/bar" docs/LEADERBOARD.md && grep -q "baz/qux" docs/LEADERBOARD.md ) \
  && _pass "leaderboard --render handles multiple rows and is idempotent" || _fail "leaderboard --render multi-row/idempotency"
rm -rf "$TMP_LB2"

# a header mismatch is a hard error (schema validation).
TMP_LB3="$(mktemp -d)"; ( cd "$TMP_LB3" && mkdir -p data docs
  printf 'wrong,header\nfoo,bar\n' > data/leaderboard.csv
  printf '<!-- leaderboard:start -->\n<!-- leaderboard:end -->\n' > docs/LEADERBOARD.md
  ! "$CLI" leaderboard --render >/dev/null 2>&1 ) \
  && _pass "leaderboard --render rejects a header mismatch" || _fail "leaderboard --render accepted bad header"
rm -rf "$TMP_LB3"

# a malformed row (wrong field count) is a hard error.
TMP_LB4="$(mktemp -d)"; ( cd "$TMP_LB4" && mkdir -p data docs
  printf 'repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date\nfoo/bar,abc1234,10,1000,100\n' > data/leaderboard.csv
  printf '<!-- leaderboard:start -->\n<!-- leaderboard:end -->\n' > docs/LEADERBOARD.md
  ! "$CLI" leaderboard --render >/dev/null 2>&1 ) \
  && _pass "leaderboard --render rejects a malformed row" || _fail "leaderboard --render accepted malformed row"
rm -rf "$TMP_LB4"

# a docs/LEADERBOARD.md with no markers is a clear error, not silent no-op.
TMP_LB5="$(mktemp -d)"; ( cd "$TMP_LB5" && mkdir -p data docs
  printf 'repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date\nfoo/bar,abc1234,10,1000,100,90,99,0.5.0,2026-01-01\n' > data/leaderboard.csv
  printf '# no markers here\n' > docs/LEADERBOARD.md
  ! "$CLI" leaderboard --render >/dev/null 2>&1 ) \
  && _pass "leaderboard --render errors when markers are missing" || _fail "leaderboard --render silently no-op'd without markers"
rm -rf "$TMP_LB5"

# 2026-07-10 critic finding #1: a START marker without its END marker must
# hard-error and leave the file untouched — the awk state machine would
# otherwise silently truncate everything after the start marker.
TMP_LB6="$(mktemp -d)"; ( cd "$TMP_LB6" && mkdir -p data docs
  printf 'repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date\nfoo/bar,abc1234,10,1000,100,90,99,0.5.0,2026-01-01\n' > data/leaderboard.csv
  printf 'intro\n<!-- leaderboard:start -->\nold\nTRAILING CONTENT\n' > docs/LEADERBOARD.md
  ! "$CLI" leaderboard --render >/dev/null 2>&1 \
    && grep -q "TRAILING CONTENT" docs/LEADERBOARD.md ) \
  && _pass "a missing end marker hard-errors without truncating the file" || _fail "missing end marker truncated or silently passed"
rm -rf "$TMP_LB6"

# RM-45 (critic finding #5): adversarial CSV values hard-error with the field
# named — non-numeric counts, out-of-range/inverted percents, pipe injection,
# a non-hex commit, a bad date; a well-typed row still renders.
TMP_LB7="$(mktemp -d)"; ( cd "$TMP_LB7" && mkdir -p data docs
  H='repo,commit,files,skim_tok,spine_tok,reduction_pct_low,reduction_pct_high,atlas_version,date'
  printf '<!-- leaderboard:start -->\n<!-- leaderboard:end -->\n' > docs/LEADERBOARD.md
  bad=0
  for row in \
    'foo/bar,abc1234,ten,1000,100,90,99,0.5.0,2026-01-01' \
    'foo/bar,abc1234,10,1000,100,NaN,999,0.5.0,2026-01-01' \
    'foo|inject,abc1234,10,1000,100,90,99,0.5.0,2026-01-01' \
    'foo/bar,nothex!,10,1000,100,90,99,0.5.0,2026-01-01' \
    'foo/bar,abc1234,10,1000,100,95,90,0.5.0,2026-01-01' \
    'foo/bar,abc1234,10,1000,100,90,99,0.5.0,not-a-date'; do
    printf '%s\n%s\n' "$H" "$row" > data/leaderboard.csv
    "$CLI" leaderboard --render >/dev/null 2>&1 && bad=1
  done
  printf '%s\nfoo/bar,abc1234,10,1000,100,90,99,0.5.0,2026-01-01\n' "$H" > data/leaderboard.csv
  [[ $bad -eq 0 ]] && "$CLI" leaderboard --render >/dev/null 2>&1 && grep -q "foo/bar" docs/LEADERBOARD.md ) \
  && _pass "adversarial CSV rows hard-error; a well-typed row renders" || _fail "CSV schema validation leaked"
rm -rf "$TMP_LB7"

# same guard on the auth path: a corrupted ~/.ssh/config marker pair must
# hard-error, never truncate the user's own Host entries after the marker.
FAKE_HOME_MB="$(mktemp -d)"
HOME="$FAKE_HOME_MB" "$CLI" auth login --method ssh --email "t@t" >/dev/null 2>&1
grep -v "# atlas-auth:end" "$FAKE_HOME_MB/.ssh/config" > "$FAKE_HOME_MB/.ssh/config.new" && mv "$FAKE_HOME_MB/.ssh/config.new" "$FAKE_HOME_MB/.ssh/config"
printf 'Host usercustom\n  User me\n' >> "$FAKE_HOME_MB/.ssh/config"
if HOME="$FAKE_HOME_MB" "$CLI" auth login --method ssh --email "t@t" >/dev/null 2>&1; then
  _fail "auth login succeeded on a broken marker pair"
else
  grep -q "Host usercustom" "$FAKE_HOME_MB/.ssh/config" \
    && _pass "auth login hard-errors on a broken marker pair without truncating config" \
    || _fail "auth login truncated user content after broken marker"
fi
rm -rf "$FAKE_HOME_MB"

# 2026-07-10 critic finding #3: a FAILED dispatch whose output happens to be
# table-shaped (inside the fenced failure block) must NOT silence CRITICS_STALE.
FAKE_BIN_CR18="$(mktemp -d)"
cat > "$FAKE_BIN_CR18/codex" <<'FAKECODEX'
#!/usr/bin/env bash
echo "| 1 | partial table row before crash | high | - | - |"
echo "error: auth token expired" >&2
exit 42
FAKECODEX
chmod +x "$FAKE_BIN_CR18/codex"
TMP_CR18="$(mktemp -d)"; ( cd "$TMP_CR18" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
  printf '# ROADMAP\n- [ ] x\n## Done\n- [x] a\n- [x] b\n- [x] c\n' > ROADMAP.md
  printf '# CRITICS\n' > CRITICS.md
  PATH="$FAKE_BIN_CR18:$PATH" "$CLI" critique "fail with table output" >/dev/null 2>&1
  "$CLI" check --json | grep -q CRITICS_STALE ) \
  && _pass "table-shaped failure output (fenced) doesn't silence CRITICS_STALE" || _fail "fenced failure table silenced CRITICS_STALE"
rm -rf "$TMP_CR18" "$FAKE_BIN_CR18"

# 2026-07-10 critic finding #4: the 20KB cap must be measured in BYTES —
# multibyte UTF-8 output (>20KB bytes, <20k characters) must still be capped.
if command -v python3 >/dev/null 2>&1; then
  FAKE_BIN_CR19="$(mktemp -d)"
  cat > "$FAKE_BIN_CR19/codex" <<'FAKECODEX'
#!/usr/bin/env bash
python3 -c "print('\U0001F389' * 8000)"
echo "FINAL_ANSWER_MARKER"
FAKECODEX
  chmod +x "$FAKE_BIN_CR19/codex"
  TMP_CR19="$(mktemp -d)"; ( cd "$TMP_CR19" && git init -q -b main 2>/dev/null && "$CLI" init --critics >/dev/null 2>&1
    PATH="$FAKE_BIN_CR19:$PATH" "$CLI" critique "utf8 cap" >/dev/null 2>&1
    grep -q "truncated: showing the final" CRITICS.md && grep -q "FINAL_ANSWER_MARKER" CRITICS.md ) \
    && _pass "the output cap is byte-based (UTF-8 transcript over 20KB bytes gets capped)" || _fail "UTF-8 transcript escaped the byte cap"
  rm -rf "$TMP_CR19" "$FAKE_BIN_CR19"
else
  _pass "UTF-8 byte-cap test skipped (no python3)"
fi

# MCP router: deep tools light up + route when an ecosystem CLI (stub graphify) is on PATH
if command -v python3 >/dev/null 2>&1; then
  GFD="$(mktemp -d)"; printf '#!/usr/bin/env bash\necho ok\n' > "$GFD/graphify"; chmod +x "$GFD/graphify"
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | PATH="$GFD:$PATH" ATLAS_PROJECT="$TMP" "$CLI" mcp 2>/dev/null | grep -q 'atlas_graph' \
    && _pass "mcp router: deep tools appear when graphify is on PATH" || _fail "mcp router detection"
  rm -rf "$GFD"
else
  _pass "mcp router test skipped (no python3)"
fi

# deepened analyzer: a real module graph with talks-to edges (cmd → internal)
TMP_DG="$(mktemp -d)"; ( cd "$TMP_DG" && git init -q && echo m>go.mod && mkdir cmd internal \
  && echo 'import "x/internal/y"' > cmd/main.go && touch internal/y.go \
  && "$CLI" init >/dev/null 2>&1 && "$CLI" init --analyze >/dev/null 2>&1 \
  && grep -q 'Module graph' ATLAS.md && grep -qE '\| .cmd/. \|.*internal' ATLAS.md ) \
  && _pass "analyze builds a module graph with talks-to edges" || _fail "analyze module graph"
rm -rf "$TMP_DG"

# one-command onboard scaffolds the quartet + measures
TMP_OB="$(mktemp -d)"; ( cd "$TMP_OB" && git init -q && echo m>go.mod && mkdir cmd && echo x>cmd/main.go \
  && "$CLI" onboard >/dev/null 2>&1 && [ -f ATLAS.md ] && [ -f SCARS.md ] && [ -f AGENTS.md ] ) \
  && _pass "onboard scaffolds + measures in one command" || _fail "onboard"
rm -rf "$TMP_OB"

# measure stays graceful on a tiny repo (no nonsensical negative %)
TMP_TY="$(mktemp -d)"; ( cd "$TMP_TY" && git init -q && echo m>go.mod && "$CLI" init >/dev/null 2>&1 \
  && "$CLI" measure 2>/dev/null | grep -q 'overhead' ) && _pass "measure is graceful on a tiny repo" || _fail "measure tiny-repo guard"
rm -rf "$TMP_TY"

# measure must NOT abort on a >400-file repo (the `| head -400` SIGPIPE-under-pipefail trap):
# it must still print its banner (the abort would happen *before* the banner).
TMP_BIG="$(mktemp -d)"; ( cd "$TMP_BIG" && git init -q && mkdir s && i=0 && while [ $i -lt 450 ]; do echo x > "s/f$i.go"; i=$((i+1)); done \
  && echo 'package s'>s/m.go && "$CLI" init >/dev/null 2>&1 \
  && "$CLI" measure 2>/dev/null | grep -q 'atlas measure' ) && _pass "measure survives a >400-file repo (no SIGPIPE abort)" || _fail "measure big-repo SIGPIPE"
rm -rf "$TMP_BIG"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
