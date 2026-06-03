#!/usr/bin/env bash
# adapters/zed/install.sh
#
# Wires ATLAS into Zed. Zed's Assistant reads project-local AGENTS.md
# (since ~2025); we also drop a .zed/atlas.md as a project hint, plus
# append a marker block to ~/.config/zed/agents.md if that path is
# being used as the user-level agents config.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
ZED_CFG="${ZED_CFG:-$HOME/.config/zed}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"

_say() { echo "atlas[zed]: $*"; }

# 1. Project-scoped hint
mkdir -p "$PROJECT_DIR/.zed"
PROJ_HINT="$PROJECT_DIR/.zed/atlas.md"
cat > "$PROJ_HINT" <<'EOF'
# ATLAS bootstrap for Zed Assistant

When opening this project, before exploring or editing:

1. Read ./ATLAS.md §0 + §1 (project graph).
2. Read ./.agents/skill/<project>/SKILL.md Table of Contents.
3. Cite §ANCHOR-NAMES in commits.
4. Update ATLAS.md in the same commit as any structural change.

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
EOF
_say "wrote $PROJ_HINT (project hint)"

# 2. User-level agents config (Zed reads AGENTS.md in some setups)
mkdir -p "$ZED_CFG"
G_MD="$ZED_CFG/agents.md"
MARKER_START="<!-- atlas-bootstrap:start -->"
MARKER_END="<!-- atlas-bootstrap:end -->"
BLOCK=$(cat <<EOF
${MARKER_START}
## ATLAS bootstrap (auto-managed)

At the start of every task: if ./ATLAS.md exists, read §0 + §1. If
./.agents/skill/<project>/SKILL.md exists, read its Table of Contents.
Cite §ANCHOR-NAMES in commits. Update ATLAS.md in the same commit as
any structural change.

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
_say "done. Zed Assistant will read ATLAS.md + SKILL.md at the start of every"
_say "task in this project (.zed/atlas.md) and others (user-level agents.md)."
_say ""
_say "Note: Zed's exact agents file path has shifted across versions. If your"
_say "build doesn't pick up ~/.config/zed/agents.md, also create AGENTS.md at"
_say "the project root — Zed always reads that."
