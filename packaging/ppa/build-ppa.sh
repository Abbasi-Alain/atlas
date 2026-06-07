#!/usr/bin/env bash
# build-ppa.sh — build a signed Debian SOURCE package for a Launchpad PPA.
#
# Run on Ubuntu/Debian (or `docker run --rm -it -v "$PWD":/src ubuntu:24.04`),
# NOT macOS. Builds from the committed tree (git archive HEAD), so the private
# `abbasi` symlink, `.DS_Store`, and `.launch/` can never leak into the package.
#
# Prereqs (one-time on the build box):
#   sudo apt-get update
#   sudo apt-get install -y devscripts debhelper dput-ng gnupg git nodejs
#   # …and a GPG key that you've uploaded + verified on Launchpad (see README.md)
#
# Usage:
#   packaging/ppa/build-ppa.sh [SERIES] [PPA_REV]
#     SERIES   target Ubuntu series (default: noble). One upload per series.
#     PPA_REV  bump when re-uploading the same version+series (default: 1)
#
# Env:
#   VERSION  upstream version (default: from package.json)
#   GPGKEY   key id to sign with (default: your default gpg key)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

SERIES="${1:-noble}"
PPA_REV="${2:-1}"
VERSION="${VERSION:-$(node -p "require('./package.json').version" 2>/dev/null \
          || grep -m1 '"version"' package.json | sed -E 's/.*"([0-9.]+)".*/\1/')}"
DEBVER="${VERSION}-1~ppa${PPA_REV}~${SERIES}1"

for t in dpkg-buildpackage debuild git; do
  command -v "$t" >/dev/null || { echo "missing '$t' — sudo apt-get install -y devscripts debhelper git"; exit 1; }
done

BUILD="$(mktemp -d)"
SRC="$BUILD/atlas-$VERSION"
echo "[ppa] staging committed tree (git archive HEAD) -> $SRC"
mkdir -p "$SRC"
git archive HEAD | tar -x -C "$SRC"

echo "[ppa] orig tarball: atlas_${VERSION}.orig.tar.gz"
( cd "$BUILD" && tar czf "atlas_${VERSION}.orig.tar.gz" "atlas-$VERSION" )

echo "[ppa] debian/ + changelog  ($DEBVER, $SERIES)"
cp -R packaging/ppa/debian "$SRC/debian"
chmod +x "$SRC/debian/rules"
cat > "$SRC/debian/changelog" <<EOF
atlas ($DEBVER) $SERIES; urgency=medium

  * Release $VERSION for $SERIES.

 -- Alain Abbasi <abbasi.alain@gmail.com>  $(date -R)
EOF

echo "[ppa] debuild -S (signing source package)"
args=(-S -sa)
[[ -n "${GPGKEY:-}" ]] && args+=("-k$GPGKEY")
( cd "$SRC" && debuild "${args[@]}" )

echo ""
echo "[ppa] built source package in: $BUILD"
ls -1 "$BUILD"/atlas_*"$DEBVER"* 2>/dev/null || true
echo ""
echo "[ppa] upload to your PPA with:"
echo "    dput ppa:<your-launchpad-user>/atlas \"$BUILD/atlas_${DEBVER}_source.changes\""
echo ""
echo "[ppa] first time? activate a PPA named 'atlas' at https://launchpad.net/~ first."
