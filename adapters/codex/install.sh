#!/usr/bin/env bash
# adapters/codex/install.sh
#
# Wires ATLAS into the OpenAI Codex CLI.
#
# Codex CLI (https://github.com/openai/codex) reads a project-local
# AGENTS.md at startup, plus an optional ~/.codex/AGENTS.md global.
# We don't have a strict SessionStart hook, so we instead append an
# "ATLAS bootstrap" stanza to ~/.codex/AGENTS.md that tells Codex to
# `cat ATLAS.md && cat .agents/skill/*/SKILL.md` at the start of
# every task.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"

_say() { echo "atlas[codex]: $*"; }

mkdir -p "$CODEX_DIR"
AGENTS_MD="$CODEX_DIR/AGENTS.md"

MARKER_START="<!-- atlas-bootstrap:start -->"
MARKER_END="<!-- atlas-bootstrap:end -->"

BLOCK=$(cat <<EOF
${MARKER_START}
## ATLAS bootstrap (auto-managed)

At the start of every task, before exploring the codebase:

1. If \`./ATLAS.md\` exists, read it. It is the project graph index — pointers to every important module, cross-cutting concerns, glossary, data model, observability, build/deploy.
2. If \`./.agents/skill/<project>/SKILL.md\` exists, read its Table of Contents. Anchors (\`§NAME-LIKE-THIS\`) are stable; expand a section's body only when relevant to your task.
3. Cite SKILL anchors in commit messages and PR descriptions.

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
${MARKER_END}
EOF
)

if [[ -f "$AGENTS_MD" ]] && grep -q "$MARKER_START" "$AGENTS_MD"; then
  # Replace the existing block.
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

_say "done. The Codex CLI will now read ATLAS.md and SKILL.md at the"
_say "start of every task in any project that has them."
