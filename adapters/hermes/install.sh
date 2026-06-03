#!/usr/bin/env bash
# adapters/hermes/install.sh
#
# Wires ATLAS into a Hermes agent stack.
#
# Hermes (NousResearch/Hermes-Function-Calling and downstream forks)
# uses a system-prompt-based bootstrap. We install a system-prompt
# fragment that any Hermes agent runner can `cat` into its system
# prompt at startup. The fragment is small and runtime-agnostic.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"

_say() { echo "atlas[hermes]: $*"; }

mkdir -p "$HERMES_DIR"
FRAGMENT="$HERMES_DIR/atlas-bootstrap.txt"

cat > "$FRAGMENT" <<'EOF'
# ATLAS bootstrap (project-aware orientation)

Before exploring the codebase or making changes:

1. If `./ATLAS.md` exists, read it. It is the project's graph index — pointers to every important module, cross-cutting concerns (timezones, auth, logging, caching, concurrency), glossary, data model, external dependencies, runtime topology, observability, security boundaries, and build/deploy.

2. If `./.agents/skill/<project>/SKILL.md` exists, read its Table of Contents. Anchors (§NAME-LIKE-THIS) are stable references to specific scars: each entry has symptom → root cause → do NOT → do → file location → commit SHA. Expand a section's body only when relevant to your task.

3. Cite SKILL anchors in commit messages and PR descriptions ("fixes §IBKR-OVERNIGHT regression").

4. If a structural change introduces a new module, service, or dependency, update ATLAS.md in the same commit (SKILL §ATLAS-IS-INDEX).

Spec: https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md
EOF

_say "system-prompt fragment installed: $FRAGMENT"
_say ""
_say "To use:"
_say "  - For a Hermes function-calling loop, prepend this fragment to your"
_say "    system prompt:"
_say "      SYSTEM_PROMPT=\"\$(cat $FRAGMENT)\\n\\n\$SYSTEM_PROMPT\""
_say "  - For a Hermes notebook/REPL, paste the contents into the system role"
_say "    at session start."
_say ""
_say "done."
