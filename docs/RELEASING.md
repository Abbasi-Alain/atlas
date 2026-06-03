# Releasing ATLAS

The release pipeline is fully automated. To ship a new version:

```bash
# 1) Update CHANGELOG.md — add a [X.Y.Z] section above [Unreleased]
$EDITOR CHANGELOG.md

# 2) Bump package.json + create git tag + commit
npm version patch    # or minor / major / preminor / etc.

# 3) Push
git push origin main --tags
```

**That's it.** GitHub Actions does the rest.

---

## What happens automatically on `git push --tags`

1. **`release.yml`** fires on the tag push.
   - Extracts the CHANGELOG entry for the new version.
   - Creates the GitHub release with that body.
   - The release `published` event then triggers all the channel-specific workflows in parallel:

2. **`release-npm.yml`** — publishes `@alainabbasi/atlas@X.Y.Z` to npm with provenance.

3. **`release-deb.yml`** — builds `atlas_X.Y.Z_all.deb` and attaches to the release.

4. **`release-homebrew.yml`** — bumps the `Abbasi-Alain/homebrew-atlas` tap's formula with the new url + sha256 + version and pushes.

5. **`release-aur.yml`** — bumps the `aur.archlinux.org/atlas.git` PKGBUILD's pkgver + sha256sums and pushes.

All four channels updated within ~5 minutes of the tag push. No manual steps.

---

## One-time setup (do this once; never again)

These have to be done ONCE so the CI has credentials to publish on your behalf.

### 1. npm token

```
1. Go to https://www.npmjs.com/settings/alainabbasi/tokens/new
2. Select: "Automation" token (works without 2FA; never expires by default)
3. Generate
4. Copy the token (starts with `npm_...`)
5. Add to repo secrets:
   → https://github.com/Abbasi-Alain/atlas/settings/secrets/actions/new
   → Name:  NPM_TOKEN
   → Value: <paste>
```

### 2. Homebrew tap repo

```bash
# Create the empty tap repo
gh repo create Abbasi-Alain/homebrew-atlas \
  --public \
  --description "Homebrew tap for ATLAS"

# Push the initial formula
git clone https://github.com/Abbasi-Alain/homebrew-atlas.git ~/homebrew-atlas
mkdir -p ~/homebrew-atlas/Formula
cp packaging/homebrew/atlas.rb ~/homebrew-atlas/Formula/atlas.rb
cd ~/homebrew-atlas
git add Formula/atlas.rb
git commit -m "Initial atlas formula v0.1.0"
git push origin main
```

Then generate a Personal Access Token so CI can push to it:

```
1. Go to https://github.com/settings/personal-access-tokens/new
2. Select: "Fine-grained personal access token"
3. Repository access: "Only select repositories" → Abbasi-Alain/homebrew-atlas
4. Permissions → Contents: Read and write
5. Generate
6. Copy the token (starts with `github_pat_...`)
7. Add to MAIN repo secrets:
   → https://github.com/Abbasi-Alain/atlas/settings/secrets/actions/new
   → Name:  HOMEBREW_TAP_TOKEN
   → Value: <paste>
```

Users can now install:

```bash
brew tap Abbasi-Alain/atlas
brew install atlas
```

### 3. AUR account + SSH

```
1. Register at https://aur.archlinux.org/register
2. Generate an SSH key dedicated to AUR:
   ssh-keygen -t ed25519 -f ~/.ssh/aur_atlas -N "" -C "aur-atlas"
3. Upload the PUBLIC key (~/.ssh/aur_atlas.pub) to your AUR account:
   https://aur.archlinux.org/account/ → "Edit Account" → "SSH Public Key"
4. Initial push (one-time):
   ssh -i ~/.ssh/aur_atlas -o StrictHostKeyChecking=accept-new aur@aur.archlinux.org help
   GIT_SSH_COMMAND="ssh -i ~/.ssh/aur_atlas" git clone ssh://aur@aur.archlinux.org/atlas.git ~/aur-atlas
   cp packaging/aur/PKGBUILD ~/aur-atlas/PKGBUILD
   cd ~/aur-atlas
   # Need makepkg locally for .SRCINFO. If you're on macOS, run this on a Linux box / Docker.
   makepkg --printsrcinfo > .SRCINFO
   git add PKGBUILD .SRCINFO
   GIT_SSH_COMMAND="ssh -i ~/.ssh/aur_atlas" git commit -m "Initial commit: atlas v0.1.0"
   GIT_SSH_COMMAND="ssh -i ~/.ssh/aur_atlas" git push origin master
5. Add the PRIVATE key (~/.ssh/aur_atlas) to MAIN repo secrets so CI can push updates:
   → https://github.com/Abbasi-Alain/atlas/settings/secrets/actions/new
   → Name:  AUR_SSH_PRIVATE_KEY
   → Value: $(cat ~/.ssh/aur_atlas)   # the full private key, including the BEGIN/END lines
6. Add username + email:
   → Name: AUR_USERNAME   Value: alainabbasi    (or whatever you registered)
   → Name: AUR_EMAIL      Value: abbasi.alain@gmail.com
```

Users can now install on Arch / Manjaro:

```bash
yay -S atlas       # or paru -S atlas
```

### 4. Debian — NO setup needed

The `.deb` workflow only writes to GitHub releases on this repo. No external account, no PPA, no GPG keys. It Just Works using the default `GITHUB_TOKEN`.

Users install via:

```bash
curl -L https://github.com/Abbasi-Alain/atlas/releases/latest/download/atlas_X.Y.Z_all.deb \
  -o /tmp/atlas.deb && sudo dpkg -i /tmp/atlas.deb
```

---

## Required GitHub secrets — checklist

| Secret name | Required for | Set up? |
|---|---|---|
| (none) | `.deb` (uses default `GITHUB_TOKEN`) | ✅ auto |
| `NPM_TOKEN` | `release-npm.yml` | ⏳ |
| `HOMEBREW_TAP_TOKEN` | `release-homebrew.yml` | ⏳ |
| `AUR_SSH_PRIVATE_KEY` | `release-aur.yml` | ⏳ |
| `AUR_USERNAME` | `release-aur.yml` | ⏳ |
| `AUR_EMAIL` | `release-aur.yml` | ⏳ |

Set them at: https://github.com/Abbasi-Alain/atlas/settings/secrets/actions

---

## Versioning convention

ATLAS follows [SemVer](https://semver.org/):

- **Patch** (`v0.1.0 → v0.1.1`): bug fixes, no behavior change. `npm version patch`
- **Minor** (`v0.1.x → v0.2.0`): new features, backwards compatible. `npm version minor`
- **Major** (`v0.x.x → v1.0.0`): breaking changes (spec or CLI surface). `npm version major`

Pre-1.0, occasional minor versions can introduce small breaks if necessary — call them out in the CHANGELOG.

---

## Skipping a channel

If you ever want to release WITHOUT publishing to npm (e.g. fast doc-only bump), comment out the workflow:

```yaml
# In .github/workflows/release-npm.yml, change `published` to a placeholder:
on:
  release:
    types: [SKIP-for-this-release]
```

Then re-enable after the release.

---

## Debugging a failed release

1. Tag pushed but no GH Release? → Check Actions → `release` workflow
2. GH Release created but a channel didn't fire? → Check Actions → the per-channel workflow
3. Channel fired but failed? → Click into the run, read the step output
4. Tap repo got malformed formula? → The `Update Formula/atlas.rb` step uses sed — if your formula's structure deviates, it can fail silently. Test locally:
   ```bash
   cp packaging/homebrew/atlas.rb /tmp/atlas.rb
   sed -i -E "s|^(\s*url\s+\").*(\".*)$|\1NEW_URL\2|" /tmp/atlas.rb
   diff packaging/homebrew/atlas.rb /tmp/atlas.rb
   ```

Most failures are missing or wrong secrets. The error message usually points right at it.
