#!/usr/bin/env bash
# adapters/cursor/install.sh
#
# Wires ATLAS into Cursor. Cursor reads project-local rules from
# .cursor/rules/*.mdc. We install a project-aware rule that tells
# Cursor to read ATLAS.md and SKILL.md at the start of every task.
#
# This installer is project-scoped — run it from inside the project,
# not globally. Cursor's global config doesn't have a strict equivalent
# of SessionStart hooks, so we wire per-project.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"

_say() { echo "atlas[cursor]: $*"; }

cd "$PROJECT_DIR"
mkdir -p .cursor/rules
RULE="$PROJECT_DIR/.cursor/rules/atlas.mdc"

cat > "$RULE" <<'EOF'
---
description: ATLAS bootstrap — read project graph + playbook before any task
alwaysApply: true
---

At the start of every task, before exploring the codebase:

1. If `./ATLAS.md` exists, read its §0 (Quick orientation) and §1 (Top-level)
   sections. This is the project's graph index — every important module and
   its cross-cutting concerns are one click away.

2. If `./.agents/skill/<project>/SKILL.md` exists, read its Table of Contents.
   Anchors (§NAME-LIKE-THIS) are stable; expand a section's body only when
   relevant to your task.

3. Cite SKILL anchors in commit messages and PR descriptions.

4. If a structural change introduces a new module, service, or dependency,
   update ATLAS.md in the same commit (SKILL §ATLAS-IS-INDEX).

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
EOF

_say "wrote $RULE"
_say ""
_say "Cursor will now read ATLAS.md and SKILL.md at the start of every chat"
_say "in this project. The rule is project-scoped — re-run inside each project"
_say "you want covered."
_say ""
_say "For a global Cursor rule, copy this content into:"
_say "  ~/.cursor/rules/atlas.mdc"
