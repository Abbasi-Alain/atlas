#!/usr/bin/env bash
# atlas-skill-loader — SessionStart-equivalent hook.
#
# Detects ATLAS.md, SCARS.md, .agents/skill/<project>/SKILL.md (and, if present,
# the optional LOOP.md / BUGS.md / CRITICS.md / FAQ.md) in the cwd and prints their
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
#   - FAQ:     a one-line pointer (only if the repo has a Q&A knowledge ledger,
#              at FAQ.md or docs/FAQ.md)
#   - AKIGI:   a one-line pointer (only if the repo has a purpose contract;
#              mentions FRQ.md when the feature-request queue is present too)
#
# Sub-agents do NOT inherit this hook; their parent must include a
# "read ATLAS.md, SCARS.md, and SKILL.md first" instruction in the prompt.

set -u

CWD="$(pwd 2>/dev/null || echo "$HOME")"
ATLAS="$CWD/ATLAS.md"
HAS_OUTPUT=0

# Mirror guard (SPEC §5, BUG-7): a drifted AGENTS.md means every non-Claude
# runtime reads the wrong contract, and nothing fails loudly between manual
# 'atlas check' runs. cmp is cheap; run it every session start.
if [[ -f "$CWD/CLAUDE.md" && -f "$CWD/AGENTS.md" ]] && ! cmp -s "$CWD/CLAUDE.md" "$CWD/AGENTS.md"; then
  HAS_OUTPUT=1
  echo "!!! AGENTS.md HAS DRIFTED from CLAUDE.md — non-Claude runtimes are"
  echo "!!! reading the wrong behavioral contract RIGHT NOW."
  echo "!!! One-line fix:  atlas fix   (re-mirrors AGENTS.md from CLAUDE.md)"
  echo ""
fi

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

FAQ="$CWD/FAQ.md"
[[ -f "$FAQ" ]] || FAQ="$CWD/docs/FAQ.md"
if [[ -f "$FAQ" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "FAQ.md (Q&A knowledge ledger) detected at $FAQ"
  echo "================================================================"
  echo "check the FAQ before asking or re-deriving — questions a human already"
  echo "asked are answered there once, with pointers. Append new answered"
  echo "questions (stable FAQ-NNN ids) as they come up."
  echo ""
fi

HANDOFF_DIR="$CWD/.agents/handoff"
if [[ -d "$HANDOFF_DIR" ]]; then
  HANDOFFS="$(find "$HANDOFF_DIR" -name '*.md' 2>/dev/null | sort)"
  if [[ -n "$HANDOFFS" ]]; then
    HAS_OUTPUT=1
    echo "================================================================"
    echo "ACTIVE MISSION HANDOFFS (.agents/handoff/) — resume, don't rediscover"
    echo "================================================================"
    echo "An earlier agent's mission state lives in these files (MISSION/STATE/"
    echo "NEXT/VERIFY/FORBIDDEN/COST). If you are picking up one of these"
    echo "missions, READ the file first; delete it when the mission completes."
    while IFS= read -r HF; do
      echo "  - ${HF#"$CWD"/}"
    done <<< "$HANDOFFS"
    echo ""
  fi
fi

CLAIMS="$CWD/.agents/claims.md"
if [[ -f "$CLAIMS" ]] && grep -q '^- ' "$CLAIMS"; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "ACTIVE FILE CLAIMS (.agents/claims.md) — check before editing"
  echo "================================================================"
  echo "Another agent owns these paths. Claim before touching; release on"
  echo "completion ('atlas claim')."
  grep '^- ' "$CLAIMS"
  echo ""
fi

AKIGI="$CWD/AKIGI.md"
if [[ -f "$AKIGI" ]]; then
  HAS_OUTPUT=1
  echo "================================================================"
  echo "AKIGI.md (purpose contract) detected at $AKIGI"
  echo "================================================================"
  echo "this repo's raison d'être: purpose, scope/non-goals, and the"
  echo "acceptance principles incoming requests are triaged against."
  if [[ -f "$CWD/FRQ.md" ]]; then
    echo "FRQ.md is the cross-agent feature-request queue: triage open FRQs"
    echo "against the AKIGI; outside agents read the AKIGI before filing."
  fi
  if [[ -f "$CWD/BRD.md" ]]; then
    echo "BRD.md is the external bug-disclosure intake: triage open BRDs"
    echo "(evidence + repro required); accepted ones graduate to the"
    echo "internal BUGS.md flow."
  fi
  if [[ -f "$CWD/SRD.md" ]]; then
    echo "SRD.md is the security-disclosure surface: NEVER triage it as an"
    echo "agent — escalate to the maintainer; no exploit detail in public."
  fi
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
