# AUR (Arch User Repository) setup

To publish ATLAS on AUR, do this **once**:

## 1) Create an AUR account

https://aur.archlinux.org/register

Add your SSH key to your account.

## 2) Clone the empty AUR repo for the package

```bash
git clone ssh://aur@aur.archlinux.org/atlas.git ~/aur-atlas
cd ~/aur-atlas
```

## 3) Copy the PKGBUILD + generate .SRCINFO

```bash
cp /path/to/atlas/packaging/aur/PKGBUILD .
makepkg --printsrcinfo > .SRCINFO
```

## 4) Commit + push

```bash
git add PKGBUILD .SRCINFO
git commit -m "Initial commit: atlas v0.1.0"
git push origin master
```

## 5) Verify

```bash
yay -S atlas
# or
paru -S atlas
# or manual:
git clone https://aur.archlinux.org/atlas.git
cd atlas && makepkg -si
```

## On every new release

```bash
cd ~/aur-atlas
cp /path/to/atlas/packaging/aur/PKGBUILD .   # already updated with new pkgver + sha
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO && git commit -m "atlas vX.Y.Z" && git push
```

## What `yay -S atlas` will do

```
:: Synchronizing package databases...
==> Cloning atlas build files...
==> Making package: atlas 0.1.0-1
==> Retrieving sources...
==> Validating source files with sha256sums...
==> Starting package()...
==> Finished package()...
==> Installing atlas...
```

Done — `atlas version` works.
