# Packaging

Source manifests for distributing ATLAS via standard package channels.

| Channel | File | Setup |
|---|---|---|
| Homebrew tap (macOS/Linux) | `homebrew/atlas.rb` | See `homebrew/README.md` |
| Debian / Ubuntu `.deb` (download) | `debian/build-deb.sh` | Run `./build-deb.sh`; attach `dist/atlas_*.deb` to the release |
| Ubuntu PPA (`apt install atlas`) | `ppa/` | See `ppa/README.md` — needs a Launchpad account + GPG (build on Ubuntu) |
| AUR (Arch / Manjaro) | `aur/PKGBUILD` | See `aur/README.md` |

## Update on every release

After tagging `vX.Y.Z` and creating the GitHub release:

```bash
# 1) Compute the tarball SHA
TARBALL="https://github.com/Abbasi-Alain/atlas/archive/refs/tags/vX.Y.Z.tar.gz"
SHA=$(curl -sL "$TARBALL" | shasum -a 256 | awk '{print $1}')

# 2) Update SHA + version in:
#    - packaging/homebrew/atlas.rb       (url, sha256, version)
#    - packaging/aur/PKGBUILD            (pkgver, sha256sums)

# 3) Build + attach the .deb
./packaging/debian/build-deb.sh
gh release upload vX.Y.Z dist/atlas_*.deb --clobber

# 4) Push the brew formula to the tap repo
cp packaging/homebrew/atlas.rb ~/homebrew-atlas/Formula/atlas.rb
cd ~/homebrew-atlas && git add Formula/atlas.rb && git commit -m "atlas vX.Y.Z" && git push

# 5) Push the AUR PKGBUILD
cd ~/aur-atlas
cp ../atlas/packaging/aur/PKGBUILD .
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO && git commit -m "atlas vX.Y.Z" && git push
```

A future GitHub Action can automate steps 1–5 on every release.
