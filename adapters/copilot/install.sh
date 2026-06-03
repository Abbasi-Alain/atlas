#!/usr/bin/env bash
# adapters/copilot/install.sh
#
# Wires ATLAS into GitHub Copilot Chat (VS Code / JetBrains).
#
# Copilot Chat (VS Code) reads .github/copilot-instructions.md in the
# project, which acts as a per-repo system prompt for the chat. We
# install a marker-delimited ATLAS bootstrap block there.
#
# Note: Copilot autocomplete (the inline code suggestions) does NOT
# read this file — only the chat does. The inline model is small and
# context-window-limited; it can't be steered the same way.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"

_say() { echo "atlas[copilot]: $*"; }

cd "$PROJECT_DIR"
mkdir -p .github
INSTR="$PROJECT_DIR/.github/copilot-instructions.md"

MARKER_START="<!-- atlas-bootstrap:start -->"
MARKER_END="<!-- atlas-bootstrap:end -->"

BLOCK=$(cat <<EOF
${MARKER_START}
## ATLAS bootstrap

This repo uses the [ATLAS](https://github.com/Abbasi-Alain/atlas) standard.

Before exploring code or making changes:

1. Read \`./ATLAS.md\` §0 (Quick orientation) and §1 (Top-level). It maps every important module and cross-cutting concern.
2. Read \`./.agents/skill/<project>/SKILL.md\` Table of Contents. Anchors (\`§NAME-LIKE-THIS\`) are stable references to bug-pattern playbooks.
3. Cite SKILL anchors in commit messages and PR descriptions.
4. Update ATLAS.md in the same commit as any structural change.

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
${MARKER_END}
EOF
)

if [[ -f "$INSTR" ]] && grep -q "$MARKER_START" "$INSTR"; then
  awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$BLOCK" '
    $0 == start { skipping = 1; print block; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$INSTR" > "$INSTR.tmp" && mv "$INSTR.tmp" "$INSTR"
  _say "updated existing ATLAS block in $INSTR"
else
  printf "\n%s\n" "$BLOCK" >> "$INSTR"
  _say "appended ATLAS block to $INSTR"
fi

_say ""
_say "done. Copilot Chat in VS Code / JetBrains will read this on every"
_say "chat in this project."
_say ""
_say "Caveat: this affects Copilot CHAT only. The inline autocomplete"
_say "model is separately steered (smaller context); it won't read"
_say "ATLAS.md the same way. The chat model does."
