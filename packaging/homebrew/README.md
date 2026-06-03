# Homebrew tap setup

This directory holds the formula. To activate the tap so users can `brew install atlas`, do this **once**:

## 1) Create the tap repository on GitHub

The repo MUST be named exactly `homebrew-atlas`:

```bash
gh repo create Abbasi-Alain/homebrew-atlas \
  --public \
  --description "Homebrew tap for ATLAS — Agentic Harness Standard"
```

## 2) Clone + add the formula

```bash
git clone https://github.com/Abbasi-Alain/homebrew-atlas.git ~/homebrew-atlas
mkdir -p ~/homebrew-atlas/Formula
cp packaging/homebrew/atlas.rb ~/homebrew-atlas/Formula/atlas.rb
cd ~/homebrew-atlas
git add Formula/atlas.rb
git commit -m "Add atlas formula v0.1.0"
git push origin main
```

## 3) Verify

```bash
brew tap Abbasi-Alain/atlas
brew install atlas
atlas version
```

If it works, the public install pattern is:

```bash
brew tap Abbasi-Alain/atlas && brew install atlas
```

## On every new release

Bump `url`, `sha256`, and `version` in `Formula/atlas.rb`:

```bash
# Compute the new SHA after tagging vX.Y.Z and pushing the tag:
TARBALL="https://github.com/Abbasi-Alain/atlas/archive/refs/tags/vX.Y.Z.tar.gz"
SHA=$(curl -sL "$TARBALL" | shasum -a 256 | awk '{print $1}')
echo "$SHA"

# Edit Formula/atlas.rb (3 lines) and commit.
```

You can automate this with a GitHub Action in the tap repo that watches the
main repo's release events and bumps the formula automatically.
