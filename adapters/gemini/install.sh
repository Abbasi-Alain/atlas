#!/usr/bin/env bash
# adapters/gemini/install.sh
#
# Wires ATLAS into the Gemini CLI. Gemini reads project-local GEMINI.md
# (same convention as AGENTS.md). We append an ATLAS bootstrap block
# globally, and provide a per-project hint.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
GEMINI_DIR="${GEMINI_DIR:-$HOME/.gemini}"

_say() { echo "atlas[gemini]: $*"; }

mkdir -p "$GEMINI_DIR"
G_MD="$GEMINI_DIR/GEMINI.md"

MARKER_START="<!-- atlas-bootstrap:start -->"
MARKER_END="<!-- atlas-bootstrap:end -->"

BLOCK=$(cat <<EOF
${MARKER_START}
## ATLAS bootstrap (auto-managed)

At the start of every task, before exploring the codebase:

1. If \`./ATLAS.md\` exists, read its §0 (Quick orientation) and §1 (Top-level). It is the project's graph index — every important module, cross-cutting concern, glossary entry, data model row, external dependency, runtime topology, observability signal, security boundary, and build/deploy step is one click away.
2. If \`./.agents/skill/<project>/SKILL.md\` exists, read its Table of Contents. Anchors (\`§NAME-LIKE-THIS\`) are stable; expand a section's body only when relevant.
3. Cite SKILL anchors in commit messages and PR descriptions.
4. If a structural change introduces a new module, service, or dependency, update ATLAS.md in the same commit (SKILL §ATLAS-IS-INDEX).

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
${MARKER_END}
EOF
)

if [[ -f "$G_MD" ]] && grep -q "$MARKER_START" "$G_MD"; then
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$BLOCK" '
    $0 == start { skipping = 1; print block; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$G_MD" > "$G_MD.tmp" && mv "$G_MD.tmp" "$G_MD"
  _say "updated existing ATLAS block in $G_MD"
else
  printf "\n%s\n" "$BLOCK" >> "$G_MD"
  _say "appended ATLAS block to $G_MD"
fi

_say ""
_say "done. Gemini CLI will now read ATLAS.md + SKILL.md at the start of"
_say "every task in any project that has them."
_say ""
_say "Per-project override: create ./GEMINI.md in any project that needs"
_say "different behavior — Gemini reads it before the global file."
