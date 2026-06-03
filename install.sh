#!/usr/bin/env bash
# install.sh — install the `atlas` CLI.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Abbasi-Alain/atlas/main/install.sh | bash
#
# Or, after cloning:
#   ./install.sh
#
# Defaults:
#   ATLAS_HOME        ~/.atlas             (where to put assets)
#   ATLAS_BIN_DIR     ~/.local/bin         (where to put the launcher)
#   ATLAS_REPO        https://github.com/Abbasi-Alain/atlas
#   ATLAS_REF         main                  (branch / tag / sha)
#
# Override any of them via env vars, e.g.:
#   ATLAS_HOME=/opt/atlas ATLAS_BIN_DIR=/usr/local/bin sudo -E bash install.sh

set -euo pipefail

ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"
ATLAS_BIN_DIR="${ATLAS_BIN_DIR:-$HOME/.local/bin}"
ATLAS_REPO="${ATLAS_REPO:-https://github.com/Abbasi-Alain/atlas}"
ATLAS_REF="${ATLAS_REF:-main}"

_have() { command -v "$1" >/dev/null 2>&1; }
_say()  { echo "atlas-install: $*"; }
_die()  { echo "atlas-install: $*" >&2; exit 1; }

# 1. Acquire the source tree.
if [[ -d "$ATLAS_HOME/.git" ]]; then
  _say "updating existing install at $ATLAS_HOME"
  git -C "$ATLAS_HOME" fetch --depth=1 origin "$ATLAS_REF"
  git -C "$ATLAS_HOME" checkout -q "$ATLAS_REF"
  git -C "$ATLAS_HOME" reset --hard "origin/${ATLAS_REF}" 2>/dev/null \
    || git -C "$ATLAS_HOME" reset --hard "$ATLAS_REF"
elif [[ -d "$ATLAS_HOME" && -f "$ATLAS_HOME/bin/atlas" ]]; then
  _say "found existing non-git install at $ATLAS_HOME — leaving as-is"
elif _have git; then
  _say "cloning $ATLAS_REPO -> $ATLAS_HOME"
  rm -rf "$ATLAS_HOME"
  git clone --depth=1 -b "$ATLAS_REF" "$ATLAS_REPO" "$ATLAS_HOME"
elif _have curl && _have tar; then
  _say "downloading tarball ($ATLAS_REF) -> $ATLAS_HOME"
  rm -rf "$ATLAS_HOME"
  mkdir -p "$ATLAS_HOME"
  curl -fsSL "${ATLAS_REPO}/archive/${ATLAS_REF}.tar.gz" \
    | tar -xz -C "$ATLAS_HOME" --strip-components=1
else
  _die "need either 'git' or ('curl' + 'tar') to install"
fi

chmod +x "$ATLAS_HOME/bin/atlas"
[[ -f "$ATLAS_HOME/hooks/atlas-skill-loader.sh" ]] \
  && chmod +x "$ATLAS_HOME/hooks/atlas-skill-loader.sh"

# 2. Place a launcher on PATH.
mkdir -p "$ATLAS_BIN_DIR"
LAUNCHER="$ATLAS_BIN_DIR/atlas"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# atlas launcher — forwards to $ATLAS_HOME/bin/atlas
exec "$ATLAS_HOME/bin/atlas" "\$@"
EOF
chmod +x "$LAUNCHER"
_say "launcher installed: $LAUNCHER"

# 3. PATH hint.
case ":$PATH:" in
  *":$ATLAS_BIN_DIR:"*) : ;;
  *) _say "note: add '$ATLAS_BIN_DIR' to your PATH (e.g. in ~/.bashrc or ~/.zshrc)" ;;
esac

# 4. Show the logo for fun + confirmation.
echo ""
"$ATLAS_HOME/bin/atlas" version 2>/dev/null || true

# 5. Suggest adapter install.
_say ""
_say "next: wire ATLAS into your agent runtime:"
_say "  atlas install --runtime claude-code     # Claude Code (~/.claude)"
_say "  atlas install --runtime codex           # OpenAI Codex CLI"
_say "  atlas install --runtime opencode        # OpenCode SST"
_say "  atlas install --runtime hermes          # Hermes"
_say "  atlas install --runtime generic         # any runtime (manual doc)"
_say ""
_say "then in any project:    atlas init && atlas check"
