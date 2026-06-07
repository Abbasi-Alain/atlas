# Launchpad PPA — step by step (no prior account)

A **PPA** (Personal Package Archive) gives Ubuntu users the familiar:

```bash
sudo add-apt-repository ppa:<your-launchpad-user>/atlas
sudo apt-get update
sudo apt-get install atlas
```

Launchpad hosts and **builds** it for you — you upload a *signed source*
package, their builders produce the `.deb`. You need a Launchpad account and a
GPG key (both free; created below). This is separate from the plain
downloadable `.deb` in [`../debian/`](../debian) — that one needs no account.

> **You cannot do the final steps on macOS.** Building a Debian *source*
> package needs Ubuntu tooling. Use any Ubuntu box, a VM, or Docker:
> `docker run --rm -it -v "$PWD":/src -w /src ubuntu:24.04 bash`.

---

## 1. Create a Launchpad account (~3 min)

1. Go to <https://launchpad.net> → **Log in / Register** (uses Ubuntu One SSO).
2. Pick a username — this becomes your PPA URL: `ppa:<username>/atlas`.
3. Read + agree to the Ubuntu Code of Conduct when prompted (Launchpad asks
   the first time you do anything that needs it).

## 2. Create + upload a GPG key (~5 min)

```bash
# Generate a key (pick RSA 4096; use the SAME email you'll register on Launchpad)
gpg --full-generate-key

# Find the key id (the long hex after 'sec   rsa4096/')
gpg --list-secret-keys --keyid-format=long

# Publish the public key to the keyserver Launchpad reads
gpg --keyserver keyserver.ubuntu.com --send-keys <YOUR_KEY_ID>
```

Then register it on Launchpad:

1. <https://launchpad.net/~/+editpgpkeys>
2. Paste the key **fingerprint** (`gpg --fingerprint <KEY_ID>`, strip spaces).
3. Launchpad emails you an **encrypted** confirmation message. Decrypt it:
   ```bash
   gpg -d the-email-you-got.txt    # or paste the block into `gpg -d`
   ```
   Open the link inside to finish verifying the key.

## 3. Activate the PPA

1. <https://launchpad.net/~> → **Create a new PPA**.
2. URL/name: **`atlas`**. Display name: `ATLAS`. Description: short blurb.

## 4. Build the signed source package

On the Ubuntu box / container, from a **clean clone of this repo at the tag you
want to release** (the script builds from `git archive HEAD`):

```bash
sudo apt-get update
sudo apt-get install -y devscripts debhelper dput-ng gnupg git nodejs

# Build for the current LTS. Re-run per series you want to support.
packaging/ppa/build-ppa.sh noble        # 24.04
packaging/ppa/build-ppa.sh jammy        # 22.04   (separate upload)
```

If you have several GPG keys, pass the one Launchpad knows:
`GPGKEY=<YOUR_KEY_ID> packaging/ppa/build-ppa.sh noble`.

## 5. Upload

The script prints the exact line, e.g.:

```bash
dput ppa:<your-launchpad-user>/atlas /tmp/xxxx/atlas_0.1.0-1~ppa1~noble1_source.changes
```

Launchpad emails you "Accepted" within a minute, then **builds** the `.deb`
(watch progress at `https://launchpad.net/~<user>/+archive/ubuntu/atlas`).
First build of a new series can take 10–30 min.

## 6. Users install

```bash
sudo add-apt-repository ppa:<your-launchpad-user>/atlas
sudo apt-get update
sudo apt-get install atlas
atlas version
```

---

## Notes & gotchas

- **One upload per series.** A `.changes` targets exactly one series (the
  `noble` / `jammy` field in `debian/changelog`). Run the script once per
  series; you may also use Launchpad's web "Copy packages" to clone a build
  across series without rebuilding.
- **Re-uploading the same version?** Launchpad refuses to overwrite. Bump the
  PPA revision: `build-ppa.sh noble 2` → `…~ppa2~noble1`.
- **New upstream version?** Just re-run after bumping `package.json`; the
  script reads the version from there.
- **Generic-name check.** `atlas` is a common name. Before announcing, confirm
  nothing else in the user's sources shadows it: `apt-cache policy atlas`
  should show *your* PPA as the candidate. If a clash ever surfaces, the
  cleanest fix is to rename the binary package to `atlas-agent` in
  `debian/control` (keep the `/usr/bin/atlas` command).
- **Lintian.** `lintian` runs during `debuild`; warnings are usually
  non-fatal. Read them — they're the same checks Debian/Ubuntu reviewers use.
- **This installs to `/usr`** (proper policy), unlike the standalone
  `../debian/build-deb.sh` which uses `/usr/local` for hand-installed `.deb`s.
