#!/usr/bin/env bash
# adapters/opencode/install.sh
#
# Wires ATLAS into OpenCode (sst/opencode).
#
# OpenCode reads project-local AGENTS.md (same convention as Codex
# CLI) and ~/.config/opencode/AGENTS.md global. We append a
# bootstrap block instructing OpenCode to read ATLAS.md and SKILL.md
# at the start of every task.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
OPENCODE_DIR="${OPENCODE_DIR:-$HOME/.config/opencode}"

_say() { echo "atlas[opencode]: $*"; }

mkdir -p "$OPENCODE_DIR"
AGENTS_MD="$OPENCODE_DIR/AGENTS.md"

MARKER_START="<!-- atlas-bootstrap:start -->"
MARKER_END="<!-- atlas-bootstrap:end -->"

BLOCK=$(cat <<EOF
${MARKER_START}
## ATLAS bootstrap (auto-managed)

At the start of every task, before exploring the codebase:

1. If \`./ATLAS.md\` exists, read it (graph index of every module + cross-cutting concerns + glossary + data model + observability + build/deploy).
2. If \`./.agents/skill/<project>/SKILL.md\` exists, read its Table of Contents. Anchors (\`§NAME-LIKE-THIS\`) are stable; expand bodies only when relevant.
3. Cite SKILL anchors in commit messages and PR descriptions.
4. If a structural change introduces a new module, service, or dependency, update ATLAS.md in the same commit (SKILL §ATLAS-IS-INDEX).

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
${MARKER_END}
EOF
)

if [[ -f "$AGENTS_MD" ]] && grep -q "$MARKER_START" "$AGENTS_MD"; then
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$BLOCK" '
    $0 == start { skipping = 1; print block; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$AGENTS_MD" > "$AGENTS_MD.tmp" && mv "$AGENTS_MD.tmp" "$AGENTS_MD"
  _say "updated existing ATLAS block in $AGENTS_MD"
else
  printf "\n%s\n" "$BLOCK" >> "$AGENTS_MD"
  _say "appended ATLAS block to $AGENTS_MD"
fi

_say "done."
