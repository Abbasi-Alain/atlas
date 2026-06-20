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
HOME="$FAKE_HOME" "$CLI" auth login --method ssh --email "t@t" >/dev/null 2>&1; rc=$?
[[ $rc -eq 0 ]] && _pass "auth login --method ssh is idempotent" || _fail "re-run failed"
n=$(grep -c "atlas-auth:start" "$FAKE_HOME/.ssh/config")
[[ "$n" == "1" ]] && _pass "auth login doesn't duplicate marker on re-run" || _fail "marker duplicated ($n)"
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
