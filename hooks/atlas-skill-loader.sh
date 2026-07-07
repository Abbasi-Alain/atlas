#!/usr/bin/env bash
# atlas-skill-loader — SessionStart-equivalent hook.
#
# Detects ATLAS.md, SCARS.md, .agents/skill/<project>/SKILL.md (and, if present,
# the optional LOOP.md / BUGS.md / CRITICS.md) in the cwd and prints their
# navigational spine to stdout. Whichever agent
# runtime invokes this hook will see that output and feed it into
# the conversation as context — so the main agent automatically
# knows where things live and what NOT to do.
#
# Hook contract (runtime-agnostic):
#   - read no input
#   - print bounded output to stdout
#   - exit 0 always
#
# Output is bounded:
#   - ATLAS:   through end of §1 (~80 lines)
#   - SCARS:   Table-of-contents section only (failure anchors)
#   - SKILL:   ToC section only (anchors with one-line summaries)
#   - LOOP:    a one-line pointer (only if the repo runs an autonomous loop)
#   - PACK:    a one-line pointer (only if ROADMAP.md has an EXECUTOR PACK block)
#   - BUGS:    a one-line pointer (only if the repo has an open-issues register)
#   - CRITICS: a one-line pointer (only if the repo has a second-opinion log)
#
# Sub-agents do NOT inherit this hook; their parent must include a
# "read ATLAS.md, SCARS.md, and SKILL.md first" instruction in the prompt.

set -u

CWD="$(pwd 2>/dev/null || echo "$HOME")"
ATLAS="$CWD/ATLAS.md"
HAS_OUTPUT=0

if [[ -f "$ATLAS" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "ATLAS.md detected at $ATLAS — quick orientation:"
  echo "================================================================"
  awk '
    /^## 2\./ { exit }
    { print }
  ' "$ATLAS" | head -80
  echo ""
  echo "(full ATLAS: read $ATLAS — has graph index of every module)"
  echo ""
fi

SCARS="$CWD/SCARS.md"
if [[ -f "$SCARS" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "SCARS.md (hard-won failure memory) detected at $SCARS"
  echo "================================================================"
  echo "Anchors below are stable — DO NOT repeat these. Read the full"
  echo "section (Read tool) before touching the relevant area."
  echo ""
  awk '
    /^## Table of contents/ { in_toc = 1; print; next }
    in_toc && /^## / && !/^## Table of contents/ { exit }
    in_toc { print }
  ' "$SCARS"
  echo ""
fi

SKILL_FILE=""
if [[ -d "$CWD/.agents/skill" ]]; then
  SKILL_FILE=$(find "$CWD/.agents/skill" -maxdepth 2 -name SKILL.md -type f 2>/dev/null | head -1)
fi

if [[ -n "$SKILL_FILE" && -f "$SKILL_FILE" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "SKILL.md (procedural task playbook) detected at $SKILL_FILE"
  echo "================================================================"
  echo "Anchors below are stable — cite from commits/PRs and use Read"
  echo "tool on the file to expand any section's full body."
  echo ""
  awk '
    /^## Table of contents/ { in_toc = 1; print; next }
    in_toc && /^## / && !/^## Table of contents/ { exit }
    in_toc { print }
  ' "$SKILL_FILE"
  echo ""
fi

LOOP="$CWD/LOOP.md"
if [[ -f "$LOOP" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "LOOP.md (autonomous improvement loop) detected at $LOOP"
  echo "================================================================"
  echo "This repo runs an ATLAS autonomous loop. One iteration: pick the top"
  echo "ROADMAP.md item by expected value → implement → 'atlas check --strict'"
  echo "→ commit (cite SCARS §ANCHORS). Read LOOP.md for the rules."
  echo ""
fi

ROADMAP="$CWD/ROADMAP.md"
if [[ -f "$ROADMAP" ]] && grep -qi "EXECUTOR PACK" "$ROADMAP"; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "ROADMAP.md has an EXECUTOR PACK — read it before your first ticket"
  echo "================================================================"
  echo "Non-frontier models especially: the pack's trap-sheet + universal"
  echo "definition-of-done save you from repo-specific landmines. Read it once."
  echo ""
fi

BUGS="$CWD/BUGS.md"
if [[ -f "$BUGS" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "BUGS.md (open-issues register) detected at $BUGS"
  echo "================================================================"
  echo "check BUGS.md before debugging — a known-not-yet-understood issue may"
  echo "already be logged there, so you don't re-discover it at full cost."
  echo ""
fi

CRITICS="$CWD/CRITICS.md"
if [[ -f "$CRITICS" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "CRITICS.md (second-opinion log) detected at $CRITICS"
  echo "================================================================"
  echo "before a non-trivial decision ships, run 'atlas critique \"<topic>\"'"
  echo "for a cross-vendor adversarial pass — check CRITICS.md for prior"
  echo "objections first so you don't repeat one already raised."
  echo ""
fi

if [[ "$HAS_OUTPUT" == "0" ]]; then
  if [[ -d "$CWD/.git" || -f "$CWD/Cargo.toml" || -f "$CWD/pyproject.toml" \
        || -f "$CWD/package.json" || -f "$CWD/go.mod" || -d "$CWD/src" ]]; then
    echo "tip: this project has no ATLAS.md. Run 'atlas init' to bootstrap"
    echo "     a graph index + error-pattern playbook."
    echo "     ( https://github.com/Abbasi-Alain/atlas )"
  fi
fi

exit 0
