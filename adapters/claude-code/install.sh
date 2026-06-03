#!/usr/bin/env bash
# adapters/claude-code/install.sh
#
# Wires ATLAS into Claude Code:
#   1. Copies the SessionStart hook into ~/.claude/hooks/
#   2. Registers the hook in ~/.claude/settings.json (idempotent merge)
#   3. Installs the /init-atlas slash command at ~/.claude/commands/
#
# Reads ATLAS_HOME from the parent `atlas install` invocation, or
# defaults to ~/.atlas.

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

_say() { echo "atlas[claude-code]: $*"; }
_die() { echo "atlas[claude-code]: $*" >&2; exit 1; }

[[ -d "$ATLAS_HOME" ]] || _die "ATLAS_HOME=$ATLAS_HOME does not exist (run install.sh first)"
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/commands"

# 1. Copy the hook.
HOOK_SRC="$ATLAS_HOME/hooks/atlas-skill-loader.sh"
HOOK_DST="$CLAUDE_DIR/hooks/atlas-skill-loader.sh"
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
_say "hook installed: $HOOK_DST"

# 2. Register the hook in settings.json (idempotent — uses jq if available).
SETTINGS="$CLAUDE_DIR/settings.json"
if [[ ! -f "$SETTINGS" ]]; then
  cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$HOOK_DST" } ] }
    ]
  }
}
EOF
  _say "settings.json created"
elif command -v jq >/dev/null 2>&1; then
  TMP=$(mktemp)
  jq --arg cmd "$HOOK_DST" '
    .hooks //= {} |
    .hooks.SessionStart //= [] |
    if any(.hooks.SessionStart[]?; .hooks[]?.command == $cmd)
    then .
    else .hooks.SessionStart += [ { "hooks": [ { "type": "command", "command": $cmd } ] } ]
    end
  ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
  _say "settings.json updated (hook registered)"
else
  _say "WARNING: 'jq' not found — please add this block to $SETTINGS manually:"
  cat <<EOF

  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$HOOK_DST" } ] }
    ]
  }

EOF
fi

# 3. Install the /init-atlas slash command.
CMD_DST="$CLAUDE_DIR/commands/init-atlas.md"
cat > "$CMD_DST" <<EOF
---
description: Bootstrap ATLAS.md + SKILL.md + CLAUDE.md + AGENTS.md + EXAMPLES.md from the ATLAS template. Args: --style <minimal|strict|karpathy|google|default>, --force.
allowed-tools: Bash, Read, Edit
---

# /init-atlas

Runs \`atlas init\` in the current project to bootstrap the **ATLAS trio**:
ATLAS.md (structural), SKILL.md (procedural), CLAUDE.md (behavioral) +
AGENTS.md mirror, plus EXAMPLES.md (teaching pairs).

## Args (via \`\$ARGUMENTS\`)

- \`--style <preset>\` — \`default\` | \`minimal\` | \`strict\` | \`karpathy\` | \`google\`. Run \`atlas styles\` for the live list.
- \`--force\` — overwrite existing files.

## Steps you (Claude) should take

1. Run: \`atlas init \$ARGUMENTS\`
2. Read the generated ATLAS.md (graph) and CLAUDE.md (behavior).
3. Walk the project tree (\`ls -1\`, \`git ls-files | head -100\`) and fill in:
   - ATLAS §0 quick-orientation rows mapping to real start-here files.
   - ATLAS §1, §2 module index tables with \`Role\` and \`Talks-to\` edges.
   - ATLAS §7 cross-cutting concerns (timezones, auth, logging, caching, concurrency, …) — only ones that exist.
   - ATLAS §A, §G, §D, §X, §R, §O, §Sec, §B — universal sections; delete the ones that don't apply, fill the rest tersely.
4. Run \`atlas check\` to validate.
5. Suggest: \`git add ATLAS.md CLAUDE.md AGENTS.md EXAMPLES.md .agents/skill/ && git commit -m "docs: ATLAS trio scaffolding"\`.

For the spec: see [Atlas SPEC](https://github.com/Abbasi-Alain/atlas/blob/main/docs/SPEC.md).
EOF
_say "slash command installed: $CMD_DST"

_say ""
_say "done. start (or /clear) a Claude Code session in any project — the"
_say "ATLAS.md / SKILL.md spine will load automatically. If neither file"
_say "exists yet, run /init-atlas inside Claude Code or 'atlas init' in"
_say "the shell."
