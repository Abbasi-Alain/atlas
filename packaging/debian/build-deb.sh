#!/usr/bin/env bash
# packaging/debian/build-deb.sh — produce atlas_<version>_all.deb
#
# Usage:
#   ./packaging/debian/build-deb.sh           # uses version from package.json
#   VERSION=0.2.0 ./packaging/debian/build-deb.sh
#
# Output: dist/atlas_<version>_all.deb
#
# After build, attach to the GitHub release:
#   gh release upload v$(VERSION) dist/atlas_*.deb
#
# Users install with:
#   curl -L https://github.com/Abbasi-Alain/atlas/releases/download/v0.1.0/atlas_0.1.0_all.deb -o /tmp/atlas.deb
#   sudo dpkg -i /tmp/atlas.deb
#   sudo apt-get install -f   # if any deps need pulling

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${VERSION:-$(python3 -c "import json; print(json.load(open('package.json'))['version'])")}"
ARCH="all"
PKG="atlas_${VERSION}_${ARCH}"
STAGE="packaging/debian/build/${PKG}"
OUT_DIR="dist"

echo "[deb] building atlas v${VERSION}"

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
         "$STAGE/usr/local/bin" \
         "$STAGE/usr/local/share/atlas"

# Stage the assets in /usr/local/share/atlas
cp -R bin templates adapters hooks "$STAGE/usr/local/share/atlas/"
cp -R docs/SPEC.md "$STAGE/usr/local/share/atlas/" 2>/dev/null || true
cp -R README.md LICENSE CHANGELOG.md "$STAGE/usr/local/share/atlas/" 2>/dev/null || true

# Launcher in PATH that points ATLAS_HOME at the staged tree.
cat > "$STAGE/usr/local/bin/atlas" <<'LAUNCHER'
#!/usr/bin/env bash
# atlas — Debian launcher. Forwards to the bundled CLI with ATLAS_HOME
# pointed at /usr/local/share/atlas.
export ATLAS_HOME="/usr/local/share/atlas"
exec "/usr/local/share/atlas/bin/atlas" "$@"
LAUNCHER
chmod 0755 "$STAGE/usr/local/bin/atlas"

# Control file.
cat > "$STAGE/DEBIAN/control" <<EOF
Package: atlas
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Maintainer: Alain Abbasi <abbasi.alain@gmail.com>
Depends: bash (>= 4.0), git
Recommends: gh
Homepage: https://github.com/Abbasi-Alain/atlas
Description: ATLAS — Agentic Harness Standard
 ATLAS is a three-Markdown-file standard that cuts AI agent context tokens
 by 10-30x. Zero infrastructure. Works with Claude / Codex / Cursor / Gemini
 / Zed / OpenCode / Copilot Chat / Hermes / generic — 9 runtime adapters
 out of the box. CLI ships init, check, mirror, auth, repo, critique, adr,
 research, and more.
EOF

mkdir -p "$OUT_DIR"
dpkg-deb --build "$STAGE" "$OUT_DIR/${PKG}.deb"

echo "[deb] wrote $OUT_DIR/${PKG}.deb"
ls -lh "$OUT_DIR/${PKG}.deb"

echo ""
echo "[deb] verify the package contents:"
echo "  dpkg-deb --contents $OUT_DIR/${PKG}.deb | head"
echo ""
echo "[deb] attach to GitHub release:"
echo "  gh release upload v${VERSION} $OUT_DIR/${PKG}.deb --clobber"
